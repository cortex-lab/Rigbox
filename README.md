----------
# Rigbox
![Coverage badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fsilent-zebra-36.tunnel.datahub.at%2Fcoverage%2Frigbox%2Fmaster)
![Build status badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fsilent-zebra-36.tunnel.datahub.at%2Fstatus%2Frigbox%2Fmaster)

Rigbox is a high-performance, open-source MATLAB toolbox for managing behavioral neuroscience experiments. Initially developed to probe mouse behavior for the [Steering Wheel Setup](https://www.ucl.ac.uk/cortexlab/tools/wheel),  Rigbox simplifies hardware/software interfacing and creates a runtime environment in which an experiment's parameters can be easily monitored and manipulated.

Rigbox includes many features including synchronizing recordings, managing experimental data and a viewing model for visual stimuli.

Rigbox is mostly object-oriented and highly modular, making designing new experiments much simpler. Rigbox is currently under active, test-driven development. 

## Requirements

For running full experiments Rigbox requires two PCs: one for presenting stimuli and one for monitoring the experiment.  Currently only National Instruments DAQs are supported for acquiring data from hardware devices.  For testing, the toolbox can be run on a single machine.  

### Software

Rigbox has the following software dependencies:
* Windows Operating System (7 or later, 64-bit)
* MATLAB (2017b or later) 
* [Visual C++ Redistributable Packages for Visual Studio 2013](https://www.microsoft.com/en-us/download/details.aspx?id=40784) & [2015-2019](https://github.com/Psychtoolbox-3/Psychtoolbox-3/raw/master/Psychtoolbox/PsychContributed/vcredist_x64_2015-2019.exe) <for Signals>
* The following MathWorks MATLAB toolboxes (note, these can all be downloaded and installed directly within MATLAB via the "Add-Ons" button in the "Home" top toolstrip):
    * Data Acquisition Toolbox
* The following community MATLAB toolboxes:
    * [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) (v2 or later)
    * [Psychophysics Toolbox](http://psychtoolbox.org/download.html) (v3 or later)
    * [NI-DAQmx support package](https://uk.mathworks.com/hardware-support/nidaqmx.html) <Required if using an NI DAQ>      

Additionally, Rigbox works with a number of extra submodules (included with Rigbox):
* [signals](https://github.com/cortex-lab/signals) (for designing bespoke experiments in Signals)
* [alyx-matlab](https://github.com/cortex-lab/alyx-matlab) (for registering data to, and retrieving from, an [Alyx database](https://alyx.readthedocs.io/en/latest/))
* [npy-matlab](https://github.com/kwikteam/npy-matlab) (for saving data in binary NPY format)
* [wheelAnalysis](https://github.com/cortex-lab/wheelAnalysis) (for analyzing data from the steering wheel task) 

### Hardware

Below are a few minimum hardware requirements for both PCs.  These are more of a guide than a requirement as it depends on the type of experiments you wish to run. 

**Processor:** Intel Core i5-6500 @ 3.0 GHz (or similar)
**Graphics:** NVIDIA Quadro P400 (or similar)
**Memory:** DDR4 16 GB @ 2133 MHz (e.g. Corsair Vengeance 16 GB) 

## Installation

Below are short instructions for installing Rigbox for users familiar with Git and MATLAB.  For detailed instructions, please see the [installation guide](https://cortex-lab.github.io/Rigbox/intall.html).

Before starting, ensure the above toolboxes and packages are installed.  PsychToobox can not be installed via the MATLAB AddOns browser.  See [Installing PsychToobox](#Installing-PsychToolbox) for install instructions.  

It is highly recommended to install Rigbox via the [Git Bash](https://git-scm.com/download/win) terminal*. 

1. To install Rigbox, run the following commands in the Git Bash terminal to clone the repository from GitHub to your local machine.
```
git clone --recurse-submodules https://github.com/cortex-lab/Rigbox
```
2. Run the `addRigboxPaths.m` function in MATLAB (found in the Rigbox directory) then restart the program.  This adds all required folders and functions to your MATLAB path.  *Note*: Do __not__ manually add all Rigbox folders and subfolders to the paths!**

\* Accepting all installer defaults will suffice.  
** To add the paths temporarily for testing:
```
addRigboxPaths('SavePaths', false, 'Strict', false)
```

### Installing PsychToolbox

PsychToolbox-3 is required for visual and auditory stimulus presentation.  Below are some simple steps for installing PsychToolbox.  For full details see [their documentation](http://psychtoolbox.org/download.html#Windows).

1. Download and install a Subversion client.  [SilkSVN](https://sliksvn.com/download/) is recommended.
2. Download and install the [64-Bit GStreamer-1.16.0 MSVC runtime](https://gstreamer.freedesktop.org/data/pkg/windows/1.16.0/gstreamer-1.0-msvc-x86_64-1.16.0.msi).  Make sure all offered packages are installed.
3. Download the MATLAB [installer function](https://raw.githubusercontent.com/Psychtoolbox-3/Psychtoolbox-3/master/Psychtoolbox/DownloadPsychtoolbox.m) from the PsychToolbox GitHub page.
4. Call the function in MATLAB with the target install location (folder must exist) and follow the instructions:
```
DownloadPsychtoolbox('C:\') % Install to C drive
```

## Getting started
After following the installation instructions you can start playing around with Rigbox and Signals.  To run one of the example experiments, open MATLAB and run `eui.SignalsTest();`, then select 'advancedChoiceWorld.m'.

Full Rigbox documentaion can be found at [https://cortex-lab.github.io/Rigbox/](https://cortex-lab.github.io/Rigbox/).
To get an idea of how experiments are run using the Rigbox Signal Experiment framework see [Playing Around With Signals](https://cortex-lab.github.io/Rigbox/using_test_gui.html).  
To run the example experiments from the Rigbox paper, see [Running Paper Examples](https://cortex-lab.github.io/Rigbox/paper_examples.html).

### Running an experiment
For running experiments, edit your `+dat.paths.m` file to set paths for saving config files and experiment data.  A template can be found in  [docs/setup/paths_template.m](https://github.com/cortex-lab/Rigbox/blob/master/docs/setup/paths_template.m).  Then configure the hardware by following the instructions in the [Configuring hardware](https://cortex-lab.github.io/Rigbox/hardware_config.html) guide.  This will guide you through configuring a visual viewing model, configuring audio devices and setting up hardware that requires a DAQ.  

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

Information specific to the steering wheel task can be found on the [CortexLab website](https://www.ucl.ac.uk/cortexlab/tools/wheel).

## Updating the code
With Git it's very easy to keep the code up-to-date.  To update Rigbox and all submodules at the same time, run the following in the Git Bash terminal (within the Rigbox directory):
```
git pull --recurse-submodules
```

When calling `srv.expServer` and `mc`, the code is automatically updated if a new stable release is available.  This behvaiour can be configured with the 'updateSchedule' field in your `+dat/paths.m` file.

## Contributing

If you experience a bug or have a feature request, please report them on the [GitHub Issues page](https://github.com/cortex-lab/Rigbox/issues).  To contribute code we encourage anyone to open up a pull request into the dev branch of Rigbox or one of its submodules.  Ideally you should include documentation and a test with your feature.

Please read [CONTRIBUTING.md](https://github.com/cortex-lab/Rigbox/blob/dev/CONTRIBUTING.md) for further details on how to contribute, as well as maintainer guidelines and our code of conduct.

## Authors & Accreditation

Rigbox was started by [Chris Burgess](https://github.com/dendritic/) in 2013. It is now maintained and developed by Miles Wells (miles.wells@ucl.ac.uk), Jai Bhagat (j.bhagat@ucl.ac.uk) and a number of others at [CortexLab](https://www.ucl.ac.uk/cortexlab). See also the full list of [contributors](https://github.com/cortex-lab/Rigbox/graphs/contributors).

For further information, see [our publication](https://www.biorxiv.org/content/10.1101/672204v3). Please cite this source appropriately in publications which use Rigbox to acquire data.

## Acknowledgements

* [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) for code pertaining to Rigbox's UI
* [Psychophsics Toolbox](http://psychtoolbox.org) for code pertaining to visual stimulus presentation
* [NI-DAQmx](https://uk.mathworks.com/hardware-support/nidaqmx.html) for code pertaining to inerfacing with a NI-DAQ device
* [TooTallNate](https://github.com/TooTallNate/Java-WebSocket) for code pertaining to using Java Websockets
* [Andrew Janke](https://github.com/apjanke) for the `isWindowsAdmin` function
* [Timothy E. Holy](http://holylab.wustl.edu/) for the `distinguishable_colors` function