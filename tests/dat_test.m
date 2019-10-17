classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})...
    dat_test < matlab.unittest.TestCase
  
  properties
    nSubs = 10
    nDates = 4
    nSeq = 3
  end
  
  methods (TestClassSetup)
    
    function setup(testCase)
      % Check paths file
      assert(endsWith(which('dat.paths'),...
        fullfile('tests', 'fixtures', '+dat', 'paths.m')));
      
      % Check temp mainRepo folder is empty.  An extra safe measure as we
      % don't won't to delete important folders by accident!
      mainRepo = dat.reposPath('main', 'master');
      assert(~exist(mainRepo, 'dir') || isempty(file.list(mainRepo)),...
        'Test experiment repo not empty.  Please set another path or manually empty folder');
      
      addTeardown(testCase, @clearCBToolsCache)
    end
    
  end
  
  methods (TestMethodSetup)
    function setupFolders(testCase)
      % Make some subject folders
      nSubs = testCase.nSubs; %#ok<*PROP>
      nDates = testCase.nDates;
      nSeq = testCase.nSeq;
      
      subjects = repelems(strcat('subject_',num2cellstr(1:nSubs)), ...
        ones(1,nSubs)*nDates*nSeq);
      expDate = repmat(repelems(floor(now-(nDates-1):now),ones(1,nDates)*nSeq),1,nSubs);
      expSeq = num2cellstr(repmat((1:nSeq), 1, nDates*nSubs));
      repo = dat.reposPath('main','master');
      folders = mapToCell(@(s,d,n)fullfile(repo,s,d,n), ...
        subjects(:), cellstr(datestr(expDate, 'yyyy-mm-dd')), expSeq(:));
      success = cellfun(@mkdir, folders);
      assert(all(success), 'Failed to create subject folders')
      
      % Create some alternates with overlapping experiments
      subjects = repelems(strcat('subject_',num2cellstr(nSubs:nSubs+1)), ...
        ones(1,2)*nDates*nSeq);
      expDate = repmat(repelems(floor(now:now+(nDates-1)),ones(1,nDates)*nSeq),1,2);
      expSeq = num2cellstr(repmat((2:nSeq+1), 1, nDates*2));
      folders = mapToCell(@(s,d,n)fullfile([repo,'2'],s,d,n), ...
        subjects(:), cellstr(datestr(expDate, 'yyyy-mm-dd')), expSeq(:));
      success = cellfun(@mkdir, folders);
      assert(all(success), 'Failed to create alternate repository')
      assert(mkdir(dat.reposPath('main','l')), 'Failed to create local repository')
      
      % Create other folders
      assert(mkdir(getOr(dat.paths,'rigConfig')), 'Failed to create config directory')
      
      % Add teardown to remove folders
      testFolders = [dat.reposPath('main');...
        {[dat.reposPath('main', 'm') '2']};...
        {getOr(dat.paths, 'globalConfig')}];
      rmFcn = @(repo)assert(rmdir(repo, 's'), 'Failed to remove test repo %s', repo);
      addTeardown(testCase, @cellfun, rmFcn, testFolders)
    end
  end
    
  methods (Test)
    function test_listSubjects(testCase)
      % Test listSubjects function
      result = dat.listSubjects;
      testCase.verifyTrue(issorted(result), 'Failed to return sorted list')
      expected = sort(strcat('subject_',num2cellstr(1:testCase.nSubs)));
      testCase.verifyEqual(expected(:), result, 'Unexpected subject list')
      
      % Test using alternate paths
      repo = dat.reposPath('main', 'master');
      testCase.assertEqual(repo, dat.reposPath('main', 'r'), 'Unexpected paths')
      % Make new path
      altMain2Paths(testCase)
      % Test alternates
      result = dat.listSubjects;
      testCase.verifyTrue(issorted(result), 'Failed to return sorted list')
      expected = sort(strcat('subject_',num2cellstr(1:testCase.nSubs+1)));
      testCase.verifyEqual(expected(:), result, 'Unexpected subject list')
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
        'updateSchedule';
        'mainRepository';
        'globalConfig';
        'rigConfig';
        'expDefinitions';
        'workingAnalysisRepository';
        'tapeStagingRepository';
        'tapeArchiveRepository'};
      testCase.verifyEqual(expected, fieldnames(p), 'Unexpected paths list')
      
      % Add a custom path
      paths.mainRepository = 'C:\NewPath';
      paths.novelRepo = p.rigbox;
      paths.main2Repository = [p.mainRepository '2'];
      paths.altRepository = [p.mainRepository '3'];
      save(fullfile(p.rigConfig, 'paths'), 'paths')
      clearCBToolsCache
      
      p = dat.paths('testRig');
      testCase.verifyTrue(ismember('novelRepo', fieldnames(p)), ...
        'Failed to load custom repo name')
      testCase.verifyEqual(p.mainRepository,'C:\NewPath', ...
        'Failed to merge paths')
      
      % Test repos path
      testCase.verifyTrue(numel(dat.reposPath('*'))==7, 'Failed to return all repo paths')
      paths = dat.reposPath('main');
      testCase.verifyEqual(paths, {p.localRepository;p.mainRepository}, ...
        'reposPath(''main'') failed to return correct paths')
      paths = dat.reposPath('main', 'master');
      testCase.verifyEqual(paths, p.mainRepository, ...
        'reposPath(''main'',''master'') failed to return correct paths')
      paths = dat.reposPath('main', 'all');
      testCase.verifyEqual(paths, {p.localRepository;p.mainRepository}, ...
        'reposPath(''main'',''all'') failed to return correct paths')
      paths = dat.reposPath('main', 'remote');
      expected = {p.mainRepository;p.main2Repository;p.altRepository};
      testCase.verifyEqual(paths, expected, ...
        'reposPath(''main'',''remote'') failed to return correct paths')
      paths = dat.reposPath('local');
      testCase.verifyEqual(paths, {p.localRepository}, ...
        'reposPath(''local'') failed to return correct paths')
      paths = dat.reposPath('main','local');
      testCase.verifyEqual(paths, p.localRepository, ...
        'reposPath(''main'',''local'') failed to return correct paths')
      paths = dat.reposPath('workingAnalysis','r');
      expected = {p.workingAnalysisRepository;p.altRepository};
      testCase.verifyEqual(paths, expected, ...
        'reposPath(''workingAnalysis'',''remote'') failed to return correct paths')
    end
    
    function test_newExp(testCase)
      % Test method for dat.newExp.  Note that this function is largely
      % depricated within Rigbox as Alyx.newExp is used instead.  This
      % function may still be used by users though.
      
      % Test creation of experiment with defaults
      subject = ['subject_',num2str(testCase.nSubs)];
      [expRef, expSeq] = dat.newExp(subject);
      pattern = ['_',num2str(testCase.nSeq+1),'_'];
      testCase.verifyTrue(contains(expRef, pattern) && expSeq == testCase.nSeq+1, ...
        'Unexpected sequence number')
      testCase.verifyTrue(endsWith(expRef, subject), ...
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
    
    function test_expFilePath(testCase)
      % [full, filename] = expFilePath(ref, type, [reposlocation, ext])
      % [full, filename] = expFilePath(subject, date, seq, type, [reposlocation, ext])
      
      % Add a custom path
      altMain2Paths(testCase)
      
      ref = dat.constructExpRef('subject_1', now, 1);
      [full, filename] = dat.expFilePath(ref, 'parameters');
      testCase.verifyEqual(filename, [ref,'_parameters.mat'], 'Unexpected filename')
      testCase.verifyTrue(numel(full)==2, 'Unexpected path number')
      testCase.verifyTrue(startsWith(full{1},dat.reposPath('main','l')))
      testCase.verifyTrue(startsWith(full{2},dat.reposPath('main','m')))
      % Test other input form
      testCase.verifyEqual(full, dat.expFilePath('subject_1', now, 1, 'parameters'))
      
      % Test repos location
      full = dat.expFilePath(ref, 'parameters', 'remote');
      testCase.verifyTrue(numel(full)==2, 'Unexpected path number')
      testCase.verifyTrue(startsWith(full{1}, [dat.reposPath('main','m') filesep]))
      testCase.verifyTrue(startsWith(full{2}, [dat.reposPath('main','m') '2']))
      
      % Test ext input
      [full, filename] = dat.expFilePath(ref, 'parameters', 'm', 'json');
      success = endsWith(full,'_parameters.json') && endsWith(filename,'_parameters.json');
      testCase.verifyTrue(success, 'Failed to return correct file extension')
      testCase.verifyEqual(full, dat.expFilePath(ref, 'parameters', 'm', '.json'))
      
      % Test multiple inputs
      full = dat.expFilePath(ref, {'parameters';'block'}, 'm');
      testCase.verifyTrue(endsWith(full{1}, 'parameters.mat') && endsWith(full{2}, 'Block.mat'))
      ref = dat.constructExpRef(strcat('subject_',num2cellstr(1:3)), now, 1); %FIXME most functions return Nx1 arrays, constructExpRef returns 1xN
      full = dat.expFilePath(ref', 'parameters', 'm');
      success = cellfun(@endsWith, full, strcat(ref,'_parameters.mat')');
      testCase.verifyTrue(all(success))
    end
    
    function test_expPath(testCase)
      % [P, REF] = DAT.EXPPATH(ref, reposname, [reposlocation])
      % [P, REF] = DAT.EXPPATH(subject, date, seq, reposname, [reposlocation])
      [p, ref] = dat.expPath('subject_1', now, 1, 'main');
      testCase.verifyEqual(ref,dat.constructExpRef('subject_1',now,1))
      testCase.verifyTrue(startsWith(p{1},dat.reposPath('main','l')))
      testCase.verifyTrue(startsWith(p{2},dat.reposPath('main','m')))
    end
    
    function test_listExps(testCase)
      % Test query of one subject
      subject = strcat('subject_',num2str(testCase.nSubs));
      [expRef, expDate, expSeq] = dat.listExps(subject);
      numelems = testCase.nDates*testCase.nSeq;
      testCase.verifyTrue(numel(expRef) == numelems && all(endsWith(expRef, subject)));
      expected = repelems(floor(now-(testCase.nDates-1):now), ...
        ones(testCase.nDates,1)*testCase.nSeq);
      testCase.verifyEqual(expDate, expected(:));
      testCase.verifyEqual(expSeq, repmat((1:testCase.nSeq)',testCase.nDates,1));
      
      % Test query of multiple subjects
      subjects = {subject;strcat('subject_',num2str(testCase.nSubs-1))};
      [expRef, expDate, expSeq] = dat.listExps(subjects);
      testCase.verifyTrue(iscell(expRef) && iscell(expDate) && iscell(expSeq))
      testCase.verifyEqual({expected(:);expected(:)}, expDate);
      expected = cellfun(@(r,s)all(endsWith(r,s)),expRef,subjects);
      testCase.verifyTrue(all(expected));
      expected = repmat((1:testCase.nSeq)',testCase.nDates,1);
      testCase.verifyEqual({expected;expected}, expSeq);
      
      % Add a custom path
      altMain2Paths(testCase)
      % Test query with alternate paths
      subjects = {subject;strcat('subject_',num2str(testCase.nSubs+1))};
      [expRef, expDate, expSeq] = dat.listExps(subjects);
      % Check for new subject exps
      testCase.verifyTrue(~isempty(expRef{2}) && all(endsWith(expRef{2},subjects{2})))
      % Check for duplicates
      testCase.verifyEqual(expRef{1}, unique(expRef{1}), 'Duplicate references')
      testCase.verifyEqual(numel(expRef{1}), numel(expDate{1}), numel(expSeq{1}))
      testCase.verifyEqual(numel(expRef{2}), numel(expDate{2}), numel(expSeq{2}))
    end
    
    function test_loadBlock(testCase)
      % Should search all remote repos and give precedence to main
      altMain2Paths(testCase)
      % Create files on repos
      subject = strcat('subject_',num2str(testCase.nSubs));
      block = struct('block', struct('expType','one'));
      full = cellflat(dat.expFilePath(subject, now, [1;2;4], 'block', 'r'));
      full = full(file.exists(mapToCell(@fileparts,full)));
      superSave(full(1:2),  block)
      block.block.expType = 'two';
      superSave(full(3:end),  block)
      testCase.assertTrue(all(file.exists(full)), 'Failed to create test blocks')
      % Test load precedence
      block = catStructs(rmEmpty(dat.loadBlock(subject, now, [1;2;4])));
      testCase.verifyEqual(strcmp({block.expType}, 'one'),[true true false], ...
        'Failed to load with the correct precedence')
      % Test expType filtering
      block = catStructs(rmEmpty(dat.loadBlock(subject, now, [1;2;4], 'two')));
      testCase.verifyTrue(all(strcmp({block.expType}, 'two')), ...
        'Failed to filter blocks by experiment type')
    end
    
    function test_expParams(testCase)
      % Should search all remote repos and give precedence to main
      altMain2Paths(testCase)
      % Create files on repos
      subject = strcat('subject_',num2str(testCase.nSubs));
      refs = dat.constructExpRef(subject, now, [1;2;4]);
      parameters = struct('parameters', struct('expType','one'));
      full = cellflat(dat.expFilePath(refs, 'parameters', 'r'));
      full = full(file.exists(mapToCell(@fileparts,full)));
      superSave(full(1:2),  parameters)
      parameters.parameters.expType = 'two';
      superSave(full(3:end),  parameters)
      testCase.assertTrue(all(file.exists(full)), 'Failed to create test parameters')
      % Test load precedence
      parameters = catStructs(rmEmpty(dat.expParams(refs)));
      testCase.verifyEqual(strcmp({parameters.expType}, 'one'),[true true false], ...
        'Failed to load with the correct precedence')
    end
    
    function test_expExists(testCase)
      % Should search all remote repos and give precedence to main
      altMain2Paths(testCase)
      % Create some experiments to test the existence of
      refs = {dat.constructExpRef('subject_1', now, testCase.nSeq-1); % Exists on master
        dat.constructExpRef('subject_1', now+1, testCase.nSeq+1); % Doesn't exist
        dat.constructExpRef(['subject_',num2str(testCase.nSubs)], now, testCase.nSeq); % Exists on remote
        dat.constructExpRef(['subject_',num2str(testCase.nSubs+1)], now, 1)}; % Exists on alt only
      
      testCase.verifyEqual(dat.expExists(refs),[true; false; true; false], ...
        'Failed to load with the correct precedence')
      % Test behaviour with char input
      testCase.verifyTrue(dat.expExists(refs{1}))
    end
    
  end
  
  methods (Access = private)
    function altMain2Paths(testCase)
      % Add a secondary main repository as a custom path, pointing to the
      % Subjects2 fixture 
      testCase.assertEmpty(dat.listExps(strcat('subject_',num2str(testCase.nSubs+1))),...
        'Secondary main repo already in path, expected otherwise')
      paths.main2Repository = [dat.reposPath('main','m') '2'];
      save(fullfile(getOr(dat.paths,'rigConfig'), 'paths'), 'paths')
      clearCBToolsCache % Ensure paths are reloaded
      testCase.assertEqual(paths.main2Repository, getOr(dat.paths,'main2Repository'),...
        'Failed to create custom paths file')
    end
  end
end