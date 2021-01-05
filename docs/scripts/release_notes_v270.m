%% Release Notes v2.7.0
% Below is a short explanation of changes made to this version.  For a
% brief list of changes, see the
% <https://github.com/cortex-lab/Rigbox/blob/master/CHANGELOG.md
% CHANGELOG>.

%% Rigbox
%
% *Major changes*
% 
% * |exp.MovieWorld| - A new Experiment class designed for parameterizing
% passive movie presentation experiments
%
% *Documentaion*
%
% The following functions and classes are now documented:
% 
% * |git.listVersions|
% 
% Updates to guides:
% 
% * 
% 
%
% *Bug fixes*
% 
% * |fixFiles| - Fixed error when calling with 'changed'.
%
%
% *Enhancements*
%
% * |git.listVersions| - Now fetches the remote repository before listing
% the tags so list is always up-to-date.  Also nothing is returned if no
% output arg is defined but printed to the command by default.
%
% *Tests*
%
% * AlyxPanel_test - No more infinit loops when headless, no fatal asserts
% in setup method
%

%% signals

%% alyx-matlab v2.6
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
% * |Alyx/login| - No more infinit loop when server unreachable; moves into
% headless state
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
% *Major changes*
% 
% * |wheel.findWheelMoves3| - Renamed to wheel.findWheelMoves.  Other
% numbered functions have been removed.
%