classdef tlOutput < matlab.mixin.Heterogeneous & handle
  %hw.tlOutput Code to specify an output channel for timeline
  %   This is an abstract class. 
  %
  %   Below is a list of some subclasses and their functions:
  %     hw.tlOutputClock - clocked output on a counter channel
  %     hw.tlOutputChrono - the default, flip/flop status check output
  %     hw.tlOutputAcqLive - a digital channel that is on for the duration
  %     of the recording
  %     hw.tlOutputStartStopSync - a digital channel that turns on only at
  %     the beginning and end of the recording
  %
  %   The timeline object will call the init, start, process, and stop
  %   methods.
  %
  % Part of Rigbox
  
  % 2018-01 NS created
  
  properties
      name % user choice, text
      enable = true % will not do anything with it unless this is true
      verbose = false % output status updates. Initialization message outputs regardless of verbose.
  end
  
  properties (Transient)
      session
  end
  
  methods (Abstract)
    init(obj, timeline) % called when timeline is initialized (see hw.Timeline/init), e.g. to open daq session and set parameters
    start(obj, timeline) % called when timeline is started (see hw.Timeline/start), e.g. to start outputs
    process(obj, timeline, event) % called every time Timeline processes a chunk of data, in case output needs to react to it
    stop(obj, timeline) % called when timeline is stopped (see hw.Timeline/stop), to close and clean up
    s = toStr(obj) % a string that describes the object succintly 
  end
  
end

