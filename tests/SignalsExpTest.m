classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'expDefinitions']),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util']),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util' filesep 'ptb'])})...
    SignalsExpTest < matlab.perftest.TestCase & matlab.mock.TestCase
  % Note that the experiment object must explicitly be deleted in order for
  % the Signals networks to be unloaded.  
  %
  % Four major things left to test:
  %  1. Visual stimuli
  %  2. Event handlers
  %  3. Posting water and trial numbers to Alyx
  %  4. Performance of Signals

  properties
    % Maximum time in seconds before the quit method is called after
    % starting an experiment.  Precaution in case we get stuck in the main
    % experiment loop
    Timeout {mustBePositive} = 5
  end
  
  properties (SetAccess = protected, Transient)
    % Structure of rig device mock objects
    Rig
    % Structure of mock behavior objects
    RigBehaviours
    % SignalsExp object
    Experiment exp.SignalsExp
    % An experiment reference for the test
    Ref char
    % A basic parameter struct for the test experiment `expDef`
    Pars struct
    % Timer for quitting experiment after timeout
    Timer timer
  end
    
  methods (TestClassSetup)
    function setupFolder(testCase)
      % SETUPFOLDER Set up subject, queue and config folders for test
      %  Creates a few folders for saving parameters and hardware.  Adds
      %  teardowns for deletion of these folders.  Sets global INTEST flag
      %  to true and adds teardown.  Also creates a custom paths file to
      %  deactivate Alyx.

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
            
      testCase.applyFixture(ReposFixture) %TODO maybe move to method setup
      
      % Clear any current networks and add class teardown
      deleteNetwork
      addTeardown(testCase, @clear, 'createNetwork')
      
      % Create our timer
      testCase.Timer = timer(...
        'StartDelay', 5, ...
        'Tag', 'QuitTimer');
      testCase.addTeardown(@delete, testCase.Timer)
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
      
      % First set up a valid experiment reference
      testCase.Ref = dat.constructExpRef('test', now, randi(10000));
      assert(mkdir(dat.expPath(testCase.Ref, 'main', 'master')))
      % Set some basic parameters for expDef we'll use
      testCase.Pars = struct(...
        'defFunction', @testCase.expDef,...
        'numRepeats', 1000);

      % Clear all persistant variables and cache on teardown
      testCase.applyFixture(ClearTestCache)
    end
  end
  
  methods (Test)
    function test_constructor(testCase)
      % Ensure warning on for this test
      id = 'Rigbox:exp:SignalsExp:NoScreenConfig';
      orig = warning('on', id);
      testCase.addTeardown(@warning, orig)
      
      % Instantiate
      testCase.Experiment = testCase.verifyWarning(...
        @()exp.SignalsExp(testCase.Pars, testCase.Rig), id);
      
      % Check our signals wired properly.  expStop behaviour is tested
      % separately
      expected = {'endTrial'; 'expStart'; 'expStop'; 'newTrial'; 'repeatNum'; 'trialNum'};
      actual = fieldnames(testCase.Experiment.Events);
      testCase.assertEqual(sort(actual), expected)
      
      testCase.Experiment.Events.expStart.post(testCase.Ref)
      getVals = @()mapToCell(@(s)s.Node.CurrValue, ...
        struct2cell(testCase.Experiment.Events));
      testCase.verifyEqual(getVals(), {testCase.Ref; true; 1; 1; []; []})
      
      runSchedule(testCase.Experiment.Events.expStart.Node.Net)
      testCase.verifyEqual(getVals(), {testCase.Ref; true; 1; 2; []; true})
      
      testCase.Experiment.Events.newTrial.post(false)
      runSchedule(testCase.Experiment.Events.expStart.Node.Net)
      testCase.verifyEqual(getVals(), {testCase.Ref; true; 2; 4; []; false}) 
      
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
        
      % Create a minimal set or parameters
      testCase.Pars.numRepeats = 5;
      % Instantiate
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
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
      
      % Check the data were saved
      % Load block
      allSaved = all(file.exists(dat.expFilePath(testCase.Ref, 'Block')));
      testCase.assertTrue(allSaved)
      block = dat.loadBlock(testCase.Ref);
      testCase.verifyEqual(block, block)
      
      % TODO Check signals input values
      
    end
    
    function test_expStop(testCase)
      % Test behaviour of expStop event and of quitting via keypress and
      % method calls.  There are 7 possibilities here:
      %  1. Without expStop defined in def function...
      %    a. quit method call (by keypress or direct call to quit method)
      %    b. no more trials (all conditions repeated)
      %  2. With expStop defined in def function...
      %    a. quit method call (by keypress or direct call to quit method)
      %    b. no more trials (all conditions repeated)
      %    c. user-defined expStop event takes a value
      %
      % All but 1b are tested here.
      
      % Removing lick detector from rig in order to reduce command output
      % clutter
      testCase.Rig = rmfield(testCase.Rig, 'lickDetector');
      
      % Test expStop definition within the experiment function: expStop
      % takes value on 11th trial (2c)
      testCase.Pars.numRepeats = 15;
            
      % Instantiate
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
      data = testCase.Experiment.run(testCase.Ref);
      
      testCase.verifyEqual(data.endStatus, 'quit')
      testCase.assertTrue(isfield(data.events, 'expStopValues'))
      testCase.verifyTrue(data.events.trialNumValues(end) == 11)
      testCase.verifyMatches(data.events.expStopValues, 'complete')
      testCase.verifyTrue(numel(data.events.expStopTimes) == 1)

      % Test out of trials (2b)
      testCase.Pars.numRepeats = 5;
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
      data = testCase.Experiment.run(testCase.Ref);
      
      testCase.verifyEqual(data.endStatus, 'quit')
      testCase.assertTrue(isfield(data.events, 'expStopValues'))
      testCase.verifyTrue(data.events.trialNumValues(end) == 5)
      testCase.verifyTrue(data.events.expStopValues)
      testCase.verifyTrue(numel(data.events.expStopTimes) == 1)
      
      % Test quit keypress 
      KbQueueCheck(-1, 'q'); % Immediately quit
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
      data = testCase.Experiment.run(testCase.Ref);
      
      testCase.verifyEqual(data.endStatus, 'quit')
      testCase.assertTrue(isfield(data.events, 'expStopValues'))
      testCase.verifyTrue(data.events.expStopValues)
      testCase.verifyTrue(numel(data.events.expStopTimes) == 1)
      
      % Test quit keypress when no expStop in function (1a)
      KbQueueCheck(-1, 'q'); % Immediately quit
      testCase.Pars.defFunction = 'advancedChoiceWorld';
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
      data = testCase.Experiment.run(testCase.Ref);
      
      testCase.verifyEqual(data.endStatus, 'quit')
      testCase.assertTrue(isfield(data.events, 'expStopValues'))
      testCase.verifyTrue(data.events.expStopValues)
      testCase.verifyTrue(numel(data.events.expStopTimes) == 1)
    end
    
    function test_alyxRegistration(testCase)
      % Test Alyx interactions
      % First, check the presence of warnings when database url is set and
      % we're not logged into Alyx
      import matlab.mock.constraints.Occurred
      import matlab.mock.constraints.WasCalled
      import matlab.mock.AnyArguments
            
      % Verify databaseURL is set
      testCase.assertNotEmpty(getOr(dat.paths, 'databaseURL'))
      
      % Ensure warning on for this test
      id = 'Rigbox:exp:SignalsExp:noTokenSet';
      orig = warning('on', id);
      testCase.addTeardown(@warning, orig)
      
      % Instantiate
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
      testCase.verifyWarning(@()testCase.Experiment.run(testCase.Ref), id)
      
      % Test with Alyx not logged in
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
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
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
      testCase.Experiment.AlyxInstance = ai;
      testCase.Experiment.run(testCase.Ref);
      testCase.verifyThat(withAnyInputs(behaviour.registerFile), Occurred)
      testCase.verifyThat(withAnyInputs(behaviour.postWater), Occurred)
      
      % Test with no database URL
      paths.databaseURL = '';
      save(fullfile(getOr(dat.paths,'rigConfig'), 'paths'), 'paths')
      clearCBToolsCache
      testCase.assertEmpty(getOr(dat.paths, 'databaseURL'))
      
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
      testCase.verifyWarningFree(@()testCase.Experiment.run(testCase.Ref))
    end
    
    function test_eventHandlers(testCase)
      % Also test updates
      
      import matlab.mock.constraints.Occurred
      % Test expStop definition within the experiment function: expStop
      % takes value on 11th trial
                  
      % Instantiate and spy on comms
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
      testCase.Experiment.Communicator = testCase.Rig.communicator;
      testCase.Experiment.run(testCase.Ref);
      
      % Get history of communicator interaction and check experiment phase
      % updates occured in the correct order.
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
      % Check signals events sent
      testCase.verifyNotEmpty(...
        events.filter(type('signals')).first, ...
        'Failed to send any signals updates')
    end
    
    function test_errors(testCase)
      % Test that SignalsExp saves data upon an error 
      wheel = testCase.RigBehaviours.mouseInput;
      errorID = 'Rigbox:SignalsExp:Fail'; errorMsg = 'Failed!';
      testCase.throwExceptionWhen(withAnyInputs(wheel.readAbsolutePosition), ...
        MException(errorID, errorMsg))
      
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
      
      testCase.assertError(@()testCase.Experiment.run(testCase.Ref), errorID)
      % Load block
      allSaved = all(file.exists(dat.expFilePath(testCase.Ref, 'Block')));
      testCase.assertTrue(allSaved)
      data = dat.loadBlock(testCase.Ref);
      testCase.verifyEqual(data.endStatus, 'exception')
      testCase.verifyEqual(data.exceptionMessage, errorMsg)
    end
    
    function test_checkInput(testCase)
      % FIXME This test is not robust
      testCase.Experiment = exp.SignalsExp(testCase.Pars, testCase.Rig);
      % Set a post delay that should be aborted upon second quit keypress
      testCase.Experiment.PostDelay = 5;
            
      % Simulate random keypress, then two quick presses, then pause,
      % another press, resume, quit and urgent quit
      abKey = {true, zeros(size(KbName('KeyNames')))};
      abKey{2}(KbName({'a','b'})) = deal(GetSecs);
      pKey = testCase.Experiment.PauseKey;
      qKey = testCase.Experiment.QuitKey;
      otherKey = '7';
      KbQueueCheck(-1, sequence({otherKey abKey pKey otherKey pKey qKey qKey}));
      
      [T, data] = evalc('testCase.Experiment.run(testCase.Ref)');
      testCase.verifyMatches(T, 'Pause')
      testCase.verifyMatches(T, 'Quit')
      testCase.verifyTrue(data.duration < testCase.Timeout, ...
        'quit key failed to end experiment')
      % Only the first three key presses should be posted to keyboard input
      % signal as others either occur during pause or are reserved keys
      testCase.verifyEqual(data.inputs.keyboardValues, [otherKey, 'ab'], ...
        'Failed to correctly update keyboard signal')
      % Test double-quit abort
      testCase.verifyEqual(data.endStatus, 'aborted', ...
        'failed to abort on second quit keypress')
      delay = diff([data.events.expStopTimes data.experimentCleanupTime]);
      testCase.verifyTrue(delay < testCase.Experiment.PostDelay)
    end
    
    function test_visualStim(testCase)
      % TODO
      parsStruct = exp.inferParameters(@advancedChoiceWorld);
      testCase.Experiment = exp.SignalsExp(parsStruct, testCase.Rig);
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
      if testCase.Timer.Running; stop(testCase.Timer); end
      testCase.deleteExperiment % Delete previous, freeing network slots
      experiment.addEventHandler(exp.EventHandler('experimentStarted'));
      % TODO Remove display
      cb = @(t,~)iff(isvalid(experiment), ... % If not yet deleted
        @()fun.applyForce({@()disp('Timer quit'); @()quit(experiment)}), ... % call quit method
        @()stop(t)); % otherwise just stop the timer
      testCase.Timer.TimerFcn = cb;
      experiment.EventHandlers.addCallback(@(~,~)start(testCase.Timer));
      testCase.Experiment = experiment;
    end
    
  end
  
  methods (Static)
    function expDef(~, events, varargin)
      % EXPDEF A simple def function for testing constructor
      % FIXME: Runaway recursion
      events.endTrial = events.newTrial.delay(0); % delay required for updates
      events.expStop = then(events.trialNum > 10, 'complete');
    end
  end
end