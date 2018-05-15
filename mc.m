function m = mc
%MC Starts the MC experiment GUI in a window
%   See also EUI.MCONTROL.
% Part of Rigbox

% 2013-06 CB created
warning('off', 'Rigbox:setup:toolboxRequired')
warning('off', 'Rigbox:setup:javaNotSetup')
warning('off', 'Rigbox:setup:libraryRequired')
warning('off', 'toStr:isstruct:Unfinished')
addRigboxPaths(false)
f = figure('Name', 'MC',...
        'MenuBar', 'none',...
        'Toolbar', 'none',...
        'NumberTitle', 'off',...
        'Units', 'normalized',...
        'OuterPosition', [0.1 0.1 0.8 0.8],...
        'CloseRequestFcn', @(~,~) fun.applyForce({...
        @()quitServer,...
        @closereq}));
h = eui.MControl(f);

if nargout > 0
  m = h;
end

%% Create dummer rig object to communicate with

% srv.expServerDummy

end

function quitServer()
global running
running = false;
end
