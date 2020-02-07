----------
# Rigbox

![Coverage badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgladius.serveo.net%2Fcoverage%2Frigbox%2Fdev)
![Build status badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgladius.serveo.net%2Fstatus%2Frigbox%2Fdev)

Rigbox is a high-performance, open-source toolbox for managing behavioral neuroscience experiments. Initially developed to probe mouse behavior for the [Burgess Steering Wheel Task](https://www.ucl.ac.uk/cortexlab/tools/wheel), Rigbox's main goals are to simplify hardware/software interfacing, behavioral task design, and visual and auditory stimuli presentation. Additionally, Rigbox can time-align datastreams from multiple sources and communicate with a remote database to manage experiment data.

Rigbox is mostly object-oriented and highly modular, which simplifies the process of designing both new and iterative experiments. Rigbox is run in MATLAB with Java components that handle network communication and a C library to boost performance. Rigbox is currently under active, test-driven development.

For further information, see the [Rigbox publication](https://www.biorxiv.org/content/10.1101/672204v3).

@todo add short movie showing exp def running on a rig.

## Notes on Installation

There are different requirements and installation instructions depending on the type of installation performed.

1) For exploring Rigbox's features and running test experiments, Rigbox only needs to be installed on a single computer. We refer to this as a "test installation".

2) When running experiments, Rigbox must be installed on two computers: one computer (which we refer to as the "Stimulus Computer" or "SC") communicates with an experiment rig's hardware and presents stimuli, and the other computer (which we refer to as the "Master Computer" or "MC") runs a GUI which the experimenter uses to start, monitor, parameterize, and stop the experiment. We refer to this as a "MC + SC installation".

## Requirements

### Software

