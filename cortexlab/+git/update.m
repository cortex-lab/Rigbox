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
if scheduled && weekday(now) ~= scheduled && now - lastFetch < 7
  return
end
disp('Updating code...')

gitexepath = getOr(dat.paths, 'gitExe', 'C:\Program Files\Git\cmd\git.exe'); %TODO generalize
gitexepath = ['"', gitexepath, '"'];
origDir = pwd;
cd(root)

% cmdstr = strjoin({gitexepath, 'fetch'});
% system(cmdstr, '-echo');
% if isempty(cmdout)
%   cd(origDir)
%   return
% end

cmdstr = strjoin({gitexepath, 'pull'});
[status, cmdout] = system(cmdstr);
if status ~= 0
  if fatalOnError
    cd(origDir)
    error('gitUpdate:pull:pullFailed', 'Failed to pull latest changes:, %s', cmdout)
  else
    warning('gitUpdate:pull:pullFailed', 'Failed to pull latest changes:, %s', cmdout)
  end
end
% TODO: check if submodules are empty and use init flag
cmdstr = strjoin({gitexepath, 'submodule update --remote --merge'});
status = system(cmdstr, '-echo');
if status ~= 0
  if fatalOnError
    cd(origDir)
    error('gitUpdate:submodule:updateFailed', ...
      'Failed to pull latest changes for submodules:, %s', cmdout)
  else
    warning('gitUpdate:submodule:updateFailed', ...
      'Failed to pull latest changes for submodules:, %s', cmdout)
  end
end

cd(origDir)
end