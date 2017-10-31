classdef DigitalOnOff < hw.ControlSignalGenerator
  %HW.DIGITALONOFF Digital HIGH/LOW switch
  %   Currently converts input to either HIGH or LOW digital output. In the
  %   future timed switch should be introduced.
  %
  % See also HW.DAQCONTROLLER
  %
  % Part of Rigbox

  % 2017-07 MW created
  
  properties
    OnValue = 5 % The HIGH voltage to output
    OffValue = 0 % The LOW voltage to output
    ParamsFun = @(in) logical(in); % Converts input to logical
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

