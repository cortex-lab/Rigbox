function switchVersion(repoVer, repoDir)
% TODO Add test
% TODO Document
if nargin == 0, repoVer = 'latest'; end
if nargin < 2, repoDir = getOr(dat.paths, 'rigbox', pwd); end
if isnumeric(repoVer), repoVer = num2str(repoVer); end
availableStr = ensureCell(git.listVersions(repoDir, false)); % list available versions
available = cellfun(@getParts, availableStr, 'UniformOutput', false); % parse
available = reshape(cell2mat(available'), [], 3);
% If no versions available, [0 0 0] returned
if strcmpi(repoVer, 'latest')
  disp('Updating to latest version')
  % TODO Return latest version somehow
  echo('git.update', 'off')
  mess = onCleanup(@() echo('git.update', 'on'));
%   exitCode = git.update(0); % TODO Uncomment
  if exitCode == 2
    % TODO Code not pulled
  else
    assert(exitCode == 0, 'Rigbox:git:switchVersion:failedToUpdate', ...
      'Failed to update to latest version')
  end
  return % We're done
elseif startsWith(repoVer, 'prev', 'IgnoreCase', true)
  v = available(available(:,1) == max(available(:,1)), :); % major
  v = v(v(:,2) == max(v(:,2)), :); % minor
  v = v(v(:,3) == max(v(:,3)), :); % patch
else
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
% TODO finish
vStr = availableStr{all(v == available, 2)};
pars = {'dir', repoDir, 'echo', 0};
% failed = git.runCmd(['checkout tags/version ' vStr], pars{:}) % TODO Uncomment
assert(~failed, 'Rigbox:git:switchVersion:failedToUpdate', ...
  'Failed to update to version %s', sprintf('%d.', v))
end

function [v, precision] = getParts(V)
% GETPARTS Parse semver string
%   Note: modified from verLessThan builtin
% 
V = iff(V(1) == 'v', V(2:end), V); % Remove preceeding 'v'
parts = sscanf(V, '%d.%d.%d');
precision = length(parts);
% zero-fills to 3 elements
v = zeros(1,3);
v(1:numel(parts)) = parts;
end
