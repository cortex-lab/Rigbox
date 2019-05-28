%% Dealing with parameters
paramStruct = exp.inferParameters('defFunction');
parameters = exp.Parameters(paramStruct);

parameters.set(name, value, description, units)
parameters.makeTrialSpecific(name)
parameters.makeGlobal(name, newValue)
parameters.Struct = rmfield(parameters.Struct, name);
parameters.removeConditions(indices)

[cs, globalParams, trialParams] = parameters.toConditionServer(obj, randomOrder);
[globalParams, trialParams] = parameters.assortForExperiment;