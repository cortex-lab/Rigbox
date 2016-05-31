classdef ControlSignalGenerator < matlab.mixin.Heterogeneous & handle
  %UNTITLED4 Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    DefaultCommand %optional, for generating a default control waveform
    DefaultValue %default voltage value
  end
  
  methods (Abstract)
    samples = waveform(obj, command)
  end
  
end

