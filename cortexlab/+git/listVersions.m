function versions = listVersions(repoDir, printToCmd)
%GIT.LISTVERSIONS todo document
%  TODO Add support for multiple repos
%  TODO Add test
%

% Default repo is Rigbox
if nargin == 0 || isempty(repoDir)
  repoDir = getOr(dat.paths, 'rigbox');
end

if nargin < 2 || printToCmd
  printToCmd = {'echo', true}; 
else
  printToCmd = {'echo', false}; 
end

[failed, versions] = git.runCmd('tag', 'dir', repoDir, printToCmd{:});
assert(~failed, 'Rigbox:git:listVersions:failedForRepo', ...
  'failed to list versions for repo ''%s'':\n\t %s', repoDir, versions)
versions = strsplit(strtrim(versions));