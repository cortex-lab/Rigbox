classdef DaqLaser < hw.RewardController
  %DAQLASER Controls a laser via a DAQ to deliver reward
  %   Must (currently) be sole outputer on DAQ session
  
  properties
    DaqSession % should be a DAQ session containing just one output channel
    DaqId = 'Dev1' % the DAQ's device ID, e.g. 'Dev1'
    DaqChannelId = 'ao1' % the DAQ's ID for the counter channel. e.g. 'ao0'
    DaqOutputChannelIdx = 2
    % for controlling the reward valve
    OpenValue = 5
    ClosedValue = 0
    MeasuredDeliveries %
    PulseLength = 10e-3 % seconds
    StimDuration = 0.5 % seconds
    PulseFrequency = 25 %Hz
  end
  
  properties (Access = protected)
    CurrValue
  end
  
  methods
    function createDaqChannel(obj)
      obj.DaqSession.addAnalogOutputChannel(obj.DaqId, obj.DaqChannelId, 'Voltage');
%       obj.DaqSession.outputSingleScan(obj.ClosedValue);
      obj.CurrValue = 0;
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
    function samples = waveformFor(obj, size)
      % Returns the waveform that should be sent to the DAQ to control
      % reward output given a certain reward size
      sampleRate = obj.DaqSession.Rate;
      
      nCycles = ceil(obj.PulseFrequency*obj.StimDuration);
      nSamples = nCycles/obj.PulseFrequency*sampleRate;
      samples = zeros(nSamples/nCycles, nCycles);
      nPulseSamples = obj.PulseLength*sampleRate;
      samples(1:nPulseSamples,:) = obj.OpenValue;
      samples = samples(:);
    end

    function deliverBackground(obj, size)
      % size not implemeneted yet
      lasersamples = waveformFor(obj, size);
      samples = zeros(numel(lasersamples), numel(obj.DaqSession.Channels));
      samples(:,obj.DaqOutputChannelIdx) = lasersamples;
      daqSession = obj.DaqSession;
      if daqSession.IsRunning
        daqSession.wait();
      end
      daqSession.queueOutputData(samples);
      daqSession.startBackground();
      time = obj.Clock.now;
      obj.CurrValue = obj.ClosedValue;
      logSample(obj, size, time);
    end
    
    function deliverMultiple(obj, size, interval, n, sizeIsOpenDuration)
      error('not implemented')
    end
  end
  
end

