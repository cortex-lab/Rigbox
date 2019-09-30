classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})... 
    expServer_test < matlab.unittest.TestCase & matlab.mock.TestCase
  
  properties
    % Figure visibility setting before running tests
    FigureVisibleDefault
    Rig
    RigBehaviours
  end
    
  methods (TestClassSetup)
    function killFigures(testCase)
      testCase.FigureVisibleDefault = get(0,'DefaultFigureVisible');
      set(0,'DefaultFigureVisible','off');
    end
    
    function setupMock(testCase)
      testCase.setTestFlag(true)

      root = getOr(dat.paths, 'rigbox'); % Rigbox root directory
      fetch_head = fullfile(root, '.git', 'FETCH_HEAD');
      file.modDate(fetch_head, now);
      
      [testCase.Rig, testCase.RigBehaviours] = mockRig(testCase);
      testCase.addTeardown(@testCase.setTestFlag, false)
    end
  end
  
  methods (TestClassTeardown)
    function restoreFigures(testCase)
      set(0,'DefaultFigureVisible',testCase.FigureVisibleDefault);
    end
  end
  
  methods (TestMethodSetup)
    function setMockRig(testCase)
       hw.devices('testRig', false, testCase.Rig);
    end
  end
  
  methods (Test)
    function test_quit(testCase)
      % TODO Test cleanup
      KbQueueCheck(-1, 'q');
      srv.expServer;
      testCase.verifyCalled(...
        testCase.RigBehaviours.communicator.close, ...
        'Failed to close communicator on exit')
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
      import matlab.mock.actions.AssignOutputs
      % Simulate message received
      when(get(testCase.RigBehaviours.communicator.IsMessageAvailable), ...
        AssignOutputs(true).then(AssignOutputs(false)))
      % Simuluate message data
      id = num2str(randi(10000));
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        id, {'status'}, 'mockRig');
      KbQueueCheck(-1, 'q'); % Simulate quit
      srv.expServer;
      testCase.verifyCalled(...
        testCase.RigBehaviours.communicator.send(id,{'fail', ref}), ...
        'Failed to return correct status')
    end
    
    function test_run(testCase)
      import matlab.mock.actions.AssignOutputs
      import matlab.mock.constraints.WasCalled
      
      % 
      ref = dat.constructExpRef('test', now, 1);
      testCase.assertFalse(dat.expExists(ref), ...
        ['Test experiment should not yet exist. ' ...
        'Please manually check test paths and remove test subject data'])
      % Set up mock experiment
      [experiment, behaviour] = createMock(testCase, ...
        'AddedProperties', properties(exp.Experiment)', ...
        'AddedMethods', methods(exp.Experiment)');
      params.experimentFun = @(~,~)experiment;
      savePath = dat.expFilePath(ref, 'parameters', 'master');
      % save(savePath, struct('parameters', params)) % TODO
      % Set mock communicator behaviour
      id = num2str(randi(10000));
      testCase.assignOutputsWhen(...
        withExactInputs(testCase.RigBehaviours.communicator.receive), ...
        id, {'run', ref, 0, 0, []}, 'mockRig');
      % Simulate message arrival
%       when(get(testCase.RigBehaviours.communicator.IsMessageAvailable), ...
%         AssignOutputs(true).then(AssignOutputs(true)))
      testCase.assignOutputsWhen(...
        get(testCase.RigBehaviours.communicator.IsMessageAvailable), true)
      
      KbQueueCheck(-1, 'q'); % Simulate quit
      srv.expServer;

      
      % Verify failure
      % Retrieve mock history for the DaqControllor
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
      % TODO Create experiment and test run
    end
  end
  
  methods (Static)
    function setTestFlag(TF)
      global INTEST
      INTEST = TF;
    end
  end
end
