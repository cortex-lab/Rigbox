function [exitCode, cmdOut] = runGitCmd(cmd, varargin)
%GIT.RUNGITCMD runs git commands in MATLAB.
%
% Inputs:
%   `cmd`: A cellstr array of git command(s) to run.
%   `dir`: An optional string name-value paired argument which specifies
%   the directory in which to run the command (default is `pwd`)
%   `echo`: An optional boolean name-value paired argument which specifies
%   whether to display command output on the MATLAB command window (default
%   is `true`).
%
% Outputs:
%   `exitCode`: A flag array indicating whether each command in `cmd` was 
%   run succesfully (0) or there was an error (1).
%   `cmdOut`: A cellstr array of the output of `cmd`.
%
% Example: Get the status and log for the git repository in the working 
% folder, display the commands' outputs in MATLAB, and save the command
% outputs in the `cmdOut` cellstr:
%   [exitCode, cmdOut] = git.runGitCmd({'status', 'log -n 1'});
%
% Example: Stash the working changes in the Rigbox repository without
% displaying the command's output:
%   rigboxPath = which('addRigboxPaths');
%   exitCode = git.runGitCmd({'stash push -m "WIP..."'}, 'dir', rigboxPath,... 
%                             'echo', false);

%% set-up 
% Make sure `cmd` is a cellstr
if ~iscellstr(cmd) %#ok<ISCLSTR>
  error('runGitCmd:invalidInputArg', ['%s requires the first input arg to '...
        'be a cellstr']);
end
% When this function terminates, return to the working directory.
origDir = pwd;
cleanup = onCleanup(@() cd(origDir));

% Define default input args in a struct.
argS.dir = pwd; 
argS.echo = true;

% Get input args and reshape into two rows (into name-value pairs):
% 1st row = arg names, 2nd row = arg values. 
pairedArgs = reshape(varargin,2,[]);

% If the name-value pairs don't match up, throw error.
if ~all(cellfun(@ischar, (pairedArgs(1,:)))) || mod(length(varargin),2)
  error('runGitCmd:nameValueArgs', ['%s requires optional input '... 
         'args to be constructed in name-value pairs'], mfilename);
end

% For the specified input args, change default input args to new values. 
for pair = pairedArgs
  argName = pair{1};
  if any(strcmpi(argName, fieldnames(argS)))
    argS.(argName) = pair{2};
  end
end

% Change into the specified directory.
cd(argS.dir);

%% run commands

% Search `dat.paths` for the path to the Git exe; if not found, perform a
% system search; if still not found, throw an error.
gitexepath = getOr(dat.paths, 'gitExe');
if isempty(gitexepath)
  [exitCode, gitexepath] = system('where git');
  if exitCode
    error(['runGitCmd:gitNotFound', 'Could not find the git executable on '...
           'your system. Please ensure that you have git installed, and '...
           'assign it''s full path (as a char array) to `p.gitExe` in '...
           'your `+dat/paths.m` file.']); 
  end
end
% Convert to string for running system commands.
gitexepath = ['"', strtrim(gitexepath), '"'];

% Run commands.
exitCode = zeros(1, length(cmd));
cmdOut = cell(1, length(cmd));
if argS.echo % then use `'-echo' flag to output to MATLAB command window
  for i = 1:length(cmd)
    [exitCode(i), cmdOut{i}] = system([gitexepath, ' ', cmd{i}], '-echo');
  end
else
  for i = 1:length(cmd)
    [exitCode(i), cmdOut{i}] = system([gitexepath, ' ', cmd{i}]);
  end
end
end