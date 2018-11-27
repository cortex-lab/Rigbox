function update(scheduled)
% GIT.UPDATE Pull latest Rigbox code 
%   Pulls the latest code from the remote repository.  If scheduled is a
%   value in the range [1 7] corresponding to the days of the week, the
%   function will only continue on that day, or if the last fetch was over
%   a week ago.  
% TODO Find quicker way to check for changes
% See also
if nargin < 1; scheduled = getOr(dat.paths, 'updateSchedule', 0); end

root = fileparts(which('addRigboxPaths'));
lastFetch = getOr(dir(fullfile(root, '.git', 'FETCH_HEAD')), 'datenum');
if (scheduled && weekday(now) ~= scheduled && now - lastFetch < 7) || ...
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
  [status, cmdout] = system(cmdstrStash, '-echo');
  [status, cmdout] = system(cmdstrStashSubs, '-echo');
  [status, cmdout] = system(cmdstrInit, '-echo');
  [status, cmdout] = system(cmdstrPull, '-echo');
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
