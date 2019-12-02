function [exitCode, cmdOut] = runCmd(cmd, varargin)
%GIT.RUNCMD runs git commands in MATLAB.
%
% Inputs:
%   `cmd`: A str or cellstr array of git command(s) to run.
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
%   [exitCode, cmdOut] = git.runCmd({'status', 'log -n 1'});
%
% Example: Stash the working changes in the Rigbox repository without
% displaying the command's output:
%   rigboxPath = which('addRigboxPaths');
%   exitCode = git.runCmd({'stash push -m "WIP..."'}, 'dir', rigboxPath,... 
%                             'echo', false);

%% set-up 
% If `cmd` is a char or cellstr, turn it into a string
cmd = string(cmd); % Convert to string array

% When this function terminates, return to the working directory.
origDir = pwd;
cleanup = onCleanup(@() cd(origDir));

% Define default input args in a struct.
defaults.dir = pwd;
defaults.echo = true;
try
  % Parse Name-Value pairs
  inputs = cell2struct(varargin(2:2:end)', varargin(1:2:end)');
  args = mergeStructs(inputs, defaults);
catch
  % If the name-value pairs don't match up, throw error.
  error('Rigbox:git:runCmd:nameValueArgs', ['%s requires optional input '...
    'args to be constructed in name-value pairs'], mfilename);
end

% Change into the specified directory.
cd(args.dir);

%% run commands
% Search `dat.paths` for the path to the Git exe; if not found, perform a
% system search; if still not found, throw an error.
gitexepath = getOr(dat.paths, 'gitExe');
if isempty(gitexepath)
  [exitCode, gitexepath] = system('where git');
  if exitCode
    error('Rigbox:git:runCmd:gitNotFound', ['Could not find the git '...
           'executable on your system. Please ensure that you have git '...
           'installed, and set it''s full path in `+dat/paths.m`.']); 
  end
end
% Convert to string for running system commands.
gitexepath = ['"', strtrim(gitexepath), '"'];

% Run commands.
exitCode = zeros(1, length(cmd));
cmdOut = cell(1, length(cmd));
cmd = strcat(gitexepath, " ", cmd);

for i = 1:length(cmd)
  if args.echo
    [exitCode(i), cmdOut{i}] = system(cmd{i}, '-echo');
  else
    [exitCode(i), cmdOut{i}] = system(cmd{i});
  end
end
