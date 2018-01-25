classdef tlOutputChrono < hw.tlOutput
  %hw.tlOutputChrono Timeline uses this to monitor that
  %   acquisition is proceeding normally during a recording.
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

    function onInit(obj, timeline)
        fprintf(1, 'initialize chrono\n');
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
    end
    
    function onStart(~, ~)     
        fprintf(1, 'start chrono\n');
                        
    end
    
    function onProcess(obj, timeline, event)
        fprintf(1, 'process chrono\n');
        
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
        
    end
    
    function onStop(obj,~)
        fprintf(1, 'stop chrono\n');
        stop(obj.session);
        release(obj.session);
        obj.session = [];
    end
    
  end
  
end

