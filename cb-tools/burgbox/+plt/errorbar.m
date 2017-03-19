function h = errorbar(axh, x, y, yL, yU, varargin)
%PLT.ERRORBAR Like MATLAB's errorbar but specify actual EB co-ordinates
%   H = PLT.ERRORBAR(AXH, X, Y, YL, YU, ...)
%
%   Differences to MATLAB's errorbar, this:
%   * takes the actual y coordinates of the errorbar top and bottom, rather
%   than the offset from y coordinates
%   * always takes the axes as the first parameter
%   * if there is no data to plot, then it won't throw a wobbly, it just
%   wont plot anything
%
% Part of Burgbox

% 2013-10 CB created

if numel(x) > 0
  h = errorbar(x, y, y - yL, y - yU, varargin{:}, 'Parent', axh);
else
  h = [];
end

end

