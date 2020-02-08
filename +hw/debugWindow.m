function [window, viewingModel] = debugWindow(open)
%HW.DEBUGWINDOW On-screen window & viewing model for testing
%   Uses Psychtoolbox to open and control an on-screen window that is
%   useful for debugging. Also returns a dummy viewing model.
%
%   Input (Optional):
%     open (logical): Immediately open the PTB window after instantiating.
%       Default true.
%
%   Outputs:
%     window (hw.ptb.Window): A Window object configured for a 800x600
%       stimulus screen, with PTB warning and sync tests supressed.
%     viewingModel (hw.BasicScreenViewingModel): A ViewingModel object
%       configured for a subject positioned squarely in front of the
%       window, 7cm away.
%
%   Example:
%     % Open a window for testing and set to middle grey
%     win = hw.debugWindow;
%     win.BackgroundColour = 255/2;
%     win.flip();
%
%   Example:
%     % Save the debug window and model into a test rig's hardware file
%     [stimWindow, stimViewingModel] = hw.debugWindow(false);
%     hwPath = getOr(dat.paths('testRig', 'rigConfig'));
%     save(fullfile(hwPath, 'hardware.mat'), 'stim*', '-append')
%
% See also hw.ptb.Window, PsychDebugWindowConfiguration
%
% Part of Rigbox

% 2012-10 CB created

% Default is to immediately open the window
if nargin < 1, open = true; end

% Set some reasonable parameters for the window (800x600 resolution)
pixelWidth = 800;
pixelHeight= 600;
viewWidth = 0.2; % Assume window is 200mm wide on the screen
viewHeight = viewWidth*pixelHeight/pixelWidth;

% Create the window object
window = hw.ptb.Window;
window.PtbVerbosity = 0; % Supress warnings
window.PtbSyncTests = 2; % Supress sync tests (always fail when windowed)
window.OpenBounds = SetRect(50, 50, pixelWidth+50, pixelHeight+50);
if open, window.open(); end % Open now if open == true

% Create the viewing model
viewingModel = hw.BasicScreenViewingModel;
viewingModel.ScreenWidthPixels = pixelWidth;
viewingModel.ScreenWidthMetres = viewWidth;
viewingModel.SubjectPos = [.5*viewWidth .5*viewHeight .07];

