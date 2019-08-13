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
% The location of the configuration file is set in DAT.PATHS.  If running
% this on the stimulus computer you can use the following syntax:
p = getOr(dat.paths, 'rigConfig');
save(fullfile(p, 'hardware.mat'), 'stimWindow', '-append')

%% Adding hardware inputs
% In this example we will add two inputs, a DAQ rotatary encoder and a beam
% lick detector.  NB: Currently these object variable names must be exactly
% as below in order to work in Signals.

% Create a input for the Burgess LEGO wheel using the HW.DAQROTARYENCODER
% class:
doc hw.DaqRotaryEncoder % More details for this class
mouseInput = hw.DaqRotaryEncoder;

% To deteremine what devices you have installed and their IDs:
device = daq.getDevices
% DAQ's device ID, e.g. 'Dev1'
mouseInput.DaqId = 'Dev1'
% DAQ's ID for the counter channel. e.g. 'ctr0'
% Size of DAQ counter range for detecting over- and underflows (e.g. if
% the DAQ's counter is 32-bit, this should be 2^32)
mouseInput.DaqChannelId = 'ctr0'
mouseInput.DaqCounterPeriod = 2^32
    % Number of pulses per revolution.  Found at the end of the KÜBLER
    % product number, e.g. 05.2400.1122.0100 has a resolution of 100
    EncoderResolution = 1024
    % Diameter of the wheel in mm
    WheelDiameter = 62


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

%% Adding a weigh scale


%% Loading your hardware file
% To load your rig hardware objects for testing at a rig, you can use
% HW.DEVICES:
rig = hw.devices;

% To load the hardware file or a different rig, you can input the rig name.
% Note HW.DEVICES initializes some of the hardware by default, including
% creating DAQ sessions and adding any required channels.  To load without
% initializing:
rigName = 'ZREDONE';
initialize = false;
rig = hw.devices(rigName, initialize);