----------
# Rigbox

Rigbox is a (mostly) object-oriented MATLAB software package for designing and controlling behavioural experiments (principally, the [steering wheel setup](https://www.ucl.ac.uk/cortexlab/tools/wheel) which [we](https://www.ucl.ac.uk/cortexlab) developed to probe mouse behaviour. Rigbox requires two machines, one for stimulus presentation ('the stimulus server') and another for controlling and monitoring the experiment ('mc').

## Getting Started

The following is a brief description of how to install Rigbox on your experimental rig. Additional detailed, step-by-step information can be found [here](https://www.ucl.ac.uk/cortexlab/tools/wheel).

## Prerequisites

Rigbox has the following software dependencies:
* Windows Operating System (7 or later)
* MATLAB (2016a or later) 
* The following MathWorks MATLAB toolboxes:
    * Data Acquisition Toolbox
    * Signal Processing Toolbox
    * Instrument Control Toolbox
    * Statistics and Machine Learning Toolbox
* The following community MATLAB toolboxes:
    * [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) (v2 or later)
    * [Psychophsics Toolbox](http://psychtoolbox.org/download.html) (v3 or later)
    * [NI-DAQmx support package](https://uk.mathworks.com/hardware-support/nidaqmx.html)        

(* *Note*: You can download all required MathWorks MATLAB toolboxes directly within MATLAB via the "Add-Ons" button in the top Toolstrip with the "Home" tab selected.)
![MATLAB Home Toolstrip](http://i67.tinypic.com/k0zue.png)
​
Afterwards, you can use the MATLAB "ver" command to bring up the list of installed MathWorks toolboxes.

Additionally, Rigbox works with a number of extra submodules (included):
* [signals](https://github.com/cortex-lab/signals) (for running bespoke experiment designs)
* [alyx-matlab](https://github.com/cortex-lab/alyx-matlab) (for registering data to, and retrieving from, an Alyx database)
* [npy-matlab](https://github.com/kwikteam/npy-matlab) (for saving data in binary NPY format)
* [wheelAnalysis](https://github.com/cortex-lab/wheelAnalysis) (for analyzing data from the steering wheel task) 

## Installation via git

0. It is highly recommended to install Rigbox via git. If not already downloaded and installed, install [git](https://git-scm.com/download/win) (and the included minGW software environment and Git Bash MinTTY terminal emulator). After installing, launch the Git Bash terminal. 
1. To install Rigbox, use the following commands in the Git Bash terminal to clone the repository from github to your local machine.  (* *Note*: It is *not* recommended to clone directly into the MATLAB folder)
```
cd ~
git clone https://github.com/cortex-lab/Rigbox.git
```
2. Pull the latest Rigbox-lite branch. This branch is currently the cleanest one, though in the future it will likely be merged with the master branch.  
```
cd Rigbox/
git checkout rigbox-lite
```
3. Clone the submodules:
```
git submodule update --init
```
4. Open MATLAB, make sure Rigbox and all subdirectories are in your path, run: 
> addRigboxPaths 

and restart MATLAB.

5. Set the correct paths by following the instructions in the 'Rigbox\+dat\paths.m' file on both machines.
6. On the stimulus server, load 'Rigbox\Repositories\code\config\exampleRig\hardware.mat' and edit according to your specific hardware setup (link to detailed instructions above, under 'Getting started').

To keep the submodules up to date, run the following in the Git Bash terminal (within the Rigbox directory):
```
git pull
git submodule update --remote
```
## Running an experiment in MATLAB

On the stimulus server, run:
> srv.expServer

On the mc computer, run:
> mc

This opens a GUI that will allow you to choose a subject, edit some of the experimental parameters and press 'Start' to begin the basic steering wheel task on the stimulus server.

## Code organization

Below is a list of the principle directories and their general purpose.

### +dat

The "data" package contains code pertaining to the organization and logging of data. It contains functions that generate and parse unique experiment reference ids, and return file paths where subject data and rig configuration information is stored. Other functions include those that manage experimental log entries and parameter profiles. A nice metaphor for this package is a lab notebook.

### +eui

The "user interface" package contains code pertaining to the Rigbox user interface. It contains code for constructing the mc GUI (MControl.m), and for plotting live experiment data or generating tables for viewing experiment parameters and subject logs. 

This package is exclusively used by the mc computer.

### +exp

The "experiments" package is for the initialization and running of behavioural experiments. It contains code that define a framework for event- and state-based experiments. Actions such as visual stimulus presentation or reward delivery can be controlled by experiment phases, and experiment phases are managed by an event-handling system (e.g. ResponseEventInfo).  

The package also triggers auxiliary services (e.g. starting remote acquisition software), and loads parameters for presentation for each trail. The principle two base classes that control these experiments are 'Experiment' and its "signals package" counterpart, 'SignalsExp'.

This package is almost exclusively used by the stimulus server.

### +hw

The "hardware" package is for configuring, and interfacing with, hardware (such as screens, DAQ devices, weighing scales and lick detectors). Within this is the "+ptb" package which contains classes for interacting with PsychToolbox.

'devices.m' loads and initializes all the hardware for a specific experimental rig. There are also classes for unifying system and hardware clocks.

### +psy

The "psychometrics" package contains simple functions for processing and plotting psychometric data.

### +srv

The "stim server" package contains the expServer function as well as classes that manage communications between rig computers.  

The 'Service' base class allows the stimulus server to start and stop auxiliary acquisition systems at the beginning and end of experiments.

The 'StimulusControl' class is used by the mc computer to manage the stimulus server.

* *Note*: Lower-level communication protocol code is found in the "cortexlab/+io" package.

### cb-tools/burgbox

Burgbox contains many simple helper functions that are used by the main packages. Within this directory are additional packages:

* +bui --- Classes for managing graphics objects such as axes
* +aud --- Functions for interacting with PsychoPortAudio
* +file --- Functions for simplifying directory and file management, for instance returning the modified dates for specified folders or filtering an array of directories by those that exist
* +fun --- Convenience functions for working with function handles in MATLAB, e.g. functions similar cellfun that are agnostic of input type, or ones that cache function outputs
* +img --- Classes that deal with image and frame data (DEPRECATED)
* +io --- Lower-level communications classes for managing UDP and TCP/IP Web sockets
* +plt --- A few small plotting functions (DEPRECATED)
* +vis --- Functions for returning various windowed visual stimuli (i.g. gabor gratings)
* +ws --- An early Web socket package using SuperWebSocket (DEPRECATED)

### cortexlab

The cortexlab directory is intended for functions and classes that are rig or cortexlab specific, for instance code that allows compatibility with other stimulus presentation packages used by cortexlab (e.g. MPEP)

### submodules

Additional information on the [alyx-matlab](https://github.com/cortex-lab/alyx-matlab), [npy-matlab](https://github.com/kwikteam/npy-matlab), [signals](https://github.com/cortex-lab/signals) and [wheelAnalysis](https://github.com/cortex-lab/wheelAnalysis) submodules can be found in their respective github repositories.

## Authors

The majority of the Rigbox code was written by [Chris Burgess](https://github.com/dendritic/) in 2013. It is now maintained and developed by a number of people at [CortexLab](https://www.ucl.ac.uk/cortexlab).
