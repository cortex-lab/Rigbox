function v = switchVersion(repoVer, repoDir)
% GIT.SWITCHVERSION Switch release version
%   Switch to the specified release version for the given repository.  This
%   relies on the version matching the release tag for the git repository
%
%   Inputs:
%     repoVer (char) : The semantic version to switch to.  Default: 'lastest'
%     repoDir (char) : The directory of the git repository to switch
%                      version.  Default: rigbox location in dat.paths
%
%   Output:
%     v (char) : The current (new) semantic version
%
%   Examples:
%     git.switchVersion(2.1);
%     git.switchVersion('3.0.1');
%     git.switchVersion('2');
%     git.switchVersion('prev');
%     git.switchVersion('latest');
%
% See also GIT.LISTVERSIONS, GIT.REPOVERSION

% Validate inputs
if nargin == 0, repoVer = 'latest'; end
if nargin < 2, repoDir = getOr(dat.paths, 'rigbox', pwd); end
if isnumeric(repoVer), repoVer = num2str(repoVer); end

% Get list of the available versions: the tags for this git repository
availableStr = ensureCell(git.listVersions(repoDir, false)); % list available versions
available = cellfun(@getParts, availableStr, 'UniformOutput', false); % parse
available = reshape(cell2mat(available'), [], 3);
% If no versions available, [0 0 0] returned


if strcmpi(repoVer, 'latest')
  disp('Updating to latest version')
  % Update to latest on master branch
  checkout = 'checkout origin/master';
  init = 'submodule update --init';
  pull = 'pull --recurse-submodules --strategy-option=theirs';
  cmds = {checkout, init, pull};
  % run commands in Rigbox root folder
  failed = any(git.runCmd(cmds, 'dir', repoDir, 'echo', false));
  % Check success
  assert(~failed, 'Rigbox:git:switchVersion:failedToUpdate', ...
    'Failed to update to latest version')
  % Get new repo version, if possible TODO add warning about repo version
  try v = git.repoVersion(repoDir); catch, v = ''; end
  return % We're done
elseif startsWith(repoVer, 'prev', 'IgnoreCase', true)
  % Move to previous version
  v = available(available(:,1) == max(available(:,1)), :); % major
  v = v(v(:,2) == max(v(:,2)), :); % minor
  v = v(v(:,3) == max(v(:,3)), :); % patch
else
  % Move to specific version
  [parts, precision] = getParts(repoVer);
  % Check if any exists
  v = available;
  for i = 1:3
    part = iff(i > precision, max(v(:,i)), parts(i));
    v = v(v(:,i) == part, :);
    assert(~isempty(v), 'Rigbox:git:switchVersion:versionUnknown', ....
      'version %s not available', repoVer)
  end
end

% Change version
disp(['Updating to version ' sprintf('%d.', v)])
% Checkout the tagged version
vStr = availableStr{all(v == available, 2)};
pars = {'dir', repoDir, 'echo', 0};
[failed, out] = git.runCmd(['checkout tags/version ' vStr], pars{:});
assert(~failed, 'Rigbox:git:switchVersion:failedToUpdate', ...
  'Failed to update to version %s:\n\t%s', vStr, out)
% Get new repo version, if possible TODO add warning about repo version
try 
  v = git.repoVersion(repoDir);
catch
  warning('Rigbox:git:switchVersion:versionUnknown', ...
    'failed to determine current version')
  v = '';
end
end

function [v, precision] = getParts(V)
% GETPARTS Parse semver string
%   Note: modified from verLessThan builtin
%
%   Input:
%     V (char) : The semantic version to parse, optionally starting with
%                'v'
%
%   Outputs:
%     v (numerical) : A 1x3 array of the parsed version in the form [major,
%                     minor, patch]
%     precision (int) : The number of parts to the version.  If only the
%                      major version, precision = 1; major + minor = 2, etc.
% 
V = iff(V(1) == 'v', V(2:end), V); % Remove preceeding 'v'
parts = sscanf(V, '%d.%d.%d');
precision = length(parts);
% zero-fills to 3 elements
v = zeros(1,3);
v(1:numel(parts)) = parts;
end
