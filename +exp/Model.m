classdef Model < handle
  %SEXPERIMENT Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    Time % time signal
    Input % input signals
    Output % output signals
    Params % parameter signals
    Audio % auditory stream signals
    Visual % visual stimuli elements
    Events % event signals
    UI % user interface signals
  end
  
  methods
    function this = Model(signet)
      this.Time = signet.origin('t');
      this.Input = sig.Registry;
      this.Output = sig.Registry;
      this.Audio = audstream.Registry(96e3);
      this.Visual = sig.Registry;
      this.UI = sig.Registry;
    end
  end
  
end

