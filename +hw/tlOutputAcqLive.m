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

    function init(obj, ~)
        if obj.enable
            fprintf(1, 'initializing %s\n', obj.toStr);
            obj.session = daq.createSession(obj.daqVendor);
            obj.session.addDigitalChannel(obj.daqDeviceID, obj.daqChannelID, 'OutputOnly');
            outputSingleScan(obj.session, false);
        end
    end
    
    function start(obj, ~) 
        if obj.enable
            if obj.verbose
                fprintf(1, 'start %s\n', obj.name);
            end
                    
            pause(obj.initialDelay);
            outputSingleScan(obj.session, true);
        end
    end
    
    function process(~, ~, ~)
        %fprintf(1, 'process acqLive\n');
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
        s = sprintf('"%s" on %s/%s (acqLive, initial delay %.2f)', obj.name, ...
            obj.daqDeviceID, obj.daqChannelID, obj.initialDelay);
    end
    
  end
  
end

