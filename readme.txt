In order to install on any computer:

- Rigbox with containing cb-tools and cortexlab
 - cortexlab directory contains all default parameters and the main ChoiceWorld function
- dat.paths must be changed

2016b quirks:

- cb-tools/GUILayout: this is from the Matlab Central 'GUI Layout Toolbox'.  Installed newer version as toolbox.
- Lay to rest the initialism 'MC'
- exp.inferParameters in +eui\MControl line 70 doesn't seem to exist
- Look into tall arrays
- Fully initialize all objects with default constuctors (not always done, e.g. in ParamEditor)

Currently working on ParamEditor/buildGlobalUI
Selector/buildUI: obj.Handle should have normalized Units, BorderType none

Useful info:

+eui/MControl/buildUI is where all major uicontainers are constructed (the main function for building the GUI)
+bui/label simply places text labels in the GUI with uicontrol
+bui/Selector produces a dropdown box, well documented

