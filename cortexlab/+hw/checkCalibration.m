function c = checkCalibration()
channel = 'rewardValve'; % The channel name of the reward controller
rig = hw.devices; % Load the hardware file

% Fetch the reward control signal generator object
rewardId = strcmp(rig.daqController.ChannelNames, channel);
signalGen = rig.daqController.SignalGenerators(rewardID);
% Fetch the most recent calibration
[newestDate, I] = max([signalGen.Calibrations.dateTime]);
lastCalibration = signalGen(rewardId).Calibrations(I);
ul = [lastCalibration.volumeMicroLitres]; % Recorded volumes
dt = [lastCalibration.durationSecs]; % Previous opening times

% Two specific volumes to test
volumes = [2, 3];
durations = arrayfun(@(x)interp1(ul, dt, x, 'pchip'), volumes);
% OR two equally spaced points within the range
durations = pick(linspace(dt(1), dt(end), 4), [2,3]);

% Run a quick calibration
c = hw.calibrate(channel, rig.daqController, rig.scale, ...
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
