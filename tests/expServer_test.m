classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})...
    expServer_test < matlab.unittest.TestCase & matlab.mock.TestCase
  
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
      %  teardowns for deletion of these folders via ReposFixture.  Also
      %  creates a custom paths file to deactivate Alyx.
      %
            
      % Set INTEST flag to true
      setTestFlag(true);
      testCase.addTeardown(@setTestFlag, false)
      
      % Ensure we're using the correct test paths and add teardowns to
      % remove any folders we create
      testCase.applyFixture(ReposFixture)
      
      % Now create a single subject folder
      mainRepo = dat.reposPath('main', 'master');
      assert(mkdir(fullfile(mainRepo, 'test')), ...
        'Failed to create subject folder')
            
      % Save a custom path disabling Alyx
      paths.databaseURL = [];
      configDir = getOr(dat.paths, 'rigConfig');
      save(fullfile(configDir, 'paths.mat'), 'paths')
      
      % Alyx queue location
      qDir = getOr(dat.paths, 'localAlyxQueue');
      assert(mkdir(qDir), 'Failed to create alyx queue')
      
      addTeardown(testCase, @ClearTestCache)
    end
    
    function fixUpdates(~)
      % FIXUPDATES Ensure git update doesn't pull code
      %  Have FETCH_HEAD file appear recently modified to avoid triggering
      %  any code updates.
      %
      % See also GIT.UPDATE
      
      % Make sure git update not triggered
      root = getOr(dat.paths, 'rigbox'); % Rigbox root directory
      fetch_head = fullfile(root, '.git', 'FETCH_HEAD');
      file.modDate(fetch_head, now); % Set recent fetch
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

      % Inject our mocks via calls to hw.devices
      hw.devices('testRig', false, testCase.Rig);
      
      % Set some default behaviours for some of the objects
      % First set up a valid experiment (i.e. save some parameters to load)
      testCase.Ref = dat.constructExpRef('test', now, randi(10000));
      
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
      clearHistory = @(mock) testCase.clearMockHistory(mock);
      structfun(@(mock) testCase.addTeardown(clearHistory, mock), testCase.Rig);
      testCase.addTeardown(@clear, ...
        'KbQueueCheck', 'configureDummyExperiment', 'devices')
    end
  end
  
  methods (Test)
    function test_quit(testCase)
      % 1. Test local quit when idle 
      % 2. Test remote quit during experiment
      % 3. Test remote quit when idle
      % Local quit during experiment is handled by the experiment itself.
      import matlab.mock.actions.Invoke
      import matlab.mock.constraints.Occurred
      
      KbQueueCheck(-1, 'q');
      T = evalc('srv.expServer'); % Capture output
      
      % Test log
      testCase.verifyMatches(T, 'Quitting', 'Failed to log quit')
      testCase.verifyCalled(withAnyInputs(...
        testCase.RigBehaviours.communicator.close), ...
        'Failed to close communicator on exit')
      
      % Retrieve mock history for the DaqControllor
      history = testCase.getMockHistory(testCase.Rig.stimWindow);
      % Check window interactions
      testCase.assertEqual(length(history), 3, ...
        'Unexpected number of stimWindow interactions')
      
      % Verify background colour set
      propSet = strcmp(history(1).Name, 'BackgroundColour') && ...
        all(history(1).Value == 127);
      testCase.verifyTrue(propSet, 'Failed to set background colour')
      
      % Verify window opened then closed
      expected = strcmp(history(2).Name, 'open') && ...
        strcmp(history(3).Name, 'close');
      testCase.verifyTrue(expected, 'Failed to open and close window')
      
      %%% Test remote quit %%%
      % Inject our our mock experiment via function call in srv.prepareExp
      exp.configureDummyExperiment([], [], testCase.Experiment);
      params.experimentFun = @(~,~)exp.configureDummyExperiment;
      
      % Save parameters for expServer to load
      savePath = dat.expFilePath(testCase.Ref, 'parameters', 'master');
      superSave(savePath, struct('parameters', params))
      testCase.assertTrue(dat.expExists(testCase.Ref), ...
        'Failed to save test parameters')

      % Configure our communicator to spoof run message
      id = num2str(randi(10000)); % An id for message verification
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        id, {'run', testCase.Ref, 0, 0, []}, 'mockRig');
      
      % Simulate message arrival
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.communicator.IsMessageAvailable), true)
      
      % When the experiment is run, notify comm listeners of a quit message
      args = {'quit', true, struct('Headless', false, 'IsLoggedIn', true)};
      data = io.MessageReceived(randi(1000), args, 'mockRig');
      cb = @(varargin)testCase.Rig.communicator.notify('MessageReceived', data);
      when(withAnyInputs(testCase.ExpBehaviour.run), Invoke(cb))
      
      KbQueueCheck(-1, 'q');
      T = evalc('srv.expServer'); % Capture output
      
      % Test log
      testCase.verifyMatches(T, 'Aborting', 'Failed to log quit')
      
      % Test experiment interaction upon quit
      experiment = testCase.ExpBehaviour;
      expected = struct('Headless', true, 'IsLoggedIn', true);
      testCase.verifyThat([...
        experiment.AlyxInstance.setToValue(expected), ...
        experiment.quit(true)], Occurred('RespectingOrder', false))
      
      % Test end vs abort: change abort flag to false
      data.Data{2} = false;
      cb = @(varargin)testCase.Rig.communicator.notify('MessageReceived', data);
      when(withAnyInputs(testCase.ExpBehaviour.run), Invoke(cb))
      
      KbQueueCheck(-1, 'q');
      T = evalc('srv.expServer'); % Capture output
      
      % Test log
      testCase.verifyMatches(T, 'Ending', 'Failed to log quit')
      testCase.verifyCalled(testCase.ExpBehaviour.quit(false))
      
      %%% Test remote quit when idle %%%
      % Configure our communicator to spoof quit message
      id = num2str(randi(10000)); % An id for message verification
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        id, args, 'mockRig');
      
      KbQueueCheck(-1, 'q');
      T = evalc('srv.expServer'); % Capture output
      
      testCase.verifyMatches(T, 'no experiment is running', ...
        'Failed to log remote quit when idle')
    end
    
    function test_devices_fail(testCase)
      % Set hw.devices to return empty
      clear devices;
      id = 'Rigbox:srv:expServer:missingHardware';
      testCase.verifyError(@srv.expServer, id, ...
        'Expected error for misconfigured hardware');
    end
    
    function test_bgColour(testCase)
      % Test setting the background colour as an input arg and test making
      % the screen white.
      
      % Pick a random colour to set as out background
      colour = randi(255, 1, 3);
      
      % Assign output for 'White' property
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.stimWindow.White), 255)
      
      % Simulate a couple of key presses and run
      KbQueueCheck(-1, sequence({'b', 'q'}));
      srv.expServer(false, colour)
      
      % Filter for interactions
      f = @(type,name) @(a) contains(class(a), type) && strcmp(a.Name, name);
      % Retrieve mock history for the stimWindow
      history = testCase.getMockHistory(testCase.Rig.stimWindow);
      
      % Verify mock window interactions
      testCase.verifyEqual(length(history), 7, ...
        'Unexpected number of Window interactions')
      
      % Verify background colour set correctly
      propSet = fun.filter(f('Mod', 'BackgroundColour'), history);
      correctSet = numel(propSet) == 3 && ...
        isequal({propSet.Value}, {colour, 255, colour});
      testCase.verifyTrue(correctSet, 'Failed to correcly set background')
      
      % Verify flips
      methodCall = fun.filter(f('Call', 'flip'), history);
      testCase.verifyTrue(numel(methodCall) == 1, ...
        'Failed to flip buffer when changing background')
    end
    
    function test_valve_actions(testCase)
      % Test behaviour when various reward and water toggle keys are
      % pressed
      import matlab.mock.actions.AssignOutputs
      
      KbQueueCheck(-1, sequence({'space', 'w', 'w', 'q'}));
      
      % Assign output for 'DefaultCommand' property
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.RewardValveControl.DefaultCommand), 3)
      
      % Assign output for 'OpenValue' property
      high = 5; low = 0;
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.RewardValveControl.OpenValue), high)
      
      % Assign output for 'ClosedValue' property
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.RewardValveControl.ClosedValue), low)
      
      % Assign output for daqController 'Value' property
      when(get(testCase.RigBehaviours.daqController.Value), ...
        AssignOutputs(low).then(AssignOutputs(high)))
      
      % Clear history
      testCase.clearMockHistory(testCase.Rig.daqController)
      
      srv.expServer % Run the server
      
      % Find method calls and property modifications
      f = @(a) endsWith(class(a),{'Modification', 'Call'});
      % Retrieve mock history for the DaqControllor
      history = testCase.getMockHistory(testCase.Rig.daqController);
      
      % Find inputs to send method
      calls = fun.filter(f, history);
      testCase.assertEqual(length(calls), 3, ...
        'Failed to set output correct number of times')
      
      % First call should have been default value command
      expected = strcmp(calls(1).Name, 'command') && calls(1).Inputs{2} == 3;
      testCase.verifyTrue(expected, ...
        'Failed to send correct output on reward key press')
      
      % Second check the reward toggles
      expected = all(strcmp('Value', [calls(2:3).Name])) && ...
        isequal([calls(2:3).Value], [high low]);
      testCase.verifyTrue(expected, ...
        'Failed to correctly toggle water reward valve')
    end
    
    function test_reward_switch(testCase)
      import matlab.mock.actions.AssignOutputs
      
      % Create 'mock' reward controller as nonscalar struct (mock objects
      % can not be stored in heterogeneous arrays)
      s = @() struct(...
        'DefaultCommand', rand, ...
        'OpenValue', rand, ...
        'ClosedValue', rand);
      generators = [s() s()];
      
      % Assign output for 'ClosedValue' property
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.daqController.SignalGenerators), generators)
      
      % Assign output for daqController 'Value' property
      when(get(testCase.RigBehaviours.daqController.Value), ...
        AssignOutputs([generators.ClosedValue]). ...
        then(AssignOutputs([generators.OpenValue])). ...
        then(AssignOutputs([generators.ClosedValue])). ...
        then(AssignOutputs([generators.OpenValue])))
      
      % Clear history
      testCase.clearMockHistory(testCase.Rig.daqController)
      
      keys = sequence({'2', 'space', 'w', 'w', '1', 'space', 'w', 'w', 'q'});
      KbQueueCheck(-1, keys);
      srv.expServer % Run the server
      
      % Find method calls and property modifications
      f = @(a) endsWith(class(a),{'Modification', 'Call'});
      % Retrieve mock history for the DaqControllor
      history = testCase.getMockHistory(testCase.Rig.daqController);
      
      % Find inputs to send method
      calls = fun.filter(f, history);
      testCase.assertEqual(length(calls), 6, ...
        'Failed to set controller correct number of times')
      
      % First call should have been default value command with second
      % signal generator
      idx = [1,4]; % Order of command calls
      inputs = arrayfun(@(a)a.Inputs{2}, calls(idx)); % Get inputs
      expected = all(strcmp([calls(idx).Name], 'command')) && ...
        all(inputs == [generators([2,1]).DefaultCommand]);
      testCase.verifyTrue(expected, ...
        'Failed to send correct output on reward key press')
      
      % Second check the reward toggles
      idx = [2,3,5,6]; % Order of reward toggles
      
      % Index assigns are not recorded in any detail so this looks
      % confusing.
      values = [generators([1,2,1,2]).OpenValue ...
        repmat([generators(1).ClosedValue generators(2).OpenValue], 1, 2)];
      expected = all(strcmp('Value', [calls(idx).Name])) && ...
        isequal([calls(idx).Value], values);
      testCase.verifyTrue(expected, ...
        'Failed to correctly toggle water reward valve')
    end
    
    function test_timeline_override(testCase)
      % Test timeline overrride with toggle key and expServer input
      import matlab.mock.constraints.WasSet
      
      KbQueueCheck(-1, sequence({'t', 'q'})); % Toggle timeline then quit
      srv.expServer(false) % Call server
      testCase.verifyThat(testCase.RigBehaviours.timeline.UseTimeline, ...
        WasSet('ToValue', false), 'Failed to override timeline default')
      
      % Test clock access
      % Retrieve mock history for the sensor devices
      history = testCase.getMockHistory(testCase.Rig.mouseInput);
      correctlySet = ...
        numel(history) == 2 && ... % Clock set twice
        isa(history(1).Value, 'hw.ptb.Clock') && ... % First with ptb Clock
        isa(history(2).Value, 'hw.TimelineClock'); % Then TimelineClock
      testCase.verifyTrue(correctlySet, 'Failed to correctly set mouseInput clock')
      
      % We cannot test the same behaviour for the lickDetertor mock because
      % accesses or modifications of concrete superclass properties are not
      % recorded
      correctlySet = isa(testCase.Rig.lickDetector.Clock, 'hw.TimelineClock');
      testCase.verifyTrue(correctlySet, 'Failed to correctly set lickDetector clock')
    end
    
    function test_timeline(testCase)
      % Test behaviour when experiment run with timeline activated
      import matlab.mock.constraints.WasCalled
      ref = testCase.Ref;
            
      % Create a dummy experiment to inject
      exp.configureDummyExperiment([], [], testCase.Experiment);
      params.experimentFun = @(~,~)exp.configureDummyExperiment;
      
      % Save parameters for expServer to load
      savePath = dat.expFilePath(ref, 'parameters', 'master');
      superSave(savePath, struct('parameters', params))
      testCase.assertTrue(dat.expExists(ref), ...
        'Failed to save test parameters')
      
      % Configure our communicator to spoof run message
      id = num2str(randi(10000)); % An id for message verification
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        id, {'run', ref, 0, 0, []}, 'mockRig');
      
      % Simulate message arrival
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.communicator.IsMessageAvailable), true)
      
      % Clear history
      testCase.clearMockHistory(testCase.Rig.communicator)
      
      KbQueueCheck(-1, 'q'); % Simulate quit
      srv.expServer(true)
      
      % Filter for interactions
      f = @(type,name) @(a) contains(class(a), type) && strcmp(a.Name, name);
      % Retrieve mock history for the communicator
      history = testCase.getMockHistory(testCase.Rig.timeline);
      
      % Find access of UseInputs property
      useInputs = fun.filter(f('Mod', 'UseInputs'), history);
      % Verify that property was accessed once and that rotaryEncoder was
      % removed from list
      correct = numel(useInputs) == 1 && ~ismember('rotaryEncoder', useInputs.Value);
      testCase.verifyTrue(correct, 'Failed to correctly modify UseInputs')
      
      % Check that timeline was started and stopped correctly
      startCall = fun.filter(f('Call', 'start'), history);
      startedCorrectly = ... % Verify that start method was...
        numel(startCall) == 1 && ... % called only once
        strcmp(startCall.Inputs{2}, ref) && ... % with the correct expRef
        isa(startCall.Inputs{3}, 'Alyx'); % and Alyx instance
      testCase.verifyTrue(startedCorrectly, 'Failed to correctly start Timeline')
      
      % Verify stop method was called
      tl = testCase.RigBehaviours.timeline;
      testCase.verifyThat(withAnyInputs(tl.stop), WasCalled('WithCount', 1))
    end
    
    function test_alyx(testCase)
      % The following three things are tested:
      % 1. When Alyx is inactive (default for this test class), no warning
      % should occur
      % 2. When Alyx is active but not logged in, various warnings should
      % occur
      % 3. When Alyx is logged in, various things should be registered to
      % the database
      % 4. Test that Alyx-related errors are not fatal
      % 5. Test Alyx update when user logs in during experiment
      import matlab.mock.constraints.WasSet
      import matlab.mock.constraints.Occurred
      import matlab.mock.actions.Invoke
      
      %%% Test warning free %%%
      testCase.assertEmpty(getOr(dat.paths, 'databaseURL'), ...
        'Expected databaseURL field to be unset for this test')
      testCase.verifyWarningFree(@srv.expServer)
      
      %%% Test warnings while not logged in %%%
      % The following warnings should be thrown, we only test for the first
      %     - 'Alyx:HeadlessLoginFail'
      %     - 'Alyx:getData:InvalidToken'
      %     - 'Alyx:HeadlessLoginFail'
      %     - 'Alyx:getData:InvalidToken'
      %     - 'Alyx:HeadlessLoginFail'
      %     - 'Alyx:getData:InvalidToken'
      %     - 'Alyx:registerFile:UnableToValidate'
      %     - 'Alyx:flushQueue:NotConnected'
      
      % Set custom paths.  First add teardown to restore behaviour, then
      % delete paths file
      customPath = fullfile(getOr(dat.paths, 'rigConfig'), 'paths.mat');
      paths.databaseURL = [];
      testCase.addTeardown(@superSave, customPath, struct('paths', paths))
      % Remove custom paths
      delete(customPath)
      testCase.assertNotEmpty(getOr(dat.paths, 'databaseURL'), ...
        'Expected databaseURL field to be unset for this test')
      
      % Inject our our mock experiment via function call in srv.prepareExp
      exp.configureDummyExperiment([], [], testCase.Experiment);
      params.experimentFun = @(~,~)exp.configureDummyExperiment;
      
      % Save parameters for expServer to load
      savePath = dat.expFilePath(testCase.Ref, 'parameters', 'master');
      superSave(savePath, struct('parameters', params))
      testCase.assertTrue(dat.expExists(testCase.Ref), ...
        'Failed to save test parameters')

      % Configure our communicator to spoof run message
      id = num2str(randi(10000)); % An id for message verification
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        id, {'run', testCase.Ref, 0, 0, []}, 'mockRig');
      
      % Simulate message arrival
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.communicator.IsMessageAvailable), true)
      
      KbQueueCheck(-1, 'q');
      testCase.verifyWarning(@srv.expServer, 'Alyx:HeadlessLoginFail')

      %%% Test warnings while logged in %%%
      % First create a mock Alyx object
      [ai, behaviour] = createMock(testCase, ...
        'AddedProperties', properties(Alyx('',''))', ...
        'AddedMethods', methods(Alyx('',''))');
      
      % Simulate logged in
      testCase.assignOutputsWhen(get(behaviour.IsLoggedIn), true)
      
      % Add our mock to the run message
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        id, {'run', testCase.Ref, 0, 0, ai}, 'mockRig');
      
      KbQueueCheck(-1, 'q');
      srv.expServer(false) % run without timeline
      
      % We expect Alyx to be made headless, then a file to be registered:
      hwInfo = dat.expFilePath(testCase.Ref, 'hw-info', 'master', 'json');
      testCase.verifyThat([...
        behaviour.Headless.setToValue(true), ...
        behaviour.registerFile(hwInfo)], ...
        Occurred('RespectingOrder', true))
      
      %%% Test handling registration warnings %%%
      testCase.throwExceptionWhen(withAnyInputs(behaviour.registerFile), ...
        MException('Alyx:registerFile:Fail', 'Failed!'))
      KbQueueCheck(-1, 'q');
      testCase.verifyWarning(@()srv.expServer(false), 'Alyx:registerFile:Fail')
      
      %%% Test update request during experiment %%%
      % When the experiment is run, notify comm listeners of a new
      % Alyx instance.
      fakeAlyx = struct('Headless', false);
      data = io.MessageReceived(randi(1000), {'updateAlyxInstance', fakeAlyx}, 'mockRig');
      cb = @(varargin)testCase.Rig.communicator.notify('MessageReceived', data);
      when(withAnyInputs(testCase.ExpBehaviour.run), Invoke(cb))
      
      % Undo registerFile error for this section of the test
      testCase.assignOutputsWhen(...
        withAnyInputs(behaviour.registerFile), 201);
      
      % Clear histories
      testCase.clearMockHistory(testCase.Rig.communicator)
      testCase.clearMockHistory(testCase.Experiment)
      
      KbQueueCheck(-1, 'q');
      srv.expServer(false) % run without timeline
      
      % Check confirmation of receipt sent
      comm = testCase.RigBehaviours.communicator;
      testCase.verifyCalled(comm.send(data.Id, []), ...
        'Failed to confirm AlyxUpdate received')
      
      % Check AlyxInstance prop was set and instance was made headless
      expected = struct('Headless', true);
      testCase.verifyThat(...
        testCase.ExpBehaviour.AlyxInstance.setToValue(expected), ...
        Occurred('RespectingOrder', false))
    end
    
    function test_waterCalibration(testCase)
      % Test water calibration via calibrate key.  For a more in depth test
      % of the calibration function, see calibrate_test
      import matlab.mock.actions.AssignOutputs
      import matlab.mock.actions.Invoke
      import matlab.mock.constraints.Occurred
      
      % Check hardware file exists, if not create one
      hwPath = fullfile(getOr(dat.paths, 'rigConfig'), 'hardware.mat');
      if ~file.exists(hwPath)
        superSave(hwPath, struct)
      end
      
      % Simulate some properties of daqController
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.daqController.ChannelNames), {'rewardValve'})
      
      % Return a serial object when Port is accessed to pass checks
      testCase.assignOutputsWhen(... % ComPort
        get(testCase.RigBehaviours.scale.Port), serial('port'))
      when(withAnyInputs(testCase.RigBehaviours.scale.readGrams), ...
        AssignOutputs(0).then(AssignOutputs(1).then(AssignOutputs(2))))
      
      % Temporarily disable pause functionality
      oldState = pause('off');
      testCase.addTeardown(@pause, oldState)
      
      KbQueueCheck(-1, sequence({'m', 'q'})); % Sumulate key press sequence
      % We can't actually save mock objects but we can check for the
      % warning as validation that calibration would indeed we saved.
      testCase.verifyWarning(@srv.expServer, 'MATLAB:mock:classes:UnableToSave', ...
        'No attempt to save calibration detected')
      
      % Test scale interations
      scale = testCase.RigBehaviours.scale;
      testCase.verifyThat([...
        withAnyInputs(scale.init()), ...
        get(scale.Port), ...
        withAnyInputs(scale.readGrams()), ...
        withAnyInputs(scale.cleanup())], Occurred('RespectingOrder', false))
      
      % Test interactions with daqController
      controller = testCase.RigBehaviours.daqController;
      testCase.verifyCalled(withAnyInputs(controller.command), ...
        'Failed to deliver calibration rewards')
    end
    
    function test_gammaCalibration(testCase)
      % The expected behaviour is thus:
      %  1. access the ID from the daqController object
      %  2. call the stimWindow drawText method to prompt user
      %  3. call the stimWindow calibration method with this value
      %  4. assign the output to the stimWindow Calibrations property
      %  5. call the applyCalibrations method
      %  6. Save this modified object to file
      
      % Save a hardware file for expServer to load and modify
      hwPath = fullfile(getOr(dat.paths, 'rigConfig'), 'hardware.mat');
      stimWindow = hw.ptb.Window;
      save(hwPath, 'stimWindow')
      
      % Assign output for 'DaqIds' property
      id = 2;
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.daqController.DaqIds), id)
      % Assign output for 'calibration' method.  Normally a struct but we
      % don't actually care for this test.
      data = randi(10000);
      testCase.assignOutputsWhen(...
        withAnyInputs(testCase.RigBehaviours.stimWindow.calibration), data)
      % Allow setting of Calibration property
      testCase.returnStoredValueWhen(get(testCase.RigBehaviours.stimWindow.Calibration))
      
      % Temporarily disable pause functionality
      oldState = pause('off');
      testCase.addTeardown(@pause, oldState)
      
      % Mock sequence of key presses
      KbQueueCheck(-1, sequence({'g', 'q'}));
      srv.expServer
      
      % Filter for interactions
      f = @(type,name) @(a) contains(class(a), type) && strcmp(a.Name, name);
      % Retrieve mock history for the stimWindow
      history = testCase.getMockHistory(testCase.Rig.stimWindow);
      
      % Verify mock window interactions
      testCase.verifyEqual(length(history), 10, ...
        'Unexpected number of Window interactions')
      
      % Verify text prompt
      drawText = fun.filter(f('Call', 'drawText'), history);
      correctInput = numel(drawText) == 1 && ...
        contains(drawText.Inputs{2}, 'Please connect');
      testCase.verifyTrue(correctInput, 'Failed to draw text prompt to window')
      
      % Verify calibration
      methodCall = fun.filter(f('Call', 'calibration'), history);
      correctInput = numel(methodCall) == 1 && methodCall.Inputs{2} == id;
      testCase.verifyTrue(correctInput, ...
        'Failed to call calibration method with correct input')
      
      % Verify calibration set and applied
      propSet = fun.filter(f('Mod', 'Calibration'), history);
      correctSet = numel(propSet) == 1 && propSet.Value == data;
      testCase.verifyTrue(correctSet, 'Failed to correcly set Calibration')
      applied = ~isempty(fun.filter(f('Call', 'applyCalibration'), history));
      testCase.verifyTrue(applied, 'Failed to apply calibration')
      
      % Verify calibration saved
      stimWindow = pick(load(hwPath), 'stimWindow');
      testCase.verifyEqual(stimWindow.Calibration, data, ...
        'Failed to save the calibration to file')
    end
    
    function test_status(testCase)
      % Tests status requests when idle.  For testing status while an
      % experiment is running see test_run.  Also tests behaviour when
      % remote rig disconnects.
      
      % Simulate message received
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.communicator.IsMessageAvailable), true);
      % Simuluate message data
      id = num2str(randi(10000));
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        id, {'status'}, 'mockRig');
      
      KbQueueCheck(-1, 'q'); % Simulate quit
      srv.expServer % Call server
      
      % Verify correct status was sent
      testCase.verifyCalled(...
        testCase.RigBehaviours.communicator.send(id, {'idle'}), ...
        'Failed to return correct status')
      
      % Simulate remote host disconnect
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        'goodbye', [], 'mockRig');
      
      % Run server an capture output
      KbQueueCheck(-1, 'q'); % Simulate quit
      T = evalc('srv.expServer');
      testCase.verifyMatches(T, "'mockRig' disconnected", ...
        'Failed to log remote disconnect')
    end
    
    function test_run(testCase)
      % Test behaviour when running an experiment remotely and also
      % requesting a status during an experiment.
      ref = testCase.Ref;
      
      % Import some extra test modules
      import matlab.mock.actions.AssignOutputs
      import matlab.mock.actions.Invoke
      import matlab.mock.constraints.WasSet
      import matlab.mock.constraints.Occurred
      
      % When the experiment is run, notify comm listeners of a new
      % status request.
      data = io.MessageReceived(randi(1000), {'status'}, 'mockRig');
      cb = @(varargin)testCase.Rig.communicator.notify('MessageReceived', data);
      when(withAnyInputs(testCase.ExpBehaviour.run), Invoke(cb))
            
      % Inject our our mock via function call in srv.prepareExp
      exp.configureDummyExperiment([], [], testCase.Experiment);
      params.experimentFun = @(~,~)exp.configureDummyExperiment;
      
      % Save parameters for expServer to load
      savePath = dat.expFilePath(ref, 'parameters', 'master');
      superSave(savePath, struct('parameters', params))
      testCase.assertTrue(dat.expExists(ref), ...
        'Failed to save test parameters')
      
      % Configure our communicator to spoof run message
      id = num2str(randi(10000)); % An id for message verification
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        id, {'run', ref, 0, 0, []}, 'mockRig');
      
      % Simulate message arrival
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.communicator.IsMessageAvailable), true)
      
      % Now run expServer
      srv.expServer(false) % Override UseTimeline
      
      % We expect four messages sent:
      %  1. confirmation of 'run' receive
      %  2. 'starting' status
      %  3. 'status' response
      %  4. 'completed' status
      comm = testCase.RigBehaviours.communicator;
      testCase.verifyThat([...
        withExactInputs(comm.open()), ...
        get(comm.IsMessageAvailable), ...
        withExactInputs(comm.receive()), ...
        comm.send(id, []), ...
        comm.send('status', {'starting', ref}), ...
        comm.EventMode.setToValue(true), ...
        withAnyInputs(comm.notify), ...
        comm.send(data.Id, {'running', ref}), ...
        comm.EventMode.setToValue(false), ...
        comm.send('status', {'completed', ref, true}), ...
        withExactInputs(comm.close())], Occurred('RespectingOrder', false))
      
      % Check rig hardware saved
      hwInfo = dat.expFilePath(ref, 'hw-info', 'master', 'json');
      testCase.verifyTrue(file.exists(hwInfo), 'Failed to save hardware json')
      
      % As we ran without timeline, check object methods were not called
      tl = testCase.RigBehaviours.timeline;
      testCase.verifyNotCalled(withAnyInputs(tl.start))
      
      % Test handling of experiment object
      experiment = testCase.ExpBehaviour;
      testCase.verifyThat([...
        experiment.PreDelay.setToValue(0), ...
        experiment.PostDelay.setToValue(0), ...
        setToValue(experiment.Communicator,testCase.RigBehaviours.communicator), ...
        set(experiment.AlyxInstance), ...
        withAnyInputs(experiment.delete)], Occurred('RespectingOrder', false))
    end
    
    function test_run_fail(testCase)
      % Test behaviour when attempting to run experiment fails.  The
      % following three situations are tested:
      %  1. A request for a non-existant experiment
      %  2. An exception thrown during an experiment
      %  3. A request to run experiment while another is already active
      import matlab.mock.actions.Invoke
      import matlab.mock.actions.AssignOutputs
      ref = testCase.Ref;
      
      %%% 1. A request for a non-existant experimen %%%
      testCase.assertFalse(dat.expExists(ref), ...
        ['Test experiment should not yet exist. ' ...
        'Please manually check test paths and remove test subject data'])
      % Set mock communicator behaviour
      id = num2str(randi(10000));
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        id, {'run', ref, 0, 0, []}, 'mockRig');
      % Simulate message arrival
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.communicator.IsMessageAvailable), true)
      
      KbQueueCheck(-1, 'q'); % Simulate quit
      srv.expServer
      
      % Verify failure
      % Retrieve mock history for the communicator
      history = testCase.getMockHistory(testCase.Rig.communicator);
      % Find inputs to send method
      f = @(method) @(a) strcmp(a.Name, method);
      inputs = fun.filter(f('send'), history).Inputs;
      testCase.verifyMatches(inputs{2}, id, 'Failed to send correct id')
      testCase.verifyMatches(inputs{3}{1}, 'fail', 'Failed to send correct status')
      testCase.verifyMatches(inputs{3}{2}, ref, 'Failed to send correct exp ref')
      
      % Clear history
      testCase.clearMockHistory(testCase.Rig.communicator)
      
      %%% 2. An exception thrown during an experiment %%%
      % Configure experiment to throw exception
      exp.configureDummyExperiment([], [], testCase.Experiment);
      params.experimentFun = @(~,~)exp.configureDummyExperiment;
      exId = 'Rigbox:exp:Experiment'; exMsg = 'Error during experiment.';
      testCase.throwExceptionWhen(withAnyInputs(testCase.ExpBehaviour.run), ...
        MException(exId, exMsg));
      
      % Save parameters to file
      savePath = dat.expFilePath(ref, 'parameters', 'master');
      superSave(savePath, struct('parameters', params))
      testCase.assertTrue(dat.expExists(ref), ...
        'Failed to save test parameters')
      
      when(get(testCase.RigBehaviours.communicator.IsMessageAvailable), ...
        AssignOutputs(true).then(AssignOutputs(false)))
      
      KbQueueCheck(-1, 'q'); % Simulate quit
      testCase.verifyError(@()srv.expServer(false), exId, ...
        'Failed to throw expected error')
      
      % Retrieve mock history for the communicator
      history = testCase.getMockHistory(testCase.Rig.communicator);
      % Find inputs to send method
      calls = fun.filter(f('send'), history);
      inputs = calls(end).Inputs;
      
      % Test exception status
      testCase.verifyMatches(inputs{3}{1}, 'expException', ...
        'Failed to send correct status on exception')
      testCase.verifyMatches(inputs{3}{3}, exMsg, ...
        'Failed to send correct exception message')
      testCase.verifyFalse(isempty(fun.filter(f('close'), history)), ...
        'Failed to close communicator on exception')
      
      % Test window closed
      history = testCase.getMockHistory(testCase.Rig.stimWindow);
      closed = strcmp(history(end).Name, 'close');
      testCase.verifyTrue(closed, 'Failed to close window')
      
      % Clear history
      testCase.clearMockHistory(testCase.Rig.communicator)
      
      %%% 3. A request to run experiment while another is already active %%%
      % When the experiment is run, notify comm listeners of a new
      % experiment request.
      data = io.MessageReceived(randi(1000), {'run', ref, 0, 0, []}, 'mockRig');
      cb = @(varargin)testCase.Rig.communicator.notify('MessageReceived', data);
      when(withAnyInputs(testCase.ExpBehaviour.run), Invoke(cb))
      
      % Simulate message arrival
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.communicator.IsMessageAvailable), true)
      
      KbQueueCheck(-1, 'q'); % Simulate quit
      srv.expServer(false)
      
      % Retrieve mock history for the communicator
      history = testCase.getMockHistory(testCase.Rig.communicator);
      % Find inputs to send method
      calls = fun.filter(f('send'), history);
      % Find the call with our message id
      fail = calls(arrayfun(@(o)isequal(o.Inputs{2}, data.Id), calls));
      testCase.assertNotEmpty(fail, ...
        'failed to respond to run message in event mode')
      inputs = fail.Inputs;
      testCase.verifyMatches(inputs{3}{1}, 'fail', ...
        'Failed to send correct status id')
      testCase.verifyMatches(inputs{3}{3}, 'another experiment', ...
        'Failed to send correct fail message')
      
      testCase.verifyCalled(withAnyInputs(testCase.ExpBehaviour.delete), ...
        'Failed to cleanup experiment object')
    end
  end
  
end
