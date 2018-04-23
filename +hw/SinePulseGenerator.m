classdef SinePulseGenerator < hw.ControlSignalGenerator
  %HW.PULSESWITCHER Generates a train of pulses
  %   Detailed explanation goes here
  
  properties    
    Offset
  end
  
  methods
    function obj = SinePulseGenerator(offset)
      obj.DefaultValue = 0;      
      obj.Offset = offset;
    end

    function samples = waveform(obj, sampleRate, pars)
      dt = pars(1);
      
      if numel(pars)==3
          f = pars(2);
          amp = pars(3);
      else
          f = 40;
          amp = 1;
      end
      
      % first construct one cycle at this frequency      
      oneCycleDt = 1/f;
      t = linspace(0, oneCycleDt - 1/sampleRate, sampleRate*oneCycleDt);
      samples = amp/2*(-cos(2*pi*f*t) + 1);
      
      % if dt is greater than the duration of that cycle, then put zeros in
      % the middle
      if dt>oneCycleDt
          nSamp = round(dt*sampleRate)-numel(samples);
          m = round(numel(samples)/2);
          samples = [samples(1:m) amp*ones(1,nSamp) samples(m+1:end)];
      end
      
      % add a zero so it turns off at the end
      samples = [samples'; 0];
      
      samples = samples+obj.Offset;
    end
  end
  
end

