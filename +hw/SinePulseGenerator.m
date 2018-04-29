classdef SinePulseGenerator < hw.ControlSignalGenerator
  %HW.PULSESWITCHER Generates a train of pulses
  %   Detailed explanation goes here
  
  properties    
    Offset
    OldSamples = []
    OldTime = 0;
  end
  
  methods
    function obj = SinePulseGenerator(offset)
      obj.DefaultValue = 0;      
      obj.Offset = offset;
    end

    function samples = waveform(obj, sampleRate, pars)
        %pars
      dt = pars(1);
      
      if dt>0 || numel(pars)>1 % we have a new request for output!
          %fprintf(1, 'new request\n')
          % btw, if you want to set output to zero then ask for amp=0 like
          % pars=[0 40 0]. But it will go back to DefaultValue actually!
          
          obj.OldTime = now;
          
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

          % back to defaultValue at the end
          samples = [samples'; obj.DefaultValue];

          samples = samples+obj.Offset;
          
          obj.OldSamples = samples;
      else
          fprintf(1, 'command not for us\n')
          % we got "0" so this was a request for someone else. Let's check
          % if our old samples are probably done playing or not, and if not
          % we'll ask to send the rest of the samples out. 
          
          samples = obj.DefaultValue;
          
          if ~isempty(obj.OldSamples) % we had previously played something
              
              newT = now;
              oldSampDur = numel(obj.OldSamples)/sampleRate;
              
              timeSinceLast = (newT-obj.OldTime)*24*3600; % to seconds
              
              if timeSinceLast<oldSampDur  %the last one was probably not done playing, it hasn't been long enough
                  fprintf(1, 'sending old samples\n')
                  samplesSinceLast = round(timeSinceLast*sampleRate);
                  samples = obj.OldSamples(samplesSinceLast:end);                  
              end
              
          end
      end
    end
  end
  
end

