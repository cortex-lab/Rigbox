%% The Clock object
% This class is to help with abstracting code that needs to timestamp
% events. Subclasses of this implement timestamps using different clocks 
% (e.g. using MATLAB's |now|, Psychtoolbox's |GetSecs|, or a DAQ
% timing clock). 
%
% During an experiment all times are recorded using a Clock object.  This
% object is stored by a number of different objects, ensuring that anything
% that records a time does so using the same clock.  The Clock object is
% always stored in an object's Clock property.  The following classes (and
% their subclasses) use a Clock:
% 
% * hw.Window
% * exp.Experiment (& exp.SignalsExp)
% * hw.DataLogging
%
%% Using the Clock
% Below are some examples of how to use a Clock object.  |hw.Clock| is an
% abstract class with each subclass implementing |absoluteTime|.  We will
% instatiate |hw.ptb.Clock|, Rigbox's default Clock.  This uses the
% Psychtoolbox function |GetSecs| in its |absoluteTime| method.

clock = hw.ptb.Clock
%%%
%  clock = 
%
%    Clock with properties:
%
%      ReferenceTime: 0
%%%
% Timestamps are returned by calling the |now| method, which must return
% the time in *seconds* since some reference time, as counted by whatever
% clock the subclass uses:

clock.now()
%%%
%   ans =
% 
%      1.3128e+06

%%%
% This class also allows you to 'zero' the reference time at some moment.
% Time is then counted up from that moment on (and is negative for times
% before that point). Code that needs to track time can use this class to
% remain agnostic about what timing clock is acutally used. You could even
% use this e.g. as a neat way to run an experiment at a different speed.

zero(clock);
t = clock.now()
%%%
%   t =
% 
%      3.3180e-04

%%%
% The Clock class also provides some ways to interconvert timestamps, for
% instance |fromMatlab| converts from a MATLAB serial date number to the
% same time but expressed in this clocks reference frame:
yesterday = now-1;
t = clock.fromMatlab(yesterday)
%%%
%   t =
% 
%     -8.6400e+04

%%%
% There are also |toPtb| and |fromPTB| methods for subclasses that don't
% use GetSecs.

%% The Experiment Clock
% When running an experiment via |srv.expServer|, the clock is retrieved
% via |hw.devices|.  If there is no 'clock' field in your hardware file,
% an instance of |hw.ptb.Clock| is returned.  If Timeline is enabled, a
% |hw.TimelineClock| instance is used instead.  For more info, see the
% <./Timeline.html#23 Timeline guide>.
%
% The clock is zero'd as soon as an expRef is received (e.g. when a new
% experiment is started in mc and the messeage is received by expServer).
% This happens in |srv.expServer/runExp|.  All experiment times are
% therefore relative to this moment.

%% Etc.
% <./index.html Home>
%
% Author: Miles Wells
%
% v0.1.0

%#ok<*NOPTS,*NASGU>