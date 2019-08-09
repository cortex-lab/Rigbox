classdef Timeline < handle
% HW.TIMELINE A record-keeper that time-aligns acquired hardware signals
%
% A `hw.Timeline` object (tl) manages the aquisition of acquired hardware
% signals using an NI data aquisition device (NI-DAQ). tl generates a main
% timing signal, 'chrono' (an instantiated object of `hw.TLOutputChrono`),
% as a digital squarewave that flips each time a new chunk of data is
% available from the NI-DAQ (see the `NotifyWhenDataAvailableExceeds`
% property in `daq.Sessions` for more info). A callback function to this
% flip event (see `process`) collects the timestamp from the NI-DAQ of the
% precise scan where the chrono signal flipped. The difference between this
% and the system time recorded when the flip command was given is recorded
% as the `CurrSysTimeTimelineOffset` property of `hw.TLOutputChrono`, and 
% can be used to unify all timestamps across computers during an experiment
% (see `time` and `ptbSecsToTimeline`). It is assumed that the time between 
% sending the chrono pulse and recieving it is negligible. tl uses the 
% PsychToolbox function `GetSecs` to get the most reliable system time 
% (see also `GetSecsTest`). NB: both the system time and the DAQ times can 
% (and do) drift.
%
% Besides the chrono signal, tl can aquire any number of inputs and
% record their values on the same clock. For example, tl can record the
% times at which a screen updates via input from a photodiode (see 
% `addInput`). The NI-DAQ wiring information for any given channel can be 
% displayed by running `tl.wiringInfo(name)`.
%
% There are also other available clocking signals besides chrono, for 
% instance, 'acqLive' and 'clock'. The former outputs a high (+5V) signal 
% the entire time tl is aquiring (0V otherwise), and can be used to trigger 
% devices with a TTL input. The latter is a regular pulse at a frequency of
% `ClockOutputFrequency` and duty cycle of `ClockOutputDutyCycle`. This can
% be used to trigger a camera at a specific frame rate. See the
% `properties` block below for further details on output configurations.
%
% tl requires the Data Aquisition Toolbox and the JSONlab add-on.
%
% Example: Set up tl for use with a Signals experiment
%   % Open your hardware.mat file and instantiate a new Timeline object.
%   timeline = hw.Timeline;
%   % Set tl to be started by default.
%   timeline.UseTimeline = true;
%   % To set up chrono, a wire must bridge the channels specified for
%   % chrono in `timeline.Outputs` and `timeline.Inputs`. Get this info
%   % and then physically wire the NI-DAQ accordingly):
%   timeline.wiringInfo('chrono');
%   % Add rotary encoder input to tl.
%   timeline.addInput('rotaryEncoder', 'ctr0', 'Position');
%   % Add lick detector input to tl.
%   timeline.addInput('lickDetector', 'ctr1', 'EdgeCount');
%   % Trigger camera frame acquisition by default.
%   timeline.UseOutputs{end+1} = 'clock';
%   % Save tl to your `hardware.mat` file
%   save('hardware.mat', 'timeline', '-append')
%
% TODO:
%   - Register files to Alyx
%   - Comment livePlot function
%   - In future could implement option to only write to disk to avoid
%     memory limitations when aquiring a lot of data
%   - Delete local binary files once timeline has successfully saved to zserver?
%   - save par file in json instead
%
% See also hw.TimelineClock, hw.TlOutput, hw.TLOutputChrono
%
% Part of Rigbox

% 2014-01 CB created
    
