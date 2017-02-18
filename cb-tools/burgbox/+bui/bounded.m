function b = bounded(p, rect)
%BUI.BOUNDED Indicates whether point bounded by rectangle
%   b = BUI.BOUNDED(p, rect) returns true if point, 'p' is bounded by
%   rectangle 'rect', where rect is a vector of the form
%   [left bottom width height] as used in e.g. the MATLAB graphics object
%   Position property.
%
% Part of Burgbox

% 2013-01 CB created

b = (p(1) >= rect(1)) && (p(1) < rect(1) + rect(3)) && ...
  (p(2) >= rect(2)) && (p(2) < rect(2) + rect(4));

