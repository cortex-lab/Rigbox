classdef SineWaveGenerator < hw.ControlSignalGenerator
  %HW.PULSESWITCHER Generates a train of pulses
  %   Detailed explanation goes here
  
  properties
    Frequency
    Duration
    Offset
  end
  
  methods
    function obj = SineWaveGenerator(freq, duration, offset)
      obj.DefaultValue = 0;
      obj.Frequency = freq;
      obj.Duration = duration;
      obj.Offset = offset;
    end

    function samples = waveform(obj, sampleRate, amp)
      f = obj.Frequency;
      dt = obj.Duration;
      t = linspace(0, dt - 1/sampleRate, sampleRate*dt);
      samples = amp/2*(-cos(2*pi*f*t) + obj.Offset);
      samples = [samples'; 0];
    end
  end
  
end

