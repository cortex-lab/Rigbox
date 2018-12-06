function update(fatalOnError, scheduled)
% GIT.UPDATE Pull latest Rigbox code 
%   Pulls the latest code from the remote repository.  If scheduled is a
%   value in the range [1 7] corresponding to the days of the week, the
%   function will only continue on that day, or if the last fetch was over
%   a week ago.  
% TODO Find quicker way to check for changes
% See also
if nargin == 0; fatalOnError = true; end
if nargin < 2; scheduled = 0; end

root = fileparts(which('addRigboxPaths'));
lastFetch = getOr(dir(fullfile(root, '.git', 'FETCH_HEAD')), 'datenum');
if (scheduled && weekday(now) ~= scheduled && now - lastFetch < 7) || ...
        (~scheduled && now - lastFetch < 1/24)
  return
end
disp('Updating code...')

% Get the path to the Git exe (can we assume this is unnecessary)? 
gitexepath = getOr(dat.paths, 'gitExe');
if isempty(gitexepath)
  [~,gitexepath] = system('where git'); % this doesn't always work
end
gitexepath = ['"', strtrim(gitexepath), '"'];

% Temporarily change directory into Rigbox -> isn't it safe to assume we're
% already in Rigbox? (since we're running this file, presumably we are?)
origDir = pwd;
cd(root)

% Check if there are changes before pulling
% cmdstr = strjoin({gitexepath, 'fetch'});
% system(cmdstr, '-echo');
% if isempty(cmdout)
%   cd(origDir)
%   return
% end

% Check that the submodules are initialized
cmdstrInit = [gitexepath, ' ', 'submodule update --init'];
[status, cmdout] = system(cmdstrInit, '-echo');

% Stash any WIP changes
cmdstrStash = [gitexepath ' ' 'stash push -m "stash working changes before scheduled git update"'];
[status, cmdout] = system(cmdstrStash, '-echo');

%Pull submodules using "theirs" merge strategy
cmdstrPull = [gitexepath, ' ', 'pull --recurse-submodules --strategy-option=theirs'];
[status, cmdout] = system(cmdstrPull, '-echo');
if status ~= 0
  if fatalOnError
    cd(origDir)
    error('gitUpdate:pull:pullFailed', 'Failed to pull latest changes:, %s', cmdout)
  else
    warning('gitUpdate:pull:pullFailed', 'Failed to pull latest changes:, %s', cmdout)
  end
end

% Run any new tasks
changesPath = fullfile(root, 'cortexlab', '+git', 'changes.m');
if exist(changesPath, 'file')
  git.changes;
  delete(changesPath);
end

cd(origDir)
end