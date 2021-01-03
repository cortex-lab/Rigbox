classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('../../fixtures')})...
    repoVersion_test < GitTestCase
  %REPOVERSION_TEST contains unit tests for git.repoVersion
  
  properties
    % A char array for non-git directory
    Badrepo = 'C:/'
    % The path to Git executable
%     GitEXE char
  end
  
  properties (TestParameter)
    % Tags list for testing system command parse
    Tag = {'2.0', 'v1.0.3', '2.4.0-78-g2ddd952'}
    % Expected output given tag parameter
    Expected = {'2.0.0', '1.0.3', '2.4.0'}
  end
  
%   methods (TestClassSetup)
%       function setup(testCase)
%           % SETUP Store Git location and add fixture to mock system command
%           if isempty(testCase.GitEXE)
%             [failed, testCase.GitEXE] = system('where git');
%             assert(~failed)
%           end
%           assert(file.exists(strtrim(testCase.GitEXE)))
%           import matlab.unittest.fixtures.PathFixture
%           addFolder = ['../../fixtures' filesep 'util'];
%           testCase.applyFixture(PathFixture(addFolder));
%       end
%   end
%     
  methods (Test, ParameterCombination = 'sequential')    
    function testVersion(testCase, Tag, Expected)
      % Set the system command output
      system('*', {0, Tag}); % Set all commands to return success
      v = git.repoVersion();
      testCase.verifyEqual(v, Expected, ...
        'Unexpected version returned')
    end
      
    function testRepoDir(testCase)
      % Tests the errors and repo location
      system('*', {0, 'fakefake'}); % Set all commands to return weird tag
      testCase.verifyError(@() git.repoVersion, 'Rigbox:git:repoVersion:noTags')
      
      system('*', {128, 'fail'}); % Git fail, NB: Doesn't really test repo input
      testCase.verifyError(@() git.repoVersion(testCase.Badrepo), ...
        'Rigbox:git:repoVersion:unrecognizedGitRepo')
      end

    end
    
end