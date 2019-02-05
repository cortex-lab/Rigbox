classdef DaqSingleScan < hw.ControlSignalGenerator
  %HW.DaqSingleScan Outputs a single value, just changing the level of the
  %analog output
  %   
  %
  
  properties        
    Scale % multiplicatively scale the output
          % for instance, make this a conversion factor between your
          % desired output units (like mm of a galvo, or mW of a laser) and
          % voltage
  end
  
  methods
    function obj = DaqSingleScan(scale)
      obj.DefaultValue = 0;      
      obj.Scale = scale;
    end

    function samples = waveform(obj, varargin)
      % just take the first value (if multiple were provided) and output
      % it, scaled, as a single number. This will result in the analog
      % output channel switching to that value and staying there. 
      samples = varargin{end}*obj.Scale; 
    end
  end
  
end

