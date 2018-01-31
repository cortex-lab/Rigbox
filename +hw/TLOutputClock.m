classdef TLOutputClock < hw.TlOutput
  %HW.TLOUTPUTCLOCK A regular pulse at a specified frequency and duty
  %   cycle. Can be used to trigger camera frames.
  %
  %   Example:
  %     tl = hw.Timeline;
  %     tl.Outputs(end+1) = hw.TLOutputClock('Cam-Triggar', 'Dev1', 'PFI4');
  %     tl.Outputs(end).InitialDelay = 5 % Add initial delay before start
  %     tl.start('2018-01-01_1_mouse2', alyxInstance);
  %     >> initializing Cam-Triggar
  %     >> start Cam-Triggar
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
    InitialDelay = 0 % delay from session start to clock output
    Frequency = 60; % Hz, of the clocking pulse
    DutyCycle = 0.2;  % proportion of each cycle that the pulse is "true"
  end    
  
  properties (Transient, Hidden, Access = protected)
      ClockChan % Holds an instance of the PulseGeneration channel 
  end
  
  methods
    function obj = TLOutputClock(name, daqDeviceID, daqChannelID)
      % TLOUTPUTCHRONO Constructor method
      obj.Name = name;
      obj.DaqDeviceID = daqDeviceID;
      obj.DaqChannelID = daqChannelID;      
    end

    function init(obj, ~)
      % INIT Initialize the output session
      %   INIT(obj, timeline) is called when timeline is initialized.
      %   Creates the DAQ session and adds a PulseGeneration channel with
      %   the specified frequency, duty cycle and delay.
      %
      % See Also HW.TIMELINE/INIT
        if obj.Enable
            fprintf(1, 'initializing %s\n', obj.toStr);
            
            obj.session = daq.createSession(obj.DaqVendor);
            obj.session.IsContinuous = true;
            clocked = obj.Session.addCounterOutputChannel(obj.DaqDeviceID, obj.DaqChannelID, 'PulseGeneration');
            clocked.Frequency = obj.Frequency;
            clocked.DutyCycle = obj.DutyCycle;
            clocked.InitialDelay = obj.InitialDelay;
            obj.ClockChan = clocked;
        end
    end
    
    function start(obj, ~)
      % START Starts the clocking pulse
      %   Called when timeline is started, this uses STARTBACKGROUND to
      %   start the clocking pulse
      %
      % See Also HW.TIMELINE/START
        if obj.Enable
            if obj.Verbose; fprintf(1, 'start %s\n', obj.Name); end
            startBackground(obj.session);
        end
    end
    
    function process(~, ~, ~)
      % PROCESS() Listener for processing acquired Timeline data
      %   PROCESS(obj, source, event) is a listener callback
      %   function for handling tl data acquisition. Called by the
      %   'main' DAQ session with latest chunk of data. 
      %
      % See Also HW.TIMELINE/PROCESS

      %fprintf(1, 'process Clock\n');
      % -- pass
    end
    
    function stop(obj,~)
        % STOP Stops the DAQ session object.
        %   Called when timeline is stopped.  Stops and releases the
        %   session object.
        %
        % See Also HW.TIMELINE/STOP
        if obj.Enable
            if obj.Verbose; fprintf(1, 'stop %s\n', obj.Name); end
            stop(obj.session);
            release(obj.session);
            obj.session = [];
        end
    end
    
    function s = toStr(obj)
      % TOSTR Returns a string that describes the object succintly
      %
      % See Also INIT
        s = sprintf('"%s" on %s/%s (clock, %dHz, %.2f duty cycle)', obj.Name, ...
            obj.DaqDeviceID, obj.DaqChannelID, obj.Frequency, obj.DutyCycle);
    end
  end
  
end

