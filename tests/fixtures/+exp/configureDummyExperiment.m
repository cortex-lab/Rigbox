function experiment = configureDummyExperiment(~, ~, setMock)
% CONFIGUREDUMMYEXPERIMENT Return a preset experiment mock object
%  Used for injecting a mock or dummy experiment object into the expServer
%  code.  This function may be set in the parameters instead of a typical
%  experiment function.
%
%  Example:
%   exp.configureDummyExperiment([],[],mock);
%   params.experimentFun = @(~,~)exp.configureDummyExperiment;
%
% 2019-09-30 MW created
persistent mock

if nargin > 2 && ~isempty(setMock)
  [experiment, mock] = deal(setMock);
  return
end

if isempty(mock)
  import matlab.mock.TestCase
  testCase = TestCase.forInteractiveUse;
  [mock, experiment] = createMock(testCase, ...
    'AddedProperties', properties(exp.Experiment)', ...
    'AddedMethods', methods(exp.Experiment)');
else
  experiment = mock;
end