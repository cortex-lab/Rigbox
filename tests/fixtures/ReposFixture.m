classdef ReposFixture < matlab.unittest.fixtures.Fixture
  %REPOSFIXTURE Fixture for using test dat.paths file
  %   Assures test paths are returned, creates a rig config folder for
  %   tests to save a hardware file to and upon teardown removes all
  %   existing test repository folders.
    
  properties (Access = private)
    % MATLAB runs teardown even when setup fails, and teardown deletes the
    % folders that dat.paths returns. Teardown runs only after a complete
    % setup, which confirms that dat.paths is the test copy.
    SetupDone = false
  end

  methods
    function setup(fixture)
      % SETUP Ensure correct test paths and create rig config folder
      fixture.SetupDone = false;
      fixture.applyFixture(TestPathsFixture(fileparts(mfilename('fullpath'))))
      
      % Check paths file
      assert(endsWith(which('dat.paths'),...
        fullfile('tests', 'fixtures', '+dat', 'paths.m')));
      
      % Check temp mainRepo folder is empty.  An extra safe measure as we
      % don't won't to delete important folders by accident!
      mainRepo = dat.reposPath('main', 'master');
      assert(~exist(mainRepo, 'dir') || isempty(file.list(mainRepo)),...
        'Test experiment repo not empty.  Please set another path or manually empty folder');
      
      % Create other folders
      assert(mkdir(getOr(dat.paths, 'rigConfig')), 'Failed to create config directory')
      fixture.SetupDone = true;
    end
    
    function teardown(fixture)
      if ~fixture.SetupDone
        return
      end
      assert(endsWith(which('dat.paths'), fullfile('tests', 'fixtures', '+dat', 'paths.m')), ...
        'Rigbox:tests:ReposFixture:pathsChanged', ...
        'dat.paths is %s, not the test copy. Teardown doesn''t remove any test folders.', ...
        which('dat.paths'));
      testFolders = [dat.reposPath('main');...
        {[dat.reposPath('main', 'm') '2']};...
        {getOr(dat.paths, 'globalConfig')};...
        {getOr(dat.paths, 'localAlyxQueue')}];
      testFolders = testFolders(file.exists(testFolders));
      rmFcn = @(repo)assert(rmdir(repo, 's'), 'Failed to remove test repo %s', repo);
      cellfun(rmFcn, testFolders)
      clearCBToolsCache
    end
  end
end