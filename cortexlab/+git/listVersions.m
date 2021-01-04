function versions = listVersions(repoDir, printToCmd)
%GIT.LISTVERSIONS List repository releases
%  Lists the version tags for a given Git repository.  
%
%  Inputs:
%     repoDir (char) : The directory of the git repository to return
%                      version of.  Default: rigbox location in dat.paths.
%     printToCmd (logical) : If true, the versions are echoed to the 
%                            command window.  If no output is specified, 
%                            the versions are printed by default.
%
%  Output (Optional):
%    A cell array of version tags
%
%  TODO Add support for multiple repos
%
% See also GIT.SWTICHVERSION, GIT.REPOVERSION

% Default repo is Rigbox
if nargin == 0 || isempty(repoDir)
  repoDir = getOr(dat.paths, 'rigbox');
end

if (nargin > 1 && printToCmd) || (nargin < 2 && nargout)
  printToCmd = {'echo', true}; 
else
  printToCmd = {'echo', false}; 
end

git.runCmd('fetch', 'dir', repoDir, 'echo', false);
[failed, v] = git.runCmd('tag', 'dir', repoDir, printToCmd{:});
assert(~failed, 'Rigbox:git:listVersions:failedForRepo', ...
  'failed to list versions for repo ''%s'':\n\t %s', repoDir, v)
if nargout == 0, return, end
versions = strsplit(strtrim(v));