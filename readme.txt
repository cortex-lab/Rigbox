In order to install on any computer:

- Rigbox with some updated functions from cb-tools and cortexlab
 - cortexlab directory contains all default parameters and the main ChoiceWorld function
- dat.paths must be changed

2016b quirks:

- cb-tools/GUILayout: this is from the Matlab Central 'GUI Layout Toolbox'.  Installed newer version as toolbox.
- Lay to rest the initialism 'MC'
- Setting children with object arrays seems to take way longer than with numerical handles...

To Do:

- Experiment panel not checked
- List cortexlab and burg-box functions that were changed

Little fixes:

- checkbox in param editor now functions correctly (added line 382 +eui.ParamEditor/addParamUI)