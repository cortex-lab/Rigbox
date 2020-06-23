%%% DEFAULT HARDWARE CONFIGURATION FOR THE BURGESS WHEEL TASK %%%
% Saves the config settings for a rig that's set up following the Burgess
% hardware setup instructions for running the steering wheel task.  This
% script should be run on a stimulus computer.  Note that it will overwrite
% the hardware or remote config files if they already exist.
%
% See also docs/scripts/Burgess_setup.m

% The hardware device settings are stored in a MAT file named 'hardware',
% defined in dat.paths
hardware = fullfile(getOr(dat.paths, 'rigConfig'), 'hardware.mat');
% The stimulus controllers are loaded from a MAT file with the name
% 'remote' in the globalConfig directory, defined in dat.paths:
remote = fullfile(getOr(dat.paths, 'globalConfig'), 'remote.mat');

% Check whether these files already exist
if any(file.exists({hardware, remote}))
  prompt = ['A hardware and/or remote settings file already exists. ' ...
            'Do you want to overwrite them? Y/N [N]: '];
  str = input(prompt, 's');
  if isempty(str) || strcmpi(str, 'n')
    return
  elseif ~strcmpi(str, 'y')
    error('User input not understood')
  end
end

%%% Window
stimWindow = hw.ptb.Window;
% This setting assumes the stimulus monitors are the primary screen (i.e.
% the Windows menu bar is shown on these monitors.
stimWindow.ScreenNum = 0; 
stimWindow.positionSyncRegion('NorthEast', 100, 100)
stimWindow.PxDepth = Screen('PixelSize', stimWindow.ScreenNum);
stimWindow.BackgroundColour = 127*[1 1 1];
stimWindow.MonitorId = 'LG LP097QX1'; % The screens used in Burgess et al.

save(hardware, 'stimWindow') % Save the stimWindow to file

%%% Viewing model
% First define some physical dimentions in cm:
screenDimsCm = [19.6 14.7]; %[width_cm heigh_cm], each screen is the same
centerPt = [0, 0, 9.5]; % [x, y, z], observer position in cm. z = dist from screen
centerPt(2,:) = [0, 0, 10];% Middle screen, observer slightly further back
centerPt(3,:) = centerPt; % Observer equidistant from left and right motitors 
angle = [-90; 0; 90]; % The angle of the screen relative to the observer

% Define the pixel dimentions for the monitors
r = Screen('Resolution', stimWindow.ScreenNum); % Returns the current resolution
pxW = r.width; % e.g. 1280
pxH = r.height; % e.g. 1024

% Plug these values into the screens function:
screens(1) = vis.screen(centerPt(1,:), angle(1), screenDimsCm, [0 0 pxW pxH]);        % left screen
screens(2) = vis.screen(centerPt(2,:), angle(2), screenDimsCm, [pxW 0 2*pxW pxH]);    % ahead screen
screens(3) = vis.screen(centerPt(3,:), angle(3), screenDimsCm, [2*pxW  0 3*pxW pxH]); % right screen

save(hardware, 'screens', '-append');

%%% Inputs
mouseInput = hw.DaqRotaryEncoder;
save(hardware, 'mouseInput', '-append')

%%% Outputs
daqController = hw.DaqController;
% Add a new channel
daqController.ChannelNames = {'rewardValve'};
% Define the channel ID to output on
daqController.DaqChannelIds = {'ai0'};
% Add a signal generator that will return the correct samples for
% delivering a reward of a specified volume
daqController.SignalGenerators(1) = hw.RewardValveControl;

% Save your hardware file
save(hardware, 'daqController', '-append');

%%% Timeline
% Timeline will be off by default
timeline = hw.Timeline;
timeline.UseTimeline = False;
% Save your hardware.mat file
save(hardware, 'timeline', '-append')

%%% Scale
% Assumes the scale model 'ES-300HA' connected on COM1
scale = hw.WeighingScale;
save(hardware, 'scale', '-append')

%%% Audio
fprintf(['To select the correct audio device, we will cycle through each '...
      'audio device playing white noise through all channels for 2 '...
      'seconds.\nThe lowest latency devices are selected first.\n'...
      'Press the space bar when you hear noise coming through your '...
      'speakers and the current device will be saved into your '...
      'hardware file.\nPress any other key to proceed to the next device.\n'])
input('Press enter to continue')
hw.testAudioOutputDevices('SaveAsDefault', true);

%%% Websockets
% Let's create a new stimulus controller
name = ipaddress(hostname);
stimulusControllers = srv.StimulusControl.create(name);
% Save your new configuration
save(remote, 'stimulusControllers')