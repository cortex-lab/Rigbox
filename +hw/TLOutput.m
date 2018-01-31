classdef TLOutput < matlab.mixin.Heterogeneous & handle
  %HW.TLOUTPUT Code to specify an output channel for timeline
  %   This is an abstract class. 
  %
  %   Below is a list of some subclasses and their functions:
  %     hw.TLOutputClock - clocked output on a counter channel
  %     hw.TLOutputChrono - the default, flip/flop status check output
  %     hw.TLOutputAcqLive - a digital channel that signals that
  %     aquisition has begun or ended with either a constant on signal or a
  %     brief pulse.
  %
  %   The timeline object will call the init, start, process, and stop
  %   methods.  Example:
  %
  %     tl = hw.Timeline;
  %     tl.Outputs(1) = hw.TLOutputAcqLive('Instra-Triggar', 'Dev1',
  %     'PFI4');
  %     tl.start('2018-01-01_1_mouse2', alyxInstance);
  %     >> initializing Instra-Triggar
  %     >> start Instra-Triggar
  %     >> Timeline started successfully
  %     tl.stop;
  %
  % See Also HW.TLOutputChrono, HW.TLOutputAcqLive, HW.TLOutputClock
  %
  % Part of Rigbox
  
  % 2018-01 NS created
  
  properties
    Name % The name of the timeline output, for easy identification
    Enable = true % Will not do anything with it unless this is true
    Verbose = false % Flag to output status updates. Initialization message outputs regardless of verbose.
  end
  
  properties (Transient, Hidden, Access = protected)
    Session % Holds an NI DAQ session object
  end
  
  methods (Abstract)
    % Called when timeline is initialized (see HW.TIMELINE/INIT), e.g. to open daq session and set parameters
    init(obj, timeline) 
    % Called when timeline is started (see HW.TIMELINE/START), e.g. to start outputs
    start(obj, timeline) 
    % Called every time Timeline processes a chunk of data, in case output needs to react to it
    process(obj, timeline, event) 
    % Called when timeline is stopped (see HW.TIMELINE/STOP), to close and clean up
    stop(obj, timeline) 
    % Returns a string that describes the object succintly
    s = toStr(obj) 
  end
  
end

