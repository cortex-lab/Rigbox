%% Installing Rigbox for Timeline only
% Below are some easy step-by-step instructions for installing Rigbox
% exclusively to run Timeline.

%% Requirements
% Timeline runs on MATLAB 2018b or later for Windows. Currently only
% <https://www.ni.com/en-us/innovations/academic-research/teaching-measurements-instrumentation.html
% National Instruments DAQs> are supported for acquiring data from hardware
% devices.
% 
%%% Software
% Rigbox requires the following software to work properly:
% 
% * Windows Operating System (7 or later, 64-bit)
% * MATLAB (2018b, also known as version 9.5, or later)
% * The MATLAB Data Acquisition Toolbox
% * The NI-DAQmx support package (_free_)
% * Psychophysics Toolbox (v3 or later, _free_)
% 
%%% Hardware
% 
% Below are a few minimum PC hardware requirements. 
% 
% * *Processor*: Intel Core i5-6500 @ 3.0 GHz (or similar)
% * *Memory*: DDR4 16 GB @ 2133 MHz (e.g. Corsair Vengeance 16 GB) 
%
%
%% Install steps
% Below are detailed steps on installing all required software. If you 
% already have software installed for a particular step, feel free to skip
% that step.
%
% # Install Windows 7 or later (Windows 10 is recommended).  Windows must
% be must be 64-bit (sometimes called x64, x86_64, AMD64 or Intel 64).
% # Download and install <https://uk.mathworks.com/downloads/ MATLAB> by
% following their
% <https://uk.mathworks.com/help/install/ug/install-mathworks-software.html
% installation guide> (See note 1).  At
% <https://uk.mathworks.com/help/install/ug/install-mathworks-software.html#brhzmcm-1
% step 9>, make sure to check the box for the Data Acquisition Toolbox,
% along with any other MATLAB Mathworks toolboxes you want, though for
% testing Rigbox, no other toolboxes are required (See note 2).  NB: This
% step may take a while.
% # Once downloaded, open MATLAB by double-clicking on the MATLAB icon in
% the start menu.
% # Within MATLAB, install the NI-DAQmx Support Package (See note 2).  NB:
% This step may take a while.
% # Download and install <https://sliksvn.com/download/ SilkSVN> (See note
% 3).
% # Download the
% <https://raw.github.com/Psychtoolbox-3/Psychtoolbox-3/master/Psychtoolbox/DownloadPsychtoolbox.m
% PsychToolbox installer function> and save it into your |Documents/MATLAB| folder.
% # In the MATLAB Command Window (See note 4), type
% |DownloadPsychtoolbox(userpath)| (no quotes) and press enter.  This will
% download and install PsychToolbox to MATLAB folder.  At certain points in
% the installation it will print stuff to the Command Window and ask you to
% press any key to continue.  Do this until the two angled brackes ('|>>|')
% reappear.
% # Close MATLAB by pressing the '|X|' in the top right corner of the window.
% # Download and install <https://git-scm.com/download/win Git Bash for
% Windows> (See note 5).  Use all defaults.
% # Launch Git Bash (See note 6).  A black command line window should appear.  
% # Type the following line into Git Bash (or copy/paste): |cd
% ~/Documents/Github|
% # Copy this line and paste it into Git Bash (use right click for
% pasting): |git clone --recurse-submodules
% https://github.com/cortex-lab/Rigbox|
% # Launch MATLAB and navigate to the following folder (See note 7):
% |Documents\Github\Rigbox|
% # Type the following into the MATLAB Command Window and press enter (See
% note 8): |addRigboxPaths('strict', false)|
% # You should be done now. To test that the NI DAQ support package is
% correctly installed, run |daq.getDevices|. You should see a list of
% available NI devices connected to your computer.
% # See <./paths_config.html Setting up the paths> for how to configure the
% paths for loading harware config settings and saving data.
% # See the Timeline section of <./hardware_config.html#25 Configureing rig hardware> 
% for details on setting up Timeline, and the <./Timeline.html Timeline>
% guide for instructions on using Timeline.

%% Notes
% # MATLAB is not free and requires a MATLAB account in order to
% download.  If you are part of an academic institution you may be able to
% get MATLAB for free.  If in doubt ask your lab supervisor or institute IT
% department.   For more information see
% <https://uk.mathworks.com/help/install/ MATLAB's install guide>. 
% # Once MATLAB is installed, toolboxes can be downloaded and installed
% directly within MATLAB via the "Add-Ons" button in the "Home" top
% toolstrip.  This opens the MATLAB 'AddOn Explorer' where you can search
% and install toolboxes.
% # To download and install <https://sliksvn.com/download/ SilkSVN>,
% follow the link and click the blue button that says 'SVN 1.12.0, 64 bit'
% on the left-hand side.  The numbers might be slightly different but the
% important thing is that you choose the one that says '64 bit'.  Click
% 'OK' in the pop-up window to save the installer zip file.  Once
% downloaded double-click the zip file and open the exe file contained.
% Follow all the steps in the installer.
% # The MATLAB Command Window is usually at the bottom of the MATLAB
% window and has a '|>>|' in it.  For more information, please read the
% <https://uk.mathworks.com/help/matlab/ref/commandwindow.html MATLAB
% documentation about the Command Window>.
% # To download and install <https://git-scm.com/download/win Git Bash for
% Windows>, follow the link and click 'Save file' when the download window
% pops up.  Open the installer file and click 'Next' repeatedly until the
% end, then click 'Finish'.
% # There might be more than one program installed that has 'Git' in the
% name.  Make sure the one you open is called 'Git Bash'.
% # To navigate to a folder in MATLAB, either use the
% <https://uk.mathworks.com/help/matlab/matlab_env/files-and-folders-that-matlab-accesses.html
% Address Field> or type the following into the MATLAB Command Window,
% replacing |USER| with the name of the Windows user that's currently
% logged in: |cd('C:\Users\USER\Documents\Github\rigbox\')|
% # If you've followed the above steps you can safely ignore any warnings
% you may see for trying out Timeline. 

%% Etc.
% Authors: Jai Bhagat, Matteo Caranini, Miles Wells
%
% v0.1.0
%