properties
  % 'ni' is using National Instruments USB-6211 DAQ
  DaqVendor = 'ni'
  % Device ID can be found with daq.getDevices()
  DaqIds = 'Dev1'
  % rate at which daq aquires data in Hz, see Rate
  DaqSampleRate = 1000
  % determines the number of data samples to be processed each time,
  % see Timeline.process(), constructor and
  % NotifyWhenDataAvailableExceeds
  DaqSamplesPerNotify
  % array of output classes, defining any signals you desire to be
  % sent from the daq. See Also HW.TLOUTPUT, HW.TLOUTPUTCLOCK
  Outputs = hw.TLOutputChrono
  % All configured inputs.
  Inputs = struct('name', 'chrono',...
    'arrayColumn', -1,... -1 is default indicating unused, this is update when the channels are added during tl.start()
    'daqChannelID', 'ai0',...
    'measurement', 'Voltage',...
    'terminalConfig', 'SingleEnded',...
    'axesScale', 1) % multiplicative vertical scaling for when live plotting the input
  % array of inputs to record while tl is running
  UseInputs = {'chrono'}
  % currently pauses for at least 2 secs as 'hack' before stopping
  % main DAQ session to allow
  StopDelay = 2
  % expected experiment time so data structure is initialised to
  % sensible size (in secs)
  MaxExpectedDuration = 2*60*60
  % default data type for the acquired data array (i.e.
  % Data.rawDAQData)
  AquiredDataType = 'double'
  % If true, timeline is started by default (otherwise can be toggled
  % with the t key in expServer)
  UseTimeline matlab.lang.OnOffSwitchState = 'off'
  % if true the data are plotted as the data are aquired
  LivePlot matlab.lang.OnOffSwitchState = 'off'
  % figure position in normalized units, default is full screen
  FigureScale = [0 0 1 1]
  % if true the data buffer is written to disk as they're aquired NB:
  % in the future this will happen by default
  WriteBufferToDisk matlab.lang.OnOffSwitchState = 'off'
end

properties (Dependent)
  % Sampling interval defined as 1/DaqSampleRate
  SamplingInterval
  % Switch set to true when the first chrono pulse is aquired and
  % set to false when tl is stopped (and everything saved), see
  % tl.process and tl.stop
  IsRunning matlab.lang.OnOffSwitchState = 'off'
end

properties (Transient, Access = protected)
  % holds the listener for 'DataAvailable', see DataAvailable and
  % Timeline.process()
  Listener
  % the last timestamp returned from the daq during the DataAvailable
  % event.  Used to check sampling continuity, see tl.process()
  LastTimestamp
  % the expRef string.  See tl.start()
  Ref
  % a struct contraining the Alyx token, user and url for ile
  % registration.  See tl.start()
  AlyxInstance
  % A structure containing timeline data
  Data
  % A figure handle for plotting the aquired data as it's processed
  Axes
  % The data file ID for writing aquired data directly to disk
  DataFID
end

properties (Transient, SetAccess = protected, GetAccess = {?hw.Timeline, ?hw.TLOutput})
  % Map of daq sessions and their channels, created at tl.start()
  Sessions = containers.Map
end

