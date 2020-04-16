function e = configureSignalsExperiment(paramStruct, rig)
%exp.configureSignalsExperiment Setup Signals Experiment class
%   Instantiate the exp.SignalsExp class and configure the object.
%   Subclasses may be instantiated here using the type parameter.
%
%   Inputs:
%     paramStruct : a SignalsExp parameter structure
%     rig : a structure of rig hardware objects returned by hw.devices)
%
%   Output:
%     e : a SignalsExp object
%
%   Example:
%     rig = hw.devices;
%     rig.stimWindow.open();
%     pars = exp.inferParameters(@choiceWorld);
%     e = exp.configureSignalsExperiment(pars, rig);
%     e.run([]);
%
% See also exp.configureFilmExperiment, exp.configureChoiceExperiment

%% Set the background colour
% If the 'bgColour' parameter is defined, set the background colour
if isfield(paramStruct, 'bgColour')
  rig.stimWindow.BackgroundColour = paramStruct.bgColour;
end

%% Create the experiment object
e = exp.SignalsExp(paramStruct, rig);
e.Type = paramStruct.type; %record the experiment type

end

