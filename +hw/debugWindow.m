function [window, viewingModel] = debugWindow(open)
%HW.DEBUGWINDOW On-screen window & viewing model for testing
%   Uses Psychtoolbox to open and control an on-screen window that is
%   useful for debugging. Also returns a dummy viewing model.
%
% Part of Rigbox

% 2012-10 CB created

if nargin < 1
  open = true;
end

pixelWidth = 800;
pixelHeight= 600;
viewWidth = 0.2;
viewHeight = viewWidth*pixelHeight/pixelWidth;

% oldSyncTests = Screen('Preference', 'SkipSyncTests', 2);
% oldVerbosity = Screen('Preference', 'Verbosity', 0);
% cleanup1 = onCleanup(@() Screen('Preference', 'SkipSyncTests', oldSyncTests));
% cleanup2 = onCleanup(@() Screen('Preference', 'Verbosity', oldVerbosity));

window = hw.ptb.Window;
window.PtbVerbosity = 0;
window.PtbSyncTests = 2;
window.OpenBounds = SetRect(50, 50, pixelWidth+50, pixelHeight+50);

if open
  window.open();
end


viewingModel = hw.BasicScreenViewingModel;
viewingModel.ScreenWidthPixels = pixelWidth;
viewingModel.ScreenWidthMetres = viewWidth;
viewingModel.SubjectPos = [.5*viewWidth .5*viewHeight .07];

end

