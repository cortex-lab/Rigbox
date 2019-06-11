classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})... 
  dat_test < matlab.unittest.TestCase & matlab.mock.TestCase

  methods (TestClassSetup)
            
    function setup(~)
      % Check paths file
      assert(endsWith(which('dat.paths'),...
        fullfile('tests', 'fixtures', '+dat', 'paths.m')));
      
      % Check temp mainRepo folder is empty.  An extra safe measure as we
      % don't won't to delete important folders by accident!
      mainRepo = getOr(dat.paths, 'mainRepository');
      assert(~exist(mainRepo, 'dir') || isempty(setdiff(getOr(dir(mainRepo),'name'),{'.','..'})),...
        'Test experiment repo not empty.  Please set another path or manual empty folder');
    end
    
  end
  
  methods (TestMethodTeardown)
    function methodTaredown(~)
      % Remove subject directories
      dataRepo = getOr(dat.paths, 'mainRepository');
      assert(rmdir(dataRepo, 's'), 'Failed to remove test data directory')
    end
  end
  
  methods (Test)
    function test_listSubjects(testCase)
      % Test listSubjects function
      testCase.assertEmpty(dat.listSubjects, 'Unexpected subjects list')
      % Make some subject folders
      subjects = strcat('subject_',strsplit(num2str(1:10)))';
      repo = getOr(dat.paths, 'mainRepository');
      success = cellfun(@(d)mkdir(repo,d), subjects);
      testCase.assertTrue(all(success), 'Failed to create subject folders')
      
      result = dat.listSubjects;
      testCase.verifyTrue(issorted(result), 'Failed to return sorted list')
      testCase.verifyEqual(sort(subjects),result, 'Unexpected subject list')
    end
  end
end