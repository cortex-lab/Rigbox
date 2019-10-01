classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})...
    expServer_test < matlab.unittest.TestCase & matlab.mock.TestCase
  % TODO Test Timeline start and stop
  % TODO Test water calibration 
  % TODO Test quit via message
  % TODO Verify Alyx warnings 
  
  properties
    % Structure of rig device mock objects
    Rig
    % Structure of mock behavior objects
    RigBehaviours
  end
  
  methods (TestClassSetup)
    function setupFolder(testCase)
      % SETUPFOLDER Set up subject, queue and config folders for test
      %  Creates a few folders for saving parameters and hardware.  Adds
      %  teardowns for deletion of these folders.
      % 
      % TODO Make into shared fixture
      
      assert(endsWith(which('dat.paths'),...
        fullfile('tests', 'fixtures', '+dat', 'paths.m')));
      
      % Check temp mainRepo folder is empty.  An extra safe measure as we
      % don't won't to delete important folders by accident!
      mainRepo = dat.reposPath('main', 'master');
      assert(~exist(mainRepo, 'dir') || isempty(file.list(mainRepo)),...
        'Test experiment repo not empty.  Please set another path or manually empty folder');
      
      % Now create a single subject folder
      assert(mkdir(fullfile(mainRepo, 'test')), ...
        'Failed to create subject folder')
      
      % Create a rig config folder
      configDir = getOr(dat.paths, 'rigConfig');
      assert(mkdir(configDir), 'Failed to create config directory')
      
      % Alyx queue location
      qDir = getOr(dat.paths, 'localAlyxQueue');
      assert(mkdir(qDir), 'Failed to create alyx queue')
      
      addTeardown(testCase, @clearCBToolsCache)
      
      % Add teardown to remove folders
      testFolders = {mainRepo; qDir; getOr(dat.paths, 'globalConfig')};
      rmFcn = @(repo)assert(rmdir(repo, 's'), 'Failed to remove test repo %s', repo);
      addTeardown(testCase, @cellfun, rmFcn, testFolders)
    end
    
    function setupMock(testCase)
      % SETUPMOCK Create mock rig objects and avoid git update
      %  1. Sets global INTEST flag to true and adds teardown
      %  2. Creates mock rig device objects
      %  3. Ensure git update doesn't pull code
      %
      % See also MOCKRIG
      
      % Set INTEST flag to true
      testCase.setTestFlag(true)
      testCase.addTeardown(@testCase.setTestFlag, false)
      
      % Make sure git update not triggered
      root = getOr(dat.paths, 'rigbox'); % Rigbox root directory
      fetch_head = fullfile(root, '.git', 'FETCH_HEAD');
      file.modDate(fetch_head, now); % Set recent fetch
      
      % Create mock devices and clear functions on teardown
      [testCase.Rig, testCase.RigBehaviours] = mockRig(testCase);
      testCase.addTeardown(@clear, 'configureDummyExperiment', 'INTEST', 'devices')
    end
  end
  
  methods (TestMethodSetup)
    function setMockRig(testCase)
      hw.devices('testRig', false, testCase.Rig);
      clearHistory = @(mock) testCase.clearMockHistory(mock);
      structfun(@(mock) testCase.addTeardown(clearHistory, mock), testCase.Rig);
    end
  end
  
  methods (Test)
    function test_quit(testCase)
      % TODO Test cleanup
      KbQueueCheck(-1, 'q');
      srv.expServer;
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
    end
    
    function test_devices_fail(testCase)
      % Set hw.devices to return empty
      clear devices;
      id = 'rigbox:srv:expServer:missingHardware';
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
      srv.expServer(false, colour);
      
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

      srv.expServer; % Run the server
      
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
      srv.expServer; % Run the server
      
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
    
    function test_timeline(testCase)
      %       testCase.Rig.timeline.UseTimeline = true;
      % TODO Test cleanup
      import matlab.mock.constraints.WasSet
      KbQueueCheck(-1, sequence({'t','q'})); % Toggle timeline then quit
      srv.expServer(false);
      testCase.verifyThat(testCase.RigBehaviours.timeline.UseTimeline, ...
        WasSet('ToValue',false), 'Failed to override timeline default')
    end
    
    function test_gammaCalibration(testCase)
      % The expected behaviour is thus:
      %  1. access the ID from the daqController object
      %  2. call the stimWindow drawText method to prompt user
      %  3. call the stimWindow calibration method with this value
      %  4. assign the output to the stimWindow Calibrations property
      %  5. call the applyCalibrations method
      %  6. Save this modified object to file

      % Check hardware file exists, if not create one
      hwPath = fullfile(getOr(dat.paths, 'rigConfig'), 'hardware.mat');
      stimWindow = hw.ptb.Window;
      if ~file.exists(hwPath)
        save(hwPath, 'stimWindow')
      end
      
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
      srv.expServer;
      
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
      % experiment is running see test_run
      
      % Simulate message received
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.communicator.IsMessageAvailable), true);
      % Simuluate message data
      id = num2str(randi(10000));
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        id, {'status'}, 'mockRig');
      
      KbQueueCheck(-1, 'q'); % Simulate quit
      srv.expServer;
      
      % Verify correct status was sent
      testCase.verifyCalled(...
        testCase.RigBehaviours.communicator.send(id, {'idle'}), ...
        'Failed to return correct status')
    end
    
    function test_run(testCase)
      % Test behaviour when running an experiment remotely and also
      % requesting a status during an experiment.
      
      % Import some extra test modules
      import matlab.mock.actions.AssignOutputs
      import matlab.mock.actions.Invoke
      
      % First set up a valid experiment (i.e. save some parameters to load)
      % NB: Ref must be different to other tests
      ref = dat.constructExpRef('test', now-1, randi(10000));
      
      % Set up mock experiment
      % Create a duck typed experiment mock
      [experiment, behaviour] = createMock(testCase, ...
        'AddedProperties', properties(exp.Experiment)', ...
        'AddedMethods', methods(exp.Experiment)');
      
      % Add outputs for properties accessed by expServer, namely the
      % endStatus of the experiment
      testCase.assignOutputsWhen(...
        get(behaviour.Data), struct('endStatus', 'aborted'))
      
      % When the experiment is run, notify comm listeners of a new
      % status request.
      data = io.MessageReceived(randi(1000), {'status'}, 'mockRig');
      cb = @(varargin)testCase.Rig.communicator.notify('MessageReceived', data);
      when(withAnyInputs(behaviour.run), Invoke(cb))
      
      % Add outputs for properties accessed by expServer, namely the
      % endStatus of the experiment
      testCase.assignOutputsWhen(...
        get(behaviour.Data), struct('endStatus', 'aborted', 'expRef', ref))
      
      % Inject our our mock via function call in srv.prepareExp
      exp.configureDummyExperiment([], [], experiment);
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
      KbQueueCheck(-1, 'q'); % Ensure we quit expServer after starting experiment
      srv.expServer(false); % Override UseTimeline
      
      % Find inputs to send method
      f = @(method) @(a) strcmp(a.Name, method);
      % Retrieve mock history for the DaqControllor
      history = testCase.getMockHistory(testCase.Rig.communicator);
      % Find inputs to send method
      calls = {fun.filter(f('send'), history).Inputs};
      
      % We expect three messages sent:
      %  1. confirmation of 'run' receive
      %  2. 'starting' status
      %  3. 'status' response
      %  4. 'completed' status
      testCase.assertEqual(length(calls), 4, ...
        'Unexpected number of calls to communicator send method')
      % Check the confirmation id
      testCase.verifyMatches(calls{1}{2}, id, ...
        'Failed to send correct id on exchange')
      testCase.verifyMatches(calls{2}{3}{1}, 'starting', ...
        'Failed to send correct status on starting')
      % Test status update during experiment
      testCase.verifyEqual(calls{3}{2}, data.Id, ...
        'Failed to respond to status request with correct id')
      testCase.verifyEqual(calls{3}{3}{1}, 'running', ...
        'Failed to respond to status request with status')
      % Test completed status
      testCase.verifyMatches(calls{4}{3}{1}, 'completed', ...
        'Failed to send correct status on exception')
      testCase.verifyTrue(calls{4}{3}{3}, 'Failed to report correct end status')
      % Check correct ref was sent
      allEqual = isequal(calls{2}{3}{2}, calls{4}{3}{2}, calls{3}{3}{2}, ref);
      testCase.verifyTrue(allEqual, 'Failed to send correct experiment reference')
      
      % Check event mode was set correctly
      evtModeCalls = fun.filter(f('EventMode'), history);
      modClass = 'matlab.mock.history.SuccessfulPropertyModification';
      states = arrayfun(@(o)o.Value, ...
        evtModeCalls(arrayfun(@(o)isa(o, modClass), evtModeCalls)));
      testCase.verifyTrue(isequal(states, [0 1 0]), ...
        'Failed to correctly set event mode before and after experiment')
    end
    
    function test_run_fail(testCase)
      % Test behaviour when attempting to run experiment fails.  The
      % following three situations are tested:
      %  1. A request for a non-existant experiment
      %  2. An exception thrown during an experiment
      %  3. A request to run experiment while another is already active
      import matlab.mock.actions.Invoke
      import matlab.mock.actions.AssignOutputs
      import matlab.mock.constraints.WasCalled
      
      %%% 1. A request for a non-existant experimen %%%
      ref = dat.constructExpRef('test', now, 1);
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
      srv.expServer;
      
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
      % Set up mock experiment
      [experiment, behaviour] = createMock(testCase, ...
        'AddedProperties', properties(exp.Experiment)', ...
        'AddedMethods', methods(exp.Experiment)');
      exp.configureDummyExperiment([],[],experiment);
      params.experimentFun = @(~,~)exp.configureDummyExperiment;
      exId = 'Rigbox:exp:Experiment'; exMsg = 'Error during experiment.';
      testCase.throwExceptionWhen(withAnyInputs(behaviour.run), ...
        MException(exId, exMsg));
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
      when(withAnyInputs(behaviour.run), Invoke(cb))
      % Add outputs for properties accessed by expServer, namely the
      % endStatus of the experiment
      testCase.assignOutputsWhen(...
        get(behaviour.Data), struct('endStatus', 'aborted', 'expRef', ref))
      
      % Simulate message arrival
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.communicator.IsMessageAvailable), true)
      
      KbQueueCheck(-1, 'q'); % Simulate quit
      srv.expServer(false);
      
      % Retrieve mock history for the communicator
      history = testCase.getMockHistory(testCase.Rig.communicator);
      % Find inputs to send method
      calls = fun.filter(f('send'), history);
      % Find the call with our message id
      fail = calls(arrayfun(@(o)isequal(o.Inputs{2}, data.Id), calls));
      testCase.assertTrue(~isempty(fail), ...
        'failed to respond to run message in event mode')
      inputs = fail.Inputs;
      testCase.verifyMatches(inputs{3}{1}, 'fail', ...
        'Failed to send correct status id')
      testCase.verifyMatches(inputs{3}{3}, 'another experiment', ...
        'Failed to send correct fail message')
    end
  end
  
  methods (Static)
    function setTestFlag(TF)
      % SETTESTFLAG Set global INTEST flag
      %   Allows setting of test flag via callback function
      global INTEST
      INTEST = TF;
    end
  end
end
