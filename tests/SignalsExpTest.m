classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'expDefinitions']),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util']),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util' filesep 'ptb'])})...
    SignalsExpTest < matlab.perftest.TestCase & matlab.mock.TestCase
  % Note that the experiment object must explicitly be deleted in order for
  % the Signals networks to be unloaded.  This is important 

  properties (SetAccess = protected)
    % Structure of rig device mock objects
    Rig
    % Structure of mock behavior objects
    RigBehaviours
    % SignalsExp object
    Experiment exp.SignalsExp
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
      
      % Turn off unwanted warnings
      orig = warning('off', 'toStr:isstruct:Unfinished');
      testCase.addTeardown(@warning, orig)
      
      testCase.applyFixture(ReposFixture) %TODO maybe move to method setup
      
      % Clear any current networks and add class teardown
      deleteNetwork
      addTeardown(testCase, @clear, 'createNetwork')
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
      % Define some output for the lickDetector
      testCase.assignOutputsWhen(...
        withAnyInputs(testCase.RigBehaviours.lickDetector.readPosition), ...
        randi(100), 0, rand)
      % Define some output for daqController.  These are accessed when
      % determining the water type
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.daqController.SignalGenerators), ...
        struct('WaterType', 'Water'))
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.daqController.ChannelNames), ...
        'rewardValve')

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
      
      % Set some default behaviours for some of the objects
      % First set up a valid experiment (i.e. save some parameters to load)
      testCase.Ref = dat.constructExpRef('test', now, randi(10000));
      assert(mkdir(dat.expPath(testCase.Ref, 'main', 'master')))
      
      % Timeline behaviours
      tl = testCase.RigBehaviours.timeline;
      testCase.assignOutputsWhen(get(tl.UseInputs), {'wheel', 'rotaryEncoder'})
            
%       KbQueueCheck(-1, 'q'); % Just in case we forget to quit out!

      testCase.applyFixture(ClearTestCache)
    end
  end
  
  methods (Test)
    function test_constructor(testCase)
      % Create a minimal set or parameters
      parsStruct.defFunction = @testCase.expDef;
      parsStruct.numRepeats = 1000;
      
      % Instantiate
      testCase.Experiment = testCase.verifyWarning(...
        @()exp.SignalsExp(parsStruct, testCase.Rig), ...
        'Rigbox:exp:SignalsExp:NoScreenConfig');
      
      % Check our signals wired properly.  expStop behaviour is tested
      % separately
      
      expected = {'expStart'; 'newTrial'; 'repeatNum'; 'trialNum'; 'endTrial'; 'expStop'};
      testCase.assertEqual(fieldnames(testCase.Experiment.Events), expected)
      
      testCase.Experiment.Events.expStart.post(testCase.Ref)
      getVals = @()mapToCell(@(s)s.Node.CurrValue, ...
        struct2cell(testCase.Experiment.Events));
      testCase.verifyEqual(getVals(), {testCase.Ref; true; 1; 1; []; []})
      
      runSchedule(testCase.Experiment.Events.expStart.Node.Net)
      testCase.verifyEqual(getVals(), {testCase.Ref; true; 1; 2; true; []})
      
      testCase.Experiment.Events.newTrial.post(false)
      runSchedule(testCase.Experiment.Events.expStart.Node.Net)
      testCase.verifyEqual(getVals(), {testCase.Ref; true; 2; 4; false; []}) 
      
      % Check outputs, etc.
      parsStruct = exp.inferParameters(@advancedChoiceWorld);
      testCase.Rig.screens = rand;
      testCase.Experiment = testCase.verifyWarningFree(...
        @() exp.SignalsExp(parsStruct, testCase.Rig));
      
      % Check screens use used in occulus model
      testCase.verifyEqual(testCase.Experiment.Occ.screens, testCase.Rig.screens)
      
