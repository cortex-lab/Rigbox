function tests = inferParams_perfTest
% expDefPath = fullfile(fileparts(which('addRigboxPaths')), 'tests', 'expDefinitions');
% def1 = fullfile(expDefPath, 'advancedChoiceWorld.m');
% def2 = fullfile(expDefPath, 'choiceWorld.m');
% fcn{1} = @()exp.inferParameters(def1);
% fcn{2} = @()exp.inferParameters(def2);

tests = functiontests(localfunctions);
end

function testInferParams(testCase)
expDefPath = fullfile(fileparts(which('addRigboxPaths')), 'tests', 'fixtures', 'expDefinitions');
def1 = fullfile(expDefPath, 'advancedChoiceWorld.m');
exp.inferParameters(def1);
end

function testInferParams2(testCase)
expDefPath = fullfile(fileparts(which('addRigboxPaths')), 'tests', 'fixtures', 'expDefinitions');
def2 = fullfile(expDefPath, 'choiceWorld.m');
exp.inferParameters(def2);
end