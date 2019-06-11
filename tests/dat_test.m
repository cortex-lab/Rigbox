classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})... 
  dat_test < matlab.unittest.TestCase

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
      if exist(dataRepo,'dir') == 7
        assert(rmdir(dataRepo, 's'), 'Failed to remove test data directory')
      end
      localRepo = getOr(dat.paths, 'localRepository');
      if exist(localRepo,'dir') == 7
        assert(rmdir(localRepo, 's'), 'Failed to remove local test data directory')
      end
      % Remove config directories
      configRepo = getOr(dat.paths, 'globalConfig');
      if exist(configRepo,'dir') == 7
        assert(rmdir(configRepo, 's'), 'Failed to remove test config directory')
      end
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
    
    function test_paths(testCase)
      % Test the paths structure
      p = dat.paths;
      expected = {...
      'rigbox';
      'localRepository';
      'localAlyxQueue';
      'databaseURL';
      'gitExe';
      'mainRepository';
      'globalConfig';
      'rigConfig';
      'expDefinitions';
      'workingAnalysisRepository';
      'tapeStagingRepository';
      'tapeArchiveRepository'};

      testCase.verifyEqual(expected, fieldnames(p), 'Unexpected paths list')
      
      % Add a custom path
      paths = struct('mainRepository', 'C:\NewPath', 'novelRepo', p.rigbox);
      mkdir(p.rigConfig);
      testCase.assertTrue(exist(p.rigConfig, 'dir') == 7, ...
        'Failed to create config directory')
      save(fullfile(p.rigConfig, 'paths'), 'paths')
      
      p = dat.paths('testRig');
      testCase.verifyTrue(ismember('novelRepo', fieldnames(p)), ...
        'Failed to load custom repo name')
      testCase.verifyEqual(p.mainRepository,'C:\NewPath', ...
        'Failed to merge paths')
    end
    
    function test_newExp(testCase)
      % Test method for dat.newExp.  Note that this function is largely
      % depricated within Rigbox as Alyx.newExp is used instead.  This
      % function may still be used by users though.
      
      % Test creation of experiment with defaults
      testCase.assertTrue(mkdir(getOr(dat.paths,'mainRepository'),'subject_1'))
      [expRef, expSeq] = dat.newExp('subject_1');
      testCase.verifyTrue(contains(expRef, '_1_') && expSeq == 1, ...
        'Unexpected sequence number')
      testCase.verifyTrue(endsWith(expRef, 'subject_1'), ...
        'Unexpected subject in expRef')
      testCase.verifyTrue(startsWith(expRef, datestr(now,'yyyy-mm-dd')), ...
        'Unexpected date in expRef')
      path = dat.expFilePath(expRef, 'parameters');
      testCase.assertTrue(exist(path{1}, 'file') == 2, 'Failed to save local parameters')
      testCase.assertTrue(exist(path{2}, 'file') == 2, 'Failed to save remote parameters')
      load(path{2}, 'parameters')
      testCase.verifyEmpty(parameters)
      
      % Test creation with inputs
      [expRef, expSeq] = dat.newExp('subject_1', now+2, exp.choiceWorldParams);
      testCase.verifyTrue(contains(expRef, '_1_') && expSeq == 1, ...
        'Unexpected sequence number')
      testCase.verifyTrue(endsWith(expRef, 'subject_1'), ...
        'Unexpected subject in expRef')
      testCase.verifyTrue(startsWith(expRef, datestr(now+2,'yyyy-mm-dd')), ...
        'Unexpected date in expRef')
      path = dat.expFilePath(expRef, 'parameters', 'master', 'json');
      testCase.assertTrue(exist(path, 'file') == 2, 'Failed to save json parameters')
      fid = fopen(path); jsonPars = jsondecode(fscanf(fid,'%c')); fclose(fid);
      testCase.verifyEqual(fieldnames(jsonPars), fieldnames(exp.choiceWorldParams))
    end

  end
end