%       fieldnames(testCase.Experiment.Inputs); % TODO
%       expected = {'wheel'; 'wheelMM'; 'wheelDeg'; 'lick'; 'keyboard'};
%       testCase.verifyEqual(fieldnames(testCase.Experiment.Events), expected)
      
      % Test output mapping
      testCase.assertEqual(fieldnames(testCase.Experiment.Outputs), {'reward'});
      node = testCase.Experiment.Outputs.reward.Node;
      affectedIdxs = submit(node.NetId, node.Id, 5);
      applyNodes(node.NetId, affectedIdxs);
      import matlab.mock.constraints.Occurred
      testCase.verifyThat(testCase.RigBehaviours.daqController.command(5), Occurred)

      % Test pars
      testCase.Experiment.Events.expStart.post(testCase.Ref)
      actual = testCase.Experiment.Params.Node.CurrValue;
      testCase.verifyTrue(all(ismember(fieldnames(actual), fieldnames(parsStruct))))
    end
    
    function test_run(testCase)
      % Turn off KbQueueCheck warning
      origWarn = warning('off', 'Rigbox:tests:KbQueueCheck:keypressNotSet');
      testCase.addTeardown(@warning, origWarn)
      
      % Create a minimal set or parameters
      parsStruct.defFunction = @testCase.expDef;
      parsStruct.numRepeats = 5;
      % Instantiate
      testCase.Experiment = exp.SignalsExp(parsStruct, testCase.Rig);
      data = testCase.Experiment.run(testCase.Ref);
      
      expected = {'events', 'inputs', 'outputs', 'paramsValues', 'paramsTimes'};
      testCase.assertTrue(all(ismember(expected, fieldnames(data)))) 
      
      % FIXME End status could be different for experiments that complete
      testCase.verifyEqual(data.endStatus, 'quit')
      tol = 1/(24*60); % 1 minute tolerance
      testCase.verifyEqual(data.startDateTime, now, 'AbsTol', tol)
      testCase.verifyEqual(datenum(data.startDateTimeStr), data.startDateTime, 'AbsTol', tol)
      testCase.verifyEqual(data.expRef, testCase.Ref)
      testCase.verifyEqual(data.rigName, testCase.Rig.name)
      
    end
    
    function test_expStop(testCase)
      % Test behaviour of expStop event and of quitting via keypress and
      % method calls
      
      % Test expStop definition within the experiment function: expStop
      % takes value on 11th trial
      parsStruct.defFunction = @testCase.expDef;
      parsStruct.numRepeats = 15;
      
      % Turn off KbQueueCheck warning
      origWarn = warning('off', 'Rigbox:tests:KbQueueCheck:keypressNotSet');
      testCase.addTeardown(@warning, origWarn)
      
      % Instantiate
      testCase.Experiment = exp.SignalsExp(parsStruct, testCase.Rig);
      data = testCase.Experiment.run(testCase.Ref);
      
      testCase.verifyEqual(data.endStatus, 'quit')
      testCase.assertTrue(isfield(data.events, 'expStopValues'))
      testCase.verifyTrue(data.events.trialNumValues(end) == 11)
      testCase.verifyMatches(data.events.expStopValues, 'complete')

      % Test out of trials
      parsStruct.numRepeats = 5;
      testCase.Experiment = exp.SignalsExp(parsStruct, testCase.Rig);
      data = testCase.Experiment.run(testCase.Ref);
      
      testCase.verifyEqual(data.endStatus, 'quit')
      testCase.assertTrue(isfield(data.events, 'expStopValues'))
      testCase.verifyTrue(data.events.trialNumValues(end) == 5)
      testCase.verifyTrue(data.events.expStopValues)
      
      % Test no expStop in function
      KbQueueCheck(-1, 'q'); % Immediately quit
      parsStruct.defFunction = 'advancedChoiceWorld';
      testCase.Experiment = exp.SignalsExp(parsStruct, testCase.Rig);
      data = testCase.Experiment.run(testCase.Ref);
      
      testCase.verifyEqual(data.endStatus, 'quit')
      testCase.assertTrue(isfield(data.events, 'expStopValues'))
      testCase.verifyTrue(data.events.expStopValues)
    end
    
    function test_alyxRegistration(testCase)
      % Test Alyx interactions
      % First, check the presence of warnings when database url is set and
      % we're not logged into Alyx
      import matlab.mock.constraints.Occurred
      import matlab.mock.constraints.WasCalled
      import matlab.mock.AnyArguments
      % Test expStop definition within the experiment function: expStop
      % takes value on 11th trial
      parsStruct.defFunction = @testCase.expDef;
      parsStruct.numRepeats = 15;
      
      % Turn off KbQueueCheck warning
      origWarn = warning('off', 'Rigbox:tests:KbQueueCheck:keypressNotSet');
      testCase.addTeardown(@warning, origWarn)
      
      % Verify databaseURL is set
      testCase.assertNotEmpty(getOr(dat.paths, 'databaseURL'))
      
      % Instantiate
      testCase.Experiment = exp.SignalsExp(parsStruct, testCase.Rig);
      testCase.verifyWarning(@()testCase.Experiment.run(testCase.Ref), ...
        'Rigbox:exp:SignalsExp:noTokenSet')
      
      % Test with Alyx not logged in
      testCase.Experiment = exp.SignalsExp(parsStruct, testCase.Rig);
      ai = Alyx('','');
      ai.Headless = true;
      testCase.Experiment.AlyxInstance = ai;
      testCase.Experiment.Communicator = testCase.Rig.communicator;
      testCase.verifyWarning(@()testCase.Experiment.run(testCase.Ref), ...
        'Alyx:HeadlessLoginFail')
      comm = testCase.RigBehaviours.communicator;
      testCase.verifyThat(comm.send('AlyxRequest', AnyArguments), WasCalled)
      
      % Test with logged in
      [ai, behaviour] = testCase.createMock(...
        'addedProperties', properties(ai)', ...
        'addedMethods', methods(ai)');
      testCase.assignOutputsWhen(get(behaviour.IsLoggedIn), true)
      testCase.assignOutputsWhen(get(behaviour.Headless), true)
      testCase.Experiment = exp.SignalsExp(parsStruct, testCase.Rig);
      testCase.Experiment.AlyxInstance = ai;
      testCase.Experiment.run(testCase.Ref);
      testCase.verifyThat(withAnyInputs(behaviour.registerFile), Occurred)
      testCase.verifyThat(withAnyInputs(behaviour.postWater), Occurred)
      
      % Test with no database URL
      paths.databaseURL = '';
      save(fullfile(getOr(dat.paths,'rigConfig'), 'paths'), 'paths')
      clearCBToolsCache
      testCase.assertEmpty(getOr(dat.paths, 'databaseURL'))
      
      testCase.Experiment = exp.SignalsExp(parsStruct, testCase.Rig);
      testCase.verifyWarningFree(@()testCase.Experiment.run(testCase.Ref))
    end
    
    function test_eventHandlers(testCase)
      % Also test updates
      
      import matlab.mock.constraints.Occurred
      % Test expStop definition within the experiment function: expStop
      % takes value on 11th trial
      parsStruct.defFunction = @testCase.expDef;
      parsStruct.numRepeats = 15;
      
      % Turn off KbQueueCheck warning
      origWarn = warning('off', 'Rigbox:tests:KbQueueCheck:keypressNotSet');
      testCase.addTeardown(@warning, origWarn)
            
      % Instantiate
      testCase.Experiment = exp.SignalsExp(parsStruct, testCase.Rig);
      testCase.Experiment.Communicator = testCase.Rig.communicator;
      testCase.Experiment.run(testCase.Ref);
      
      history = getMockHistory(testCase, testCase.Rig.communicator);
      events = sequence({history.Inputs});
      type = @(kind) @(event)strcmp(event{2}, kind);
      statuses = events.filter(type('status'));
      expected = {...
        'experimentInit'; 
        'experimentStarted'; 
        'experimentEnded'; 
        'experimentCleanup'};
      testCase.verifyEqual(toCell(statuses.map(@(u)u{3}{4})), expected)
      testCase.verifyNotEmpty(...
        events.filter(type('signals')).first, ...
        'Failed to send any signals updates')
    end
    
    function test_errors(testCase)
      % TODO
    end
    
    function test_checkInput(testCase)
      % TODO
    end
    
    function test_visualStim(testCase)
      % TODO
    end
  end
  
  methods
    function deleteExperiment(testCase)
      % Ensures deletion of experiment
      if ~isempty(testCase.Experiment) && isvalid(testCase.Experiment)
        delete(testCase.Experiment)
      end
    end
    
    function set.Experiment(testCase, experiment)
      % For every new experiment object add event handler for quiting the
      % experiment after 5 seconds.  This is a saftey precaution in case
      % any tests fail and the experiment loop continues indefinitely.
      testCase.deleteExperiment % Delete previous, freeing network slots
      experiment.addEventHandler(exp.EventHandler('experimentStarted'));
      cb = @(t,~)iff(isvalid(experiment), ... % If not yet deleted
        @()quit(experiment), ... % call quit method
        @()stop(t)); % otherwise just stop the timer
      tmr = timer(...
        'StartDelay', 5, ...
        'TimerFcn', cb,...
        'StopFcn', @(t,~)delete(t),...
        'Tag', 'QuitTimer');
      experiment.EventHandlers.addCallback(@(~,~)start(tmr));
      testCase.Experiment = experiment;
    end
  end
  
  methods (Static)
    function expDef(~, events, varargin)
      % EXPDEF A simple def function for testing constructor
      % FIXME: Runaway recursion
      events.endTrial = events.newTrial.delay(0); % delay required for updates
      events.expStop = then(events.trialNum > 10, 'complete');
%       varargin{4}.reward = events.newTrial;
    end
  end
end