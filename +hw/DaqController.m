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
  %    * Untested with multiple devices
  %
  % See also HW.CONTROLSIGNALGENERATOR, HW.DAQROTARYENCODER
  % 2013    CB created
  % 2017-07 MW added digital output support
  
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
    ClockDaqSession % a DAQ session for implementing output to a clock channel
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
      if isempty(obj.DaqSession)&&any(obj.AnalogueChannelsIdx)
        obj.DaqSession = daq.createSession('ni');
        obj.DaqSession.Rate = obj.SampleRate; 
      end
      if isempty(obj.DigitalDaqSession)&&any(~obj.AnalogueChannelsIdx)
        obj.DigitalDaqSession = daq.createSession('ni');
      end
      if isempty(obj.ClockDaqSession)&&any(strncmp('ctr',(obj.DaqChannelIds),3))
        obj.ClockDaqSession = daq.createSession('ni');
      end
      n = obj.NumChannels;
      if n > 0
        for i = 1:n
          if iscell(obj.DaqIds)
            daqid = obj.DaqIds{i};
          else
            daqid = obj.DaqIds;
          end
          % is channel analogue?
          if strncmp('ao',(obj.DaqChannelIds{i}),2)
            obj.DaqSession.addAnalogOutputChannel(...
              daqid, obj.DaqChannelIds{i}, 'Voltage');
          % is channel clock output?
          elseif strncmp('ctr',(obj.DaqChannelIds{i}),3)
            obj.ClockDaqSession.addCounterOutputChannel(...
              daqid, obj.DaqChannelIds{i}, 'PulseGeneration');
          else % assume digital, always output only
            obj.DigitalDaqSession.addDigitalChannel(...
              daqid, obj.DaqChannelIds{i}, 'OutputOnly');
          end
        end
        v = [obj.SignalGenerators.DefaultValue];
        obj.DaqSession.outputSingleScan(v(obj.AnalogueChannelsIdx));
        if any(~obj.AnalogueChannelsIdx) && ...
            ~( any(strncmp('ctr',(obj.DaqChannelIds),3)) )
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
      % sends command signal to a channel with the corresponding value
      % (i.e. there is a channel-value pair for each command signal)
      % 'channels' is a cell array of strings with each channel name, and 
      % 'value' is a cell array of values?
      %
      % command(values)
      % for length of values, sends command signals to the corresponding
      % ordered channels
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
        for i = 1:n
          if iscell(values)
            v = values{i};
          else
            v = values(:,i);
          end
          waveforms{i} = gen(i).waveform(rate, v);
        end
        if obj.DaqSession.IsRunning
          % if a daq operation is in progress, stop it, and set its output
          % to the default value
          reset(obj);
        end
        channelNames = obj.ChannelNames(1:n);
        analogueChannelsIdx = obj.AnalogueChannelsIdx(1:n);
        % for all analogue channel outputs
        if any(analogueChannelsIdx)&&any(any(values(:,analogueChannelsIdx)~=0))
          queue(obj, channelNames(analogueChannelsIdx), waveforms(analogueChannelsIdx));
          if foreground
            startForeground(obj.DaqSession);
          else
            startBackground(obj.DaqSession);
          end
          readyWait(obj);
          obj.DaqSession.release;
%         elseif any(~analogueChannelsIdx) %why is this an elseif?
%           waveforms = waveforms(~analogueChannelsIdx);
        else % for all digital or clock outputs
          maxLnWaveform = max(cellfun(@length, waveforms));
          % pad shorter waveforms
          for i = 1:length(waveforms)
            waveforms{i}(end:maxLnWaveform) = waveforms{i}(end);
          end
          waveformsMtx = vec2mat(cell2mat(waveforms), maxLnWaveform);
          if iscolumn(waveformsMtx), waveformsMtx = waveformsMtx'; end
          % output first rows of waveformsMtx (values for each channel) (to
          % account for waveforms of different lengths)
          for n = 1:size(waveformsMtx,1)
            % for clock output channels with a valid value to output
            if strncmp('ctr',(obj.DaqChannelIds{n}),3) && waveformsMtx(n,1)>0
              obj.ClockDaqSession.dt = length(waveformsMtx(n,1)) / obj.SampleRate;
              obj.ClockDaqSession.F = 1/obj.ClockDaqSession.dt;
              obj.ClockDaqSession.Duty = 1;
              startBackground(obj.ClockDaqSession);
            else %for digital output channels
              obj.DigitalDaqSession.outputSingleScan(waveformsMtx(n,:));
            end
          end
        end
      end
    end
    
    function clearSessions(obj)
      obj.DaqSession = [];
      obj.DigitalDaqSession = [];
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
    end
  end
  
end

