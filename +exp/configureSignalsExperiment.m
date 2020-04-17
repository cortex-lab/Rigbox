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
if isfield(rig, 'stimWindow') && rig.stimWindow.IsOpen
  % If the 'bgColour' parameter is defined use that value, otherwise use
  % the current background colour
  bgColour = getOr(paramStruct, 'bgColour', rig.stimWindow.BackgroundColour);
  fullRange = rig.stimWindow.ColourRange;
  % Normalize by available colour range based on current pixel depth.  This
  % is nearly always 0-255 and sometimes 0-1 but technically it could be
  % any positive number
  rig.stimWindow.BackgroundColour = (bgColour / 255) * fullRange;
end

%% Create the experiment object
e = exp.SignalsExp(paramStruct, rig);
e.Type = paramStruct.type; %record the experiment type

end

