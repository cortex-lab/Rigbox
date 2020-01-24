% +EUI Experiment UI package
%
% This +eui package contains all code pertaining to graphical user
% interfaces in Rigbox. There are five base classes in this folder:
% 
% 1. MControl - The class behind the Master Control (MC) GUI.  
% 2. ExpPanel - The superclass for UI panels that process and plot remote
%    experiment event updates (i.e. the panels under the Current
%    Experiments tab of MC).
% 3. Log - UI control for viewing experiment log entries (the table under
%    the Log tab of MC).
% 4. AlyxPanel - UI for interacting with the Alyx database (the Alyx panel
%    in the New Experiments tab of MC).  Can be run as a stand-alone GUI.
% 5. ParamEditor - UI for viewing and editing parameters (the Parameter
%    panel in the New Experiments table of MC).  Can be run as a
%    stand-alone GUI.
%
% Files
%   AlyxPanel       - A GUI for interating with the Alyx database
%   ChoiceExpPanel  - UI control for monitoring a 2AFC experiment
%   ConditionPanel  - Deals with formatting trial conditions UI table
%   ExpPanel        - Basic UI control for monitoring an experiment
%   FieldPanel      - Deals with formatting global parameter UI elements
%   Log             - UI control for viewing experiment log entries
%   MappingExpPanel - Preliminary UI for monitoring a mapping experiment
%   MControl        - GUI for the control of experiments
%   ParamEditor     - GUI for visualizing and editing experiment parameters
%   SignalsTest     - A GUI for testing SignalsExp experiment definitions
%   SqueakExpPanel  - Basic UI control for monitoring a Signals experiment
%
% See Also
%   docs/html/using_mc.m, docs/html/using_ParamEditor.m