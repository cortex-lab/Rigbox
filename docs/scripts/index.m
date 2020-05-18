%% Rigbox Documentation
% Welcome to Rigbox's online docs.  Here you can
% find detailed documentation and guides on how to set up Rigbox, including
% writing new experiments, setting up recording devices, running
% experiments, and processing the resulting data.
% 
% For instructions on how to run the examples from the
% <https://www.biorxiv.org/content/10.1101/672204v3 Rigbox paper>, see
% <./paper_examples.html this guide>.

%% Installing Rigbox
% Below are some instructions for installing Rigbox. There are two guides,
% the first is a thorough guide for users unfamiliar with MATLAB and Git.
% The second is for 'power users' who have a basic understanding of these
% things.
% 
% # <./detailed_installation.html Detailed installation instructions>
% # <https://github.com/cortex-lab/Rigbox#installation Installing
% for power users>
% 

%% Setting up experiments
% Below is a set of steps for setting up Rigbox (after installation) in 
% order to run a full experiment. To run test/example experiments, see 
% <./paper_examples.html here.>
% 
% Briefly, before you can run a full experiment you must 1) set up your
% paths so that Rigbox knows from where to load rig settings and
% parameters, 2) save a hardware configuration file so that Rigbox can
% properly initialize its hardware, and 3) locate or create an experiment
% definition function to define your experiment.
%
% # <./paths_config.html Setting up dat.paths>
% # <./hardware_config.html How to configure hardware on the stimulus computer>
% # <./websocket_config.html Setting up communication between the stimulus computer and MC>
% # <./using_single_rig.html Setting up |mc| and |srv.expServer| on the same computer>
% # <./Burgess_hardware_setup.html Setting up hardware for the Burgess steering wheel task> 
% # <./Burgess_setup.html Configuring harware for the Burgess steering wheel task>

%% Running full experiments
% Before you can run a complete experiment, you must set up Rigbox (see
% above section).  Once this is done, you can follow the below
% sections to run a full experiment.

%% Creating experiments
% The principle way to create a new is experiment (i.e. passive stimulation
% or behaviour task) is write an <./glossary.html expDef>.  Below will be a
% set of guides for how to write an expDef, and how to test it.
% 
% * <./using_test_gui.html Playing around with Signals Experiment Definitions>
% * <./using_signals.html A guide to signals methods>
% * <./expDef_inputs.html A guide to writing expDefs>
% * <./visual_stimuli.html A guide to creating visual stimuli>
% * <./signals_cookbook.html Solutions and tips using Signals>
% * <./using_ExpPanel.html How to create a custom Experiment Panel>
% * <./advanced_signals.html Using Signals outside the Experiment
% Framework>
% 

%% Working with Rigbox Experiment data
% Below are some guides on how to work with the experimental data saved by
% Rigbox.  These guides instruduce some functions for loading and
% processing these data, and explain the forms in which data are saved.
% 
% * <./block_files.html Working with block files>
% * Working with ALF files
% * <./using_wheel.html Working with wheel data>
% * <./stim_window_analysis.html Stimulus Window analysis>
% 

%% Troubleshooting
% Rigbox is a mountain of code and there are many things that can go wrong
% when using it.  Below are a few guides for how to fix problems that arise
% in Rigbox.  
% 
% * Basic MATLAB troubleshooting - this guide is for users that are
% unfamiliar with MATLAB.
% * <troubleshooting.html General troubleshooting> - this guide gives a
% list of steps to follow when an error is encountered.
% * <./id_index.html ID index> - A list of Rigbox error/warning IDs along
% with the a detailed description of what they mean and an exhastive list
% of causes and solutions.
% * FAQ - A list of frequently asked questions regarding problems and
% pointers to the solutions.
% * <./paths_conflicts.html Paths conflicts> - Some tips on avoiding errors
% from conflicting paths.

%% User guides
% Below is a list of in-depth guides for users who want to learn the
% ins-and-outs of various packages and classes in Rigbox.
% 
% * <./using_dat_package.html The Data Package> - How to query data locations
% and log experiments using the |+dat| package.
% * <./SignalsPrimer.html How Signals works> - An in-depth guide to how
% Signals works.  This shows you how to work with Signals outside of the
% <Glossary.html Experiment Framework> and gives demonstrations of all
% Signals methods ( |scan|, etc.)  
% * <./Parameters.html Parameters> - How to create and edit
% experiment parameters.
% * <./AlyxMatlabPrimer.html Alyx> - How to interact with an Alyx database
% * <./Timeline.html Timeline> - Using Timeline for time alignment
% * <./using_stimWindow.html The Window class> - Using the stimWindow object
% * <./clocks.html Clocks> - Using the Clock class
%

%% Miscellaneous
% Below is a list of useful topics:
%
% * <./using_services.html Setting up auxiliary services>
% * <./Experiment_framework.html An overview of the Experiment Framework> 
% * <./glossary.html Glossary of Rigbox terminology>
% * <./using_visual_stimuli.html Details of the Signals viewing model>
% * <./contributing.html How to edit the documentation>
%

%% Etc.
% Author: Miles Wells
%
% v0.1.3
