----------
# Rigbox
![Coverage badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fsilent-zebra-36.tunnel.datahub.at%2Fcoverage%2Frigbox%2Fmaster)
![Build status badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fsilent-zebra-36.tunnel.datahub.at%2Fstatus%2Frigbox%2Fmaster)

Rigbox is a high-performance, open-source MATLAB toolbox for managing behavioral neuroscience experiments. Initially developed to probe mouse behavior for the [Steering Wheel Setup](https://www.ucl.ac.uk/cortexlab/tools/wheel), Rigbox is under active, test-driven development to encompass running experiments across a variety of experimental paradigms in behavioral neuroscience.

Rigbox's main goals are to simplify hardware/software interfacing, behavioral task design, and visual and auditory stimuli presentation. Additionally, Rigbox can time-align datastreams from multiple sources and communicate with a remote database to manage experiment data. Rigbox is mostly object-oriented and highly modular, which simplifies the process of designing experiments.

## Requirements

For exploring Rigbox's features and running test experiments, Rigbox only needs to be installed on a single computer.

For running experiments, we recommend installing Rigbox on two computers: one computer (which we refer to as the "Stimulus Computer" or "SC") communicates with an experiment rig's hardware and presents stimuli, and the other computer (which we refer to as the "Master Computer" or "MC") runs a GUI that the experimenter can use to start, monitor, parameterize, and stop the experiment.

### Hardware

For most experiments, typical, contemporary, factory-built desktops running Windows 10 with dedicated graphics cards should suffice. Specific requirements of a SC will depend on the complexity of the experiment. For example, running an audio-visual integration task on multiple screens will require quality graphics and sound cards. SCs may additionally require an i/o device to communicate with external rig hardware, of which only National Instruments Data Acquisition Devices (NI-DAQs, e.g. NI-DAQ USB 6211) are currently supported.

Below are some **minimum** hardware specs required for computers that run Rigbox:
* CPU: 4 logical processors @ 3.0 GHz base speed (e.g. Intel Core i5-6500)
* RAM: DDR4 16 GB @ 2133 MHz (e.g. Corsair Vengeance 16 GB)
* GPU: 2 GB @ 1000 MHz base and memory speed (e.g. NVIDIA Quadro P400)

### Software

Similar to the hardware requirements, software requirements for a SC will depend on the experiment: if acquiring data through a NI-DAQ, the SC will require the MATLAB Data Acquisition Toolbox and MATLAB [NI-DAQmx support package](https://uk.mathworks.com/hardware-support/nidaqmx.html) in addition to the following **minimum** requirements:

* OS: 64 Bit Windows 7 (or later)
* Libraries: Visual C++ Redistributable Packages for Visual Studio [2013](https://www.microsoft.com/en-us/download/details.aspx?id=40784) & [2015](https://www.microsoft.com/en-us/download/details.aspx?id=48145)
* MATLAB: 2017b or later
* Community MATLAB toolboxes:
	* [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) (v2 or later)
    * [Psychophysics Toolbox](http://psychtoolbox.org/download.html#Windows) (v3 or later)

    		The Psychophysics Toolbox is required for visual and auditory stimulus presentation. We recommend following their full installation instructions via the link above, but below we provide brief instructions:

    		1. Download and install a Subversion client. [SilkSVN](https://sliksvn.com/download/) is recommended.

			2. Download and install [gstreamer](https://gstreamer.freedesktop.org/download/). (When the installer prompts you, select the complete installation.)

			3. Download the Psychtoolbox MATLAB [installer function](https://github.com/Psychtoolbox-3/Psychtoolbox-3/blob/master/Psychtoolbox/DownloadPsychtoolbox.m) from the PsychToolbox GitHub page.

			4. Run the installer function in MATLAB with a target installation location as a string input argument, e.g. `DownloadPsychtoolbox('C:\')`, and follow the instructions that appear in the MATLAB command window.

## Installation

Before starting, ensure you have read and followed the above [requirements section](#Requirements).

Here we provide brief instructions for installing Rigbox via Git. (If not already installed, download and install [Git](https://git-scm.com/download/win), and if unsure which options to select during installation, accept the installer defaults).

1. Clone the repository from GitHub. In your git terminal, run:
```
git clone --recurse-submodules https://github.com/cortex-lab/Rigbox
```
(*Note*: It is **not** recommended to clone directly into the MATLAB folder).

2. Add all required Rigbox folders and functions to your MATLAB path. In MATLAB, navigate to the Rigbox root directory (where Rigbox was cloned), and run:
```
addRigboxPaths() 
```
OR
```
addRigboxPaths('SavePaths', false)
```
if you don't want to save the paths for future MATLAB sessions.
(*Note*: Do **not** manually add all Rigbox folders and subfolders to the paths.)

## Getting started

Rigbox uses the *Signals* framework for programatically designing and running behavioral tasks. 
See the *Signals* [docs](https://github.com/cortex-lab/signals/tree/master/docs) for more information on *Signals* and how to run example test experiments on a single computer via Rigbox's `+eui/SignalsTest.m` GUI.

![](https://github.com/cortex-lab/Rigbox/blob/master/docs/html/SignalsTest%20GUI%20Example.gif)
(The above is an example of running the `signals/docs/examples/exp defs/advancedChoiceWorld.m` file in the `+eui/SignalsTest.m` GUI)

For information on running experiments via MC and SC, see Rigbox's [index page](https://github.com/cortex-lab/Rigbox/blob/dev/docs/html/index.html). This page also contains information on setting up Rigbox (see also [`docs/setup`](https://github.com/cortex-lab/Rigbox/tree/master/docs/setup)) and using certain Rigbox features (see also [`docs/usage`](https://github.com/cortex-lab/Rigbox/tree/master/docs/setup)) after an MC and SC installation. Furthermore, this page gives an overview of the repository's organization.

## Updating the code

With Git it's very easy to keep the code up-to-date. We strongly recommend regularly updating Rigbox and its submodules by running the following git commands (within the Rigbox directory):
```
git fetch
git pull --recurse-submodules
```

## Contributing

Please read [CONTRIBUTING.md](https://github.com/cortex-lab/Rigbox/blob/master/CONTRIBUTING.md) for details on how to contribute code to this repository and our code of conduct.

## Authors & Accreditation

Rigbox was created by [Chris Burgess](https://github.com/dendritic/) in 2013. It is now maintained and developed by Miles Wells (miles.wells@ucl.ac.uk), Jai Bhagat (j.bhagat@ucl.ac.uk) and a number of others at [CortexLab](https://www.ucl.ac.uk/cortexlab). See also the full list of [contributors](https://github.com/cortex-lab/Rigbox/graphs/contributors).

For further information, see [our publication](https://www.biorxiv.org/content/10.1101/672204v3). Please cite this source appropriately in publications which use Rigbox to acquire data.

## Acknowledgements

* [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) for code pertaining to Rigbox's UI
* [Psychophsics Toolbox](http://psychtoolbox.org) for code pertaining to visual stimulus presentation
* [NI-DAQmx](https://uk.mathworks.com/hardware-support/nidaqmx.html) for code pertaining to inerfacing with a NI-DAQ device
* [TooTallNate](https://github.com/TooTallNate/Java-WebSocket) for code pertaining to using Java Websockets
* [Andrew Janke](https://github.com/apjanke) for the `isWindowsAdmin` function
* [Timothy E. Holy](http://holylab.wustl.edu/) for the `distinguishable_colors` function