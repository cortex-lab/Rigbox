%% Visual stimuli in Signals
% This tutorial will demonstrate how to create various visual stimuli in
% Signals.  

%% Shapes
%
%
%

%% Images
%
%
%

%% Gratings
%
% <include>../../signals/docs/examples/driftingGrating.m</include>
%

%% Checkerboards
%
%
%

%% FAQ
%%% Is there a way to create a variable number of visual stimuli?
% Not precisely.  You can not copy visual stimulus objects in Signals, and
% all stimulus objects must be loaded within the experiment definition,
% before your parameter signals are set.  The best option is to create a
% large number of stimulus objects with a for loop, then set the `show`
% properties to true for however many you want to use.


%% Etc.
% Author: Miles Wells
%
% v0.0.2
%
% See also <./using_signals.html Using Signals>.  For technical information
% on the Signals vieing model, see <./using_visual_stimuli.html this page>. 