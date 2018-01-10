----------
# Rigbox

Rigbox is a (mostly) object-oriented MATLAB software package for designing and controlling behavioural experiments.  Principally,  the steering wheel setup we developed to probe mouse behaviour.  It requires two computers, one for stimulus presentation ('the stimulus server') and another for controlling and monitoring the experiment ('mc').

## Getting Started

The following is a brief description of how to install Rigbox on your experimental rig.  However detailed, step-by-step information can be found [here](https://www.ucl.ac.uk/cortexlab/tools/wheel).

## Prerequisites
Rigbox has a number of essential and optional software dependencies, listed below:
* Windows 7 or later
* [MATLAB](https://uk.mathworks.com/downloads/web_downloads/?s_iid=hp_ff_t_downloads) 2016a or later
	* [Psychophsics Toolbox](https://github.com/Psychtoolbox-3/Psychtoolbox-3/releases) v3 or later
	* [NI-DAQmx support package](https://uk.mathworks.com/hardware-support/nidaqmx.html)
	* [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) v2 or later
	* Data Acquisition Toolbox
	* Signal Processing Toolbox
	* Instrument Control Toolbox

Additionally, Rigbox works with a number of extra repositories:
* [Signals](https://github.com/dendritic/signals) (for running bespoke experiment designs)
	* Statistics and Machine Learning Toolbox
	* [Microsoft Visual C++ Redistributable for Visual Studio 2015](https://www.microsoft.com/en-us/download/details.aspx?id=48145)
* [Alyx-matlab](https://github.com/cortex-lab/alyx-matlab) (for registering data to, and retrieving from, an Alyx database
	* [Missing HTTP v1](https://github.com/psexton/missing-http/releases/tag/missing-http-1.0.0) or later
	* [JSONlab](https://uk.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files)

## Installing
1. To install Rigbox, first ensure that all the above dependencies are installed.  
2. Pull the latest Rigbox-lite branch.  This branch is currently the 'cleanest' one, however in the future it will likely be merged with the master branch.  
3. In MATLAB run 'addRigboxPaths.m' and restart the program.
4. Set the correct paths by following the instructions in Rigbox\+dat\paths.m on both computers.
5. On the stimulus server, load the hardware.mat file in Rigbox\Repositories\code\config\exampleRig and edit according to your specific hardware setup (link to detailed instructions above, under 'Getting started').

## Running an experiment

On the stimulus server, run:
> srv.expServer

On the mc computer, run:
> mc

This opens a GUI that will allow you to choose  a subject, edit some of the experimental parameters and press 'Start' to begin the basic steering wheel task on the stimulus server.

# Code organization
Below is a list of the principle directories and their general purpose.
## +dat
The data package contains all the code pertaining to the organization and logging of data.  It contains functions that generate and parse unique experiment reference ids, that return the file paths where subject data and rig configuration information is stored.  Other functions include those that manage experimental log entries and parameter profiles.  This package is akin to a lab notebook.

## +eui
This package contains the code pertaining to the Rigbox user interface.  It contains code for constructing the mc GUI (MControl.m), and for plotting live experiment data or generating tables for viewing experiment parameters and subject logs.  This package is exclusively used by the mc computer.

## +exp
The experiment package is for the initialization and running of behavioural experiments.  These files define a framework for event- and state-based experiments.  Actions such as visual stimulus presentation or reward delivery can be controlled by experiment phases, and experiment phases are managed by an event-handling system (e.g. ResponseEventInfo).  

The package also triggers auxiliary services (e.g. starting remote acquisition software), and loads parameters for presentation each trail.  The principle two base classes that control these experiments are Experiment and its Signals counterpart, SignalsExp.

This package is almost exclusively used by the stimulus server

## +hw
The hardware package is for configuring, and interfacing with, hardware such as screens, DAQ devices, weighing scales and lick detectors.  Withing this is the +ptb package which contains classes for interacting with PsychToolbox.

The devices file loads and initializes all the hardware for a specific experimental rig.   There are also classes for unifying system and hardware clocks.

## +psy
This package contains simple functions for processing and plotting psychometric data

## +srv
This package contains the expServer function as well as classes that manage communications between rig computers.  

The Service base class allows the stimulus server to start and stop auxiliary acquisition systems at the beginning and end of experiments

The StimulusControl class is used by the mc computer to manage the stimulus server

NB: Lower-level communication protocol code is found in the +io package

## cb-tools\burgbox
Burgbox contains many simply helper functions that are used by the main packages.  Within this directory are further packages:
* +bui --- Classes for managing graphics objects such as axes
* +aud --- Functions for interacting with PsychoPortAudio
* +file --- Functions for simplifying directory and file management, for instance returning the modified dates for specified folders or filtering an array of directories by those that exist
* +fun --- Convenience functions for working with function handles in MATLAB, e.g. functions similar cellfun that are agnostic of input type, or ones that cache function outputs
* +img --- Classes that deal with image and frame data (DEPRICATED)
* +io --- Lower-level communications classes for managing UDP and TCP/IP Web sockets
* +plt --- A few small plotting functions (DEPRICATED)
* +vis --- Functions for returning various windowed visual stimuli (i.g. gabor gratings)
* +ws --- An early Web socket package using SuperWebSocket (DEPRICATED)

## cortexlab
The cortexlab directory is intended for functions and classes that are rig or lab specific, for instance code that allows compatibility with other stimulus presentation packages used by cortexlab (i.e. MPEP)

## Authors
The majority of the Rigbox code was written by [Chris Burgess](https://github.com/dendritic/) in 2013.  It is now maintained and developed by a number of people at [CortexLab](https://www.ucl.ac.uk/cortexlab).
