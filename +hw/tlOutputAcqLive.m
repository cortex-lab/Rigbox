classdef tlOutputAcqLive < hw.tlOutput
  %hw.tlOutputAcqLive A digital signal that goes up when the recording starts, 
  %     down when it ends.
  % See also hw.tlOutput and hw.Timeline
  %
  % Part of Rigbox
  % 2018-01 NS
  
  properties
    daqDeviceID
    daqChannelID
    daqVendor = 'ni'
    initialDelay = 0
  end
  
  methods
    function obj = tlOutputAcqLive(name, daqDeviceID, daqChannelID)
      obj.name = name;
      obj.daqDeviceID = daqDeviceID;
      obj.daqChannelID = daqChannelID;      
    end

    function onInit(obj, ~)
        fprintf(1, 'initialize acqLive\n');
        obj.session = daq.createSession(obj.daqVendor);
        obj.session.addDigitalChannel(obj.daqDeviceID, obj.daqChannelID, 'OutputOnly');
        outputSingleScan(obj.session, false);
    end
    
    function onStart(obj, ~)     
        fprintf(1, 'start acqLive\n');
        
        pause(obj.initialDelay);
        outputSingleScan(obj.session, true);
        
    end
    
    function onProcess(~, ~, ~)
        fprintf(1, 'process acqLive\n');
        
    end
    
    function onStop(obj,~)
        fprintf(1, 'stop acqLive\n');
        stop(obj.session);
        release(obj.session);
        obj.session = [];
    end
    
  end
  
end

