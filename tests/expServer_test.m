classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})...
    expServer_test < matlab.unittest.TestCase & matlab.mock.TestCase
  % TODO Test Timeline start and stop
  % TODO Test water calibration 
  % TODO Test gamma calibration 
  % TODO Test quit via message
  % TODO Test whitescreen
  % TODO Verify Alyx warnings 
  
  properties
    Rig
    RigBehaviours
  end
  
  methods (TestClassSetup)
    function setupFolder(testCase)
      % Check paths file
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
      
      % Alyx queue location
      qDir = getOr(dat.paths, 'localAlyxQueue');
      
      addTeardown(testCase, @clearCBToolsCache)
      addTeardown(testCase, @rmdir, mainRepo, 's')
      addTeardown(testCase, @rmdir, qDir, 's')
    end
    
    function setupMock(testCase)
      testCase.setTestFlag(true)
      
      root = getOr(dat.paths, 'rigbox'); % Rigbox root directory
      fetch_head = fullfile(root, '.git', 'FETCH_HEAD');
      file.modDate(fetch_head, now);
      
      [testCase.Rig, testCase.RigBehaviours] = mockRig(testCase);
      testCase.addTeardown(@testCase.setTestFlag, false)
      testCase.addTeardown(@clear, 'configureDummyExperiment')
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
      
      % Find inputs to send method
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
    
    function test_timeline(testCase)
      %       testCase.Rig.timeline.UseTimeline = true;
      % TODO Test cleanup
      import matlab.mock.constraints.WasSet
      KbQueueCheck(-1, sequence({'t','q'})); % Toggle timeline then quit
      srv.expServer(false);
      testCase.verifyThat(testCase.RigBehaviours.timeline.UseTimeline, ...
        WasSet('ToValue',false), 'Failed to override timeline default')
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
      testCase.verifyCalled(...
        testCase.RigBehaviours.communicator.send(id, {'idle'}), ...
        'Failed to return correct status')
    end
    
    function test_run(testCase)
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
      testCase.verifyFalse(isempty(fun.filter(f('close'), history)), ...
        'Failed to close communicator on quit') % TODO Reserve for exception
      
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
      global INTEST
      INTEST = TF;
    end
  end
end
