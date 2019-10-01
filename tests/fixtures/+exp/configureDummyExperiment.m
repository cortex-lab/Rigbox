function experiment = configureDummyExperiment(~, ~, setMock)
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