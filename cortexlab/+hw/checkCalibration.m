function c = checkValveCalibration(channelName, volumes)
% HW.CHECKVALVECALIBRATION Check two volumes along calibration plot
%   This function is used to plot the measured volumes at two points along
%   the last recorded calibration curve. This can be used to easily check
%   whether the calibration is still accurate.
%
%   Inputs (Optional):
%     channelName (char): The name of the reward valve channel to check.
%       The channel name must be associated with a hw.RewardValveControl
%       object in the rig's hw.DaqController object. Default 'rewardValve'.
%     volumes (numerical): A 2-element array of volumes to check.  Default
%       is to pick two evenly spaced volumes within the calibration range.
%
%   Ouput:
%     c (struct): The measured volumes corresponding to the opening times.
%
% Examples:
%   % Plot two measured volumes again the previous calibration data
%   hw.checkRewardValveCalibration();
%
%   % Check by how much the deliveries have changed for some given volumes
%   volumes = [2 3]; % Check 2 and 3ul deliveries
%   c = hw.checkRewardValveCalibration('rewardValve', volumes);
%   dV = diff([c.volumeMicroLitres; volumes])
%
% See also hw.calibrate, hw.RewardValveControl

% The default channel name of the reward controller
if nargin < 1, channelName = 'rewardValve'; end
rig = hw.devices; % Load the hardware file

% Fetch the reward control signal generator object
rewardId = strcmp(rig.daqController.ChannelNames, channelName);
signalGen = rig.daqController.SignalGenerators(rewardID);
% Fetch the most recent calibration
[newestDate, I] = max([signalGen.Calibrations.dateTime]);
lastCalibration = signalGen(rewardId).Calibrations(I);
ul = [lastCalibration.volumeMicroLitres]; % Recorded volumes
dt = [lastCalibration.durationSecs]; % Previous opening times

if nargin > 1
  % User provided two specific volumes to test
  assert(isnumeric(volumes) && numel(volumes) == 2, ...
    'Rigbox:hw:checkCalibration:volumesIncorrect', ...
    'volumes must be a two element numerical array')
  % Interpolate previous calibration data to find opening times
  durations = arrayfun(@(x)interp1(ul, dt, x, 'pchip'), volumes);
else
  % Otherwise pick two equally spaced points within the calibration range
  durations = pick(linspace(dt(1), dt(end), 4), 2:3);
end

% Run a quick calibration
c = hw.calibrate(channelName, rig.daqController, rig.scale, ...
  durations(1), ...       % Min opening time
  durations(2), ...       % Max opening time
  'settleWait', 1, ...    % Set to 1 to trim test time
  'nPerT', 1, ...         % Once per opening time
  'nVolumes', 2, ...      % Pick the min and max opening times
  'delivPerSample', 200); % 100 fewer than usual

% Plot result over the previous calibration result
figure('Color', 'w');
plot(dt, ul, 'x-');
hold on
plot([c.durationSecs], [c.volumeMicroLitres], 'o');

% Set some labels, etc.
xlabel('Duration (sec)');
ylabel('Volume (\muL)');
legend(["Previous calibration", "Measured deliveries"], 'Location', 'SouthEast')
title(datestr(newestDate))
