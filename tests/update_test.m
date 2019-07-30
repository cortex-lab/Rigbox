classdef Update_test < matlab.unittest.TestCase
  %UPDATE_TEST contains unit tests for `git.update`
  
  properties
    % A char array for a mock `FETCH_HEAD` file, so we don't manipulate the
    % repo's actual `FETCH_HEAD`.
    FetchHeadFake = fullfile(fileparts(which('addRigboxPaths')),...
                     'tests/fixtures/git/FETCH_HEAD_FAKE')
    % A char array for Rigbox's `.git` folder
    GitDir = fullfile(fileparts(which('addRigboxPaths')), '/.git/');
    % A number in the interval [1,7] representing a day that is different
    % from that returned `weekday(today)`
    DiffDay
  end
  
  properties (TestParameter)
    % Different values for the input arg to `git.update`
    Scheduled = {0, [], 'char', 'DiffDay'}
    % A boolean flag for whether or not to fetch the remote repo code.
    FetchFlag = {false, true}
  end
  
  methods (TestClassSetup)
    function setDiffDay(testCase)
      % Sets `DiffDay` to a number in the interval [1,7] based on `today`
      curDay = weekday(today);
      testCase.DiffDay = iff(curDay == 7, 6, curDay + 1);
    end
  end
  
  methods (TestMethodSetup)
    function getMockFiles(testCase)
      % Gets `FetchHeadFake` file so we don't corrupt actual `FETCH_HEAD`
      
      gitDir = testCase.GitDir;
      fetchHead = fullfile(gitDir, 'FETCH_HEAD');
      fetchHeadFake = testCase.FetchHeadFake;
      % Copy `fetchHeadFake` to `.git/`.
      system(['copy ', fetchHeadFake, ' ', gitDir]);
      % Re-name `FETCH_HEAD` as `FETCH_HEAD_cp`, and copied file as
      % `FETCH_HEAD`.
      system(['move ', fetchHead, ' ', gitDir, 'FETCH_HEAD_cp']);
      system(['move ', gitDir, 'FETCH_HEAD_FAKE', ' ', fetchHead]);
    end
  end
  
  methods (TestMethodTeardown)
    function resetFetchHead(testCase)
      % Resets original `FETCH_HEAD`
      
      gitDir = testCase.GitDir;
      % Re-name `FETCH_HEAD_cp` as `FETCH_HEAD`.
      system(['move ', gitDir, 'FETCH_HEAD_cp', ' ', fetchHead]);
    end
  end
  
  methods (Test)    
    function testInputs(testCase, Scheduled, FetchFlag) %#ok<INUSL>
      % Tests various input args for `git.update`
      
      switch FetchFlag
        % pull code
        case true
          
          switch Scheduled
            % pull immediately, since we haven't fetched within an hour
            case 0
              exitCode = git.update(Scheduled);
              msg = 'Error when input arg == 0 and code should be pulled';
              assert(isequal(exitCode, 1), msg);
            % sets the default input arg to 0, so pull
            case []
              exitCode = git.update(Scheduled);
              msg = 'Error when input arg == [] and code should be pulled';
              assert(isequal(exitCode, 1), msg);
            % sets the default input arg to 0, so pull
            case 'char'
              exitCode = git.update(Scheduled);
              msg = 'Error when input arg == ''char'' and code should be pulled';
              assert(isequal(exitCode, 1), msg);
            % not `today`, but we haven't fetched in over a week, so pull
            case 'DiffDay'
              exitCode = git.update(Scheduled);
              msg = 'Error when input arg ~= `today` and code should be pulled';
              assert(isequal(exitCode, 1), msg);
          end
          
        % don't pull changes  
        case false
          
          switch Scheduled
            % pull immediately, since we haven't fetched within an hour
            case 0
              exitCode = git.update(Scheduled);
              msg = 'Error when input arg == 0 and code shouldn''t be pulled';
              assert(isequal(exitCode, 0), msg);
            % sets the default input arg to 0, so pull
            case []
              exitCode = git.update(Scheduled);
              msg = 'Error when input arg == [] and code shouldn''t be pulled';
              assert(isequal(exitCode, 0), msg);
            % sets the default input arg to 0, so pull
            case 'char'
              exitCode = git.update(Scheduled);
              msg = 'Error when input arg == ''char'' and code shouldn''t be pulled';
              assert(isequal(exitCode, 0), msg);
            % not `today`, but we haven't fetched in over a week, so pull
            case 'DiffDay'
              exitCode = git.update(Scheduled);
              msg = 'Error when input arg ~= `today` and code shouldn''t be pulled';
              assert(isequal(exitCode, 0), msg);
          end        
      end      
    end    
  end
end