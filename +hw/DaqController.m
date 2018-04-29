classdef DaqController < handle
  %HW.DAQCONTROLLER The main class for organizing DAQ outputs
  %   This class deals with creating DAQ sessions, assigning output
  %   channels and generating the relevant waveforms to output to each
  %   channel. 
  %
  %   Example: Setting up water valve interface for a Signals behavour task
  %     %In the romote rig's hardware.mat, instantiate a HW.DAQCONTROLLER
  %     %object to interface with an NI DAQ
  %       daqController = hw.DaqController;
  %     %Set the DAQ id (can be found with daq.getDevices)
  %       daqController.DaqIds = 'Dev1';
  %     %Add a new channel
  %       daqController.ChannelNames = {'rewardValve'};
  %     %Define the channel ID to output on
  %       daqController.DaqChannelIds = {'ai0'};
  %     %As it is an analogue output, set the AnalogueChannelsIdx to true
  %       daqController.AnalogueChannelIdx(1) = true;
  %     %Add a signal generator that will return the correct samples for
  %     %delivering a reward of a specified volume
  %       daqController.SignalGenerators(1) = hw.RewardValveControl;
  %     %Set some of the required fields (see HW.REWARDVALVECONTROL for
  %     %more info
  %       daqController.SignalGenerators(1).OpenValue = 5;
  %       daqController.SignalGenerators(1).Calibrations =
  %       valveDeliveryCalibration(openTimeRange, scalesPort, openValue,...
  %       closedValue, daqChannel, daqDevice);
  %     %Save your hardware file
  %       save('hardware.mat', 'daqController', '-append');
  % 
  %   TODO:
  %    * Currently can not deal with having no analogue channels
  %    * The digital channels must be output only (no support for
  %      bi-directional digital channels
  %
  % See also HW.CONTROLSIGNALGENERATOR, HW.DAQROTARYENCODER
  % 2013    CB created
  % 2017-07 MW added digital output support
  % 2018-04 NS and MW added clock output for reward delivery. 
  %
  % See bottom of this file for test code for clock output.
  

  
  properties
    ChannelNames = {} % name to refer to each channel
    %Signal generator for each channel. Each should be an object of class
    %hw.ControlSignalGenerator, for generating command waveforms.
    SignalGenerators = hw.PulseSwitcher.empty
    DaqIds = 'Dev1' % device ID's for each channel, e.g. 'Dev1'
    DaqChannelIds = {} % DAQ's ID for each channel, e.g. 'ao0'
    SampleRate = 1000 % output sample rate ("scans/sec") of the daq device
        % 1000 is also the default of the ni daq devices themselves, so if
        % you don't change this, it doesn't actually do anything. 
  end
  
  properties (Transient)
    DaqSession % should be a DAQ session containing at least one analogue output channel
    DigitalDaqSession % a DAQ session containing only digital output channels
    % a DAQ session containing a digital clock channel for outputting an
    % asynchronous pulse to the valve controller
    ClockDaqSession
  end
  
  properties (Dependent)
    Value %The current voltage on each DAQ channel
    NumChannels %Number of channels controlled
    AnalogueChannelsIdx %Logical array of analogue channel IDs
  end
  
  properties (Access = private, Transient)
    CurrValue
  end
  
  methods
    function createDaqChannels(obj)
      if isempty(obj.DaqSession)
        obj.DaqSession = daq.createSession('ni');
        obj.DaqSession.Rate = obj.SampleRate; 
      end
      if isempty(obj.DigitalDaqSession)&&any(~obj.AnalogueChannelsIdx)
        obj.DigitalDaqSession = daq.createSession('ni');
      end
      % The first index must always be valve reward controller.  If it is
      % not an analogue channel, add a session for clocked outputs
      if isempty(obj.ClockDaqSession)&&~obj.AnalogueChannelsIdx(1)
        obj.ClockDaqSession = daq.createSession('ni');
        obj.ClockDaqSession.Rate = obj.SampleRate; 
      end
      n = obj.NumChannels;
      if n > 0
        for ii = 1:n
          if iscell(obj.DaqIds)
            daqid = obj.DaqIds{ii};
          else
            daqid = obj.DaqIds;
          end
          if obj.AnalogueChannelsIdx(ii) % is channal analogue?
            obj.DaqSession.addAnalogOutputChannel(...
              daqid, obj.DaqChannelIds{ii}, 'Voltage');
          elseif ii == 1 && ~obj.AnalogueChannelsIdx(ii)
            % The first index must always be valve reward controller.  If
            % the channel is not analogue, add a clock output channel
            obj.ClockDaqSession.addCounterOutputChannel(...
              daqid, obj.DaqChannelIds{ii}, 'PulseGeneration');
          else % assume digital, always output only
            obj.DigitalDaqSession.addDigitalChannel(...
              daqid, obj.DaqChannelIds{ii}, 'OutputOnly');
          end
        end
        v = [obj.SignalGenerators.DefaultValue];
        obj.DaqSession.outputSingleScan(v(obj.AnalogueChannelsIdx));
        if any(~obj.AnalogueChannelsIdx)
          obj.DigitalDaqSession.outputSingleScan(v(~obj.AnalogueChannelsIdx));
        end
        obj.CurrValue = v;
      else
        obj.CurrValue = [];
      end
    end
    
    function command(obj, varargin)
      % Sends command signals to each channel
      %
      % command(channels, values)
      % sends command signals to each channel carrying each value.
      % 'channels' is a cell array of strings with each channel name, and
      % value is
      %
      % command(values)
      % sends command signals to all channels carrying each value
      %
      % [CHANNEL,INDEX] = addAnalogInputChannel(...)
      % addAnalogInputChannel optionally returns CHANNEL, which is an
      % object representing the channel that was added.  It also
      % returns INDEX, which is the index into the Channels array
      % where the channel was added.
      %
      % Example:
      %     s = daq.createSession('ni');
      %     s.addAnalogInputChannel('cDAQ1Mod1', 'ai0', 'Voltage');
      %     s.startForeground();
      %
      % See also addAnalogOutputChannel, removeChannel,
      % daq.getDevices
      values = varargin{1};
      if ischar(varargin{end})
        switch varargin{end}
          case {'fg' 'foreground'}
            foreground = true;
          case {'bg' 'background'}
            foreground = false;
          otherwise
            error('Unrecognised switch option "%s"', varargin{end});
        end
      else
        foreground = false;
      end
      n = size(values, 2);
      if n > 0
        gen = obj.SignalGenerators(1:n);
        rate = obj.DaqSession.Rate;
        waveforms = cell(1, n);
        for ii = 1:n
          if iscell(values)
            v = values{ii};
          else
            v = values(:,ii);
          end
          waveforms{ii} = gen(ii).waveform(rate, v);
        end
        if obj.DaqSession.IsRunning
          % if a daq operation is in progress, stop it, and set its output
          % to the default value
          reset(obj);
        end
        channelNames = obj.ChannelNames(1:n);
        analogueChannelsIdx = obj.AnalogueChannelsIdx(1:n);
        if any(analogueChannelsIdx)&&any(any(values(:,analogueChannelsIdx)~=0))
          queue(obj, channelNames(analogueChannelsIdx), waveforms(analogueChannelsIdx));
          if foreground
            startForeground(obj.DaqSession);
          else
            startBackground(obj.DaqSession);
          end
          readyWait(obj);
          obj.DaqSession.release;
        elseif any(~analogueChannelsIdx)
            %waveforms = waveforms(~analogueChannelsIdx);
            for n = 1:length(waveforms)
              if ~analogueChannelsIdx(n) 
                  if isa(obj.SignalGenerators(n), 'hw.DigiRewardValveControl')
                      
                    dur = waveforms{n};
                    if dur>0
                        obj.ClockDaqSession.DurationInSeconds=dur+0.01;
                        obj.ClockDaqSession.Channels.Frequency = 1/dur/2;
                        obj.ClockDaqSession.Channels.DutyCycle = 0.5;
                        startBackground(obj.ClockDaqSession);

%                         tmr = timer('StartDelay', dur+0.002, ...
%                             'TimerFcn', @(~,~)stop(obj.ClockDaqSession),...
%                             'StopFcn', @(s,~)delete(s));
%                         start(tmr);
                    end
                    
                  else
                      
                      digitalValues = waveforms{n};
                      for m = 1:length(digitalValues)
                        obj.DigitalDaqSession.outputSingleScan(digitalValues(m));
                      end
                      
                  end
              end
            end
        end
      end
    end
    
    function v = get.NumChannels(obj)
      v = numel(obj.DaqChannelIds);
    end
    
    function v = get.AnalogueChannelsIdx(obj)
      v = cellfun(@(ch) any(lower(ch=='a')), obj.DaqChannelIds);
    end
    
    function v = get.Value(obj)
      v = obj.CurrValue;
    end
    
    function set.Value(obj, v)
      readyWait(obj);
      obj.DaqSession.outputSingleScan(v(obj.AnalogueChannelsIdx));
      if any(~obj.AnalogueChannelsIdx)
        obj.DigitalDaqSession.outputSingleScan(v(~obj.AnalogueChannelsIdx));
      end
      obj.CurrValue = v;
    end
    
    function reset(obj)
      stop(obj.DaqSession);
      if ~isempty(obj.DigitalDaqSession)
        stop(obj.DigitalDaqSession);
      end
      v = [obj.SignalGenerators.DefaultValue];
      outputSingleScan(obj.DaqSession, v(obj.AnalogueChannelsIdx));
      if any(~obj.AnalogueChannelsIdx)
        outputSingleScan(obj.DigitalDaqSession, v(~obj.AnalogueChannelsIdx));
      end
      obj.CurrValue = v;
    end
  end
  
  methods (Access = protected)
    function queue(obj, names, waveforms)
      names = ensureCell(names);
      waveforms = ensureCell(waveforms);
      assert(numel(names) == numel(waveforms),...
        'Number of channel names and waveforms not equal');
      len = cellfun(@numel, waveforms);
      defaultValues = [obj.SignalGenerators.DefaultValue];
      samples = repmat(defaultValues(obj.AnalogueChannelsIdx), max(len), 1);
      for ii = 1:numel(waveforms)
        cidx = strcmp(names{ii}, obj.ChannelNames);
        assert(sum(cidx) == 1, 'Channel name mismatch');
        samples(1:len(ii),cidx) = waveforms{ii};
      end
      readyWait(obj);
      %       plot(samples,'-x'), xlim([-1 300])
      obj.DaqSession.queueOutputData(samples);
      %       samplelen = size(samples,1)/1000
      %       dur = obj.DaqSession.DurationInSeconds
    end
    
    function readyWait(obj)
      if obj.DaqSession.IsRunning
        obj.DaqSession.wait();
      end
      if ~isempty(obj.DigitalDaqSession)&&obj.DigitalDaqSession.IsRunning
        obj.DigitalDaqSession.wait();
      end
      if ~isempty(obj.ClockDaqSession)&&obj.ClockDaqSession.IsRunning
        obj.ClockDaqSession.wait();
      end
    end
  end
  
end

% % test code for clock output

% % create session for clock reward output
% ClockDaqSession = daq.createSession('ni');
% daqid = 'Dev2';
% daqch = 'ctr0';
% ClockDaqSession.addCounterOutputChannel(daqid, daqch, 'PulseGeneration')
% dur = 0.25;
% ClockDaqSession.DurationInSeconds=dur+0.01
% ClockDaqSession.Channels.Frequency = 1/dur/2
% ClockDaqSession.Channels.DutyCycle = 0.5
% 
% % create session for simultaneous analog output
% DaqSession = daq.createSession('ni');
% DaqSession.addAnalogOutputChannel(daqid, 'ao0', 'Voltage')
% dat = sin(linspace(0,2*pi,1000));
% DaqSession.queueOutputData(dat')
% 
% % run them both, and the point is that they do not collide
% startBackground(DaqSession); pause(0.1); startBackground(ClockDaqSession);