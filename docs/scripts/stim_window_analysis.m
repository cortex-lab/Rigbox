%% Analyzing stimulus window times
%
%% Loading the times
% For more info see <./block_files Working with block files>.
%
%% Update lags
% The stim window update lags are the recorded delays between the time the
% buffer is updated and the time it is flipped to the screen.
%
% If stimWindowUpdateLags is not present, they can be calculated by
% subtracting the render times from the update times:
if ~isfield(block, 'stimWindowUpdateLags')
  renderTimes = block.stimWindowRenderTimes;
  updateTimes = block.stimWindowUpdateTimes;
  updateLags = updateTimes - renderTimes;
end

%%%
% Note that this is slightly different to the ChoiceWorld definition of
% Update lag, which is the time between the Window being invalidated, and
% the time when the buffer was flipped to the screen.

%% Analyzing the photodiode
% For more info on setting up a photodiode see the
% <./hardware_config.html#5 hardware configuration guide> and
% <./Timeline.html Timeline>.

%% Etc.
% Author: Miles Wells
%
% v0.0.1
%
% <index.html Home> > Analysis > Stimulus Window updates
