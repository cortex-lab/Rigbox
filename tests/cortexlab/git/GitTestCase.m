classdef GitTestCase < matlab.unittest.TestCase
  properties
    % The path to Git executable
    GitEXE char
  end
  
  methods (TestClassSetup)
    function setup(testCase)
      % SETUP Store Git location and add fixture to mock system command
      if isempty(testCase.GitEXE)
          [failed, testCase.GitEXE] = system('where git');
          assert(~failed)
      end
      assert(file.exists(strtrim(testCase.GitEXE)))
      import matlab.unittest.fixtures.PathFixture
      addFolder = ['../../fixtures' filesep 'util'];
      testCase.applyFixture(PathFixture(addFolder));
    end
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
      system('where git', {0, testCase.GitEXE});
    end
  end
end