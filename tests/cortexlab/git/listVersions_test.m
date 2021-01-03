classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('../../fixtures'),...
    matlab.unittest.fixtures.PathFixture(['../../fixtures' filesep 'util'])})... 
    listVersions_test < matlab.unittest.TestCase
  %LISTVERSIONS_TEST contains unit tests for git.listVersions
  
  properties
    % A char array for non git directory
    repoDir = 'C:/'
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
    function test_listVersions(testCase)
      % Test expected output: cell array of tags, trimmed
      out = git.listVersions;
      testCase.verifyEqual(out, testCase.Tags, 'Failed to return tag list')
      
      % Test empty tag list
      system('*', {0, ''}); % Set all commands to return success
      out = git.listVersions;
      testCase.verifyEqual(out, {''}, 'Failed to return empty tag list')
      
      % Test using different dir
      testCase.assertEmpty(dir([testCase.repoDir '*.git']), ...
        'Non-git repoDir required for this test')
      clear('system') % clear mock
      % Temporarily supress warning as we call the real system function
      warnId = 'Rigbox:tests:system:outputNotSet';
      old = warning('off', warnId);
      testCase.addTeardown(@warning, old)
      fcn = @() git.listVersions(testCase.repoDir);
      testCase.verifyError(fcn, 'Rigbox:git:listVersions:failedForRepo')
      
      % Test echo off
      T = evalc('git.listVersions([], false);');
      testCase.verifyEmpty(T, 'Failed to turn off echo')
      % Test echo on
      [T, out] = evalc('git.listVersions;');
      testCase.assertNotEmpty(out, 'can''t check echo; command returned empty')
      testCase.verifyNotEmpty(T, 'failed to print to command window')
    end    
    
  end
end