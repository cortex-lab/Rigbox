%RUNCMD_TEST contains unit tests for `git.runCmd`

% preconditions:
% set this in case a test we want to fail actually passes
ex.identifier = ''; 
root = getOr(dat.paths, 'rigbox');

%% Test 1: Inputs not specified correctly fail
% Name-value args are not specified correctly.
try git.runCmd('status', pi, true); catch ex, end
msg = 'Illegaly accepts a name-value paired arg where name is not a char';
assert(strcmp(ex.identifier, 'Rigbox:git:runCmd:nameValueArgs'), msg) 

try git.runCmd('status', 'echo'); catch ex, end
msg = ['Illegaly accepts a name-value paired arg where a name has no '... 
  'matching value'];
assert(strcmp(ex.identifier, 'Rigbox:git:runCmd:nameValueArgs'), msg)

%% Test 2 : Proper cleanup
dir = pwd;
git.runCmd('status', 'dir', root, 'echo', false);
msg = '`onCleanup` did not run correctly';
assert(strcmp(pwd, dir), msg)

%% Test 3 : Illegal system command fails
exitCode = git.runCmd('not a valid command');
msg = 'Runs an illegal command with exiting with appropriate exit code';
assert(exitCode == 1, msg)

%% Test 4 : Running different commands while using optional name-value args
% Single command.
exitCode = git.runCmd({'status'}, 'echo', false);
msg = 'Failed to run a single command';
assert(exitCode == 0, msg)
% Multiple commands.
errCode = ...
  git.runCmd({'status', 'log -n 1', 'branch'},... 
              'dir', root, 'echo', false);
msg = 'Failed to run multiple commands with user-set name-value args';
assert(~any(errCode), msg)

%% Test 5 : Echo parameter
% Test the echo input has desired effect
T = evalc("git.runCmd('status', 'echo', true);");
assert(~isempty(T), 'Failed to echo output');

T = evalc("git.runCmd('status', 'echo', false);");
assert(isempty(T), 'Unexpected output printed to command window');
