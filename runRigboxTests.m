function runRigboxTests()
% Install GUILayoutToolbox
disp('Installing required third-party toolboxes...')
matlab.addons.install('GUI Layout Toolbox 2.3.4.mltbx', true);
toolboxDir = fullfile(userpath, 'Toolboxes');
if ~exist(toolboxDir, 'dir'); mkdir(toolboxDir); end
oldState = pause('off');
DownloadPsychToolbox(toolboxDir)
pause(oldState);

% Install Rigbox paths
disp('Installing Rigbox paths...')
savePaths = false; blind = true;
addRigboxPaths(savePaths, blind)

% Move into test directory
currDir = pwd;
cleanup = onCleanup(@()cd(currDir));
testDir = fullfile(fileparts(which('addRigboxPaths')), 'tests');
cd(testDir)

% Run the tests and assert success
anyFailed = runall();
assert(~anyFailed)
