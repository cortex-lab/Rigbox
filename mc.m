function m = mc
%MC Starts the MC experiment GUI in a window
%   See also EUI.MCONTROL.
% Part of Rigbox

% 2013-06 CB created

% Pull latest changes from remote
git.update();
% Perform some checks before instantiating
% NB: paths file check is performed by git.update
assert(file.exists(fullfile(getOr(dat.paths, 'globalConfig'), 'remote.mat')), ...
  'Rigbox:mc:noRemoteFile', ['No remote file found in globalConfig repository. ',...
  'Please check your paths file and setup your ''remote.mat'' file'])
f = figure('Name', 'MC',...
        'MenuBar', 'none',...
        'Toolbar', 'none',...
        'NumberTitle', 'off',...
        'Units', 'normalized',...
        'OuterPosition', [0.1 0.1 0.8 0.8]);%...
h = eui.MControl(f);

if nargout > 0
  m = h;
end

end

