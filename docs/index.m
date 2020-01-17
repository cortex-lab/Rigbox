%% Rigging Toolbox Documentation
% Below is a list of useful topics:
%
% * <./paths_config.html Setting up dat.paths>
% * <./hardware_config.html How to configure hardware on the stimulus computer>
% * <./using_dat_package.html How to query data locations and log experiments>
% * <./websocket_config.html Setting up communication between the stimulus computer and MC>
% * <./using_test_gui.html Playing around with Signals Experiment Definitions>
% * <./SignalsPrimer.html How to create experiments in signals>
% * <./using_parameters.html How to create and edit experiment parameters>
% * <./using_timeline.html Using Timeline for time alignment>
% * <./using_services.html Setting up auxiliary services>
% * <./AlyxMatlabPrimer.html How to interact with an Alyx database>
% * <./using_ExpPanel.html How to create a custom Experiment Panel>
%
% @todo Further files to add to docs
% @body Burgess config, setting up shared paths 

%% Code organization
% Below is a list of Rigbox's subdirectories and an overview of their
% respective contents.  For more details, see the REAME.md and Contents.m
% files for each package folder.

%%% +dat
% The 'data' package contains code pertaining to the organization and
% logging of data. It contains functions that generate and parse unique
% experiment reference ids, and return file paths where subject data and
% rig configuration information is stored. Other functions include those
% that manage experimental log entries and parameter profiles. A nice
% metaphor for this package is a lab notebook.
doc +dat

%%% +eui
% The 'experiment user interface' package contains code pertaining to the
% Rigbox user interface. It contains code for constructing the mc GUI
% (MControl.m), and for plotting live experiment data or generating tables
% for viewing experiment parameters and subject logs.
%
% This package is exclusively used by the master computer.
doc +eui

%%% +exp
% The 'experiment' package is for the initialization and running of
% behavioural experiments. It contains code that define a framework for
% event- and state-based experiments. Actions such as visual stimulus
% presentation or reward delivery can be controlled by experiment phases,
% and experiment phases are managed by an event-handling system (e.g.
% ResponseEventInfo).
%
% The package also triggers auxiliary services (e.g. starting remote
% acquisition software), and loads parameters for presentation for each
% trial. The principle two base classes that control these experiments are
% 'Experiment' and its 'signals package' counterpart, 'SignalsExp'.
helpwin +exp

%%% +hw
% The 'hardware' package is for configuring, and interfacing with, hardware
% (such as screens, DAQ devices, weighing scales and lick detectors).
% Within this is the '+ptb' package which contains classes for interacting
% with PsychToolbox.
%
% |hw.devices| loads and initializes all the hardware for a specific
% experimental rig. There are also classes for unifying system and hardware
% clocks.
doc hw

%%% +psy
% The 'psychometrics' package contains simple functions for processing and
% plotting psychometric data.
doc psy

%%% +srv
% The 'stim server' package contains the 'expServer' function as well as
% classes that manage communications between rig computers.
%
% The 'Service' base class allows the stimulus computer to start and stop
% auxiliary acquisition systems at the beginning and end of experiments.
%
% The 'StimulusControl' class is used by the master computer to manage the
% stimulus computer.
%
% *Note*: Lower-level communication protocol code is found in the
% 'cortexlab/+io' package.
doc +srv

%%% cb-tools/burgbox
% 'Burgbox' contains many simple helper functions that are used by the main
% packages. Within this directory are additional packages:
% 
% * +bui --- Classes for managing graphics objects such as axes
% * +aud --- Functions for interacting with PsychoPortAudio
% * +file --- Functions for simplifying directory and file management, for instance returning the modified dates for specified folders or filtering an array of directories by those that exist
% * +fun --- Convenience functions for working with function handles in MATLAB, e.g. functions similar cellfun that are agnostic of input type, or ones that cache function outputs
% * +img --- Classes that deal with image and frame data (DEPRECATED)
% * +io --- Lower-level communications classes for managing UDP and TCP/IP Web sockets
% * +plt --- A few small plotting functions (DEPRECATED)
% * +vis --- Functions for returning various windowed visual stimuli (i.g. gabor gratings)
% * +ws --- An early Web socket package using SuperWebSocket (DEPRECATED)

%%% cortexlab
% The 'cortexlab' directory is intended for functions and classes that are
% rig or CortexLab specific, for example, code that allows compatibility
% with other stimulus presentation packages used by CortexLab (e.g. MPEP)

%%% tests
% The 'tests' directory contains code for running unit tests within Rigbox.

%%% docs
% Contains various guides for how to configure and use Rigbox.

%%% submodules
% Additional information on the
% [alyx-matlab](https://github.com/cortex-lab/alyx-matlab),
% [npy-matlab](https://github.com/kwikteam/npy-matlab),
% [signals](https://github.com/cortex-lab/signals) and
% [wheelAnalysis](https://github.com/cortex-lab/wheelAnalysis) submodules
% can be found in their respective github repositories.

%% Etc.
% Author: Miles Wells
%
% v0.0.1
