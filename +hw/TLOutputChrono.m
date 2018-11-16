classdef TLOutputChrono < hw.TLOutput
  %HW.TLOUTPUTCHRONO Principle output channel class which sets timeline clock offset 
  %   Timeline uses this to monitor that acquisition is proceeding normally
  %   during a recording and to update the synchronization between the
  %   system time and the timeline time (to prevent drift between daq and
  %   computer clock).
  %
  %   Example:
  %     tl = hw.Timeline;
  %     tl.Outputs(1) = hw.TLOutputChrono('Chrono', 'Dev1', 'PFI4');
  %     tl.start('2018-01-01_1_mouse2', alyxInstance);
  %     >> initializing Chrono
  %     >> start Chrono
  %     >> Timeline started successfully
  %     tl.stop;
  %
  % See also HW.TLOUTPUT, HW.TIMELINE
  %
  % Part of Rigbox
  % 2018-01 NS
  
  properties
    DaqDeviceID % The name of the DAQ device ID, e.g. 'Dev1', see DAQ.GETDEVICES
    DaqChannelID % The name of the DAQ channel ID, e.g. 'port1/line0', see DAQ.GETDEVICES
    DaqVendor = 'ni' % Name of the DAQ vendor
    NextChronoSign = 1 % The value to output on the chrono channel, the sign is changed each 'Process' event
  end
  
  properties (SetAccess = private)
    CurrSysTimeTimelineOffset = 0 % difference between the system time when the last chrono flip occured and the timestamp recorded by the DAQ, see tl.process()
    LastClockSentSysTime % the mean of the system time before and after the last chrono flip.  Used to calculate CurrSysTimeTimelineOffset, see tl.process()
  end
  
  methods
    function obj = TLOutputChrono(hw)
      % TLOUTPUTCHRONO Constructor method
      %   Can take the struct form of a previous instance (as saved in the
      %   Timeline hw struct) to intantiate a new object with the same
      %   properties.
      %
      % See Also HW.TIMELINE
      if nargin
        obj.Name = hw.Name;
        obj.DaqDeviceID = hw.DaqDeviceID;
        obj.DaqVendor = hw.DaqVendor;
        obj.DaqChannelID = hw.DaqChannelID;
        obj.Enable = hw.Enable;
        obj.Verbose = hw.Verbose;
      else % Some safe defaults
        obj.Name = 'Chrono';
        obj.DaqDeviceID = 'Dev1';
        obj.DaqChannelID = 'port1/line0';
      end
    end

    function init(obj, timeline)
      % INIT Initialize the output session
      %   INIT(obj, timeline) is called when timeline is initialized.
      %   Creates the DAQ session and ensures that the clocking test pulse 
      %   can be read back
      %
      % See Also HW.TIMELINE/INIT
        if obj.Enable
            fprintf(1, 'initializing %s\n', obj.toStr);
            obj.Session = daq.createSession(obj.DaqVendor);
            % Turn off warning about clocked sampling availability
            warning('off', 'daq:Session:onDemandOnlyChannelsAdded');
            % Add on-demand digital channel
            obj.Session.addDigitalChannel(obj.DaqDeviceID, obj.DaqChannelID, 'OutputOnly');
            warning('on', 'daq:Session:onDemandOnlyChannelsAdded');
            tls = timeline.Sessions('main');

            %%Send a test pulse low, then high to clocking channel & check we read it back
            idx = cellfun(@(s2)strcmp('chrono',s2), {timeline.Inputs.name});
            outputSingleScan(obj.Session, false)
            x1 = tls.inputSingleScan;
            outputSingleScan(obj.Session, true)
            x2 = tls.inputSingleScan;
            assert(x1(timeline.Inputs(idx).arrayColumn) < 2.5 && x2(timeline.Inputs(idx).arrayColumn) > 2.5,...
                'The clocking pulse test could not be read back');
            obj.CurrSysTimeTimelineOffset = GetSecs; % to initialize this, will be a bit off but fixed after the first pulse
        end
    end
    
    function start(obj, ~) 
      % START Starts the first chrono flip
      %   Called when timeline is started, this outputs the first low
      %   voltage output on the chrono output channel
      %
      % See Also HW.TIMELINE/START
      if obj.Enable % If the object is to be used
          if obj.Verbose; fprintf(1, 'start %s\n', obj.name); end
          t = GetSecs; % system time before output
          outputSingleScan(obj.Session, false) % this will be the clocking pulse detected the first time process is called
          obj.LastClockSentSysTime = (t + GetSecs)/2; 
      end
    end
    
    function process(obj, timeline, event)
      % PROCESS Record the timestamp of last chrono flip, and output again
      %   OBJ.PROCESS(TIMELINE, EVENT) is called every time Timeline
      %   processes a chunk of data. The sign of the chrono signal is
      %   flipped on each call (at LastClockSentSysTime), and the time of
      %   the previous flip is found in the data and its timestamp noted.
      %   This is used by TL.TIME() to convert between system time and
      %   acquisition time.
      %
      % See Also HW.TIMELINE/TIME() and HW.TIMELINE/PROCESS

        if obj.Enable && timeline.IsRunning && ~isempty(obj.Session)
            if obj.Verbose
                fprintf(1, 'process %s\n', obj.Name);                
            end

            % The chrono "out" value is flipped at a recorded time, and the
            % sample index that this flip is measured is noted First, find
            % the index of the flip in the latest chunk of data
            idx = elementByName(timeline.Inputs, 'chrono');
            clockChangeIdx = find(sign(event.Data(:,timeline.Inputs(idx).arrayColumn) - 2.5) == obj.NextChronoSign, 1);

            if obj.Verbose
                fprintf(1, '  CurrOffset=%.2f, LastClock=%.2f\n', ...
                obj.CurrSysTimeTimelineOffset, obj.LastClockSentSysTime);
            end
            
            % Ensure the clocking pulse was detected
            if ~isempty(clockChangeIdx)
                clockChangeTimestamp = event.TimeStamps(clockChangeIdx);
                obj.CurrSysTimeTimelineOffset = obj.LastClockSentSysTime - clockChangeTimestamp;
            else
                warning('Rigging:Timeline:timing', 'clocking pulse not detected - probably lagging more than one data chunk');
            end

            % Now send the next clock pulse
            obj.NextChronoSign = -obj.NextChronoSign; % flip next chrono
            t = GetSecs; % system time before output
            outputSingleScan(obj.Session, obj.NextChronoSign > 0); % send next chrono flip
            obj.LastClockSentSysTime = (t + GetSecs)/2; % record mean before/after system time
            if obj.Verbose
                fprintf(1, '  CurrOffset=%.2f, LastClock=%.2f\n', ...
                obj.CurrSysTimeTimelineOffset, obj.LastClockSentSysTime);
            end
        end
    end
    
    function stop(obj,~)
        % STOP Stops the DAQ session object.
        %   Called when timeline is stopped.  Stops and releases the
        %   session object.
        %
        % See Also HW.TIMELINE/STOP
        if obj.Enable
            if obj.Verbose; fprintf(1, 'stop %s\n', obj.Name); end
            stop(obj.Session);
            release(obj.Session);
            obj.Session = [];
        end
    end
    
    function s = toStr(obj)
      % TOSTR Returns a string that describes the object succintly
      %
      % See Also HW.TIMELINE/INIT
        s = sprintf('"%s" on %s/%s (chrono)', obj.Name, ...
            obj.DaqDeviceID, obj.DaqChannelID);
    end
    
  end
  
end

