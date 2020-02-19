----------
# Rigbox
![Coverage badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fsilent-zebra-36.tunnel.datahub.at%2Fcoverage%2Frigbox%2Fmaster)
![Build status badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fsilent-zebra-36.tunnel.datahub.at%2Fstatus%2Frigbox%2Fmaster)

Rigbox is a high-performance, open-source MATLAB toolbox for managing behavioral neuroscience experiments. Initially developed to probe mouse behavior for the [Steering Wheel Setup](https://www.ucl.ac.uk/cortexlab/tools/wheel),  Rigbox simplifies hardware/software interfacing and creates a runtime environment in which an experiment's parameters can be easily monitored and manipulated.  Its many features include synchronizing recordings, managing experimental data and a viewing model for visual stimuli.  Rigbox is mostly object-oriented and highly modular, making designing and extending experiments much simpler.

## Requirements

For exploring Rigbox's features and running test experiments, Rigbox only needs to be installed on a single computer.

Rigbox has the following software dependencies:
* **OS:** Windows 7 or later, 64-bit
* **MATLAB:** 2018b (v9.5) or later, with the Data Acquisition Toolbox
* **Libraries**: [Visual C++ Redistributable Packages for Visual Studio 2013](https://www.microsoft.com/en-us/download/details.aspx?id=40784) & [2015-2019](https://github.com/Psychtoolbox-3/Psychtoolbox-3/raw/master/Psychtoolbox/PsychContributed/vcredist_x64_2015-2019.exe)
* **MATLAB community toolboxes:**
    * [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) (v2 or later)
    * [Psychophysics Toolbox](http://psychtoolbox.org/download.html) (v3 or later)
    * [NI-DAQmx support package](https://uk.mathworks.com/hardware-support/nidaqmx.html) (Required if using an NI DAQ)

Additionally, Rigbox works with a number of extra submodules (included with Rigbox):
* [signals](https://github.com/cortex-lab/signals) (for designing bespoke experiments in Signals)
* [alyx-matlab](https://github.com/cortex-lab/alyx-matlab) (for registering data to, and retrieving from, an [Alyx database](https://alyx.readthedocs.io/en/latest/))
* [npy-matlab](https://github.com/kwikteam/npy-matlab) (for saving data in binary NPY format)
* [wheelAnalysis](https://github.com/cortex-lab/wheelAnalysis) (for analyzing data from the steering wheel task) 

### Hardware

Below are a few minimum hardware requirements for both PCs.  Precise requirements depend on the type of experiments you wish to run, however most contemporary PC with a dedicated graphics card should suffice. 

**Processor:** Intel Core i5-6500 @ 3.0 GHz (or similar)  
**Graphics:** NVIDIA Quadro P400 (or similar)  
**Memory:** DDR4 16 GB @ 2133 MHz (e.g. Corsair Vengeance 16 GB)   

### Software

Below are short instructions for installing Rigbox for users familiar with Git and MATLAB.  For detailed instructions, please see the [installation guide](https://cortex-lab.github.io/Rigbox/install.html).

Before starting, ensure the above toolboxes and packages are installed.  PsychToobox can not be installed via the MATLAB AddOns browser.  See [Installing PsychToobox](#Installing-PsychToolbox) for install instructions.  

* OS: 64 Bit Windows 7 or later
* Libraries: Visual C++ Redistributable Packages for Visual Studio [2013](https://www.microsoft.com/en-us/download/details.aspx?id=40784) & [2015](https://www.microsoft.com/en-us/download/details.aspx?id=48145)
* MATLAB: 2017b or later, including the Data Acquisition Toolbox
* Community MATLAB toolboxes:
	* [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) (v2 or later)
	* [Psychophysics Toolbox](http://psychtoolbox.org/download.html#Windows) (v3 or later)

1. To install Rigbox, run the following commands in the Git Bash terminal to clone the repository from GitHub to your local machine.
```
git clone --recurse-submodules https://github.com/cortex-lab/Rigbox
```
2. Run the `addRigboxPaths.m` function in MATLAB (found in the Rigbox directory) then restart the program.  This adds all required folders and functions to your MATLAB path**.  __NB__: Do __not__ manually add all Rigbox folders and subfolders to the paths

\* Accepting all installer defaults will suffice.  
** To add the paths temporarily for testing, run `addRigboxPaths('SavePaths', false, 'Strict', false)`

Before starting, ensure you have read and followed the above [requirements section](#requirements).

Below we provide brief instructions for installing Rigbox via Git. For a detailed installation guide, including installing Rigbox's software dependencies, see [here](https://cortex-lab.github.io/Rigbox/detailed_installation.html).

1. Download and install a Subversion client.  [SilkSVN](https://sliksvn.com/download/) is recommended.
2. Download and install the [64-Bit GStreamer-1.16.0 MSVC runtime](https://gstreamer.freedesktop.org/data/pkg/windows/1.16.0/gstreamer-1.0-msvc-x86_64-1.16.0.msi).  Make sure all offered packages are installed.
3. Download the MATLAB [installer function](https://raw.githubusercontent.com/Psychtoolbox-3/Psychtoolbox-3/master/Psychtoolbox/DownloadPsychtoolbox.m) from the PsychToolbox GitHub page.
4. Call the function in MATLAB with the target install location (folder must exist) and follow the instructions:
```
git clone --recurse-submodules https://github.com/cortex-lab/Rigbox
```

## Getting started
After following the installation instructions you can start playing around with Rigbox and Signals.  To run one of the example experiments, open MATLAB and run `eui.SignalsTest();`, then select 'advancedChoiceWorld.m'.  

![](https://github.com/cortex-lab/Rigbox/blob/master/docs/html/images/SignalsTest%20GUI%20Example.gif)  

Full Rigbox documentation can be found at [cortex-lab.github.io/Rigbox](https://cortex-lab.github.io/Rigbox/).  

To run the example experiments from the Rigbox paper, see [Running Paper Examples](https://cortex-lab.github.io/Rigbox/paper_examples.html).  

For more infomation on using the Signals Test GUI see [this guide](https://cortex-lab.github.io/Rigbox/using_test_gui.html).  

### Running an experiment
For running full experiments see the [Setting up experiments](https://cortex-lab.github.io/Rigbox/index.html#2) guide.  This will guide you through configuring a visual viewing model, configuring audio devices and setting up hardware that requires a DAQ.  

For information on running experiments via MC and SC, see Rigbox's [index page](https://github.com/cortex-lab/Rigbox/blob/dev/docs/html/index.html). This page also contains information on setting up Rigbox (see also [`docs/setup`](https://github.com/cortex-lab/Rigbox/tree/master/docs/setup)) and using certain Rigbox features (see also [`docs/usage`](https://github.com/cortex-lab/Rigbox/tree/master/docs/setup)) after an MC and SC installation. Furthermore, this page gives an overview of the repository's organization.

## Updating the code

With Git it's very easy to keep the code up-to-date. We strongly recommend regularly updating Rigbox and its submodules by running the following git commands (within the Rigbox directory):
```
git pull --recurse-submodules
```

## Contributing

If you experience a bug or have a feature request, please report them on the [GitHub Issues page](https://github.com/cortex-lab/Rigbox/issues). To contribute code, we encourage anyone to open up a pull request into the dev branch of Rigbox or one of its submodules. Ideally you should include documentation and a test with your feature. Please read [CONTRIBUTING.md](https://github.com/cortex-lab/Rigbox/blob/master/CONTRIBUTING.md) for details on how to contribute code to this repository and our code of conduct.

## Authors & Accreditation

Rigbox was created by [Chris Burgess](https://github.com/dendritic/) in 2013, initially developed to probe mouse behavior for the [Steering Wheel Setup](https://www.ucl.ac.uk/cortexlab/tools/wheel). It is now maintained and developed by Miles Wells (miles.wells@ucl.ac.uk), Jai Bhagat (j.bhagat@ucl.ac.uk) and a number of others at [CortexLab](https://www.ucl.ac.uk/cortexlab). See also the full list of [contributors](https://github.com/cortex-lab/Rigbox/graphs/contributors).

For further information, see [our publication](https://www.biorxiv.org/content/10.1101/672204v3). Please cite this source appropriately in publications which use Rigbox to acquire data.

## Acknowledgements

* [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) for code pertaining to Rigbox's UI
* [Psychophsics Toolbox](http://psychtoolbox.org) for code pertaining to visual stimulus presentation
* [NI-DAQmx](https://uk.mathworks.com/hardware-support/nidaqmx.html) for code pertaining to inerfacing with a NI-DAQ device
* [TooTallNate](https://github.com/TooTallNate/Java-WebSocket) for code pertaining to using Java Websockets
* [Timothy E. Holy](http://holylab.wustl.edu/) for the `distinguishable_colors` function