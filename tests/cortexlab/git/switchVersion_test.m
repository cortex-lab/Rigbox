classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('../../fixtures'),...
    matlab.unittest.fixtures.PathFixture(['../../fixtures' filesep 'util'])})... 
    switchVersion_test < matlab.unittest.TestCase
  %SWITCHVERSION_TEST contains unit tests for git.switchVersion
  
  properties
    % A char array for non-git directory
    Badrepo = 'C:/'
  end
  
  properties (Access = protected)
    % Tags list for testing system command parse
    Tags = {'2.0', '2.1', '2.3.1', '2.4.0', 'v2.0', 'v2.2.1'}
  end
    
  methods (TestMethodSetup)
    function setMocks(testCase)
      % SETMOCKS Map some outputs for calls to functions used by function
      %  Using these mocks we can simulate the result of system commands to
      %  control the output
      TF = setTestFlag(true); % Suppress out-of-test warnings
      % Clear up on teardown
      testCase.addTeardown(@setTestFlag, TF)
      testCase.applyFixture(ClearTestCache)
      % Set the system command output
      out = [strjoin(testCase.Tags, '\n') newline];
      system('*', {0, out}); % Set all commands to return success
    end
  end
  
  methods (Test)    
    function testInputs(testCase)
      % TODO Finish tests
      
      % Test numerical in
      git.switchVersion(2.1) % 2.1 expected
      git.switchVersion('2.4.0') % 2.4.0 expected
      git.switchVersion('2.2') % 2.2.1 expected
      git.switchVersion('2') % 2.4.0 expected
      git.switchVersion('2.5') % error expected
      git.switchVersion('prev') % 2.4.0 expected
      git.switchVersion('latest') % git pull expected
    end
    
  end
end