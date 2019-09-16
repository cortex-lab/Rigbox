function strarr = cellsprintf(formatSpec, varargin)
%CELLSPRINTF Generate formatted cell string array from cell array inputs
%   strArr = CELLSPRINTF(FORMATESPEC, C1, ...)
%
% Part of Burgbox

strarr = mapToCell(@(varargin) sprintf(formatSpec, varargin{:}), varargin{:});

end