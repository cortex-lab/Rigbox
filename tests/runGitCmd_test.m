%RUNGITCMD_TEST contains unit tests for `git.runGitCmd`  

%% Test 1: Inputs not specified correctly fail
% First input arg is not a cellstr.
try, git.runGitCmd('status'), catch ex, end %#ok<*NOCOMMA>
msg = 'Illegaly accepts a non-cellstr first input arg';
assert(strcmp(ex.identifier, 'runGitCmd:invalidInputArg'), msg);

% Name-value args are not specified correctly.
try, git.runGitCmd({'status'}, echo, true), catch ex, end
msg = 'Illegaly accepts a name-value paired arg where name is not a char';
assert(strcmp(ex.identifier, 'MATLAB:maxlhs'), msg); 

try, git.runGitCmd({'status'}, 'echo'), catch ex, end
msg = ['Illegaly accepts a name-value paired arg where a name has no '... 
  'matching value'];
assert(strcmp(ex.identifier, 'MATLAB:getReshapeDims:notDivisible'), msg); 

%% Test 2 : Proper cleanup
dir = pwd;
root = fileparts(which('addRigboxPaths'));
exitCode = git.runGitCmd({'status'}, 'dir', root, 'echo', false);
msg = '`onCleanup` did not run correctly';
assert(strcmp(pwd, dir), msg);

%% Test 3 : Illegal system command fails
exitCode = git.runGitCmd({'not a valid command'}, 'echo', false);
msg = 'Runs an illegal command with exiting with appropriate exit code';
assert(exitCode == 1, msg);

%% Test 4 : Running different commands while using optional name-value args
root = fileparts(which('addRigboxPaths'));
% Single command.
exitCode = git.runGitCmd({'status'}, 'echo', false);
msg = 'Failed to run a single command';
assert(exitCode == 0, msg);
% Multiple commands.
exitCode = ...
  git.runGitCmd({'status', 'log -n 1', 'branch'},... 
                 'dir', root, 'echo', false);
msg = 'Failed to run multiple commands with user-set name-value args';
assert(~any(exitCode), msg);