* Windows Operating System (7 or later, 64-bit)
* MATLAB (2017b or later) 
* The MSVC [mscvr120.dll](https://www.dll-files.com/msvcr120.dll.html) and [vcruntime140.dll](https://www.dll-files.com/vcruntime140.dll.html) libraries. These files may already exist in the `C:\Windows\System32` directory; if not, they can be downloaded inidividually via the links in the previous sentence, or as a part of downloading and installing the MSVC [2013 Redistributable Packages](https://www.itechtics.com/microsoft-visual-c-redistributable-versions-direct-download-links/#Microsoft_Visual_C_Redistributable_2013) and [2015 Redistributable Packages](https://www.itechtics.com/microsoft-visual-c-redistributable-versions-direct-download-links/#Microsoft_Visual_C_Redistributable_2015), respectively. If you choose to download the libraries individually, they should both be copied to the `C:\Windows\System32` directory.
* The following MathWorks MATLAB toolboxes (note, these can all be downloaded and installed directly within MATLAB via the "Add-Ons" button in the "Home" top toolstrip. To view a list of the currently installed toolboxes, run `ver` in MATLAB):
    * Data Acquisition Toolbox <For using an NI DAQ> (only required on a SC computer in a MC + SC installation)
    * Signal Processing Toolbox
    * Instrument Control Toolbox
    * Statistics and Machine Learning Toolbox
* The following community MATLAB toolboxes:
    * [NI-DAQmx support package](https://uk.mathworks.com/hardware-support/nidaqmx.html) <For using an NI DAQ> (only required on a SC computer in a MC + SC installation)
    * [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) (v2 or later)
    * [Psychophysics Toolbox](http://psychtoolbox.org/download.html#Windows) (v3 or later) The Psychophysics Toolbox is required for visual and auditory stimulus presentation. We recommend following their full installation instructions via the link above, but below we provide brief instructions. 
    1. Download and install a Subversion client. [SilkSVN](https://sliksvn.com/download/) is recommended.
	2. Download and install [gstreamer](https://gstreamer.freedesktop.org/download/). (When the installer prompts you, select the complete installation.)
	3. Download the Psychtoolbox MATLAB [installer function](https://github.com/Psychtoolbox-3/Psychtoolbox-3/blob/master/Psychtoolbox/DownloadPsychtoolbox.m) from the PsychToolbox GitHub page.
	4. Run the installer function in MATLAB with a target installation location as a string input argument, e.g. `DownloadPsychtoolbox('C:\')`, and follow the instructions that appear in the MATLAB command window.

### Hardware

For most experiments, typical, contemporary, factory-built desktops running Windows 10 with dedicated graphics cards should suffice. SC computers also require an i/o device to handle rig hardware. For bespoke builds, we recommend the following **minimum** hardware specs:

For MC and SC:
- cpu : at least 4 logical processors and base speed > 3 ghz. ([e.g.](https://ark.intel.com/content/www/us/en/ark/products/75122/intel-core-i7-4770-processor-8m-cache-up-to-3-90-ghz.html))
- ram: at least 16 gb ddr-4 that clocks at a minimum of 2600 mhz (or has a true latency < 20 ns). ([e.g.](https://www.corsair.com/uk/en/Categories/Products/Memory/VENGEANCE-LPX/p/CMK16GX4M2B3000C15))

For SC, additionally:
- gpu : at least 256 shaders, 2 gb gddr5 memory, 32 gb/s bandwidth, and base and memory clocks each at a minimum of 1000 mhz. ([e.g.](https://www.pny.com/nvidia-quadro-p400))
- ssd: a max read/write speed of at least 500 mb/s. ([e.g.](https://www.techradar.com/uk/reviews/samsung-860-evo))
- i/o device (to handle SC rig hardware): [NI-DAQ USB 6211](https://www.ni.com/en-gb/support/model.usb-6211.html)

## Installation

Here we provide brief instructions for the test installation of Rigbox via Git. (If not already installed, download and install [Git](https://git-scm.com/download/win), and if unsure which options to select during installation, accept the installer defaults).

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

For detailed, step-by-step instructions on the MC + SC installation, follow the [set-up guide](https://github.com/cortex-lab/Rigbox/tree/master/docs/setup) after following the above steps.

## Getting Started

Here we provide a brief overview of how *Signals* experiments run in Rigbox. *Signals* is a framework for programatically designing and running behavioral tasks. Rigbox uses *Signals* to treat an experiment as a reactive network whose nodes represent experimental parameters that update over time. *Signals* allows an experimenter to link stimulus, action, and outcome by defining transformations on input nodes to trigger output nodes. For more information on *Signals*, see the [docs](https://github.com/cortex-lab/signals/tree/master/docs).

@todo add picture

If you have completed the test installation, you can see the *Signals* [docs](https://github.com/cortex-lab/signals/tree/master/docs) for information on running example *Signals* experiments via `+eui/SignalsTest` and playing around with standalone *Signals* scripts.

If you have completed the MC + SC installation, see `\docs\setup\running_experiments\` for information on using the MC GUI to run *Signals* experiments.

## Code organization

For detailed information on the full contents of the Rigbox repository, see the [index](https://github.com/cortex-lab/Rigbox/blob/dev/docs/html/index.html).

## Updating the code

With Git it's very easy to keep the code up-to-date. We strongly recommend regularly updating Rigbox and its submodules by running the following git commands (within the Rigbox directory):
```
git fetch
git pull --recurse-submodules
```

The 'updateSchedule' field in your `+dat/paths.m` file can be set to automatically pull the latest code each time `srv.expServer` or `mc` is run, obviating the need to manually run the above git commands. See the [paths template file](https://github.com/cortex-lab/Rigbox/blob/dev/docs/setup/paths_template.m) for more information.

## Contributing

Please read [CONTRIBUTING.md](https://github.com/cortex-lab/Rigbox/blob/dev/CONTRIBUTING.md) for details on how to contribute code to this repository and our code of conduct.

## Acknowledgements

* [GUI Layout Toolbox](https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) for code pertaining to Rigbox's UI.
* [Psychophsics Toolbox](http://psychtoolbox.org) for code pertaining to visual and auditory stimulus presentation.
* [NI-DAQmx](https://uk.mathworks.com/hardware-support/nidaqmx.html) for code pertaining to inerfacing with a NI-DAQ device.
* [TooTallNate](https://github.com/TooTallNate/Java-WebSocket) for code pertaining to using Java Websockets to handle network communication between 'MC' and 'SC'.

## Authors & Accreditation

The majority of the Rigbox code was written by [Chris Burgess](https://github.com/dendritic/) in 2013. It is now maintained and developed by Miles Wells (miles.wells@ucl.ac.uk), Jai Bhagat (j.bhagat@ucl.ac.uk) and a number of others at [CortexLab](https://www.ucl.ac.uk/cortexlab). See also the full list of [contributors](https://github.com/cortex-lab/Rigbox/graphs/contributors).

Rigbox is described in-depth in [this publication](https://www.biorxiv.org/content/10.1101/672204v3). Please cite this source appropriately in publications that present data that has been acquired using Rigbox.

The Burgess steering wheel task was first described in [this publication](https://www.ncbi.nlm.nih.gov/pubmed/28877482). Please cite this source appropriately in publications that present data that has been acquired in experiments that use a variant of this task.

In addition to the [Alyx ReadTheDocs](https://alyx.readthedocs.io/en/latest/), Alyx is also described in [this publication](https://www.biorxiv.org/content/10.1101/827873v2). Please cite this source apropriately in publications that present data that has been logged using Alyx.