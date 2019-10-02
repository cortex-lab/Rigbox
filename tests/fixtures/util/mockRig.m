function [rig, behaviour] = mockRig(testCase)
% MOCKRIG Create rig device mock objects
%  Returns a structure of mock rig objects and another structure of
%  Mock Behavior objects.
%
%  Inputs:
%    testCase (matlab.mock.TestCase) - an instance of a mock unit test case
%
%  Outputs:
%    rig (struct) - structure of mocks with field names matching those
%    	saved in the rig hardware file.
%    behaviour (struct) - Mock Behavior objects corresponding to each mock
%    	in rig.
%
%  Example:
%    import matlab.mock.TestCase
%    testCase = TestCase.forInteractiveUse;
%    [rig, behaviour] = mockRig(testCase)
%
% TODO Call this from calibrate_test
% TODO Make into Fixture
%
% See also HW.DEVICES
%
% 2019-09-30 MW created

rig = struct;

% Window
% [rig.stimWindow, behaviour.stimWindow] = createMock(testCase, ?hw.Window);
[rig.stimWindow, behaviour.stimWindow] = createMock(testCase, ...
  'AddedProperties', properties(hw.ptb.Window)', ...
  'AddedMethods', methods(hw.ptb.Window)');

% Timeline
[rig.timeline, behaviour.timeline] = createMock(testCase, ...
  'AddedProperties', properties(hw.Timeline)', ...
  'AddedMethods', methods(hw.Timeline)');

% mouseInput
[rig.mouseInput, behaviour.mouseInput] = createMock(testCase, ...
  'AddedProperties', properties(hw.DaqRotaryEncoder)', ...
  'AddedMethods', methods(hw.DaqRotaryEncoder)');

% lickDetector
[rig.lickDetector, behaviour.lickDetector] = ...
  createMock(testCase, ?hw.DataLogging);

% scale
[rig.scale, behaviour.scale] = createMock(testCase, ...
  'AddedProperties', properties(hw.WeighingScale)', ...
  'AddedMethods', methods(hw.WeighingScale)');

% daqController
[rig.daqController, behaviour.daqController] = ...
  createMock(testCase, ...
  'AddedProperties', properties(hw.DaqController)', ...
  'AddedMethods', methods(hw.DaqController)');

% RewardValveControl
[rig.daqController.SignalGenerators, behaviour.RewardValveControl] = ...
  createMock(testCase, ...
  'AddedProperties', properties(hw.RewardValveControl)', ...
  'AddedMethods', methods(hw.RewardValveControl)');

% clock
[rig.clock, behaviour.clock] = createMock(testCase, ?hw.Clock);

% communicator
% NB: 2018b and below do not support validation functions in abstract
% property definitions.
  [rig.communicator, behaviour.communicator] = ...
    createMock(testCase, ?io.Communicator);