methods
  function obj = Timeline(hw)
    % TIMELINE Constructor method
    %   HW.TIMELINE(hw) constructor can take a timeline hardware
    %   structure as an input, replicating a previous instance.
    %   Adds chrono, aquireLive and clock to the outputs list,
    %   along with default ports and delays
    
    obj.DaqSamplesPerNotify = 1/obj.SamplingInterval; % calculate DaqSamplesPerNotify
    if nargin % if old tl hardware struct provided, use these to populate properties
      % Configure the inputs
      obj.Inputs = hw.inputs;
      obj.DaqVendor = hw.daqVendor;
      obj.DaqIds = hw.daqDevice;
      obj.DaqSampleRate = hw.daqSampleRate;
      obj.DaqSamplesPerNotify = hw.daqSamplesPerNotify;
      % Configure the outputs
      outputs = catStructs(hw.Outputs);
      obj.Outputs = objfun(@(o)eval([o.Class '(o)']), outputs, 'Uni', false);
      obj.Outputs = [obj.Outputs{:}];
    end
  end
  
  function start(obj, expRef, ai)
    % START Starts timeline data acquisition
    %   START(obj, ref, AlyxInstance) starts all DAQ sessions and adds
    %   the relevant output and input channels.
    %
    % See Also HW.TLOUTPUT/START
    
    if obj.IsRunning % check if it's already running, and if so, stop it
      disp('Timeline already running, stopping first');
      obj.stop();
    end
    obj.Ref = expRef; % set the current experiment ref
    obj.AlyxInstance = ai; % set the current instance of Alyx
    init(obj); % start the relevent sessions and add channels
    
    obj.Listener = obj.Sessions('main').addlistener('DataAvailable', @obj.process); % add listener
    
    % initialise daq data array
    numSamples = obj.DaqSampleRate*obj.MaxExpectedDuration;
    channelDirs = io.daqSessionChannelDirections(obj.Sessions('main'));
    numInputChannels = sum(strcmp(channelDirs, 'Input'));
    
    obj.Data.savePaths = dat.expFilePath(expRef, 'timeline');
    %find the local path to save the data to file during aquisition
    if obj.WriteBufferToDisk
      fprintf(1, 'opening binary file for writing\n');
      localPath = dat.expFilePath(expRef, 'timeline', 'local', 'dat'); % get the local exp data path
      if ~exist(fileparts(localPath),'dir'); mkdir(fileparts(localPath)); end % if the folder doesn't exist, create it
      obj.DataFID = fopen(localPath, 'w'); % open a binary data file
      % save params now so if things crash later you at least have this record of the data type and size so you can load the dat
      parfid = fopen([localPath(1:end-4) '.par'], 'w'); % open a parameter file
      fprintf(parfid, 'type = %s\n', obj.AquiredDataType); % record the data type
      fprintf(parfid, 'nChannels = %d\n', numInputChannels); % record the number of channels
      fprintf(parfid, 'Fs = %d\n', obj.DaqSampleRate); % record the DAQ sample date
      fclose(parfid); % close the file
    end
    
    obj.Data.rawDAQData = zeros(numSamples, numInputChannels, obj.AquiredDataType);
    obj.Data.rawDAQSampleCount = 0;
    obj.Data.startDateTime = now;
    obj.Data.startDateTimeStr = datestr(obj.Data.startDateTime);
    
    %%Start the DAQ acquiring
    %LastTimestamp is the timestamp of the last acquisition sample, which is
    %saved to ensure continuity of acquisition. Here it is initialised as if a
    %previous acquisition had been made in negative time, since the first
    %acquisition timestamp will be zero
    obj.LastTimestamp = -obj.SamplingInterval;
    startBackground(obj.Sessions('main')); % start aquisition
    
    % wait for first acquisition processing to begin
    while ~obj.IsRunning; pause(5e-3); end
    
    % Start each output
    arrayfun(@start, obj.Outputs)
    
    % Report success
    fprintf('Timeline started successfully for ''%s''.\n', expRef);
  end
  
  function record(obj, name, event, t)
    % Records an event in Timeline
    %   TL.RECORD(name, event, [time]) records an event in the Timeline
    %   object in fields prefixed with 'name', with data in 'event'. Optionally
    %   specify time 't', otherwise the time of call will be used (relative to
    %   Timeline acquisition).
    if nargin < 4; t = time(obj); end % default to time now (using Timeline clock)
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
    obj.Data.(timesFieldName)(newCount) = t;
    obj.Data.(eventFieldName){newCount} = event;
    obj.Data.(countFieldName) = newCount;
  end
  
  function secs = time(obj, strict)
    % TIME Time relative to Timeline acquisition
    %   secs = TL.TIME([strict]) Returns the time in seconds relative to
    %   Timeline data acquistion. 'strict' is optional (defaults to true), and
    %   if true, this function will fail if Timeline is not running. If false,
    %   it will just return the time using Psychtoolbox GetSecs if it's not
    %   running.
    % See also TL.PTBSECSTOTIMELINE().
    if nargin < 2; strict = true; end
    if obj.IsRunning
      idx = arrayfun(@(out)isa(out, 'hw.TLOutputChrono'), obj.Outputs);
      secs = GetSecs - obj.Outputs(idx).CurrSysTimeTimelineOffset;
    elseif strict
      error('Tried to use Timeline clock when Timeline is not running');
    else
      % Timeline not running, but not being 'strict' so just return the system
      % time as if it were the Timeline clock
      secs = GetSecs;
    end
  end
  
  function secs = ptbSecsToTimeline(obj, secs)
    % PTBSECSTOTIMELINE Convert from Pyschtoolbox to Timeline time
    %   secs = TL.PTBSECSTOTIMELINE(secs) takes a timestamp 'secs' obtained
    %   from Pyschtoolbox's functions and converts to Timeline-relative time.
    %   See also TL.TIME().
    assert(obj.IsRunning, 'Timeline is not running.');
    idx = arrayfun(@(out)isa(out, 'hw.TLOutputChrono'), obj.Outputs);
    secs = secs - obj.Outputs(idx).CurrSysTimeTimelineOffset;
  end
  
  function addInput(obj, name, channelID, measurement,...
      terminalConfig, axesScale, use)
    % Add a new input to the object's Input property
    %   ADDINPUT(name, channelID, measurement, terminalConfig, use)
    %   adds a new input 'name' to the Inputs list.  If use is
    %   true, the input is also added to the UseInputs array.
    
    % if no terminal config specified, leave empty which means use the
    % DAQ default for that port
    if nargin < 5; terminalConfig = []; end
    
    % if use is not specified, assume user wants normal scaling
    if nargin < 6; axesScale = 1; end
    
    % if use is not specified, assume user wants to record input
    if nargin < 7; use = true; end
    
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
      'terminalConfig', terminalConfig,...
      'axesScale', axesScale);
    obj.Inputs = [obj.Inputs s]; % add the new input
    if use; obj.UseInputs = [obj.UseInputs {name}]; end % add to UseInputs
    
    % Report success
    fprintf('Timeline input ''%s'' successfully added.\n', name);
  end
  
  function wiringInfo(obj, name)
    % WIRINGINFO Displays info on how to wire channels of a NI-DAQ
    %
    % If no channel name (`name`) is given as input, information on the
    % default NI-DAQ channel name conventions are displayed. Else,
    % information on how to wire the channel, `name`, is displayed.
    %
    % Inputs:
    %   `name`: An optional input char of the channel name whose wiring
    %     info is sought.
    
    % If `name` is not given, return default NI-DAQ port name
    % conventions.
    if nargin < 2
      fprintf(['For NI USB-6211, the following channels are '
        'equivalent, by default:\n']);
      fprintf('PFI0-3 = port0/line0-3 = ctr0-3\n')
      fprintf('PFI4-7 = port1/line0-3\n')
      fprintf('ctr0-3 = port1/line0-3\n')
      % Else, return wiring info for a specific channel, `name`
    else
      % Special case for 'chrono' channel: get the matching channel
      % name in both tl's inputs and outputs
      % @todo: `'chrono'` shouldn't be hard-coded below
      if strcmp(name, 'chrono') % Chrono wiring info
        InNameIdx = cellfun(@(s2) strcmp('chrono', s2),...
          {obj.Inputs.name});
        OutNameIdx = cellfun(@(s2) strcmp('chrono', s2),...
          {obj.Outputs.name});
        fprintf('Bridge terminals %s and %s\n',...
          obj.Outputs(OutNameIdx).daqChannelID,...
          obj.Inputs(InNameIdx).daqChannelID)
        % See if `name` matches one of tl's outputs
      elseif any(strcmp(name, {obj.Outputs.name}))
        idx = cellfun(@(s2)strcmp(name,s2), {obj.Outputs.name});
        fprintf('Connect device to terminal %s of the DAQ\n',...
          obj.Outputs(idx).daqChannelID)
        % See if `name` matches one of tl's inputs
      elseif any(strcmp(name, {obj.Inputs.name}))
        idx = cellfun(@(s2)strcmp(name,s2), {obj.Inputs.name});
        fprintf('Connect device to terminal %s of the DAQ\n',...
          obj.Inputs(idx).daqChannelID)
      else
        fprintf('No inputs or outputs of that name were found\n')
      end
    end
  end
  
  function v = get.SamplingInterval(obj)
    %GET.SAMPLINGINTERVAL Defined as the reciprocal of obj.DaqSampleRate
    v = 1/obj.DaqSampleRate;
  end
  
  function bool = get.IsRunning(obj)
    % TL.ISRUNNING Determine whether tl is running.
    %   timeline is officially 'running' when first acquisition
    %   samples are in, i.e. the raw sample count is greater than 0
    if isfield(obj.Data, 'rawDAQSampleCount')&&...
        obj.Data.rawDAQSampleCount > 0
      % obj.Data.rawDAQSampleCount is greater than 0 during the first call to tl.process
      bool = true;
    else % obj.Data is cleared in tl.stop, after all data are saved
      bool = false;
    end
  end
  
  function set.StopDelay(obj, delay)
    if delay < 2
      warning('Timeline:StopDelay:DelayTooShort',...
        'A stop delay less than 2s may cause some output samples to be missed upon stopping');
    end
    obj.StopDelay = delay;
  end
  
  function stop(obj)
    %TL.STOP Stops Timeline data acquisition
    %   TL.STOP() Deletes the listener, saves the aquired data,
    %   stops all running DAQ sessions
    %
    % See Also HW.TLOUTPUT/STOP
    if ~obj.IsRunning
      warning('Nothing to do, Timeline is not running!')
      return
    end
    
    % stop acquisition output signals
    arrayfun(@stop, obj.Outputs)
    % wait for the final samples to be aquired
    pause(obj.StopDelay)
    
    % stop actual DAQ aquisition
    stop(obj.Sessions('main'));
    
    % wait before deleting the listener to ensure most recent
    % samples are processed
    pause(1.5);
    delete(obj.Listener) % now delete the data listener
    
    % only keep the used part of the daq input array
    obj.Data.rawDAQData((obj.Data.rawDAQSampleCount + 1):end,:) = [];
    
    % generate timestamps in seconds for the samples
    obj.Data.rawDAQTimestamps = ...
      obj.SamplingInterval*(0:obj.Data.rawDAQSampleCount - 1);
    
    % replicate old tl data struct for legacy code
    idx = cellfun(@(s2)strcmp('chrono',s2), {obj.Inputs.name});
    arrayChronoColumn = obj.Inputs(idx).arrayColumn;
    inputsIdx = cellfun(@(x)find(strcmp({obj.Inputs.name}, x),1), obj.UseInputs);
    
    % this block finds the daqChannelID for chrono and acqLive if
    % they exist, plus some clock parameters - all for legacy
    % metadata saving, see below
    outputClasses = arrayfun(@class, obj.Outputs, 'uni', false);
    chronoChan = []; nextChrono = []; acqLiveChan = []; useClock = false; clockF = []; clockD = [];
    LastClockSentSysTime = []; CurrSysTimeTimelineOffset = [];
    chronoOutputIdx = find(strcmp(outputClasses, 'hw.TLOutputChrono'),1);
    if ~isempty(chronoOutputIdx)
      chronoChan = obj.Outputs(chronoOutputIdx).DaqChannelID;
      nextChrono = obj.Outputs(chronoOutputIdx).NextChronoSign;
      LastClockSentSysTime = obj.Outputs(chronoOutputIdx).LastClockSentSysTime;
      CurrSysTimeTimelineOffset = obj.Outputs(chronoOutputIdx).CurrSysTimeTimelineOffset;
    end
    acqLiveOutputIdx = find(strcmp(outputClasses, 'hw.TLOutputAcqLive'),1);
    if ~isempty(acqLiveOutputIdx)
      acqLiveChan = obj.Outputs(acqLiveOutputIdx).DaqChannelID;
    end
    clockOutputIdx = find(strcmp(outputClasses, 'hw.TLOutputClock'),1);
    if ~isempty(clockOutputIdx)
      useClock = true;
      clockF = obj.Outputs(clockOutputIdx).Frequency;
      clockD = obj.Outputs(clockOutputIdx).DutyCycle;
    end
    
    % legacy metadata
    obj.Data.hw = struct('daqVendor', obj.DaqVendor, 'daqDevice', obj.DaqIds,...
      'daqSampleRate', obj.DaqSampleRate, 'daqSamplesPerNotify', obj.DaqSamplesPerNotify,...
      'chronoOutDaqChannelID', chronoChan, 'acqLiveOutDaqChannelID', acqLiveChan,...
      'useClockOutput', useClock, 'clockOutputFrequency', clockF,...
      'clockOutputDutyCycle', clockD, 'samplingInterval', obj.SamplingInterval,...
      'inputs', obj.Inputs(inputsIdx), ... % find the correct inputs, in the correct order
      'arrayChronoColumn', arrayChronoColumn);
    obj.Data.expRef = obj.Ref; % save experiment ref
    obj.Data.isRunning = obj.IsRunning;
    obj.Data.nextChronoSign = nextChrono;
    obj.Data.lastTimestamp = obj.LastTimestamp;
    obj.Data.lastClockSentSysTime = LastClockSentSysTime;
    obj.Data.currSysTimeTimelineOffset = CurrSysTimeTimelineOffset;
    
    % saving hardware metadata for each output
    for outIdx = 1:numel(obj.Outputs)
      s = obj2struct(obj.Outputs(outIdx));
      obj.Data.hw.Outputs{outIdx} = s;
    end
    
    % save tl to all paths
    superSave(obj.Data.savePaths, struct('Timeline', obj.Data));
    
    %  write hardware info to a JSON file for compatibility with database
    fid = fopen(fullfile(fileparts(obj.Data.savePaths{2}), 'TimelineHW.json'), 'w');
    fprintf(fid, '%s', jsonencode(obj.Data.hw));
    fclose(fid);
    
    % save each recorded vector into the correct format in Timeline
    % timebase for Alyx and optionally into universal timebase if
    % conversion is provided. TODO: Make timelineToALF a class method
    if ~isempty(which('alf.timelineToALF'))&&~isempty(which('writeNPY'))
      alf.timelineToALF(obj.Data, [],...
        fileparts(dat.expFilePath(obj.Data.expRef, 'timeline', 'master')))
    else
      warning('did not write files into alf format. Check that alyx-matlab and npy-matlab repositories are in path');
    end
    
    %Register ALF components and hardware structures to Alyx
    %database. TODO: Make this process more robust.
    subject = dat.parseExpRef(obj.Data.expRef);
    if ~isempty(obj.AlyxInstance) && obj.AlyxInstance.IsLoggedIn && ~strcmp(subject,'default')
      try
        files = dir(fileparts(obj.Data.savePaths{2}));
        files = fullfile(files(1).folder, {files(endsWith({files.name},...
          {'HW.json', '.raw.npy', '_Timeline.npy'})).name});
        obj.AlyxInstance.registerFile([obj.Data.savePaths{2} files]);
      catch ex
        warning(ex.identifier, 'couldn''t register files to Alyx: %s', ex.message);
      end
    end
    
    % delete data from memory, tl is now officially no longer running
    obj.Data = [];
    
    % reset arrayColumn fields
    [obj.Inputs.arrayColumn] = deal(-1);
    
    % delete the figure axes, if necessary
    if obj.LivePlot; close(get(obj.Axes, 'Parent')); obj.Axes = []; end
    
    % close binary file, if necessary
    if ~isempty(obj.DataFID); fclose(obj.DataFID); end
    
    % Report successful stop
    fprintf('Timeline for ''%s'' stopped and saved successfully.\n', obj.Ref);
  end
