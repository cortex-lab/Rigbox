Installing Rigbox
=================
The following is a detailed description of how to install Rigbox on your experimental rig. 

Prerequisits
------------

Rigbox has the following software dependencies:

* Windows Operating System (7 or later, 64-bit)
* MATLAB (2017b or later)
* The following MathWorks MATLAB toolboxes (note, these can all be downloaded and installed directly within MATLAB via the "Add-Ons" button in the "Home" top toolstrip):
  - Data Acquisition Toolbox
  - Signal Processing Toolbox
  - Instrument Control Toolbox
  - Statistics and Machine Learning Toolbox
* The following community MATLAB toolboxes:
  - GUI Layout Toolbox (v2 or later)
  - Psychophsics Toolbox (v3 or later)
  - NI-DAQmx support package

Additionally, Rigbox works with a number of extra submodules (included):

* signals (for designing bespoke experiments)
* alyx-matlab (for registering data to, and retrieving from, an Alyx database)
* npy-matlab (for saving data in binary NPY format)
* wheelAnalysis (for analyzing data from the steering wheel task)

Installation via Git
--------------------

#. It is highly recommended to install Rigbox via git. If not already downloaded and installed, install git (and the included minGW software environment and Git Bash MinTTY terminal emulator). After installing, launch the Git Bash terminal.
#. To install Rigbox, run the following commands in the Git Bash terminal to clone the repository from GitHub to your local machine. (*NB*: It is not recommended to clone directly into the MATLAB folder)

    cd ~
    git clone --recurse-submodules https://github.com/cortex-lab/Rigbox

#. Open MATLAB, make sure Rigbox and all subdirectories are in your path, run:

    addRigboxPaths

#. Restart MATLAB
#. Set the correct paths on both computers by following the instructions in the '/docs/setup/paths_config' file.
#. On the stimulus computer, set the hardware configuration by following the instructions in the '/docs/setup/hardware_config' file.
#. To keep the submodules up to date, run the following in the Git Bash terminal (within the Rigbox directory):

    git pull --recurse-submodules
