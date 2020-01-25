classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture(['..' filesep 'fixtures']),...
    matlab.unittest.fixtures.PathFixture(['..' filesep 'fixtures' filesep 'util'])})...
    bindMpepServer_test < matlab.unittest.TestCase & matlab.mock.TestCase
  
  properties (SetAccess = protected)
    % Timeline mock object
    Timeline
    % Timeline behaviour object
    Behaviour
    % An experiment reference for the test
    Ref
    % Default ports used by bindMpepServer
    Ports = [9999, 1001]
  end
  
  methods (TestClassSetup)
    function setTestFlag(testCase)
      % SETTESTFLAG Set test flag
      %  Sets global INTEST flag to true and adds teardown.  Also creates a
      %  dummy expRef for tests.
      %
      % TODO Make into shared fixture
      
      % Set INTEST flag
      assert(endsWith(which('dat.paths'),...
        fullfile('tests', 'fixtures', '+dat', 'paths.m')));
      setTestFlag(true);
      testCase.addTeardown(@setTestFlag, false)
      % Set test expRef
      testCase.Ref = dat.constructExpRef('test', now, 1);
    end
  end
  
  methods (TestMethodSetup)
    function setMockRig(testCase)
      % SETMOCKRIG Inject mock rig with shadowed hw.devices
      %   1. Create mock timeline
      %   2. Set the mock rig object to be returned on calls to hw.devices
      %   3. Add teardowns
      % 
      % See also mockRig, KbQueueCheck
      
      % Create fresh Timeline mock
      [testCase.Timeline, testCase.Behaviour] = createMock(testCase, ...
        'AddedProperties', properties(hw.Timeline)', ...
        'AddedMethods', methods(hw.Timeline)');

      % Inject our mock via calls to hw.devices
      rig.timeline = testCase.Timeline;
      hw.devices('testRig', false, rig);
      
      % Clear mock histories just to be safe
      testCase.addTeardown(@testCase.clearMockHistory, testCase.Timeline);
      testCase.addTeardown(@clear, 'KbQueueCheck', 'pnet', 'devices')
    end
  end
  
  methods (Test)
    function test_bindMpepListener(testCase)
      % Test binding of sockets and returning of tls object
      % NB Actually calls bindMpepServer
      port = randi(10000);
      [T, tls] = evalc(['tl.bindMpepServer(', num2str(port), ')']);
      % Check log
      testCase.verifyMatches(T, 'Bound UDP sockets', ...
        'failed to log socket bind')
      % Check returned fields
      expected = {'close'; 'process'; 'listen'; 'AlyxInstance'; 'tlObj'};
      testCase.verifyEqual(fieldnames(tls), expected, ...
        'Unexpected structure returned')
      % Check funciton handles
      actual = structfun(@(f)isa(f, 'function_handle'), tls);
      testCase.verifyEqual(actual, [true(3,1); false(2,1)])
      % Check Alyx instance and Timeline objects set
      testCase.verifyTrue(isa(tls.AlyxInstance, 'Alyx'), ...
        'Failed to create Alyx instance')
      testCase.verifyTrue(isequal(tls.tlObj, testCase.Timeline), ...
        'Failed to set Timeline')
      % Check socket opened on correct port
      history = pnet('gethistory');
      testCase.verifyEqual(history{1}, {'udpsocket', port}, ...
        'Failed to open socket on specified port')
    end
    
    function test_close(testCase)
      % Test the close callback
      tls = tl.bindMpepServer; %#ok<NASGU> % Return tls object
      ports = testCase.Ports; % Default ports opened
      arrayfun(@(s) pnet('setoutput', s, 'close', []), ports); % Set output
      T = evalc('tls.close()'); % Callback
      % Check log
      testCase.verifyMatches(T, 'Unbinding', 'failed to log close')
      % Check close called on each socket
      history = pnet('gethistory'); % Get pnet call history
      correct = cellfun(@(a) strcmp(a{2}, 'close'), history(end-1:end));
      testCase.verifyTrue(all(correct), 'Failed to close sockets')
    end
    
    function test_process(testCase)
      % Test process callback
      import matlab.unittest.constraints.IsOfClass
      import matlab.mock.constraints.Occurred
      [subject, series, seq] = dat.parseExpRef(testCase.Ref);
      
      tls = tl.bindMpepServer; % Return tls object
      ports = testCase.Ports; % Default ports opened
      arrayfun(@(s) pnet('setoutput', s, 'readpacket', 1000), ports); % Set output
      pnet('setoutput', ports(2), 'gethost', {randi(99,1,4), 88}); % Set output
      
      % Set messages
      % Stringify Alyx instance
      ai = Alyx.parseAlyxInstance(testCase.Ref, Alyx('user',''));
      % Function for constructing message strings
      str = @(cmd) sprintf('%s %s %s %d %s', cmd, subject, ...
        datestr(series, 'yyyymmdd'), seq, iff(strcmp(cmd,'alyx'),ai,'')); 
      % Set behaviour for IsRunning method to pass IsRunning assert
      testCase.assignOutputsWhen(get(testCase.Behaviour.IsRunning), false)
      % Commands
      cmd = {'alyx', 'expstart', 'expend', 'expinterupt'};
      % Set output for 'read'
      pnet('setoutput', ports(2), 'read', sequence(mapToCell(str, cmd)));
      % Trigger reads
      arrayfun(@(~) tls.process(), 1:length(cmd))
      
      % Test Timeline interactions
      timeline = testCase.Behaviour;
      testCase.verifyThat([...
        timeline.start(testCase.Ref, IsOfClass(?Alyx)),... % expstart
        withAnyInputs(timeline.record), ... % "
        withAnyInputs(timeline.stop), ... % expstop 
        withAnyInputs(timeline.stop)], ... % expinterupt
        Occurred('RespectingOrder', true))
      
      % Retrieve mock history for Timeline
      history = testCase.getMockHistory(testCase.Timeline);
      % Find inputs to start method
      f = @(method) @(a) strcmp(a.Name, method);
      actual = fun.filter(f('start'), history).Inputs{end};
      % Check AlyxInstance updated with the one we passed in above
      testCase.verifyEqual(actual.User, 'user', 'Failed to update AlyxInstance')
      
      % Get pnet history
      history = pnet('gethistory');
      % Calls to write should equal the number of messages read
      writeCalls = cellfun(@(C) strcmp(C{2}, 'write'), history);
      testCase.verifyEqual(sum(writeCalls), length(cmd), 'Failed echo messages')
      
      % Test process fails
      testCase.throwExceptionWhen(withAnyInputs(timeline.start), ...
        MException('Timeline:error', 'Error during experiment.'));
      % Clear pnet history
      pnet('clearhistory');
      % Set output for 'read'
      pnet('setoutput', ports(2), 'read', str('expstart'));
      % Trigger pnet read; use evalc to supress output
      evalc('tls.process()');
      % Set Timeline as already running and check for error
      testCase.assignOutputsWhen(get(testCase.Behaviour.IsRunning), true)
      evalc('tls.process()');
      
      % Check message not echoed after error
      history = pnet('gethistory');
      % Calls to write should equal the number of messages read
      writeCalls = cellfun(@(C) strcmp(C{2}, 'write'), history);
      testCase.verifyFalse(any(writeCalls), 'Unexpected message echo')
    end
    
    function test_listen(testCase)
      % TODO Add test for listen function of bindMpepServer
    end
  end
  
end