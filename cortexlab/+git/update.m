function update(scheduled)
% GIT.UPDATE Pulls latest Rigbox code 
%   `git.update` pulls the latest code from the remote Rigbox Github 
%   repository if it is run on a specific day of the week (provided the 
%   remote code was last fetched over a day ago), or immediately (provided 
%   the remote code was last fetched over an hour ago), according to 
%   `scheduled`. If run without an input arg, code is pulled according to 
%   the `updateSchedule` field in the struct returned by `dat.paths`, or 
%   immediately if the `updateSchedule` field is not found in `dat.paths`
%   (provided the remote code was last fetched over an hour ago).
%   
%   Inputs:
%     `scheduled`: an optional input as an integer in the interval [0,7]. 
%     When 0, the remote code will be pulled provided the last fetch was 
%     over an hour ago. When in the interval [1,7], code will be pulled on 
%     a corresponding day according to `weekday` (Sunday=1, Monday=2, ... 
%     Saturday = 7), provided the last fetch was over a day ago. Code will 
%     also be pulled if it is not the scheduled day, but the last fetch was 
%     over a week ago. If scheduled is 0, the function will pull changes 
%     provided the last fetch was over an hour ago.
%
%   Example: Pull remote code immediately, provided last code fetch was 
%   over an hour ago:
%     git.update(0);
%
%   Example: Pull remote code if today is Monday, provided last code fetch
%   was over a day ago:
%     git.update(2);
% 
% See also DAT.PATHS
%
% TODO Find quicker way to check for changes

% when this function terminates, return to the working directory
origDir = pwd;
cleanup = onCleanup(@() cd(origDir));

% If no input arg, or input arg is not an acceptable value, use 
% `updateSchedule` in `dat.paths`. If `updateSchedule` is not found, set 
% `scheduled` to 0.
if nargin < 1 || ~any(scheduled == [0:7])
  scheduled = getOr(dat.paths, 'updateSchedule', 0);
end
root = fileparts(which('addRigboxPaths')); % Rigbox root directory
% Attempt to find date of last fetch
fetch_head = fullfile(root, '.git', 'FETCH_HEAD');
% If FETCH_HEAD file exists, retrieve datenum when modified, else return 0
% (i.e. there was never a fetch) 
lastFetch = iff(exist(fetch_head,'file')==2, ... 
  @()getOr(dir(fetch_head), 'datenum'), 0); 

% Don't pull changes if the following conditions are met:
% 1. The updates are scheduled for a different day and the last fetch was
% less than a week ago.
% 2. The updates are scheduled for today and the last fetch was today.
% 3. The updates are scheduled for every day and the last fetch was less
% than an hour ago.
notFetchDay = scheduled ~= weekday(now) && now-lastFetch < 7;
fetchDayButAlreadyFetched = scheduled == weekday(now) && now-lastFetch < 1;
fetchEverydayButAlreadyFetched = scheduled == 0 && now-lastFetch < 1/24;
if notFetchDay... 
   || fetchDayButAlreadyFetched... 
   || fetchEverydayButAlreadyFetched
  return
end
disp('Updating code...')

% Search `dat.paths` for the path to the Git exe; if not found, perform a
% system search; if still not found, throw an error.
gitexepath = getOr(dat.paths, 'gitExe');
if isempty(gitexepath)
  [exitCode, gitexepath] = system('where git');
  if exitCode
    error(['Could not find the git executable on your system. Please '
           'ensure that you have git installed, and assign it''s full path'...
           '(as a char array) to `p.gitExe` in your `+dat/paths.m` file.']); 
  end
end

% Convert to string for running system commands.
gitexepath = ['"', strtrim(gitexepath), '"'];
% Temporarily change directory into Rigbox to run git pull.
cd(root)
% Create Windows system commands for git stashing, initializing submodules,
% and pulling
cmdstrStash = [gitexepath, ' stash push -m "stash Rigbox working changes before scheduled git update"'];
cmdstrStashSubs = [gitexepath, ' submodule foreach "git stash push"'];
cmdstrInit = [gitexepath, ' submodule update --init'];
cmdstrPull = [gitexepath, ' pull --recurse-submodules --strategy-option=theirs'];

% Stash any WIP, check submodules are initialized, pull
[exitCode(1), cmdout] = system(cmdstrStash, '-echo'); %#ok<*ASGLU>
[exitCode(2), cmdout] = system(cmdstrStashSubs, '-echo');
[exitCode(3), cmdout] = system(cmdstrInit, '-echo');
[exitCode(4), cmdout] = system(cmdstrPull, '-echo');

if any(exitCode)
  error('gitUpdate:pull:pullFailed', 'Failed to pull latest changes:, %s', cmdout)
end

end
