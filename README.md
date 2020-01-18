----------
# Rigbox
![Coverage badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgladius.serveo.net%2Fcoverage%2Frigbox%2Fdev)
![Build status badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgladius.serveo.net%2Fstatus%2Frigbox%2Fdev)

Rigbox is a high-performance, open-source toolbox for managing behavioral neuroscience experiments. Initially developed to probe mouse behavior for the [Steering Wheel Setup](https://www.ucl.ac.uk/cortexlab/tools/wheel),  Rigbox's main goals are to simplify hardware/software interfacing, visual and auditory stimuli presentation, and behavioral task design and implementation, by allowing users to progrmatically define behavioral tasks whose parameters can be easily monitored and manipulated. Additionally, Rigbox can time-align data streams from multiple sources and communicate with a remote database to manage experiment data.

Rigbox is mostly object-oriented and highly modular, which simplifies the process of designing both new and iterative experiments. Rigbox is run in MATLAB with some Java components that handle network communication and a C library to boost performance. Rigbox is currently under active, test-driven development. 

## Getting Started

The following is a brief description of Rigbox's requirements and installation and getting started instructions. For exploring Rigbox's features and running test experiments, Rigbox only needs to be installed on a single computer. However, for running complete experiments, Rigbox must be installed on two computers: one computer communicates with an experiment rig's hardware and presents stimuli (which we refer to as the "Stimulus Computer" or "SC"), and the other computer the user interacts with to start, stop, monitor, and parameterize the experiment (which we refer to as the "Master Computer", or "MC"). Detailed, step-by-step information can be found in Rigbox's [documentation](https://github.com/cortex-lab/Rigbox/tree/master/docs). Information specific to the steering wheel task can be found on the [CortexLab website](https://www.ucl.ac.uk/cortexlab/tools/wheel).

### Requirements

#### Software

* Windows Operating System (7 or later, 64-bit)
* MATLAB (2017b or later) 
* [Visual C++ Redistributable Packages for Visual Studio 2013](https://www.microsoft.com/en-us/download/details.aspx?id=40784) <for Signals>
* The following MathWorks MATLAB toolboxes (note, these can all be downloaded and installed directly within MATLAB via the "Add-Ons" button in the "Home" top toolstrip):
    * Data Acquisition Toolbox <For using an NI DAQ>
    * Signal Processing Toolbox
    * Instrument Control Toolbox
    * Statistics and Machine Learning Toolbox
* The following community MATLAB toolboxes:
    * [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) (v2 or later)
    * [Psychophsics Toolbox](http://psychtoolbox.org/download.html) (v3 or later)
    * [NI-DAQmx support package](https://uk.mathworks.com/hardware-support/nidaqmx.html) <For using an NI DAQ>      

Additionally, Rigbox works with a number of extra submodules (included):
* [signals](https://github.com/cortex-lab/signals) (for designing bespoke experiments in Signals)
* [alyx-matlab](https://github.com/cortex-lab/alyx-matlab) (for registering data to, and retrieving from, an [Alyx database](https://alyx.readthedocs.io/en/latest/))
* [npy-matlab](https://github.com/kwikteam/npy-matlab) (for saving data in binary NPY format)
* [wheelAnalysis](https://github.com/cortex-lab/wheelAnalysis) (for analyzing data from the steering wheel task) 

#### Hardware
@todo fill in hardware requirements section.

### Installation

It is highly recommended to install Rigbox via the [Git Bash](https://git-scm.com/download/win) terminal*. 

1. To install Rigbox, run the following commands in the Git Bash terminal to clone the repository from GitHub to your local machine.  It is *not* recommended to clone directly into the MATLAB folder
```
git clone --recurse-submodules https://github.com/cortex-lab/Rigbox
```
2. Run the `addRigboxPaths.m` function in MATLAB (found in the Rigbox directory) then restart the program.  This adds all required folders and functions to your MATLAB path.  *Note*: Do __not__ manually add all Rigbox folders and subfolders to the paths!**
3. Edit your `+dat.paths.m` file to set paths for saving config files and experiment data.  A template can be found in  [docs/setup/paths_template.m](https://github.com/cortex-lab/Rigbox/blob/master/docs/setup/paths_template.m).
4. For running experiments, set the hardware configuration by following the instructions in the [docs/html/hardware_config.html](https://github.com/cortex-lab/Rigbox/blob/master/docs/setup/hardware_config.m) file.  This will guide you through configuring a visual viewing model, configuring audio devices and setting up hardware that requires a DAQ. 

\* Accepting all installer defaults will suffice. 
** To add the paths temporarily for testing:
```
addRigboxPaths('SavePaths', false, 'Strict', false)
```

### Installing PsychToolbox

PsychToolbox-3 is required for visual and auditory stimulus presentation.  Below are some simple steps for installing PsychToolbox.  For full details see [their documentation](http://psychtoolbox.org/download.html#Windows).

1. Download and install a Subversion client.  [SilkSVN](https://sliksvn.com/download/) is recommended.
2. Download the MATLAB [installer function](https://raw.githubusercontent.com/Psychtoolbox-3/Psychtoolbox-3/master/Psychtoolbox/DownloadPsychtoolbox.m) from the PsychToolbox GitHub page.
3. Call the function in MATLAB with the target install location (folder must exist) and follow the instructions:
```
DownloadPsychtoolbox('C:\') % Install to C drive
```

### Playing around with Signals
Full documentaion can be found in [docs/html/index.html](https://github.com/cortex-lab/tree/master/docs/index.m)
To get an idea of how experiments run using the Rigbox Signal Experiment framework, have a look at the following file: [docs/html/using_test_gui.html](https://github.com/cortex-lab/signals/tree/master/docs/using_test_gui.m).

### Running an experiment

On the stimulus computer (SC), run:
```
srv.expServer
```
This opens up a new stimulus window and initializes the hardware devices

On the master computer (MC), run:
```
mc
```

This opens the MC GUI for selecting a subject, experiment, and the SC on which to run the experiment. The MC GUI also allows for editing some experimental parameters and logging into the Alyx database (optional). Rigbox comes with some experiments, namely ChoiceWorld and some Signals experiments found in the submodule's [documentation folder](https://github.com/cortex-lab/signals/tree/master/docs).  Signals experiments are run by selecting '<custom..>' from the experiment drop-down menu and navigating to the desired experiment definition function.  To launch the experiment on the selected SC, press 'Start'.

## Updating the code
With Git it's very easy to keep the code up-to-date.  To update Rigbox and all submodules at the same time, run the following in the Git Bash terminal (within the Rigbox directory):
```
git pull --recurse-submodules
```

When calling `srv.expServer` and `mc`, the code is automatically updated if a new stable release is available.  This behvaiour can be configured with the 'updateSchedule' field in your `+dat/paths.m` file.

## Acknowledgements

* [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) for code pertaining to Rigbox's UI
* [Psychophsics Toolbox](http://psychtoolbox.org) for code pertaining to visual and auditory stimulus presentation
* [NI-DAQmx](https://uk.mathworks.com/hardware-support/nidaqmx.html) for code pertaining to inerfacing with a NI-DAQ device
* [TooTallNate](https://github.com/TooTallNate/Java-WebSocket) for code pertaining to using Java Websockets to handle network communication between 'MC' and 'SC'.

## Contributing

Please read [CONTRIBUTING.md](https://github.com/cortex-lab/Rigbox/blob/dev/CONTRIBUTING.md) for details on how to contribute code to this repository and our code of conduct.

## Authors & Accreditation

The majority of the Rigbox code was written by [Chris Burgess](https://github.com/dendritic/) in 2013. It is now maintained and developed by Miles Wells (miles.wells@ucl.ac.uk), Jai Bhagat (j.bhagat@ucl.ac.uk) and a number of others at [CortexLab](https://www.ucl.ac.uk/cortexlab). See also the full list of [contributors](https://github.com/cortex-lab/Rigbox/graphs/contributors).

Rigbox is described in-depth in [this publication](https://www.biorxiv.org/content/10.1101/672204v1). Please cite this source appropriately in publications which use Rigbox to acquire data.
