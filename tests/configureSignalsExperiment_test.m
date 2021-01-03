classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'expDefinitions']),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})...
    configureSignalsExperiment_test < matlab.mock.TestCase

  
  properties (SetAccess = protected, Transient)
    % Structure of rig device mock objects
    Rig
    % Structure of mock behavior objects
    RigBehaviours
    % SignalsExp object
    Experiment exp.SignalsExp
    % A basic parameter struct for the test experiment `expDef`
    Pars struct
  end
    
  methods (TestClassSetup)
    function setup(testCase)
      % SETUP Setup test environment
      %  Sets global INTEST flag to true and adds teardown.  

      % Set INTEST flag to true
      setTestFlag(true);
      testCase.addTeardown(@setTestFlag, false)
      
      % Turn off unwanted warnings
      unwanted = {
          'Rigbox:tests:KbQueueCheck:keypressNotSet';
          'Rigbox:exp:SignalsExp:NoScreenConfig';
          'Rigbox:exp:SignalsExp:noTokenSet';
          'toStr:isstruct:Unfinished'};
      cellfun(@(id)testCase.addTeardown(@warning, warning('off',id)), unwanted)      
                  
      % Clear any current networks and add class teardown
      deleteNetwork
      addTeardown(testCase, @clear, 'createNetwork')
    end
  end
  
  methods (TestMethodSetup)
    function setMockRig(testCase)
      % SETMOCKRIG Inject mock rig with shadowed hw.devices
      %   1. Create mock rig device objects
      %   2. Set the mock rig object to be returned on calls to hw.devices
      %   3. Set some default behaviours and add teardowns
      %   4. Set a fake expRef and some parameter defaults
      % 
      % See also mockRig, KbQueueCheck
      
      % Create fresh set of mock objects
      [testCase.Rig, testCase.RigBehaviours] = mockRig(testCase);
      % Define some output for daqController
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.daqController.ChannelNames), ...
        'rewardValve')
      
      % Add behaviour for stimWindow
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.stimWindow.IsOpen), false)
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.stimWindow.ColourRange), 255)
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.stimWindow.BackgroundColour), 127)

      % Set a couple of extra fields
      testCase.Rig.name = 'testRig';
      testCase.Rig.clock = hw.ptb.Clock;
      testCase.Rig.audioDevices = struct(...
        'DeviceName', 'default',...
        'DeviceIndex', -1,...
        'DefaultSampleRate', 44100,...
        'NrOutputChannels', 2);
      
      % Delete previous experiment, if any
      testCase.addTeardown(@testCase.deleteExperiment)
      
      % Set some basic parameters for expDef we'll use
      testCase.Pars = struct(...
        'defFunction', @testCase.expDef,...
        'numRepeats', 1000,...
        'type', 'custom');

      % Clear all persistant variables and cache on teardown
      testCase.applyFixture(ClearTestCache)
    end
  end
  
  methods (Test)
    function test_experimentConfig(testCase)
      % Test that the experiment object is instantiated and passed the rig
      % and pars structures.
      
      % Instantiate
      testCase.Experiment = ...
        exp.configureSignalsExperiment(testCase.Pars, testCase.Rig);
      
      % Check our Experiment was properly instantiated
      testCase.assertEqual(testCase.Experiment.Type, testCase.Pars.type)
      testCase.assertEqual(testCase.Experiment.RigName, testCase.Rig.name)
    end
    
    function test_screenBackground(testCase)
      % Test that the background colour is properly set based on colour
      % range, bgColour parameter, and current window colour
      import matlab.mock.constraints.WasSet
      
      % Simulate open stimWindow
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.stimWindow.IsOpen), true)

      % Check background set without the bgColour param
      testCase.Experiment = ...
        exp.configureSignalsExperiment(testCase.Pars, testCase.Rig);
      behaviour = testCase.RigBehaviours.stimWindow;
      expected = testCase.Rig.stimWindow.BackgroundColour;
      testCase.verifyThat(behaviour.BackgroundColour, ...
        WasSet('ToValue', expected), 'Failed to set background colour')
            
      % Check background set with bgColour param, normalizing by range
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.stimWindow.ColourRange), 1)
      testCase.Pars.bgColour = randi(255);
      testCase.Experiment = ...
        exp.configureSignalsExperiment(testCase.Pars, testCase.Rig);
      expected = testCase.Pars.bgColour/255;
      testCase.verifyThat(behaviour.BackgroundColour, ...
        WasSet('ToValue', expected), 'Failed to set background colour')
    end

  end
  
  methods
    function deleteExperiment(testCase)
      % Ensures deletion of experiment
      if ~isempty(testCase.Experiment) && isvalid(testCase.Experiment)
        delete(testCase.Experiment)
      end
    end
    
    function set.Experiment(testCase, e)
      % Delete previous experiment object before assigning new one
      deleteExperiment(testCase)
      testCase.Experiment = e;
    end
  end
  
  methods (Static)
    function expDef(~, events, varargin)
      % EXPDEF A simple def function for testing constructor
      % Warning: Runaway recursion if run due to zero delay
      events.endTrial = events.newTrial.delay(0); % delay required for updates
      events.expStop = then(events.trialNum > 10, 'complete');
    end
  end
end