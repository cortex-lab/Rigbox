classdef TLOutputAcqLive < hw.TlOutput
  % HW.TLOUTPUTACQLIVE A digital signal that goes up when the recording starts, 
  % down when it ends.
  %   Used for triggaring external instruments during data aquisition.
  %
  % See also HW.TLOUTPUT and HW.TIMELINE
  %
  % Part of Rigbox
  % 2018-01 NS
  
  properties
    DaqDeviceID
    DaqChannelID
    DaqVendor = 'ni'
    InitialDelay = 0 % sec, time to wait before starting
    PulseDuration = Inf; % sec, time that the pulse is on at beginning and end
  end
  
  methods
    function obj = TLOutputAcqLive(name, daqDeviceID, daqChannelID)
      % TLOUTPUTCHRONO Constructor method
      obj.Name = name;
      obj.DaqDeviceID = daqDeviceID;
      obj.DaqChannelID = daqChannelID;
    end

    function init(obj, ~)
      % INIT Initialize the output session
      %   INIT(obj, timeline) is called when timeline is initialized.
      %   Creates the DAQ session and ensures it is outputting a low
      %   (digital off) signal.
      %
      % See Also HW.TIMELINE/INIT
      if obj.Enable
        fprintf(1, 'initializing %s\n', obj.toStr);
        obj.Session = daq.createSession(obj.DaqVendor);
        obj.Session.addDigitalChannel(obj.DaqDeviceID, obj.DaqChannelID, 'OutputOnly');
        outputSingleScan(obj.Session, false); % start in the off/false state
      end
    end
    
    function start(obj, ~) 
      % START Output a high voltage signal
      %   Called when timeline is started, this outputs the first high
      %   voltage signal to triggar external instrument aquisition
      %
      % See Also HW.TIMELINE/START
      if obj.Enable
        if obj.Verbose; fprintf(1, 'start %s\n', obj.Name); end
        pause(obj.InitialDelay); % wait for some duration before starting
        outputSingleScan(obj.Session, true); % set digital output true: acquisition is "live"
        if obj.PulseDuration ~= Inf
          pause(obj.PulseDuration);
          outputSingleScan(obj.Session, false);
        end
      end
    end
    
    function process(~, ~, ~)
        % called every time Timeline processes a chunk of data
        %fprintf(1, 'process acqLive\n');
        % -- pass
    end
    
    function stop(obj,~)
        % STOP Stops the DAQ session object.
        %   Called when timeline is stopped.  Outputs a low voltage signal,
        %   the stops and releases the session object.
        %
        % See Also HW.TIMELINE/STOP
        if obj.Enable
          % set digital output false: acquisition is no longer "live"
          if obj.PulseDuration ~= Inf
            outputSingleScan(obj.Session, true);
            pause(obj.PulseDuration);
          end
          outputSingleScan(obj.Session, false);
          
          if obj.Verbose; fprintf(1, 'stop %s\n', obj.Name); end
          stop(obj.Session);
          release(obj.Session);
          obj.Session = [];
        end
    end
    
    function s = toStr(obj)
        s = sprintf('"%s" on %s/%s (acqLive, initial delay %.2f)', obj.Name, ...
            obj.DaqDeviceID, obj.DaqChannelID, obj.InitialDelay);
    end
    
  end
  
end

