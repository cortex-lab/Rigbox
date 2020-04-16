%% Release Notes v2.6.0
% Below is a short explanation of changes made to this version.  For a
% technical list of changes with commit hashes, see the
% <https://github.com/cortex-lab/Rigbox/blob/master/CHANGELOG.md
% CHANGELOG>.

%% Rigbox
%
% *Major changes*
% 
% * |hw.findDevice| - Renamed to |hw.testAudioOutputDevices|
% * |exp.MovieWorld| - A new Experiment class designed for parameterizing
% passive movie presentation experiments
% * |srv.expServer| - Experiments can now be started by calling expServer
% with an expRef.  This can be used for running experiments without MC.  A
% fair amount of refactoring has taken place.
%
% *Documentaion*
%
% The following functions and classes are now documented:
% 
% * |exp.Parameters| - Class and all its methods documented with examples
% * |getOr| - Added comparisons with |pick| function
% * |hw.testAudioOutputDevices| (formally |hw.findDevice|) - Complete
% documentation
% * |exp.configureSignalsExperiment| - Complete documentation with an
% example
% 
% Updates to guides:
% 
% * |using_wheel| - Added section on using the +wheel package for analysis
% 
%
% *Bug fixes*
% 
% * hw.ptb.Window/asyncFlipEnd - Fixed value unassigned error when no lag
% * namedArg - Fixed uniform output error when inputs non-scalar 
% * pick - Fixed uniform output error when default value a cell or string 
%
%
% *Enhancements*
%
% * |getOr| - Input arg 'field' may now be a string array
% * |hw.ptb.Window/Window| - Informative error thrown if PsychToolbox is
% likely not set up
% * |dat.listSubjects| - Removed unnecessary cellfun call
% * |dat.newExp| - More informative error messages and IDs; now local exp
% folder is removed if remote folder creation fails
% * |exp.SignalsExp| - Zeroing of input devices now happens during
% initialization, closer to experiment start.  This is in line with the
% base Experiment class
% * |git.update| - The update day may now be a char, cellstr, or string
% array, and the 'updateSchedule' field of |dat.paths| may be set to
% -1/'never' to turn off updates
% * |srv.expServer| - Pressing 'h' key in expServer will display the
%                     keyboard shortcuts.  
%                   - The calibration plot will now be displayed on the
%                     screen.
% * |exp.configureSignalsExperiment| - Stimulus window background colour
% can now be set with a 'bgColor' field in the parameter struct.  This
% allows users to set the window colour for individual experiments without
% having to restart expServer, and this parameter may be used in an expDef
% to match the colour of stimuli.  NB: The background colour can only be
% set once, at the start of the experiment.
% * |exp.rangeEventHandlers| - Function removed (old and incomplete code)
% * |exp.rangeParams| - Function removed (old and incomplete code)
%
% *Tests*
%
% * distribute - Test added
% * pick - Test added for when default value is a cell or string
% * namedArg - Test added for when inputs are nonscalar cell arrays
% * srv.expServer - Test refactoring
% * git.update - Tests added for new array support

