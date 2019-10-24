classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})...
    SignalsExpTest < matlab.perftest.TestCase & matlab.mock.TestCase

  properties (SetAccess = protected)
    % Structure of rig device mock objects
    Rig
    % Structure of mock behavior objects
    RigBehaviours
    % Experiment mock object
    Experiment
    % Experiment behaviour object
    ExpBehaviour
    % An experiment reference for the test
    Ref
  end
  
  methods (TestClassSetup)
    function setupFolder(testCase)
      % SETUPFOLDER Set up subject, queue and config folders for test
      %  Creates a few folders for saving parameters and hardware.  Adds
      %  teardowns for deletion of these folders.  Sets global INTEST flag
      %  to true and adds teardown.  Also creates a custom paths file to
      %  deactivate Alyx.

      % Set INTEST flag to true
      setTestFlag(true)
      testCase.addTeardown(@setTestFlag, false)
      
      testCase.applyFixture(ReposFixture)
      
      addTeardown(testCase, @clearCBToolsCache)
    end
  end
  
  methods (TestMethodSetup)
    function setMockRig(testCase)
      % SETMOCKRIG Inject mock rig with shadowed hw.devices
      %   1. Create mock rig device objects
      %   2. Create mock experiment
      %   3. Set the mock rig object to be returned on calls to hw.devices
      %   4. Set some default behaviours and add teardowns
      % 
      % See also mockRig, KbQueueCheck
      
      % Create fresh set of mock objects
      [testCase.Rig, testCase.RigBehaviours] = mockRig(testCase);
      
      % Create duck typed mock experiment for tests where experiment is run
      [testCase.Experiment, testCase.ExpBehaviour] = createMock(testCase, ...
        'AddedProperties', properties(exp.Experiment)', ...
        'AddedMethods', methods(exp.Experiment)');

      % Set a couple of extra fields
      testCase.Rig.name = 'testRig';
      testCase.Rig.clock = hw.ptb.Clock;
      testCase.Rig.audioDevices = struct(...
        'DeviceName', 'default',...
        'DeviceIndex', -1,...
        'DefaultSampleRate', 44100,...
        'NrOutputChannels', 2);
      
      % Set some default behaviours for some of the objects
      % First set up a valid experiment (i.e. save some parameters to load)
      testCase.Ref = dat.constructExpRef('test', now, randi(10000));
      assert(mkdir(dat.expPath(testCase.Ref, 'main', 'master')))
      
      % Timeline behaviours
      tl = testCase.RigBehaviours.timeline;
      testCase.assignOutputsWhen(get(tl.UseInputs), {'wheel', 'rotaryEncoder'})
      
      % Add outputs for properties accessed by expServer, namely the
      % endStatus of the experiment
      testCase.assignOutputsWhen(...
        get(testCase.ExpBehaviour.Data), ...
        struct('endStatus', 'aborted', 'expRef', testCase.Ref))
      
      KbQueueCheck(-1, 'q'); % Just in case we forget to quit out!

      % Clear mock histories just to be safe
%       clearHistory = @(mock) testCase.clearMockHistory(mock);
%       structfun(@(mock) testCase.addTeardown(clearHistory, mock), testCase.Rig);
      testCase.addTeardown(@clear, ...
        'KbQueueCheck', 'configureDummyExperiment', 'devices')
    end
  end
  
  methods (Test)
    function test_constructor(testCase)
      % Create a minimal set or parameters
      parsStruct.defFunction = @testCase.expDef;
      parsStruct.numRepeats = 1000;
      % Instantiate
      experiment = exp.SignalsExp(parsStruct, testCase.Rig);
      
    end
    
    function test_run(testCase)
      testCase.assignOutputsWhen(...
        withAnyInputs(testCase.RigBehaviours.lickDetector.readPosition), ...
        randi(100), 0, rand)
      
      % Create a minimal set or parameters
      parsStruct.defFunction = @testCase.expDef;
      parsStruct.numRepeats = 2;
      % Instantiate
      experiment = exp.SignalsExp(parsStruct, testCase.Rig);
      data = experiment.run(testCase.Ref);
    end
  end
  
  methods (Static)
    function expDef(~, events, varargin)
      % EXPDEF A simple def function for testing constructor
      % FIXME: Runaway recursion
      events.endTrial = events.newTrial.identity;
      events.expStop = then(events.trialNum > 400, true);
    end
  end
end