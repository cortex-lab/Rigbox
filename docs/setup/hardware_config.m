%% Configuring hardware devices 
% The stimulus computer (expServer) that...
% Many of the classes for interacting with the hardware are found in the
% +hw package.

%% Configuring the visual stimuli
% The +hw Window class is the main class for configuring the visual
% stimulus window.  It contains the attributes and methods for interacting
% with the lower level functions that interact with the graphics drivers.
% Currently the only concrete implementation is support for the
% Psychophysics Toolbox, the hw.ptb.Window class.
doc hw.ptb.Window
stimWindow = hw.ptb.Window;

%% Adding a viewing model
% The following classes [...] how the stimuli are [...]
% hw.BasicScreenViewingModel
% hw.PseudoCircularScreenViewingModel
% screen

%% Saving the hardware configurations
% The location of the configuration file is set in dat.paths.  If running
% this on the stimulus computer you can use the following syntax:
p = getOr(dat.paths, 'rigConfig');
% save(fullfile(p, 'hardware.mat'), 'stimWindow', '--append')

%% Timeline
%Open your hardware.mat file and instantiate a new Timeline object
timeline = hw.Timeline;
%Set tl to be started by default
timeline.UseTimeline = true;
%To set up chrono a wire must bridge the terminals defined in
% timeline.Outputs(1).DaqChannelID and timeline.Inputs(1).daqChannelID
timeline.wiringInfo('chrono');
%Add the rotary encoder
timeline.addInput('rotaryEncoder', 'ctr0', 'Position');
%For a lick detector
timeline.addInput('lickDetector', 'ctr1', 'EdgeCount');
%We want use camera frame acquisition trigger by default
timeline.UseOutputs{end+1} = 'clock';
%Save your hardware.mat file
% save('hardware.mat', 'timeline', '-append')

%% Loading your hardware file
rig = hw.devices;