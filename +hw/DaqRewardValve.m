classdef DaqRewardValve < hw.RewardController
  %HW.DAQREWARDVALVE Controls a valve via a DAQ to deliver reward
  %   Must (currently) be sole outputer on DAQ session
  %   TODO
  %
  % Part of Rigbox
  
  % 2013-01 CB created    
  
  properties
    DaqSession; % should be a DAQ session containing just one output channel
    DaqId = 'Dev1'; % the DAQ's device ID, e.g. 'Dev1'
    DaqChannelId = 'ao0'; % the DAQ's ID for the counter channel. e.g. 'ao0'
    DaqOutputChannelIdx = 1
    % for controlling the reward valve
    OpenValue = 6;
    ClosedValue = 0;
    MeasuredDeliveries; % deliveries with measured volumes for calibration.
    % This should be a struct array with fields 'durationSecs' & 
    % 'volumeMicroLitres' indicating the duration the valve was open, and the
    % measured volume (in ul) for that delivery. These points are interpolated 
    % to work out how long to open the valve for arbitrary volumes.
  end
  
  properties (Access = protected)
    CurrValue;
  end
  
  methods
    function createDaqChannel(obj)
      obj.DaqSession.addAnalogOutputChannel(obj.DaqId, obj.DaqChannelId, 'Voltage');
      obj.DaqSession.outputSingleScan(obj.ClosedValue);
      obj.CurrValue = obj.ClosedValue;
    end
    function open(obj)
      daqSession = obj.DaqSession;
      if daqSession.IsRunning
        daqSession.wait();
      end
      daqSession.outputSingleScan(obj.OpenValue);
      obj.CurrValue = obj.OpenValue;
    end
    function close(obj)
      daqSession = obj.DaqSession;
      if daqSession.IsRunning
        daqSession.wait();
      end
      daqSession.outputSingleScan(obj.ClosedValue);
      obj.CurrValue = obj.ClosedValue;
    end
    function closed = toggle(obj)
      if obj.CurrValue == obj.ClosedValue;
        open(obj);
        closed = false;
      else
        close(obj);
        closed = true;
      end
    end
    function duration = openDurationFor(obj, microLitres)
      % Returns the duration the valve should be opened for to deliver 
      % microLitres of reward. Is calibrated using interpolation of the
      % measured delivery data.
      volumes = [obj.MeasuredDeliveries.volumeMicroLitres];
      durations = [obj.MeasuredDeliveries.durationSecs];
      if microLitres > max(volumes) || microLitres < min(volumes)
        fprintf('Warning requested delivery of %.1f is outside calibration range\n',...
          microLitres);
      end
      duration = interp1(volumes, durations, microLitres, 'pchip');
    end
    function ul = microLitresFromDuration(obj, duration)
      % Returns the amount of reward the valve would delivery by being open
      % for the duration specified. Is calibrated using interpolation of the
      % measured delivery data.
      volumes = [obj.MeasuredDeliveries.volumeMicroLitres];
      durations = [obj.MeasuredDeliveries.durationSecs];
      ul = interp1(durations, volumes, duration, 'pchip');
    end

    function sz = deliverBackground(obj, sz)
      % size is the volume to deliver in microlitres (ul). This is turned
      % into an open duration for the valve using interpolation of the
      % calibration measurements.
      if nargin < 2
        sz = obj.DefaultRewardSize;
      end
      duration = openDurationFor(obj, sz);
      daqSession = obj.DaqSession;
      sampleRate = daqSession.Rate;
      nOpenSamples = round(duration*sampleRate);
      samples = zeros(nOpenSamples + 3, numel(obj.DaqSession.Channels));
      samples(:,obj.DaqOutputChannelIdx) = [obj.OpenValue*ones(nOpenSamples, 1) ; ...
        obj.ClosedValue*ones(3,1)];
      if daqSession.IsRunning
        daqSession.wait();
      end
%       fprintf('Delivering %gul by opening valve for %gms\n', size, 1000*duration);
      daqSession.queueOutputData(samples);
      daqSession.startBackground();
      time = obj.Clock.now;
      obj.CurrValue = obj.ClosedValue;
      logSample(obj, sz, time);
    end

    function deliverMultiple(obj, size, interval, n, sizeIsOpenDuration)
      % Delivers n rewards in shots spaced in time by at least interval.
      % Useful for example, for obtaining calibration data.
      % If sizeIsOpenDuration is true, then specified size is the open
      % duration of the valve, if false (default), then specified size is the 
      % usual micro litres size converted to open duration using the measurement
      % data for calibration.
      if nargin < 5 || isempty(sizeIsOpenDuration)
        sizeIsOpenDuration = false; % defaults to size is in microlitres
      end
      if isempty(interval)
        interval = 0.1; % seconds - good interval given open/close delays
      end
      daqSession = obj.DaqSession;
      if daqSession.IsRunning
        daqSession.wait();
      end
      if sizeIsOpenDuration
        duration = size;
        size = microLitresFromDuration(obj, size);
      else
        duration = openDurationFor(obj, size);
      end
      sampleRate = daqSession.Rate;
      nsamplesOpen = round(sampleRate*duration);
      nsamplesClosed = round(sampleRate*interval);
      period = 1/sampleRate * (nsamplesOpen + nsamplesClosed);
      signal = [obj.OpenValue*ones(nsamplesOpen, 1) ; ...
        obj.ClosedValue*ones(nsamplesClosed, 1)];
      blockReps = 20;
      blockSignal = repmat(signal, [blockReps 1]);
      nBlocks = floor(n/blockReps);

      for i = 1:nBlocks
        % use the reward timer controller to open and close the reward valve
        daqSession.queueOutputData(blockSignal);
        time = obj.Clock.now;
        daqSession.startForeground();
        fprintf('rewards %i-%i delivered.\n', blockReps*(i - 1) + 1, blockReps*i);
        logSamples(obj, repmat(size, [1 blockReps]), ...
          time + cumsum(period*ones(1, blockReps)) - period);
      end
      remaining = n - blockReps*nBlocks;
      for i = 1:remaining
        % use the reward timer controller to open and close the reward valve
        daqSession.queueOutputData(signal);
        time = obj.Clock.now;
        daqSession.startForeground();
        logSample(obj, size, time);
      end
      fprintf('rewards %i-%i delivered.\n', blockReps*nBlocks + 1, blockReps*nBlocks + remaining);
    end
  end
  
end

