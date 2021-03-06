classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('../../fixtures'),...
    matlab.unittest.fixtures.PathFixture(['../../fixtures' filesep 'util'])})... 
    update_test < matlab.unittest.TestCase
  %UPDATE_TEST contains unit tests for `git.update`
  
  properties
    % A char array for Rigbox's `.git` folder.
    GitDir = fullfile(fileparts(which('addRigboxPaths')), '.git');
  end
  
  properties (MethodSetupParameter)
    % A boolean flag for whether remote repo code recently fetched,
    % i.e. the code is already updated
    fetched = {false, true}
  end
  
  properties (TestParameter)
    % Day that update is scheduled for `git.update`.
    scheduled = {'never', 'everyday', 'today', 'tomorrow'}
  end
  
  properties (Access = protected)
    % A map storing weekday number corresponding to scheduled day
    Weekday
  end
  
  methods (TestClassSetup)
    function setScheduled(testCase)
      % Sets `Weekday` to a number in the interval [0,7] where -1 = never,
      % 0 = everyday; 1-7 = Monday-Friday
      values = {-1, 0, weekday(now), mod(weekday(now),7)+1};
      testCase.Weekday = containers.Map(testCase.scheduled, values);
      
      % If a `FETCH_HEAD` file doesn't exist in `.git` (e.g. on new
      % install), create one.
      if ~exist(fullfile(testCase.GitDir, 'FETCH_HEAD'), 'file')
        touchHEAD = ['type nul > ', testCase.GitDir, filesep, 'FETCH_HEAD'];
        errCode = builtin('system', touchHEAD);
        assert(~errCode, 'No FETCH_HEAD file found and failed to create one')
      end
    end
  end
  
  methods (TestMethodSetup)
    function setMocks(testCase, fetched)
      % SETMOCKS Map some outputs for calls to functions used by update
      %  Using these mocks we can simulate the result of system commands
      %  without actually pulling and updating the code.
      TF = setTestFlag(true); % Suppress out-of-test warnings
      % Clear up on teardown
      testCase.addTeardown(@setTestFlag, TF)
      testCase.applyFixture(ClearTestCache)
      
      % Set the date we want returned by modDate for the FETCH_HEAD file
      fetchFile = fullfile(testCase.GitDir, 'FETCH_HEAD');
      t = iff(fetched, now, now-2);
      file.modDate(fetchFile, t); % Set date to recent or 2 days ago
      
      % Set the system command output
      system('*', {0, ''}); % Set all commands to return success
    end
  end
  
  methods (Test)    
    function testNumericalInputs(testCase, scheduled, fetched)
      % Tests various input args for `git.update`.  If fetched == true,
      % function should recognize that code already updated.
      diffDay = any(strcmp(scheduled, {'tomorrow', 'never'}));
      input = testCase.Weekday(scheduled); % Get day code
      exitCode = git.update(input); % Run update
      % Test result
      expected = iff(fetched || diffDay, exitCode == 2, exitCode == 0); 
      failMsg = iff(fetched, 'Code pulled', 'Code not pulled');
      testCase.assertTrue(expected, failMsg)
    end    
    
    function testArrayInputs(testCase, fetched)
      % Tests various array inputs for `git.update`.
      [n, D] = arrayfun(@weekday, [now; now+1], 'uni', 0);
      exitCode = git.update(D); % Run update with cellstr input
      % Test result
      expected = iff(fetched, exitCode == 2, exitCode == 0); 
      failMsg = iff(fetched, 'Code pulled', 'Code not pulled');
      testCase.assertTrue(expected, failMsg)
      
      % Run update with numerical array input
      exitCode = git.update(cell2mat(n));
      expected = iff(fetched, exitCode == 2, exitCode == 0); 
      testCase.assertTrue(expected, failMsg)
      
      % Now test with a different day string input
      [~, D] = mapToCell(@(x) weekday(x, 'long'), [now+1; now+2]);
      exitCode = git.update(string(D)); % Run update with string
      testCase.assertTrue(exitCode == 2, 'Code pulled')
    end
    
    function testInvalidInputs(testCase)
      % Tests for expected error messages on invalid input arg
      errId = 'Rigbox:git:update:valueError';
      testCase.verifyError(@()git.update(9), errId)
      testCase.verifyError(@()git.update('Pankday'), errId)
    end
  end
end