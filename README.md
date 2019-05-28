----------
# Rigbox

Rigbox is a a high-performance, open-source software toolbox for managing behavioral neuroscience experiments. Initially developed to probe mouse behavior for the [Steering Wheel Setup](https://www.ucl.ac.uk/cortexlab/tools/wheel), Rigbox is under active, test-driven development to encompass a variety of experimental paradigms across behavioral neuroscience. Rigbox simplifies hardware/software interfacing, synchronizes data streams from multiple sources, manages experimental data via communication with a remote database, implements a viewing model for visual stimuli, and creates an environment where experimental parameters can be easily monitored and manipulated. Rigbox’s object-oriented paradigm facilitates a modular approach to designing experiments. Rigbox requires two machines, one for stimulus presentation ('the stimulus computer' or 'sc') and another for controlling and monitoring the experiment ('the master computer' or 'mc').

## Getting Started

The following is a brief description of how to install Rigbox on your experimental rig. Detailed, step-by-step information can be found in Rigbox's [ReadTheDocs](https://rigbox.readthedocs.io/en/latest/). Information specific to the steering wheel task can be found on the [CortexLab website](https://www.ucl.ac.uk/cortexlab/tools/wheel).

### Prerequisites

Rigbox has the following software dependencies:
* Windows Operating System (7 or later, 64-bit)
* MATLAB (2017b or later) 
* The following MathWorks MATLAB toolboxes (note, these can all be downloaded and installed directly within MATLAB via the "Add-Ons" button in the "Home" top toolstrip):
    * Data Acquisition Toolbox
    * Signal Processing Toolbox
    * Instrument Control Toolbox
    * Statistics and Machine Learning Toolbox
* The following community MATLAB toolboxes:
    * [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) (v2 or later)
    * [Psychophsics Toolbox](http://psychtoolbox.org/download.html) (v3 or later)
    * [NI-DAQmx support package](https://uk.mathworks.com/hardware-support/nidaqmx.html)        

Additionally, Rigbox works with a number of extra submodules (included):
* [signals](https://github.com/cortex-lab/signals) (for designing bespoke experiments)
* [alyx-matlab](https://github.com/cortex-lab/alyx-matlab) (for registering data to, and retrieving from, an Alyx database)
* [npy-matlab](https://github.com/kwikteam/npy-matlab) (for saving data in binary NPY format)
* [wheelAnalysis](https://github.com/cortex-lab/wheelAnalysis) (for analyzing data from the steering wheel task) 

### Installation via git

0. It is highly recommended to install Rigbox via git. If not already downloaded and installed, install [git](https://git-scm.com/download/win) (and the included minGW software environment and Git Bash MinTTY terminal emulator). After installing, launch the Git Bash terminal. 
1. To install Rigbox, run the following commands in the Git Bash terminal to clone the repository from GitHub to your local machine.  (* *Note*: It is *not* recommended to clone directly into the MATLAB folder)
```
cd ~
git clone --recurse-submodules https://github.com/cortex-lab/Rigbox
```
2. Open MATLAB, make sure Rigbox and all subdirectories are in your path, run: 
> addRigboxPaths 
and restart MATLAB.
3. Set the correct paths on both computers by following the instructions in the '/docs/setup/paths_config' file.
4. On the stimulus computer, set the hardware configuration by following the instructions in the '/docs/setup/hardware_config' file.
5. To keep the submodules up to date, run the following in the Git Bash terminal (within the Rigbox directory):
```
git pull --recurse-submodules
```

### Running an experiment in MATLAB

On the stimulus computer, run:
> srv.expServer

On the master computer, run:
> mc

This opens a GUI that will allow you to choose a subject, edit some of the experimental parameters and press 'Start' to begin the basic steering wheel task on the stimulus computer.

## Code organization

Below is a list of Rigbox's subdirectories and an overview of their respective contents.

### +dat

The "data" package contains code pertaining to the organization and logging of data. It contains functions that generate and parse unique experiment reference ids, and return file paths where subject data and rig configuration information is stored. Other functions include those that manage experimental log entries and parameter profiles. A nice metaphor for this package is a lab notebook.

### +eui

The "user interface" package contains code pertaining to the Rigbox user interface. It contains code for constructing the mc GUI (MControl.m), and for plotting live experiment data or generating tables for viewing experiment parameters and subject logs. 

This package is exclusively used by the master computer.

### +exp

The "experiments" package is for the initialization and running of behavioural experiments. It contains code that define a framework for event- and state-based experiments. Actions such as visual stimulus presentation or reward delivery can be controlled by experiment phases, and experiment phases are managed by an event-handling system (e.g. ResponseEventInfo).  

The package also triggers auxiliary services (e.g. starting remote acquisition software), and loads parameters for presentation for each trail. The principle two base classes that control these experiments are 'Experiment' and its "signals package" counterpart, 'SignalsExp'.

This package is almost exclusively used by the stimulus computer.

### +hw

The "hardware" package is for configuring, and interfacing with, hardware (such as screens, DAQ devices, weighing scales and lick detectors). Within this is the "+ptb" package which contains classes for interacting with PsychToolbox.

'devices.m' loads and initializes all the hardware for a specific experimental rig. There are also classes for unifying system and hardware clocks.

### +psy

The "psychometrics" package contains simple functions for processing and plotting psychometric data.

### +srv

The "stim server" package contains the 'expServer' function as well as classes that manage communications between rig computers.  

The 'Service' base class allows the stimulus computer to start and stop auxiliary acquisition systems at the beginning and end of experiments.

The 'StimulusControl' class is used by the master computer to manage the stimulus computer.

* *Note*: Lower-level communication protocol code is found in the "cortexlab/+io" package.

### cb-tools/burgbox

"Burgbox" contains many simple helper functions that are used by the main packages. Within this directory are additional packages:

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

The "cortexlab" directory is intended for functions and classes that are rig or CortexLab specific, for example, code that allows compatibility with other stimulus presentation packages used by CortexLab (e.g. MPEP)

### tests

The "tests" directory contains code for running unit tests within Rigbox.

### submodules

Additional information on the [alyx-matlab](https://github.com/cortex-lab/alyx-matlab), [npy-matlab](https://github.com/kwikteam/npy-matlab), [signals](https://github.com/cortex-lab/signals) and [wheelAnalysis](https://github.com/cortex-lab/wheelAnalysis) submodules can be found in their respective github repositories.

## Acknowledgements

* [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) for code pertaining to Rigbox's UI
* [Psychophsics Toolbox](http://psychtoolbox.org) for code pertaining to visual stimulus presentation
* [NI-DAQmx](https://uk.mathworks.com/hardware-support/nidaqmx.html) for code pertaining to inerfacing with a NI-DAQ device
* [TooTallNate](https://github.com/TooTallNate/Java-WebSocket) for code pertaining to using Java Websockets

## Contributing

Please read [CONTRIBUTING.md](https://github.com/cortex-lab/Rigbox/blob/dev/CONTRIBUTING.md) for details on how to contribute code to this repository and our code of conduct.

## Authors

The majority of the Rigbox code was written by [Chris Burgess](https://github.com/dendritic/) in 2013. It is now maintained and developed by Miles Wells (miles.wells@ucl.ac.uk), Jai Bhagat (j.bhagat@ucl.ac.uk) and a number of others at [CortexLab](https://www.ucl.ac.uk/cortexlab). See also the full list of [contributors](https://github.com/cortex-lab/Rigbox/graphs/contributors).
