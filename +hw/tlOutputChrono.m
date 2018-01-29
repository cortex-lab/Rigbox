classdef tlOutputChrono < hw.tlOutput
  %hw.tlOutputChrono Timeline uses this to monitor that
  %   acquisition is proceeding normally during a recording and to update
  %   the synchronization between the system time and the timeline time (to
  %   prevent drift between daq and computer clock). 
  % See also hw.tlOutput and hw.Timeline
  %
  % Part of Rigbox
  % 2018-01 NS
  
  properties
    daqDeviceID
    daqChannelID
    daqVendor = 'ni'
    NextChronoSign = 1 % the value to output on the chrono channel, the sign is changed each 'Process' event
  end
  
  methods
    function obj = tlOutputChrono(name, daqDeviceID, daqChannelID)
      obj.name = name;
      obj.daqDeviceID = daqDeviceID;
      obj.daqChannelID = daqChannelID;      
    end

    function init(obj, timeline)
        % called when timeline is initialized (see hw.Timeline/init)
        if obj.enable
            fprintf(1, 'initializing %s\n', obj.toStr);
            obj.session = daq.createSession(obj.daqVendor);
            obj.session.addDigitalChannel(obj.daqDeviceID, obj.daqChannelID, 'OutputOnly');

            tls = timeline.getSessions('main');

            %%Send a test pulse low, then high to clocking channel & check we read it back
            idx = cellfun(@(s2)strcmp('chrono',s2), {timeline.Inputs.name});
            outputSingleScan(obj.session, false)
            x1 = tls.inputSingleScan;
            outputSingleScan(obj.session, true)
            x2 = tls.inputSingleScan;
            assert(x1(timeline.Inputs(idx).arrayColumn) < 2.5 && x2(timeline.Inputs(idx).arrayColumn) > 2.5,...
                'The clocking pulse test could not be read back');
            
            timeline.CurrSysTimeTimelineOffset = GetSecs; % to initialize this, will be a bit off but fixed after the first pulse
        end
    end
    
    function start(obj, timeline) 
        % called when timeline is started (see hw.Timeline/start)
        if obj.enable
            if obj.verbose
                fprintf(1, 'start %s\n', obj.name);
            end
            t = GetSecs; % system time before output
            outputSingleScan(obj.session, false) % this will be the clocking pulse detected the first time process is called
            timeline.LastClockSentSysTime = (t + GetSecs)/2; 
        end
    end
    
    function process(obj, timeline, event)
        % called every time Timeline processes a chunk of data
        if obj.enable && timeline.IsRunning && ~isempty(obj.session)
            if obj.verbose
                fprintf(1, 'process %s\n', obj.name);                
            end
            %   sign of the chrono signal is
            %   flipped on each call (at LastClockSentSysTime), and the
            %   time of the previous flip is found in the data and its
            %   timestamp noted. This is used by tl.time() to convert
            %   between system time and acquisition time.
            %
            %   LastTimestamp is the time of the last scan in the previous
            %   data chunk, and is used to ensure no data samples have been
            %   lost.

            %%% The chrono "out" value is flipped at a recorded time, and
            %%% the sample index that this flip is measured is noted
            % First, find the index of the flip in the latest chunk of data
            idx = elementByName(timeline.Inputs, 'chrono');
            clockChangeIdx = find(sign(event.Data(:,timeline.Inputs(idx).arrayColumn) - 2.5) == obj.NextChronoSign, 1);

            if obj.verbose
                fprintf(1, '  CurrOffset=%.2f, LastClock=%.2f\n', ...
                timeline.CurrSysTimeTimelineOffset, timeline.LastClockSentSysTime);
            end
            
            %Ensure the clocking pulse was detected
            if ~isempty(clockChangeIdx)
                clockChangeTimestamp = event.TimeStamps(clockChangeIdx);
                timeline.CurrSysTimeTimelineOffset = timeline.LastClockSentSysTime - clockChangeTimestamp;
            else
                warning('Rigging:Timeline:timing', 'clocking pulse not detected - probably lagging more than one data chunk');
            end

            %Now send the next clock pulse
            obj.NextChronoSign = -obj.NextChronoSign; % flip next chrono
            t = GetSecs; % system time before output
            outputSingleScan(obj.session, obj.NextChronoSign > 0); % send next chrono flip
            timeline.LastClockSentSysTime = (t + GetSecs)/2; % record mean before/after system time
            if obj.verbose
                fprintf(1, '  CurrOffset=%.2f, LastClock=%.2f\n', ...
                timeline.CurrSysTimeTimelineOffset, timeline.LastClockSentSysTime);
            end
            
        end
    end
    
    function stop(obj,~)
        % called when timeline is stopped (see hw.Timeline/stop)
        if obj.enable
            if obj.verbose
                fprintf(1, 'stop %s\n', obj.name);                
            end
            stop(obj.session);
            release(obj.session);
            obj.session = [];
        end
    end
    
    function s = toStr(obj)
        s = sprintf('"%s" on %s/%s (chrono)', obj.name, ...
            obj.daqDeviceID, obj.daqChannelID);
    end
    
  end
  
end

