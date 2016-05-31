classdef PulseSwitcher < hw.ControlSignalGenerator
  %HW.PULSESWITCHER Generates a train of pulses
  %   Detailed explanation goes here
  
  properties
    OpenValue = 5
    ClosedValue = 0
    %A function of command that returns [duration, number of pulses, freq]
    ParamsFun
  end
  
  methods
    function obj = PulseSwitcher(duration, nPulses, freq)
      obj.DefaultValue = obj.ClosedValue;
      if nargin > 0
        obj.ParamsFun = @(sz) deal(duration, nPulses, freq);
      end
    end

    function samples = waveform(obj, sampleRate, command)
      [dt, npulses, f] = obj.ParamsFun(command);
      wavelength = 1/f;
      duty = dt/wavelength;
      assert(duty <= (1 + 1e-3), 'Pulse width larger than wavelength (duty=%.2f)', duty);
      duty = min(duty, 1);
      len = npulses*wavelength;
      nsamples = ceil(len*sampleRate);
%       fprintf('duty=%.3f,wavelength=%.4f,dt=%.4f\n', duty, wavelength, dt);
      tt = linspace(0, npulses - 1/sampleRate, nsamples)';
      samples = 0.5*(square(2*pi*tt, 100*duty) + 1); % zero to one
      % closed to open
      samples = (obj.OpenValue - obj.ClosedValue)*samples + obj.ClosedValue;
      % add 1 sample at 'closed value' to ensure it remains so
      samples = [samples; obj.ClosedValue];
    end
  end
  
end

