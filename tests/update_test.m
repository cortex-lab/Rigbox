classdef Update_test < matlab.unittest.TestCase
  %UPDATE_TEST contains unit tests for `git.update`
  
  properties
    % A char array mock `FETCH_HEAD` file, so we can fetch code without
    % manipulating repo's actual `FETCH_HEAD`.
    FetchHeadFake
    % A char array for Rigbox's `.git` folder.
    GitDir = fullfile(fileparts(which('addRigboxPaths')), '/.git/');
    % A number in the interval [1,7] representing a day that is different
    % from that returned `weekday(today)`.
    DiffDay
  end
  
  properties (MethodSetupParameter)
    % A boolean flag for whether or not to fetch the remote repo code.
    FetchFlag = {false, true}
  end
  
  properties (TestParameter)
    % Different values for the input arg to `git.update`.
    Scheduled = {0, '', 'char', 'DiffDay'}
  end
  
  methods (TestClassSetup)
    function setDiffDay(testCase)
      % Sets `DiffDay` to a number in the interval [1,7] based on `today`.

      % If a `FETCH_HEAD` file doesn't exist in `.git/` (e.g. on new
      % install), create one.
      if ~exist(fullfile(testCase.GitDir, 'FETCH_HEAD'), 'file')
        system(['type nul > ', testCase.GitDir, 'FETCH_HEAD']);
      end
      
      curDay = weekday(today);
      testCase.DiffDay = iff(curDay == 7, 6, curDay + 1);
    end
  end
  
  methods (TestMethodSetup)
    function getMockFiles(testCase, FetchFlag)
      % Gets `FetchHeadFakeOld` file so we don't corrupt actual `FETCH_HEAD`
      
      gitDir = testCase.GitDir;
      fetchHead = fullfile(gitDir, 'FETCH_HEAD');
      fetchHeadFake = fullfile(fileparts(which('addRigboxPaths')),...
                               'tests/fixtures/git/FETCH_HEAD_FAKE');
      
      % If the current test will pull new code, copy `FETCH_HEAD_FAKE` from
      % `tests/fixtures/git/` to `.git/`, else create new `FETCH_HEAD_FAKE`
      % in `.git/`.
      if FetchFlag
          system(['copy ', fetchHeadFake, ' ', gitDir]);
      else
          system(['type nul > ', fullfile(gitDir, 'FETCH_HEAD_FAKE')]);
      end
                  
      % Re-name `FETCH_HEAD` as `FETCH_HEAD_cp`, and `FETCH_HEAD_FAKE` as
      % `FETCH_HEAD`.
      system(['move ', fetchHead, ' ', gitDir, 'FETCH_HEAD_cp']);
      system(['move ', gitDir, 'FETCH_HEAD_FAKE', ' ', fetchHead]);
    end
  end
  
  methods (TestMethodTeardown)
    function resetFetchHead(testCase)
      % Resets original `FETCH_HEAD`
      
      gitDir = testCase.GitDir;
      fetchHeadFake = fullfile(gitDir, 'FETCH_HEAD');
      fetchHead = fullfile(gitDir, 'FETCH_HEAD_cp');
      % Re-name `FETCH_HEAD_cp` as `FETCH_HEAD`.
      system(['move ', fetchHead ' ', fetchHeadFake]);
    end
  end
  
  methods (Test)    
    function testInputs(testCase, Scheduled, FetchFlag)
      % Tests various input args for `git.update`
      
      if FetchFlag % pull code       
          switch Scheduled
            % pull immediately, since we haven't fetched within an hour
            case 0
              exitCode = git.update(Scheduled);
              msg = 'When input arg == 0, code should be pulled';
              assert(isequal(exitCode, 0), msg);
            % sets the default input arg to 0, so pull
            case ''
              exitCode = git.update(Scheduled);
              msg = 'When input arg == [], code should be pulled';
              assert(isequal(exitCode, 0), msg);
            % sets the default input arg to 0, so pull
            case 'char'
              exitCode = git.update(Scheduled);
              msg = 'When input arg == ''char'', code should be pulled';
              assert(isequal(exitCode, 0), msg);
            % not `today`, but we haven't fetched in over a week, so pull
            case 'DiffDay'
              exitCode = git.update(testCase.DiffDay);
              msg = 'When input arg ~= `today`, code should be pulled';
              assert(isequal(exitCode, 0), msg);
          end    
      else % don't pull code    
          switch Scheduled 
            case 0
              exitCode = git.update(Scheduled);
              msg = 'When input arg == 0, code shouldn''t be pulled';
              assert(isequal(exitCode, 2), msg);
            case ''
              exitCode = git.update(Scheduled);
              msg = 'When input arg == [], code shouldn''t be pulled';
              assert(isequal(exitCode, 2), msg);
            case 'char'
              exitCode = git.update(Scheduled);
              msg = 'When input arg == ''char'', code shouldn''t be pulled';
              assert(isequal(exitCode, 2), msg);
            case 'DiffDay'
              exitCode = git.update(testCase.DiffDay);
              msg = 'When input arg ~= `today`, code shouldn''t be pulled';
              assert(isequal(exitCode, 2), msg);
          end        
      end      
    end    
  end
end