function tests = TestPathsFixture_test
% TESTPATHSFIXTURE_TEST Tests TestPathsFixture with stand-in +dat folders in
% tempdir. Each stand-in paths() returns its own file name, so a test can
% check which copy runs.
tests = functiontests(localfunctions);
end

function setup(tc)
base = tempname;
tc.addTeardown(@() rmdir(base, 's'));          % last, after the path is restored
tc.TestData.path = path;
tc.addTeardown(@() path(tc.TestData.path));
tc.TestData.root = fullfile(base, 'root');               % stands in for Rigbox
tc.TestData.fx = fullfile(base, 'root', 'tests', 'fixtures');
writeStandIn(fullfile(tc.TestData.root, '+dat', 'paths.m'));
writeStandIn(fullfile(tc.TestData.root, '+dat', 'other.m')); % more than one function
writeStandIn(fullfile(tc.TestData.fx, '+dat', 'paths.m'));
tc.TestData.testCopy = lower(fullfile(tc.TestData.fx, '+dat', 'paths.m'));
tc.TestData.realCopy = lower(fullfile(tc.TestData.root, '+dat', 'paths.m'));
end

function testWhenFolderNotYetOnPath(tc)
addpath(tc.TestData.root);
dat.paths();
f = TestPathsFixture(tc.TestData.fx);
f.setup();
tc.verifyEqual(lower(dat.paths()), tc.TestData.testCopy);
end

function testWhenFolderBehindRootAndLookedUp(tc)
% The sequence that makes PathFixture fail in R2019b
addpath(tc.TestData.fx);
addpath(tc.TestData.root);                 % root in front
tc.assertEqual(lower(dat.paths()), tc.TestData.realCopy);
f = TestPathsFixture(tc.TestData.fx);
f.setup();
tc.verifyEqual(lower(dat.paths()), tc.TestData.testCopy);
end

function testPathFixtureFailsInR2019b(tc)
% Control: PathFixture fails on the sequence above, so the test above
% checks the R2019b behavior and doesn't pass for another reason
tc.assumeEqual(version('-release'), '2019b', 'Reproduced in R2019b only');
addpath(tc.TestData.fx);
addpath(tc.TestData.root);
dat.paths();
f = matlab.unittest.fixtures.PathFixture(tc.TestData.fx);
f.setup();
tc.addTeardown(@() f.teardown());
tc.verifyEqual(lower(dat.paths()), tc.TestData.realCopy);
end

function testFailsWhenTestCopyMissing(tc)
delete(fullfile(tc.TestData.fx, '+dat', 'paths.m'));
addpath(tc.TestData.root);
before = path;
f = TestPathsFixture(tc.TestData.fx);
tc.verifyError(@() f.setup(), 'Rigbox:tests:TestPathsFixture:wrongPaths');
f.teardown();                    % MATLAB tears down after a failed setup
tc.verifyEqual(path, before);
tc.verifyEqual(lower(dat.paths()), tc.TestData.realCopy);
end

function testTeardownRestoresPath(tc)
addpath(tc.TestData.root);
dat.paths();
before = path;
f = TestPathsFixture(tc.TestData.fx);
f.setup();
tc.verifyNotEqual(path, before);
f.teardown();
tc.verifyEqual(path, before);
tc.verifyEqual(lower(dat.paths()), tc.TestData.realCopy);
end

function testTeardownRestoresPathsWhenFolderBehindRoot(tc)
% In R2019b, restoring the path string alone leaves the test copy in use
addpath(tc.TestData.fx);
addpath(tc.TestData.root);
tc.assertEqual(lower(dat.paths()), tc.TestData.realCopy);
before = path;
f = TestPathsFixture(tc.TestData.fx);
f.setup();
tc.assertEqual(lower(dat.paths()), tc.TestData.testCopy);
f.teardown();
tc.verifyEqual(path, before);
tc.verifyEqual(lower(dat.paths()), tc.TestData.realCopy);
end

function testNestedTeardownKeepsOuterTestCopy(tc)
% As when ReposFixture applies its own fixture inside a shared one
addpath(tc.TestData.fx);
addpath(tc.TestData.root);
dat.paths();
outer = TestPathsFixture(tc.TestData.fx);
outer.setup();
inner = TestPathsFixture(tc.TestData.fx);
inner.setup();
tc.verifyWarningFree(@() inner.teardown());
tc.verifyEqual(lower(dat.paths()), tc.TestData.testCopy);
outer.teardown();
tc.verifyEqual(lower(dat.paths()), tc.TestData.realCopy);
end

function testRelativeFolder(tc)
here = cd(fullfile(tc.TestData.root, 'tests'));
tc.addTeardown(@() cd(here));
f = TestPathsFixture('fixtures');
tc.verifyEqual(lower(f.Folder), lower(tc.TestData.fx));
end

function writeStandIn(file)
if ~isfolder(fileparts(file)), mkdir(fileparts(file)); end
[~, name] = fileparts(file);
fid = fopen(file, 'w');
fprintf(fid, 'function p = %s()\np = mfilename(''fullpath'');\np = [p ''.m''];\nend\n', name);
fclose(fid);
end
