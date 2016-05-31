function m = mc
%MC Starts the MC experiment GUI in a window
%   See also EUI.MCONTROL.
% Part of Rigbox

% 2013-06 CB created

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

