classdef (Sealed) Timeline < handle
% HW.TIMELINE Returns an object that generate and aquires clocking pulses
%   Timeline (tl) manages the aquisition and generation of experimental
%   timing data using an NI data aquisition device.  The main timing signal
%   is called 'chrono' and consists of a digital squarewave that flips each
%   time a new chunk of data is availible from the DAQ (see
%   NotifyWhenDataAvailableExceeds for more information).  A callback
%   function to this event (see tl.process()) collects the timestamp from the
%   DAQ of the precise scan where the chrono signal flipped.  The
%   difference between this and the system time recorded when the flip
%   command was given is recorded as the CurrSysTimeTimelineOffset and can
%   be used to unify all timestamps across computers during an experiment
%   (see tl.time() and tl.ptbSecsToTimeline()).  In is assumed that the
%   time between sending the chrono pulse and recieving it is negligible.
%
%   There are two other available clocking signals: 'acqLive' and 'clock'.
%   The former outputs a high (+5V) signal the entire time tl is aquiring
%   (0V otherwise), and can be used to trigger devices with a TTL input.
%   The 'clock' output is a regular pulse at a frequency of
%   ClockOutputFrequency and duty cycle of ClockOutputDutyCycle.  This can
%   be used to trigger a camera at a specific frame rate.
%
%   Besides the chrono signal, tl can aquire any number of inputs and
%   record their values on the same clock.  For example a photodiode to
%   record the times at which the screen updates (see tl.addInput).
%
%   Timeline uses the PsychToolbox function GetSecs() to get the most
%   reliable system time (see GetSecs() and GetSecsTest()).  NB: both the
%   system time and the DAQ times can (and do) drift.
%
%   Part of Rigbox
%   2014-01 CB created
%   2017-10 MW updated

    properties
        DaqVendor = 'ni' % 'ni' is using National Instruments USB-6211 DAQ
        DaqIds = 'Dev1' % Device ID can be found with daq.getDevices()
        DaqSampleRate = 1000 % rate at which daq aquires data in Hz, see Rate
        DaqSamplesPerNotify % determines the number of data samples to be processed each time, see Timeline.process(), constructor and NotifyWhenDataAvailableExceeds
        Outputs % structure of outputs with their type, delays and ports, see constructor
        Inputs = struct('name', 'chrono',...
            'arrayColumn', -1,... % -1 is default indicating unused, this is update when the channels are added during tl.start()
            'daqChannelID', 'ai0',...
            'measurement', 'Voltage',...
            'terminalConfig', 'SingleEnded')
        UseInputs = {'chrono'} % array of inputs to record while tl is running
        UseOutputs = {'chrono'} % array of output pulses to use while tl is running
        StopDelay = 2 % currently pauses for at least 2 secs as 'hack' before stopping main DAQ session
        MaxExpectedDuration = 2*60*60 % expected experiment time so data structure is initialised to sensible size (in secs)
        ClockOutputFrequency = 60 % if using 'clock' output, this specifies the frequency of pulses (Hz)
        ClockOutputDutyCycle = 0.2 % if using 'clock' output, this specifies the duty cycle (as a fraction)
        AquiredDataType = 'double' % default data type for the acquired data array (i.e. Data.rawDAQData)
        UseTimeline = false % used by expServer.  If true, timeline is started by default (otherwise can be toggled with the t key)
    end
    
    properties (SetAccess = private)
        IsRunning = false % flag is set to true when the first chrono pulse is aquired and set to false when tl is stopped, see tl.process and tl.stop
    end
    
    properties (Dependent)
        SamplingInterval % defined as 1/DaqSampleRate
    end
        
    properties (Transient, Access = private)
        Listener % holds the listener for 'DataAvailable', see DataAvailable and Timeline.process()
        Sessions = containers.Map % map of daq sessions and their channels, created at tl.start()
        CurrSysTimeTimelineOffset % difference between the system time when the last chrono flip occured and the timestamp recorded by the DAQ, see tl.process()
        LastTimestamp % the last timestamp returned from the daq during the DataAvailable event.  Used to check sampling continuity, see tl.process()
        LastClockSentSysTime % the mean of the system time before and after the last chrono flip.  Used to calculate CurrSysTimeTimelineOffset, see tl.process()
        NextChronoSign = 1 % the value to output on the chrono channel, the sign is changed each 'DataAvailable' event (DaqSamplesPerNotify)
        Ref % the expRef string, concatenated with the AlyxInstance used when timeline was started (if user was logged in).  See tl.start()
        Data % A structure containing timeline data
    end
    
    methods
        function obj = Timeline()
            % Constructor method
            %   Adds chrono, aquireLive and clock to the outputs list,
            %   along with default ports and delays
            obj.DaqSamplesPerNotify = 1/obj.SamplingInterval; % calculate DaqSamplesPerNotify
            defaultOutputs = {'chrono', 'acqLive', 'clock';... % names of each output
                'port1/line0', 'port0/line1', 'ctr3';... % their default ports
                'OutputOnly', 'OutputOnly', 'PulseGeneration'; % default output type
                0, 0, 0}; % the initial delay (useful for ensure all systems are ready)
            obj.Outputs = cell2struct(defaultOutputs, {'name', 'daqChannelID', 'type', 'initialDelay'});
        end
        
        function start(obj, expRef, varargin)
            % Starts tl data acquisition
            %   TL.START(obj, expRef, [disregardInputs]) starts all DAQ
            %   sessions and adds the relevent output and input channels.
            %   'disregardInputs' is a cell array of input names (e.g.
            %   'rotaryEncoder' that temporarily not aquired if used by
            %   other sessions.  For example to turn off rotary encoder
            %   recording in tl so the experiment object can access it
            if nargin > 2 
                disregardInputs = ensureCell(varargin{1});
            else; disregardInputs = {};
            end
            if obj.IsRunning % check if it's already running, and if so, stop it
                disp('Timeline already running, stopping first');
                obj.stop();
            end
            obj.Ref = expRef; % set the current experiment ref
            init(obj, disregardInputs); % start the relevent sessions and add channels
            
            %%Send a test pulse low, then high to clocking channel & check we read it back
            idx = cellfun(@(s2)strcmp('chrono',s2), {obj.Inputs.name});
            outputSingleScan(obj.Sessions('chrono'), false)
            x1 = obj.Sessions('main').inputSingleScan;
            outputSingleScan(obj.Sessions('chrono'), true)
            x2 = obj.Sessions('main').inputSingleScan;
            assert(x1(obj.Inputs(idx).arrayColumn) < 2.5 && x2(obj.Inputs(idx).arrayColumn) > 2.5,...
                'The clocking pulse test could not be read back');
            
            obj.Listener = obj.Sessions('main').addlistener('DataAvailable', @obj.process); % add listener
            
            % initialise daq data array
            numSamples = obj.DaqSampleRate*obj.MaxExpectedDuration;
            channelDirs = io.daqSessionChannelDirections(obj.Sessions('main'));
            numInputChannels = sum(strcmp(channelDirs, 'Input'));
            obj.Data.rawDAQData = zeros(numSamples, numInputChannels, obj.AquiredDataType);
            obj.Data.rawDAQSampleCount = 0;
            obj.Data.startDateTime = now;
            obj.Data.startDateTimeStr = datestr(obj.Data.startDateTime);
            
            
            %%Start the DAQ acquiring
            outputSingleScan(obj.Sessions('chrono'), false) % make sure chrono is low
            %LastTimestamp is the timestamp of the last acquisition sample, which is
            %saved to ensure continuity of acquisition. Here it is initialised as if a
            %previous acquisition had been made in negative time, since the first
            %acquisition timestamp will be zero
            obj.LastTimestamp = -obj.SamplingInterval;
            startBackground(obj.Sessions('main')); % start aquisition
            
            %%Output clocking pulse and wait for first acquisition to complete
            % output first clocking high pulse
            t = GetSecs; %system time before outputting chrono flip
            outputSingleScan(obj.Sessions('chrono'), obj.NextChronoSign > 0); % flip chrono signal
            obj.LastClockSentSysTime = (t + GetSecs)/2; % log mean before/after system time
            
            % wait for first acquisition processing to begin
            while ~obj.IsRunning
                pause(5e-3);
            end
            
            if isKey(obj.Sessions, 'acqLive') % is acqLive being used?
                % set acquisition live signal to true
                pause(obj.Outputs(cellfun(@(s2)strcmp('chrono',s2), {obj.Outputs.name})).delay);
                outputSingleScan(obj.Sessions('acqLive'), true);
            end
            if isKey(obj.Sessions, 'clock') % is the clock output being used?
                % start session to send timing output pulses
                startBackground(obj.Sessions('clock'));
            end
            
            % Report success
            fprintf('Timeline started successfully for ''%s''.\n', expRef);
        end
        
        function record(obj, name, event, time)
            % Records an event in Timeline
            %   TL.RECORD(name, event, [time]) records an event in the Timeline
            %   struct in fields prefixed with 'name', with data in 'event'. Optionally
            %   specify 'time', otherwise the time of call will be used (relative to
            %   Timeline acquisition).
            if nargin < 3; time = time(obj); end % default to time now (using Timeline clock)
            initLength = 100; % default initial length of event data arrays
            
            timesFieldName = [name 'Times'];
            countFieldName = [name 'Count'];
            eventFieldName = [name 'Events'];
            
            %%create fields in Timeline struct if not already
            if ~isfield(obj.Data, timesFieldName)
                obj.Data.(timesFieldName) = zeros(initLength,1);
            end
            if ~isfield(obj.Data, countFieldName)
                obj.Data.(countFieldName) = 0;
            end
            if ~isfield(obj.Data, eventFieldName)
                obj.Data.(eventFieldName) = cell(initLength, 1);
            end
            
            %%increment the event count
            newCount = obj.Data.(countFieldName) + 1;
            
            %%grow arrays if necessary
            eventsLength = length(obj.Data.(eventFieldName));
            if newCount > eventsLength
                obj.Data.(eventFieldName){2*eventsLength} = [];
                obj.Data.(timesFieldName) = [obj.Data.(timesFieldName) ; ...
                    zeros(size(obj.Data.(timesFieldName)))];
            end
            
            %%store the event at the appropriate index
            obj.Data.(timesFieldName)(newCount) = time;
            obj.Data.(eventFieldName){newCount} = event;
            obj.Data.(countFieldName) = newCount;
        end
        
        function secs = time(obj, strict)
            % Time relative to Timeline acquisition
            %   secs = TL.TIME([strict]) Returns the time in seconds relative to
            %   Timeline data acquistion. 'strict' is optional (defaults to true), and
            %   if true, this function will fail if Timeline is not running. If false,
            %   it will just return the time using Psychtoolbox GetSecs if it's not
            %   running. See also TL.PTBSECSTOTIMELINE().
            if nargin < 1; strict = true; end
            if obj.IsRunning
                secs = GetSecs - obj.CurrSysTimeTimelineOffset;
            elseif strict
                error('Tried to use Timeline clock when Timeline is not running');
            else
                % Timeline not running, but not being 'strict' so just return the system
                % time as if it were the Timeline clock
                secs = GetSecs;
            end
        end
        
        function secs = ptbSecsToTimeline(obj, secs)
            % Convert from Pyschtoolbox to Timeline time
            %   secs = TL.PTBSECSTOTIMELINE(secs) takes a timestamp 'secs' obtained
            %   from Pyschtoolbox's functions and converts to Timeline-relative time.
            %   See also TL.TIME().
            assert(obj.IsRunning, 'Timeline is not running.');
            secs = secs - obj.CurrSysTimeTimelineOffset;
        end
        
        function addInput(obj, name, channelID, measurement, terminalConfig, use)
            % Add a new input to the object's Input property
            %   TL.ADDINPUT(name, channelID, measurement, terminalConfig, use)
            %   adds a new input 'name' to the Inputs list.  If use is
            %   true, the input is also added to the UseInputs array.
            
            % if no terminal config specified, leave empty which means use the
            % DAQ default for that port
            if nargin < 5; terminalConfig = []; end
                
            % if use is not specified, assume user wants to record input
            if nargin < 6; use = true; end
            
            assert(~any(strcmp(name, {obj.Inputs.name})),...
                'An input by the name of ''%s'' has already been added.', name);
            
            % sanitize measurement variable
            switch lower(measurement)
                case {'volts','voltage'}
                    measurement = 'Voltage';
                case {'edge','edgecount'}
                    measurement = 'EdgeCount';
                case {'pos','position'}
                    measurement = 'Position';
                otherwise
                    error('Unknown measurement type ''%s''', measurement);
            end
            % sanitize terminalConfig variable
            switch lower(char(terminalConfig))
                case {'dif','diff','differential'}
                    terminalConfig = 'Differential';
                case {'single','singleended'}
                    terminalConfig = 'SingleEnded';
            end
            s = struct('name', name,...
                'arrayColumn', -1,... % -1 is default indicating unused
                'daqChannelID', channelID,...
                'measurement', measurement,...
                'terminalConfig', terminalConfig);
            obj.Inputs = [obj.Inputs s]; % add the new input
            if use; obj.UseInputs = [obj.UseInputs {name}]; end % add to UseInputs
            
            % Report success
            fprintf('Timeline input ''%s'' successfully added.\n', name);
        end
        
        function v = get.SamplingInterval(obj)
            v = 1/obj.DaqSampleRate;
        end
        
        function stop(obj)
            %TL.STOP Stops Timeline data acquisition
            %   TL.STOP() Deletes the listener, saves the aquired data,
            %   stops all running DAQ sessions 
            % TODO return arrayColumn to -1
            if ~obj.IsRunning
                warning('Nothing to do, Timeline is not running!')
                return
            end
            % kill acquisition output signals
            if isKey(obj.Sessions, 'acqLive')
                obj.Sessions('acqLive').outputSingleScan(false); % live -> false
            end
            for i = 1:length(obj.UseOutputs)
                name = obj.UseOutputs{i};
                stop(obj.Sessions(name));
            end
            
            pause(obj.StopDelay)
            % stop actual DAQ aquisition
            stop(obj.Sessions('main'));
            
            % wait before deleting the listener to ensure most recent samples are
            % collected
            pause(1.5);
            delete(obj.Listener) % now delete the data listener
            
            % turn off the timeline running flag
            obj.IsRunning = false;
            
            % release hardware resources
            sessions = keys(obj.Sessions); % find names of all current sessions
            for i = 1:length(sessions)
                name = sessions{i};
                release(obj.Sessions(name));
            end
            
            % save tl to all paths
            savePaths = dat.expFilePath(obj.Ref, 'timeline'); %TODO fix for AlyxInstance ref
            superSave(savePaths, struct('Timeline', obj.Data)); % TODO replicate old tl struct
            
            % reset arrayColumn fields
            [obj.Inputs.arrayColumn] = deal(-1);
            
            % Report successful stop
            fprintf('Timeline for ''%s'' stopped and saved successfully.\n', obj.Ref);
        end
    end
    
    methods (Access = private)
        function init(obj, disregardInputs)
            % Create DAQ session and add channels
            %   TL.INIT(disregardInputs) creates all the DAQ sessions
            %   and stores them in the Sessions map by their Outputs name.
            %   Also add a 'main' session to which all input channels are
            %   added.  See daq.createSession
            
            %%Create session objects for chrono and other outputs
            [use, idx] = intersect({obj.Outputs.name}, obj.UseOutputs); % find which outputs to use
%             assert(numel(idx) == numel(obj.UseOutputs), 'Not all outputs were recognised');
            for i = 1:length(use)
                out = obj.Outputs(idx(i)); % get channel info, etc.
                switch use{i}
                    case 'chrono'
                        obj.Sessions('chrono') = daq.createSession(obj.DaqVendor);
                        obj.Sessions('chrono').addDigitalChannel(obj.DaqIds, out.daqChannelID, out.type);
                        
                    case 'acqLive'
                        obj.Sessions('acqLive') = daq.createSession(obj.DaqVendor);
                        obj.Sessions('acqLive').addDigitalChannel(obj.DaqIds, out.daqChannelID, out.type);
                        obj.Sessions('acqLive').outputSingleScan(false); % ensure acq live is false
                        
                    case 'clock'
                        obj.Sessions('clock') = daq.createSession(obj.DaqVendor);
                        obj.Sessions('clock').IsContinuous = true;
                        clocked = obj.Sessions('clock').addCounterOutputChannel(obj.DaqIds, out.daqChannelID, out.type);
                        clocked.Frequency = obj.ClockOutputFrequency;
                        clocked.DutyCycle = obj.ClockOutputDutyCycle;
                        clocked.InitialDelay = out.delay;
                end
            end
            %%Create channels for each input
            [use, idx] = intersect({obj.Inputs.name}, obj.UseInputs);% find which inputs to use
            assert(numel(idx) == numel(obj.UseInputs), 'Not all inputs were recognised');
            inputSession = daq.createSession(obj.DaqVendor);
            inputSession.Rate = obj.DaqSampleRate;
            inputSession.IsContinuous = true; % once started, continue acquiring until manually stopped
            inputSession.NotifyWhenDataAvailableExceeds = obj.DaqSamplesPerNotify; % when to process data
            obj.Sessions('main') = inputSession;
            for i = 1:length(use)
                if any(strcmp(use{i}, disregardInputs)); continue; end
                in = obj.Inputs(idx(i)); % get channel info, etc.
                switch in.measurement
                    case 'Voltage'
                        ch = obj.Sessions('main').addAnalogInputChannel(obj.DaqIds, in.daqChannelID, in.measurement);
                        if ~isempty(in.terminalConfig)
                            ch.TerminalConfig = in.terminalConfig;
                        end
                    case 'EdgeCount'
                        obj.Sessions('main').addCounterInputChannel(obj.DaqIds, in.daqChannelID, in.measurement);
                    case 'Position'
                        ch = obj.Sessions('main').addCounterInputChannel(obj.DaqIds, in.daqChannelID, in.measurement);
                        % we assume quadrature encoding (X4) for position measurement
                        ch.EncoderType = 'X4';
                end
                obj.Inputs(idx(i)).arrayColumn = i;
            end
        end
        
        function process(obj, ~, event)
            % Listener for processing acquired Timeline data
            %   TL.PROCESS(source, event) is a listener callback
            %   function for handling tl data acquisition. Called by the
            %   'main' DAQ session with latest chunk of data. This is
            %   compiled into an array which is later saved (see
            %   tl.stop()). Additionally, sign of the chrono signal is
            %   flipped on each call (at LastClockSentSysTime), and the
            %   time of the previous flip is found in the data and its
            %   timestamp noted. This is used by tl.time() to convert
            %   between system time and acquisition time. 
            %   
            %   LastTimestamp is the time of the last scan in the previous
            %   data chunk, and is used to ensure no data samples have been
            %   lost.

            % timeline is officially 'running' when first acquisition samples are in
            if ~obj.IsRunning; obj.IsRunning = true; end
            
            % assert continuity of this data from previous
            assert(abs(event.TimeStamps(1) - obj.LastTimestamp - obj.SamplingInterval) < 1e-8,...
                'Discontinuity of DAQ acquistion detected: last timestamp was %f and this one is %f',...
                obj.LastTimestamp, event.TimeStamps(1));
            
            %Now send the next clock pulse
            obj.NextChronoSign = -obj.NextChronoSign; % flip next chrono
            t = GetSecs; % system time before output
            outputSingleScan(obj.Sessions('chrono'), obj.NextChronoSign > 0); % send next chrono flip
            obj.LastClockSentSysTime = (t + GetSecs)/2; % record mean before/after system time
            
            %%Store new samples into the timeline array
            prevSampleCount = obj.Data.rawDAQSampleCount;
            newSampleCount = prevSampleCount + size(event.Data, 1);
            
            %If necessary, grow input array by doubling its size
            while newSampleCount > size(obj.Data.rawDAQData, 1)
                disp('Reached capacity of DAQ data array, growing');
                obj.Data.rawDAQData = [obj.Data.rawDAQData ; zeros(size(obj.Data.rawDAQData))];
            end
            
            %Now slice the data into the array
            obj.Data.rawDAQData((prevSampleCount + 1):newSampleCount,:) = event.Data;
            obj.Data.rawDAQSampleCount = newSampleCount;
            
            %Update continuity timestamp for next check
            obj.LastTimestamp = event.TimeStamps(end);
        end
        
    end
end