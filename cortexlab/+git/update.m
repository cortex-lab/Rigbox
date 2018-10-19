function update(fatalOnError)
% GIT.UPDATE Pull latest Rigbox code 
%
% See also
if nargin == 0; fatalOnError = true; end
gitexepath = getOr(dat.paths, 'gitExe', 'C:\Program Files\Git\cmd\git.exe'); %TODO generalize
gitexepath = ['"', gitexepath, '"'];
root = fileparts(which('addRigboxPaths'));
origDir = pwd;
cd(root)

cmdstr = strjoin({gitexepath, 'fetch'});
[~, cmdout] = system(cmdstr);
if isempty(cmdout); return; end

cmdstr = strjoin({gitexepath, 'merge'});
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
status = system(cmdstr);
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