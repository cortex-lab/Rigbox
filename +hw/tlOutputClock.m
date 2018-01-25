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
    clockChan
  end
  
  methods
    function obj = tlOutputClock(name, daqDeviceID, daqChannelID)
      obj.name = name;
      obj.daqDeviceID = daqDeviceID;
      obj.daqChannelID = daqChannelID;      
    end

    function onInit(obj, ~)
        fprintf(1, 'initialize Clock\n');
        obj.session = daq.createSession(obj.daqVendor);
        obj.session.IsContinuous = true;
        clocked = obj.session.addCounterOutputChannel(obj.daqDeviceID, obj.daqChannelID, 'PulseGeneration');
        clocked.Frequency = obj.frequency;
        clocked.DutyCycle = obj.dutyCycle;
        clocked.InitialDelay = obj.initialDelay;
        obj.clockChan = clocked;

    end
    
    function onStart(obj, ~)     
        fprintf(1, 'start Clock\n');
        
        startBackground(obj.session);        
    end
    
    function onProcess(~, ~, ~)
        fprintf(1, 'process Clock\n');
        
    end
    
    function onStop(obj,~)
        fprintf(1, 'stop Clock\n');                
        
        stop(obj.session);
        release(obj.session);
        obj.session = [];
    end
    
  end
  
end

