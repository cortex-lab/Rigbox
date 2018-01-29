classdef tlOutputClock < hw.tlOutput
  %hw.tlOutputClock A a regular pulse at a specified frequency and duty
  %   cycle. Can be used to trigger camera frames, e.g.
  % See also hw.tlOutput and hw.Timeline
  %
  % Part of Rigbox
  % 2018-01 NS
  
  properties
    daqDeviceID
    daqChannelID
    daqVendor = 'ni'
    initialDelay = 0
    frequency = 60; 
    dutyCycle = 0.2;    
  end    
  
  properties (Transient)
      clockChan
  end
  
  methods
    function obj = tlOutputClock(name, daqDeviceID, daqChannelID)
      obj.name = name;
      obj.daqDeviceID = daqDeviceID;
      obj.daqChannelID = daqChannelID;      
    end

    function init(obj, ~)
        if obj.enable
            fprintf(1, 'initializing %s\n', obj.toStr);
            
            obj.session = daq.createSession(obj.daqVendor);
            obj.session.IsContinuous = true;
            clocked = obj.session.addCounterOutputChannel(obj.daqDeviceID, obj.daqChannelID, 'PulseGeneration');
            clocked.Frequency = obj.frequency;
            clocked.DutyCycle = obj.dutyCycle;
            clocked.InitialDelay = obj.initialDelay;
            obj.clockChan = clocked;
        end
    end
    
    function start(obj, ~)
        if obj.enable
            if obj.verbose
                fprintf(1, 'start %s\n', obj.name);
            end
            startBackground(obj.session);
        end
    end
    
    function process(~, ~, ~)
        %fprintf(1, 'process Clock\n');
        % -- pass
    end
    
    function stop(obj,~)
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
        s = sprintf('"%s" on %s/%s (clock, %dHz, %.2f duty cycle)', obj.name, ...
            obj.daqDeviceID, obj.daqChannelID, obj.frequency, obj.dutyCycle);
    end
  end
  
end

