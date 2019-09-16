function [varargout] = map(f, varargin)
%FUN.MAP Like cellfun and arrayfun, but always returns a cell array
%   [C1, ...] = fun.map(FUN, A1, ...) applies the function FUN to
%   each element of the variable number of arrays A1, A2, etc, passed in. The
%   outputs of FUN are used to build up cell arrays for each output.
%
%   Unlike MATLAB's cellfun and arrayfun, MAPTOCELL(..) can take a mixture
%   of standard and cell arrays, and will always output a cell array (which
%   for cellfun and array requires the 'UniformOutput' = false flag).
%
% Part of Burgbox

nout = max(nargout, min(nargout(f), 1));

[varargout{1:nout}] = mapToCell(f, varargin{:});

end

