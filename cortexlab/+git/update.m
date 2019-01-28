function update(scheduled)
% GIT.UPDATE Pull latest Rigbox code 
%   Pulls the latest code from the remote repository.  If scheduled is a
%   value in the range [1 7] corresponding to the days of the week starting
%   Sunday, the function will only continue on that day, provided the last
%   fetch was over a day ago.  If it is not the scheduled day, but the last
%   fetch was over a week ago, the function will pull changes.  If
%   scheduled is false, the function will pull changes provided the last
%   fetch was over an hour ago.
%
% TODO Find quicker way to check for changes
% See also DAT.PATHS
if nargin < 1; scheduled = getOr(dat.paths, 'updateSchedule', 0); end

root = fileparts(which('addRigboxPaths'));
% Attempt to find date of last fetch
fetch_head = fullfile(root, '.git', 'FETCH_HEAD');
lastFetch = iff(exist(fetch_head,'file')==2, ... % If FETCH_HEAD file exists
  @()getOr(dir(fetch_head), 'datenum'), 0); % Retrieve date modified

% Don't pull changes if the following conditions are met:
% 1. The updates are scheduled for a different day and the last fetch was less
% than a week ago.
% 2. The updates are scheduled for today and the last fetch was today.
% 3. The updates are scheduled for every day and the last fetch was less
% than an hour ago.
if (scheduled && weekday(now) ~= scheduled && now - lastFetch < 7) || ...
    (scheduled && weekday(now) == scheduled && now - lastFetch < 1) || ...
        (~scheduled && now - lastFetch < 1/24)
  return
end
disp('Updating code...')

% Get the path to the Git exe
gitexepath = getOr(dat.paths, 'gitExe');
if isempty(gitexepath)
  [~,gitexepath] = system('where git'); % this doesn't always work
end
gitexepath = ['"', strtrim(gitexepath), '"'];

% Temporarily change directory into Rigbox to git pull
origDir = pwd;
cd(root)

cmdstrStash = [gitexepath, ' stash push -m "stash Rigbox working changes before scheduled git update"'];
cmdstrStashSubs = [gitexepath, ' submodule foreach "git stash push"'];
cmdstrInit = [gitexepath, ' submodule update --init'];
cmdstrPull = [gitexepath, ' pull --recurse-submodules --strategy-option=theirs'];

% Stash any WIP, check submodules are initialized, pull
try
  [~, cmdout] = system(cmdstrStash, '-echo');
  [~, cmdout] = system(cmdstrStashSubs, '-echo');
  [~, cmdout] = system(cmdstrInit, '-echo');
  [~, cmdout] = system(cmdstrPull, '-echo'); %#ok<ASGLU>
catch ex
  cd(origDir)
  error('gitUpdate:pull:pullFailed', 'Failed to pull latest changes:, %s', cmdout)
end

% Run any new tasks
changesPath = fullfile(root, 'cortexlab', '+git', 'changes.m');
if exist(changesPath, 'file')
  git.changes;
  delete(changesPath);
end
cd(origDir)
end