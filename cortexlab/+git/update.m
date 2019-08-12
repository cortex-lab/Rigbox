function exitCode = update(scheduled)
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
%   Outputs:
%     `exitCode`: An integer in the interval [0,2]. 0 indicates a
%     successful update of the code. 1 indicates an error running git
%     commands. 2 indicates successfully returning from the function
%     without updating the code if the last fetch was within an hour and
%     `scheduled` == 0, or if the last fetch was within 24 hours and
%     `scheduled` is an integer in the interval [1,7]).
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

% If no input arg, or input arg is not an acceptable value, use 
% `updateSchedule` in `dat.paths`. If `updateSchedule` is not found, set 
% `scheduled` to 0.
if nargin < 1 || ~isnumeric(scheduled) || ~any(0:7 == scheduled)
  scheduled = getOr(dat.paths, 'updateSchedule', 0);
end
root = fileparts(which('addRigboxPaths')); % Rigbox root directory
% Attempt to find date of last fetch
fetch_head = fullfile(root, '.git', 'FETCH_HEAD');
% If `FETCH_HEAD` file exists, retrieve datenum for when last modified,
% else return 0 (i.e. there was never a fetch) 
lastFetch = iff(exist(fetch_head,'file')==2, ... 
  file.modDate(fetch_head), 0); 

% Don't pull changes if the following conditions are met:
% 1. The updates are scheduled for a different day and the last fetch was
% less than a week ago.
% 2. The updates are scheduled for today and the last fetch was today.
% 3. The updates are scheduled for every day and the last fetch was less
% than an hour ago.
notFetchDay = scheduled && scheduled ~= weekday(now) && now-lastFetch < 7;
fetchDayButAlreadyFetched = scheduled == weekday(now) && now-lastFetch < 1;
fetchEverydayButAlreadyFetched = scheduled == 0 && now-lastFetch < 1/24;
if notFetchDay... 
  || fetchDayButAlreadyFetched... 
  || fetchEverydayButAlreadyFetched
  exitCode = 2;
  return
end
disp('Updating code...')

% Create Windows system commands for git stashing, initializing submodules,
% and pulling
stash = ['stash push -m "stash Rigbox working changes before '... 
               'scheduled git update"'];
stashSubs = 'submodule foreach "git stash push"';
init = 'submodule update --init';
pull = 'pull --recurse-submodules --strategy-option=theirs';
cmds = {stash, stashSubs, init, pull};
% run commands in Rigbox root folder
[exitCode, ~] = git.runGitCmd(cmds, 'dir', root, 'echo', true);
end
