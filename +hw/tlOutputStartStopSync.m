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
    initialDelay = 0 % sec, time between start of acquisition and onset of this pulse
    pulseDuration = 0.2; % sec, time that the pulse is on at beginning and end
  end
  
  methods
    function obj = tlOutputStartStopSync(name, daqDeviceID, daqChannelID)
      obj.name = name;
      obj.daqDeviceID = daqDeviceID;
      obj.daqChannelID = daqChannelID;      
    end

    function init(obj, ~)
        % called when timeline is initialized (see hw.Timeline/init)
        if obj.enable
            fprintf(1, 'initializing %s\n', obj.toStr);
            obj.session = daq.createSession(obj.daqVendor);
            obj.session.addDigitalChannel(obj.daqDeviceID, obj.daqChannelID, 'OutputOnly');
            outputSingleScan(obj.session, false); % ensure that it starts down
                % by the way, if you use this to control a light for
                % synchronization, note that you can configure in nidaqMX a
                % "default" value for the channel, so for example it will stay
                % "false" at all times even if the computer reboots. 
        end
    end
    
    function start(obj, ~)   
        % called when timeline is started (see hw.Timeline/start)
        if obj.enable
            if obj.verbose
                fprintf(1, 'start %s\n', obj.name);
            end
            pause(obj.initialDelay);
            outputSingleScan(obj.session, true);
            pause(obj.pulseDuration);
            outputSingleScan(obj.session, false);
        end
    end
    
    function process(~, ~, ~)
        % called every time Timeline processes a chunk of data
        %fprintf(1, 'process StartStopSync\n');
        % -- pass
    end
    
    function stop(obj,~)
        % called when timeline is stopped (see hw.Timeline/stop)
        if obj.enable
            if obj.verbose
                fprintf(1, 'stop %s\n', obj.name);
            end

            outputSingleScan(obj.session, true);
            pause(obj.pulseDuration);
            outputSingleScan(obj.session, false);

            stop(obj.session);
            release(obj.session);
            obj.session = [];
        end
    end
    
    function s = toStr(obj)
        s = sprintf('"%s" on %s/%s (StartStopSync, pulse duration %.2f)', obj.name, ...
            obj.daqDeviceID, obj.daqChannelID, obj.pulseDuration);
    end
    
  end
  
end

