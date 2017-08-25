classdef DigitalOnOff < hw.ControlSignalGenerator
  %HW.DigitalOnOff Digital HIGH/LOW switch
  %   Currently converts input to either HIGH or LOW digital output. In the
  %   future timed switch should be introduced.
  
  properties
    OnValue = 5
    OffValue = 0
    ParamsFun = @(in) logical(in); % converts input to logical
  end
  
  methods
    function obj = DigitalOnOff()
      obj.DefaultValue = obj.OffValue;
    end

    function out = waveform(obj, ~, command)
      out = obj.ParamsFun(command);
    end
  end
  
end

