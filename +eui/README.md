## Experiment UI Package (+eui):
This `+eui` package contains all code pertaining to graphical user interfaces in Rigbox.
There are five base classes in this folder:

1. `eui.MControl` - The class behind the Master Control (MC) GUI.  
2. `eui.ExpPanel` - The superclass for UI panels that process and plot remote experiment event updates (i.e. the panels under the Current Experiments tab of MC).
3. `eui.Log` - UI control for viewing experiment log entries (the table under the Log tab of MC).
4. `eui.AlyxPanel` - UI for interacting with the Alyx database (the Alyx panel in the New Experiments tab of MC).  Can be run as a stand-alone GUI.
5. `eui.ParamEditor` - UI for viewing and editing parameters (the Parameter panel in the New Experiments table of MC).  Can be run as a stand-alone GUI.
    
## Contents:

Below is a list of all files present:

- `MControl.m` - Whatever it is, take control of your experiments from this GUI
- `AlyxPanel.m` - A GUI for interating with the Alyx database.
- `SignalsTest.m` - A GUI for testing a Signals Experiment.
- `ExpPanel.m` - Basic UI control for monitoring an experiment.
- `SqueakExpPanel.m` - Basic UI control for monitoring a Signals Experiment.
- `ChoiceExpPanel.m` - An eui.ExpPanel subclass for monitoring ChoiceWorld experiments.
- `MappingExpPanel.m` - Preliminary UI for monitoring a mapping experiment.
- `ParamEditor.m` - GUI for visualizing and editing experiment parameters.
- `ConditionPanel.m` - A class for displaying the trial condition parameters in eui.ParamEditor.
- `FieldPanel.m` - A class for displaying global parameters in eui.ParamEditor.
- `Log.m` - UI control for viewing experiment log entries.

## See Also:

- `docs/html/using_mc.m` - A guide to using MC.
- `docs/html/using_ParamEditor.m` - A guide to using the eui.ParamEditor UI.
