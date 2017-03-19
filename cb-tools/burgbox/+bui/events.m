function e = events(graphicsHandle)
%BUI.EVENTS Mouse event generator for graphics object
%   e = BUI.EVENTS(h) returns an mouse events generator object for the
%   graphics object with handle 'h'.
%
% Part of Burgbox

% 2013-03 CB created

e = getappdata(graphicsHandle, 'Events');
if isempty(e)
  e = bui.GraphicsObjectEvents(graphicsHandle);
end

end