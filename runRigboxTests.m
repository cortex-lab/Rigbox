function runRigboxTests()
% Install Rigbox paths
disp('Installing Rigbox paths')
addRigboxPaths

% Move into test directory
currDir = pwd;
cleanup = onCleanup(@()cd(currDir));
testDir = fullfile(fileparts(which('addRigboxPaths')), 'tests');
cd(testDir)

% Run the tests and assert success
anyFailed = runall();
assert(~anyFailed)
