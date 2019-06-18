function status = reset(file)
% GIT.RESET Reset file or repo to HEAD state
%  
% See also GIT.UPDATE

origDir = pwd;
cleanup = onCleanup(@() cd(origDir));
root = fileparts(which('addRigboxPaths'));

% Get the path to the Git exe
gitexepath = getOr(dat.paths, 'gitExe');
if isempty(gitexepath)
  [~,gitexepath] = system('where git'); % this doesn't always work
end
gitexepath = ['"', strtrim(gitexepath), '"'];

% Temporarily change directory into Rigbox to git pull
cd(root)
fprintf('Resetting %s\n', iff(nargin < 1, @() 'repo', @() file));
if nargin < 1 || strcmp(path, 'all')
  cmdstr = [gitexepath ' reset --hard HEAD'];
else
  cmdstr = [gitexepath ' checkout HEAD -- ' file];
end

status = system(cmdstr, '-echo');