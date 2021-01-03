classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('../../fixtures')})... 
    switchVersion_test < GitTestCase
  %SWITCHVERSION_TEST contains unit tests for git.switchVersion
    
  properties (Access = protected)
    % Tags list for testing system command parse
    Tags = {'2.0', '2.1', '2.3.1', '2.4.0', 'v2.0', 'v2.2.1'}
  end

  methods (TestMethodSetup)
    function setupMock(testCase)
      % setupMock Map some outputs for calls to functions used by function
      %  Using these mocks we can simulate the result of system commands to
      %  control the output
      % Set the system command output
      out = [strjoin(testCase.Tags, '\n') newline];
      system('*', {0, out}); % Set all commands to return success
    end
  end
  
  methods (Test)    
    function testInputs(testCase)
      % Currently we can only safely test by reading the command output
      
      V = ["2.4.0", "2.2", "2"];
      for v = V
        T = evalc(sprintf('git.switchVersion("%s");', v));
        testCase.verifyMatches(T, join(['Updating to version', v]), ...
        'Unexpected version')
      end
      
      % Test numerical input
      T = evalc('git.switchVersion(2.1);');
      testCase.verifyMatches(T, 'Updating to version 2.1.0.', ...
        'failed for numerical inputs')
      
      % Test no matching version
      testCase.verifyError(@() git.switchVersion('2.5'), ...
        'Rigbox:git:switchVersion:versionUnknown')
      
      % Test 'previous' flag
      T = evalc('git.switchVersion(''prev'');');
      testCase.verifyMatches(T, 'Updating to version 2.4.0', ...
        'failed for numerical inputs')
      
      % Test 'lastest' flag
      testCase.verifyWarningFree(@() git.switchVersion('latest')); % git pull expected
      
      % Verify error on update to latest
      in = sprintf('"%s" checkout origin/master', strtrim(testCase.GitEXE));
      system(in, {1, 'fail'}); % Update to latest fails
      testCase.verifyError(@() git.switchVersion('latest'), ...
        'Rigbox:git:switchVersion:failedToUpdate')
      
      % Verify unknown version warning
      in = sprintf('"%s" describe --tags', strtrim(testCase.GitEXE));
      system(in, {1, ''}); % Update to latest fails
      testCase.verifyWarning(@() git.switchVersion('prev'), ...
        'Rigbox:git:switchVersion:versionUnknown')
    end
    
  end
end