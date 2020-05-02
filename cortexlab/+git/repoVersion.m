function v = repoVersion(repoDir)
% GIT.REPOVERSION Returns repository's current version
%   Return the semanic version of the specified Git repository.
%
%   Inputs:
%     repoDir (char) : The directory of the git repository to return
%                      version of.  Default: rigbox location in dat.paths.
%
%   Output:
%     v (char) : The current semantic version, e.g. '2.3.1'
%
%   Examples:
%     % Check current rigbox version
%     v = git.repoVersion;
%
%     % Check current signals version
%     repo = fullfile(getOr(dat.paths, 'rigbox'), 'signals');
%     v = git.repoVersion(repo);
%
% See also GIT.LISTVERSIONS, GIT.SWITCHVERSION

% Rigbox is the default
if nargin == 0 || isempty(repoDir)
  repoDir = getOr(dat.paths, 'rigbox');
end
[failed, out] = git.runCmd('describe --tags', 'dir', repoDir, 'echo', false);
changelog = fullfile(repoDir, 'CHANGELOG.md'); % Presumed path to changelog
% If CHANGELOG exists, print hyperlink in error
toLink = @(p) iff(file.exists(p), sprintf('<a href="%s">CHANGELOG</a>', p), p);
assert(~failed, 'Rigbox:git:repoVersion:unrecognizedGitRepo', ...
  'Failed to determine version from Git tags, please check the %s', toLink(changelog))
% Parse tag: match semVer tag with optional preceeding 'v'
v = regexp(out, '(?![$v])(\d+\.){1,3}\d+', 'match');
assert(failed ~= 128 && ~isempty(v), 'Rigbox:git:repoVersion:noTags', ...
  'Failed to determine version from Git tags, please check the %s', toLink(changelog))
% Add patch number if missing
v = iff(sum(v{1} == '.') == 1, [v{1} '.0'], v{1});
