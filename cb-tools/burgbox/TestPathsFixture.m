classdef TestPathsFixture < matlab.unittest.fixtures.Fixture
  %TESTPATHSFIXTURE Fixture that puts the test copy of dat.paths first on the path
  %   Use in place of PathFixture('fixtures'). In R2019b, after MATLAB has
  %   looked up dat.paths, moving a folder that is already on the path to
  %   the front doesn't change which dat.paths runs. Neither do rehash,
  %   rehash path, or clear functions. Removing the folder and adding it
  %   again does. PathFixture only moves the folder, so tests can run with
  %   the real dat.paths, and ReposFixture's teardown then deletes real
  %   data folders.
  %
  %   Setup fails if dat.paths isn't the test copy after it adds the
  %   folder. Teardown also removes the folder before it restores the path,
  %   because restoring the path string alone can leave the test copy in
  %   use.
  %
  %   The class is in cb-tools/burgbox, not tests/fixtures, because test
  %   classes name it in their SharedTestFixtures attribute. MATLAB
  %   evaluates that attribute when it loads the class, before
  %   tests/fixtures is on the path.
  %
  % See also REPOSFIXTURE

  properties (SetAccess = immutable)
    Folder % The fixtures folder that setup puts first on the path
  end

  properties (Access = private)
    OriginalPath
    OriginalPaths % which('dat.paths') before setup
  end

  methods
    function fixture = TestPathsFixture(folder)
      fixture.Folder = absolute(folder);
    end

    function setup(fixture)
      fixture.OriginalPath = path;
      fixture.OriginalPaths = which('dat.paths');
      if any(strcmpi(strsplit(path, pathsep), fixture.Folder))
        rmpath(fixture.Folder)
      end
      addpath(fixture.Folder)
      expected = fullfile(fixture.Folder, '+dat', 'paths.m');
      actual = which('dat.paths');
      assert(strcmpi(actual, expected), 'Rigbox:tests:TestPathsFixture:wrongPaths', ...
        ['dat.paths is %s, not the test copy %s. Tests would use the real data ' ...
        'paths, so they don''t run. Restart MATLAB, and then run the tests ' ...
        'before anything that calls dat.paths.'], actual, expected);
      fixture.SetupDescription = sprintf('Put %s first on the path', fixture.Folder);
      fixture.TeardownDescription = 'Restored the path';
    end

    function teardown(fixture)
      if isempty(fixture.OriginalPath)
        return
      end
      if any(strcmpi(strsplit(path, pathsep), fixture.Folder))
        rmpath(fixture.Folder)
      end
      path(fixture.OriginalPath)
      % When an outer fixture put the test copy in use, it stays in use
      actual = which('dat.paths');
      if ~strcmpi(actual, fixture.OriginalPaths)
        warning('Rigbox:tests:TestPathsFixture:pathsNotRestored', ...
          'dat.paths is %s after teardown, not %s as before setup. Restart MATLAB.', ...
          actual, fixture.OriginalPaths);
      end
    end
  end

  methods (Access = protected)
    function tf = isCompatible(fixture, other)
      tf = strcmpi(fixture.Folder, other.Folder);
    end
  end
end

function full = absolute(folder)
here = cd(folder);
full = pwd;
cd(here);
end
