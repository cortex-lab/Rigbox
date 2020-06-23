%% Burgess steering wheel task
% Our laboratory developed a steering wheel setup to probe mouse
% behavior(1). In this setup, a mouse turns a steering wheel with its front
% paws to indicate whether a visual stimulus appears to its left or to its
% right.
%
% This setup is being adopted in multiple laboratories, from Stanford to
% Tokyo, and is being deployed by the International Brain Laboratory.
%
% To facilitate this deployment, we provide instructions to build the setup
% with components that are entirely off-the-shelf or 3-D printed.  You can
% find the hardware setup instructions <Burgess_hardware_setup.html here>.
% 
% <<SteeringWheelBack.png>>
% 

%% Introduction
% This document gives instructions on how to build a basic version of the
% steering wheel setup to probe mouse behavior, introduced by Burgess et
% al. The goal is to make it easy for other laboratories, including those
% that make the International Brain Laboratory, to replicate the task and
% extend it in various directions. To this end, these instructions rely
% entirely on materials that can be bought off the shelf, or ordered online
% based on 3-D drawings. In this steering wheel setup, we place a steering
% wheel under the front paws of a head-fixed mouse, and we couple the
% wheel's rotation to the horizontal position of a visual stimulus on the
% screens. Turning the wheel left or right moves the stimulus left or
% right. The mouse is then trained to decide whether a stimulus appears on
% its left or its right. Using the wheel, the mouse indicates its choice by
% moving the stimulus to the center. A correct decision is rewarded with a
% drop of water and short intertrial interval, while an incorrect decision
% is penalized with a longer timeout and auditory noise. We use this setup
% throughout our laboratory, and deploy it in training rigs and
% experimental rigs. Training rigs are used to train head-fixed mice on the
% steering-wheel task and acquire behavioral data. Experimental rigs have
% additional apparatus to collect electrophysiological and imaging data,
% measure eye movements and licking activity, provide optogenetic
% perturbations, and so on. Up until recently, constructing these setups
% required a machine shop that could provide custom-made components.
% However, for the purposes of spreading this setup to other laboratories,
% we here describe a new version that does not require a machine shop: all
% components can be ordered online or 3D-printed.

%% Installing Rigbox
% Before configuring the settings, please follow the <install.html
% installation instructions> to install Rigbox and its dependencies.

%% Setup
% Follow teh <./paths_config.html setting up dat.paths> guide to set up rig
% paths.  This sets the location of the data repositories and hardware
% settings files.
%
% The below code will create a hardware settings file for the Burgess wheel
% task.  It can be run from the command window by typing
% |hw.setupBurgessDefaults|.  For details of what the code does, or to
% customize the hardware, see the <./hardware_config.html hardware config
% guide>.  
% **NB**: The below code must be run on the stimulus computer.
% 
% <include>../../cortexlab/+hw/setupBurgessDefaults.m</include>
%

%% Calibrations
% Once the hardware file has been set up, you can start the experiment
% server by running |srv.expServer|.  A grey Psychtoolbox window should
% appear on the three screens.  
%
% To calibrate the screens, press the |g| key and follow the steps. To
% calibrate the reward valve, ensure you have a set of scales connected to
% the computer (to the port set above in the previous section) and place
% them below the water spout.  Place a container on the scales to collect
% the water.  Press the |c| key to start the calibration.

%% Notes
% (1) <https://doi.org/10.1016/j.celrep.2017.08.047 DOI:10.1016/j.celrep.2017.08.047>

%% Etc.
% Authors: Lauren E Wool, Miles Wells, Hamish Forrest, and Matteo Carandini
% v1.1.3