%% signals v1.3
% *Major changes*
% 
% * |vis.checker*| - vis.checker6 is renamed to vis.checker, all others
% have been removed
% * |sig.node.Signal/filter| - A new method was added that filters its
% input signal's values using a function handle.  This allows for method
% chaining and is terser than using |keepWhen|.  Function support was also
% added to |keepWhen|.
% * |sig.Signal/num2str| - A new method overloading |num2str|
%
% *Documentaion*
%
% The following functions and classes are now documented:
% 
% * |vis.checker| (formally |vis.checker6|) - Now fully documented with
% examples and field descriptions
% * |sig.node.Signal/to| - Fully documented with examples
% * |sig.node.Signal/merge| - Fully documented with examples
% * |sig.node.Signal/keepWhen| - Fully documented with examples
% * |sig.node.Signal/bufferUpTo| - Fully documented with examples
% * |sig.node.Signal/buffer| - Fully documented with examples
% * |sig.node.Signal/setTrigger| - Fully documented with examples
% * |sig.node.Signal/setEpochTrigger| - Fully documented with examples and
% inline comments
% * |sig.scan.quiescenceWatch| - Fully documented with examples
% * |vis.grating| - Documentation improved
% * |vis.grid| - Parameters now fully documented
% * |vis.image| - Improved documentation
% * |vis.patch| - Improved documentation
% * |advancedChoiceWorld| - Minor in-line documentation improvements
% * |getOr| - Added comparisons with |pick| function
% * |sig.node.SubscriptableSignal| - Improved documentation
% * |sig.transfer.merge| - Fully documented with examples and inline
% comments
% * |sig.Signal| - Improved documentation of methods; more consistant with
% other classes
%
% Updates to guides:
% 
% * |using_signals| - 
% * |visual_stimuli| - Exhaustive descriptions and demonstrations of every
% visual stimulus function, along with screenshots of the stimuli
% * |SignalsPrimer*| - These have been removed, and the information reused
% and improved in |using_signals| and |expDef_inputs|.
% 
% *Bug fixes*
% 
% * |sig.node.Signal/bufferUpTo| - The signal's name is now correct (fixed
% bug in the format specification); bufferUpTo(0) now never updates
% * |sig.node.Signal/setEpochTrigger| - Method now actually works (fixed
% subsref error)!
% * |sig.transfer.map| - Correct error ID
% * |sig.transfer.scan| - Correct error ID
% * |signals_test| - Fixed bug where states carried over between tests
%
% *Enhancements*
%
% * |sig.test.create| - Signal names is now an input parameter, e.g.
% |[trig, arm] = sig.test.create('names', ["trigger", "arm"])|
% * |sig.test.sequence| - Signal name is now an input parameter, and cell
% arrays are now supported, allowing for nonhomogeneous sequences, e.g. |x
% = sig.test.sequence({12, true, 1:3, 'str'}, 0.2, 1, 'x')|
% * |vis.circLayer| - Dimensions may now be a Signal, meaning the dims
% field of |vis.patch| can be a Signal.
% * |vis.patch| - All fields may now be a Signal
% * |vis.grid| - Full refactoring of code, now all fields can be a Signal
% and therefore may change
% * |imageWorld| - Added sample images so that expDef can run 'out of the
% box'
% * |getOr| - Input arg 'field' may now be a string array
% * |sig.node.Signal/subscriptable| - When a Signal's name changes its
% subscriptable's name will also change
% * |sig.node.Signal/scan| - The name of a scanning signal is now
% consistant, regardless of inputs, and correctly represents the input
% order, e.g. 'a.scan(@f1, b, f2, c)'
% * |sig.node.Signal/bufferUpTo| - The number of samples to buffer can now
% be a signal and therefore can change; now done via a transfer function
% which should improve performance
% * |sig.node.Signal/buffer| - See bufferUpTo
% * |sig.node.Signal/setEpochTrigger| - The signal's name is now much more
% readable, e.g. 'dy/dx < thesh s.t. thesh = 3'; helper functions moved to
% +scan package
% * |sig.Signal/setEpochTrigger| - Added to method list
% * |sig.node.SubscriptableSignal| - Removed unused 'Subscriptable'
% property
% * |sig.test.timeplot| - Subscriptable Signals now correctly represented
% in plots (shows the field names as plot annotations)
% * |toStr| - Will correctly stringify map.Containers objects
%
% *Tests*
%
% * bufferUpTo - Added test
% * buffer - Added test
% * filter - Added test
% * merge - Added test
% * setEpochTrigger - Added test
% * str2num - Added test
% * num2str - Added test
% * size - Test now works for more recent versions of MATLAB (error ID
% change)

%% alyx-matlab
% *Major changes*
% 
% * 
%
% *Documentaion*
%
% The following functions and classes are now documented:
% 
% * 
% 
% Updates to guides:
% 
% * 
% 
% *Bug fixes*
% 
% *
%
% *Enhancements*
%
% * 
%
% *Tests*
%
% * 

%% wheelAnalysis
%
% *Documentaion*
%
% Updates to guides:
% 
% * See Rigbox updates
%
% *Enhancements*
%
% * |wheel.findWheelMoves3| - Added an extra output arg which is the peak
% amplitude of each detected movement.  This is the absolute maximum
% position relative to the position at move onset 
%
% *Tests*
%
% * |wheel.findWheelMoves3| - Updated test for the added output
%