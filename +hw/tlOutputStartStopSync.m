classdef tlOutputStartStopSync < hw.tlOutput
  %hw.tlOutputStartStopSync A digital signal that goes up when the recording starts, 
  %     but just briefly, then down again at the end. 
  % See also hw.tlOutput and hw.Timeline
  %
  % Part of Rigbox
  % 2018-01 NS
  
  properties
    daqDeviceID
    daqChannelID
    daqVendor = 'ni'
    initialDelay = 0
    pulseDuration = 0.2;
  end
  
  methods
    function obj = tlOutputStartStopSync(name, daqDeviceID, daqChannelID)
      obj.name = name;
      obj.daqDeviceID = daqDeviceID;
      obj.daqChannelID = daqChannelID;      
    end

    function onInit(obj, ~)
        fprintf(1, 'initialize StartStopSync\n');
        obj.session = daq.createSession(obj.daqVendor);
        obj.session.addDigitalChannel(obj.daqDeviceID, obj.daqChannelID, 'OutputOnly');
        outputSingleScan(obj.session, false); % ensure that it starts down
            % by the way, if you use this to control a light for
            % synchronization, note that you can configure in nidaqMX a
            % "default" value for the channel, so for example it will stay
            % "false" at all times even if the computer reboots. 
    end
    
    function onStart(obj, ~)     
        fprintf(1, 'start StartStopSync\n');
        
        pause(obj.initialDelay);
        outputSingleScan(obj.session, true);
        pause(obj.pulseDuration);
        outputSingleScan(obj.session, false);
        
    end
    
    function onProcess(~, ~, ~)
        fprintf(1, 'process StartStopSync\n');
        
    end
    
    function onStop(obj,~)
        fprintf(1, 'stop StartStopSync\n');
        
        outputSingleScan(obj.session, true);
        pause(obj.pulseDuration);
        outputSingleScan(obj.session, false);
        
        stop(obj.session);
        release(obj.session);
        obj.session = [];
    end
    
  end
  
end

