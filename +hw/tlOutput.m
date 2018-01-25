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
    session
  end
  
  methods (Abstract)
    onInit(obj, timeline)
    onStart(obj, timeline)
    onProcess(obj, timeline, event)
    onStop(obj, timeline)
    %s = propertiesAsStruct(obj) % recommend we have a method that does this, 
    %   so that we can save out all the properties in a json file. Incl a
    %   version number?
  end
  
end

