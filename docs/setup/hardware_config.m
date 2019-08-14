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
hardware = fullfile(getOr(dat.paths, 'rigConfig'), 'hardware.mat');
save(hardware, 'stimWindow', '-append')

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
% Timeline unifies various hardware and software times using a DAQ device.
doc hw.Timeline

% Let's create a new object and configure some channels
timeline = hw.Timeline
% Setting UseTimeline to true allows timeline to be started by default at
% the start of each experiment.  Otherwise it can be toggled on and off by
% pressing the 't' key while running SRV.EXPSERVER.
timeline.UseTimeline = true;
% To set up chrono a wire must bridge the terminals defined in
%  timeline.Outputs(1).DaqChannelID and timeline.Inputs(1).daqChannelID
timeline.wiringInfo('chrono');
% Add the rotary encoder
timeline.addInput('rotaryEncoder', 'ctr0', 'Position');
% For a lick detector
timeline.addInput('lickDetector', 'ctr1', 'EdgeCount');
% We want use camera frame acquisition trigger by default
timeline.UseOutputs{end+1} = 'clock';

%Save your hardware.mat file
save(hardware, 'timeline', '-append')

% For more information on using Timeline, see USING_TIMELINE:
open(fullfile(getOr(dat.paths,'rigbox'), 'docs', 'using_timeline.m'))

%% Adding a weigh scale
% MC allows you to log weights through the GUI by interfacing with a
% digital scale connected via a COM port. This is the only object of use in
% the MC computer's hardware file.
scale = hw.WeighingScale 

% The Name field should be set to the name or product code of the scale you
% connect.
scale.Name = 'SPX222';
% The COM port should be set to whichever port the scale is connected to.
% You can find out which ports are availiable in Windows by opening the
% Device Manager (Win + X, then M).  Under Universal Serial Bus, you can
% see all current USB and serial ports.  If you right-click and select
% 'Properties' you can view the port number and even reassign them (under
% Advanced)
scaleComPort = 'COM4'; % Set to a different port
% The TareCommand and FormatSpec fields should be set based on your scale's
% input and output configurations.  Check the manual.
TareCommand = 84; % 'T'
% For SPX222 the weight is transmitted directly, without any units.
% Other scales such as the ES-300HA transmit the weight along with the sign
% and units, e.g. '+ 24.01 g'.
FormatSpec = '%f'

%Save your hardware.mat file
save(hardware, 'scale', '-append')

% NewReading event

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

%% Etc.
%#ok<*NOPTS>
%#ok<*NASGU>