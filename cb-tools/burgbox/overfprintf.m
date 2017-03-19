function n = overfprintf(n, varargin)
%OVERFPRINTF fprintf over the top of previous text
%   n = OVERFPRINTF(n, formatspec, a1, ..., an)
%
%   n = OVERFPRINTF(n, fileID, formatspec, a1, ..., an)
%
% Part of Burgbox

% 2013-07 CB created

if nargin == 1
  varargin(1) = {''};
end

if isfloat(varargin{1}) && isscalar(varargin{1})
  fileID = varargin{1};
  varargin = varargin(2:end);
else
  fileID = 1; %default file ID is the standard output
end

n = fprintf(fileID, [repmat('\b', 1, n) varargin{1}], varargin{2:end}) - n;


end

