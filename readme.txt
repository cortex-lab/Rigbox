In order to install on any computer:

- run the Rigbox/addRigboxPaths.m
- install the GUI Layout Toolbox from here: https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox
- double check that the added paths (including those to the Toolbox) are above the paths to zserver

Main changes:

- handles to objects are no longer numerical
- the UI is now using the most recent version of GUI Layout Toolbox

Little fixes:

- checkbox in param editor now functions correctly (added line 382 +eui.ParamEditor/addParamUI)
- more documentation, particularly for the UI elements
- saved parameters dropdown now ordered in mc

To do:

- make parameter panel scrollable
- rename the cortexlab folder and move +exp to ExpDefinitions
- add specific path for ExpDefinitions in dat.paths (see line 115 in MControl)