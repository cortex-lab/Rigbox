function [axes, container] = paddedAxes(parent, left, bottom, right, top)
%BUI.PADDEDAXES Creates an axes control with padding
%   Detailed explanation goes here
%
% Part of Burgbox

% 2013-01 CB created

if nargin < 5
  top = 10;
end

if nargin < 4 || isempty(right)
  right = 10;
end

if nargin < 3 || isempty(bottom)
  bottom = 50;
end

if nargin < 2 || isempty(left)
  left = 50;
end

container = uiextras.Grid('Parent', parent);
createEmpty = @(n) arrayfun(...
  @(~) uiextras.Empty('Parent', container, 'Visible', 'off'), 1:n, 'uni', false); 
%3 empties in left column
createEmpty(3);
%one empty above the axes
createEmpty(1);
%now the axes
axes = bui.Axes(container);
axes.ActivePositionProperty = 'position';
%now an empty below the axes
createEmpty(1);
%finally 3 empties in right column
createEmpty(3);

container.ColumnSizes = [left -1 right];
container.RowSizes = [top -1 bottom];

end