end

methods (Access = private)
  function init(obj)
    % Create DAQ session and add channels
    %   TL.INIT() creates all the DAQ sessions
    %   and stores them in the Sessions map by their Outputs name.
    %   Also add a 'main' session to which all input channels are
    %   added.
    %
    % See Also DAQ.CREATESESSION
    
    %%reate channels for each input
    [use, idx] = intersect({obj.Inputs.name}, obj.UseInputs);% find which inputs to use
    assert(numel(idx) == numel(obj.UseInputs), 'Not all inputs were recognised');
    inputSession = daq.createSession(obj.DaqVendor); %create DAQ session for input aquisition
    inputSession.Rate = obj.DaqSampleRate; % set the aquisition sample rate
    inputSession.IsContinuous = true; % once started, continue acquiring until manually stopped
    inputSession.NotifyWhenDataAvailableExceeds = obj.DaqSamplesPerNotify; % when to process data
    obj.Sessions('main') = inputSession;
    for i = 1:length(use)
      in = obj.Inputs(strcmp({obj.Inputs.name}, obj.UseInputs(i)));
      fprintf(1, 'adding channel %s on %s\n', in.name, in.daqChannelID);
      
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
      obj.Inputs(strcmp({obj.Inputs.name}, obj.UseInputs(i))).arrayColumn = i;
    end
    
    %Initialize outputs
    arrayfun(@(out)out.init(obj), obj.Outputs)
  end
  
  function process(obj, ~, event)
    % PROCESS() Listener for processing acquired Timeline data
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
    %
    % See Also HW.TLOUTPUT/PROCESS
    
    %Assert continuity of this data from previous
    assert(abs(event.TimeStamps(1) - obj.LastTimestamp - obj.SamplingInterval) < 1e-8,...
      'Discontinuity of DAQ acquistion detected: last timestamp was %f and this one is %f',...
      obj.LastTimestamp, event.TimeStamps(1));
    
    %Process methods for outputs
    arrayfun(@(out)out.process(obj, event), obj.Outputs);
    
    %Store new samples into the timeline array
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
    % if writing to binary file, save data there
    if obj.WriteBufferToDisk && ~isempty(obj.DataFID)
      datToWrite = cast(event.Data, obj.AquiredDataType); % Ensure data are the correct type
      fwrite(obj.DataFID, datToWrite', obj.AquiredDataType); % Write to file
    end
    
    %If plotting the channels live, plot the new data
    if obj.LivePlot
      obj.livePlot(event.Data)
    else % If LivePlot has been toggled to false, delete the figure
      if ~isempty(obj.Axes)
        close(obj.Axes.Parent)
        obj.Axes = [];
      end
    end
  end
  
  function livePlot(obj, data)
    % Plot the data scans as they're aquired
    %   TL.LIVEPLOT(source, event) plots the data aquired by the
    %   DAQ while the PlotLive property is true.
    if isempty(obj.Axes)
      f = figure('Units', 'Normalized');
      obj.Axes = gca; % store a handle to the axes
      if isprop(obj, 'FigurePosition') && ~isempty(obj.FigurePosition)
        set(f, 'Position', obj.FigurePosition); % set the figure position
      end
    end
    
    % get the names of the inputs being recorded (in the correct
    % order)
    names = pick({obj.Inputs.name}, cellfun(@(x)find(strcmp({obj.Inputs.name}, x),1), obj.UseInputs), 'cell');
    nSamps = size(data,1); % Get the number of samples in this chunck
    nChans = size(data,2); % Get the number of channels
    traceSep = 7; % unit is Volts - for most channels the max is 5V so this is a good separation
    offsets = (1:nChans)*traceSep;
    
    % scales control a vertical scaling of each trace
    % (multiplicative) and can be set manually in the config. A
    % nicer future version would put a scroll wheel callback on the
    % figure and scale by scrolling the one that's hovered over
    scales = pick([obj.Inputs.axesScale], cellfun(@(x)find(strcmp({obj.Inputs.name}, x),1), obj.UseInputs));
    
    traces = get(obj.Axes, 'Children');
    if isempty(traces)
      Fs = obj.DaqSampleRate;
      plot((1:Fs*10)/Fs, zeros(Fs*10, length(names))+repmat(offsets, Fs*10, 1));
      traces = get(obj.Axes, 'Children');
      set(obj.Axes, 'YTick', offsets);
      set(obj.Axes, 'YTickLabel', names);
    end
    
    % get the measurement type of each channel, since Position-type
    % inputs are plotted differently.
    meas = pick({obj.Inputs.measurement}, cellfun(@(x)find(strcmp({obj.Inputs.name}, x),1), obj.UseInputs), 'cell');
    
    for t = 1:length(traces)
      if strcmp(meas{t}, 'Position')
        % if a position sensor (i.e. rotary encoder) scale
        % by the first point and allow negative values
        if any(data(:,t)>2^31); data(data(:,t)>2^31,t) = data(data(:,t)>2^31,t)-2^32; end
        data(:,t) = data(:,t)-data(1,t);
      end
      yy = get(traces(end-t+1), 'YData'); % get current data for trace
      yy(1:end-nSamps) = yy(nSamps+1:end); % add the new chuck for channel
      % scale and offset the traces
      if strcmp(meas{t}, 'Position')
        % for position-type inputs, plot velocity (take the
        % diff, and smooth) rather than absolute. this is
        % necessary to prevent the value from wandering way off
        % the range and making it impossible to see any of the
        % other traces. Plus it is probably more useful,
        % anyway.
        yy(end-nSamps+1:end) = conv(diff([data(1,t); data(:,t)]),...
          gausswin(50)./sum(gausswin(50)), 'same') * scales(t) + offsets(t);
      else
        yy(end-nSamps+1:end) = data(:,t)*scales(t)+offsets(t);
      end
      set(traces(end-t+1), 'YData', yy); % replot with the new data
    end
  end
end
end
