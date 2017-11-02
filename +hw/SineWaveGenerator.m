classdef SineWaveGenerator < hw.ControlSignalGenerator
  %HW.SINEWAVEGENERATOR Generates a sinewave
  %   Outputs a signwave of a particular frequency, duration and phase.  
  % See also HW.DAQCONTROLLER
  %
  % Part of Rigbox  
  properties
    Frequency % The frequency of the sinewave in Hz
    Duration % The duration of the signwave in seconds
    Offset % The phase of the sinewave
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

