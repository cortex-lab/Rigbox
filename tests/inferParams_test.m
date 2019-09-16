%inferParams test
expDefPath = fullfile(getOr(dat.paths,'rigbox'), 'tests', 'fixtures', 'expDefinitions');

% preconditions
parameters = exp.inferParameters(@nop);
correct = struct('numRepeats', 1000, 'defFunction', which('nop'), 'type', 'custom');
assert(isequal(parameters, correct),'Fundamental problem: inferParameters not returning pars')

%% Test 1: advancedChoiceWorld
% Test an experiment definition that has conditional parameters, an
% experiment panel function file and various default paramters data types
pars = exp.inferParameters([expDefPath filesep 'advancedChoiceWorld.m']);
load(fullfile(expDefPath, 'advancedChoiceWorld_parameters.mat'));

assert(strcmp(pars.defFunction, [expDefPath filesep 'advancedChoiceWorld.m']), ...
  'Incorrect expDef path')

% Remove defFunction field before comparison
pars = rmfield(pars, 'defFunction'); 
parameters = rmfield(parameters, 'defFunction');
assert(isequal(pars, parameters), 'Unexpected parameter struct returned')

%% Test 2: choiceWorld
% Test an experiment definition that has no conditional parameters
pars = exp.inferParameters([expDefPath filesep 'choiceWorld.m']);
load(fullfile(expDefPath, 'choiceWorld_parameters.mat'));

% Remove defFunction field before comparison
pars = rmfield(pars, 'defFunction'); 
parameters = rmfield(parameters, 'defFunction');
assert(isequal(pars, parameters), 'Unexpected parameter struct returned')

%% Test 3: single global parameter
% Test an experiment definition that has single parameter which is a
% character array
pars = exp.inferParameters(@singleCharParam);

parameters = struct(...
  'char', 'charecter array',...
  'numRepeats', 1000,...
  'defFunction', '',...
  'type', 'custom');

assert(isequal(pars, parameters), 'Unexpected parameter struct returned')

%% Test 4: reserved names
% Test an experiment definition that uses reserved parameter names
try
  pars = exp.inferParameters(@reservedParams);
  id = '';
catch ex
  id = ex.identifier;
end
assert(strcmp(id, 'exp:InferParameters:ReservedParameters'), ...
  'Failed to throw reserved parameter name error')

%% Helper functions
function singleCharParam(~, ~, p, varargin)
% Helper function to test an expDef where there is a single parameter which
% is a charecter array
p.char
p.char = 'charecter array';
end

function reservedParams(~, ~, p, varargin)
% Helper function to test use of reserved parameter names 
p.randomiseConditions;
p.services;
p.expPanelFun;
p.numRepeats;
p.defFunction;
p.waterType;
p.isPassive;
end