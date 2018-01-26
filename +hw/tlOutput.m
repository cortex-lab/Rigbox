classdef tlOutput < matlab.mixin.Heterogeneous & handle
  %hw.tlOutput Code to specify an output channel for timeline
  %   This is an abstract class. 
  %
  %   Below is a list of some subclasses and their functions:
  %     hw.tlOutputClock - clocked output on a counter channel
  %     hw.tlOutputChrono - the default, flip/flip status check output
  %     hw.tlOutputAcqLive - a digital channel that is on for the duration
  %     of the recording
  %     hw.tlOutputStartStopSync - a digital channel that turns on only at
  %     the beginning and end of the recording
  %
  %   The timeline object will call the onInit, onStart, onProcess, and onStop
  %   methods.
  %
  % Part of Rigbox
  
  % 2018-01 NS created
  
  properties
      name
      enable = true % will not do anything with it unless this is true
      verbose = false % output status updates. Initialization message outputs regardless of verbose.
  end
  
  properties (Transient)
      session
  end
  
  methods (Abstract)
    init(obj, timeline)
    start(obj, timeline)
    process(obj, timeline, event)
    stop(obj, timeline)
    s = toStr(obj) % a string that describes the object succintly 
  end
  
end

