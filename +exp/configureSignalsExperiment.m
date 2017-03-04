function e = configureSignalsExperiment(paramStruct, rig)
%UNTITLED13 Summary of this function goes here
%   Detailed explanation goes here

%% Create the experiment object
e = exp.SignalsExp(paramStruct, rig);
e.Type = paramStruct.type; %record the experiment type

end

