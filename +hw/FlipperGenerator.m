classdef FlipperGenerator < hw.ControlSignalGenerator
  %HW.PULSESWITCHER Generates a train of pulses
  %   Detailed explanation goes here
  
  properties    
    Offset
    OldSamples = []
    OldTime = 0;
    Scale = 0;
  end
  
  methods
    function obj = FlipperGenerator(offset)
      obj.DefaultValue = 0;      
      obj.Offset = offset;
    end

    function samples = waveform(obj, sampleRate, pars)
      dt = pars(1);
      
      if dt>0 || numel(pars)>1 % we have a new request for output!
          % btw, if you want to set output to zero then ask for amp=0 like
          % pars=[0 40 0]. But it will go back to DefaultValue actually!
          
          obj.OldTime = now;
          
          if numel(pars)==3
              f = pars(2);
              amp = pars(3);
          else
              f = 50;
              amp = 1;
          end

          samples = amp*sign(sin((0:round(sampleRate*dt))/f));          

          % back to defaultValue at the end
          samples = [obj.Scale*samples'; obj.DefaultValue];

          samples = samples+obj.Offset;
          
          obj.OldSamples = samples;
      else
          
          % we got "0" so this was a request for someone else. Let's check
          % if our old samples are probably done playing or not, and if not
          % we'll ask to send the rest of the samples out. 
          
          samples = obj.DefaultValue;
          
          if ~isempty(obj.OldSamples) % we had previously played something
              
              newT = now;
              oldSampDur = numel(obj.OldSamples)/sampleRate;
              
              timeSinceLast = (newT-obj.OldTime)*24*3600; % to seconds
              
              if timeSinceLast<oldSampDur  %the last one was probably not done playing, it hasn't been long enough
                  samplesSinceLast = round(timeSinceLast*sampleRate);
                  samples = obj.OldSamples(samplesSinceLast:end);                  
              end
              
          end
      end
    end
  end
  
end

