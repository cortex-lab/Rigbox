function [C1, varargout] = mapToCell(f, varargin)
%MAPTOCELL Like cellfun and arrayfun, but always returns a cell array
%   [C1, ...] = MAPTOCELL(FUN, A1, ...) applies the function FUN to
%   each element of the variable number of arrays A1, A2, etc, passed in. The
%   outputs of FUN are used to build up cell arrays for each output.
%
%   Unlike MATLAB's cellfun and arrayfun, MAPTOCELL(..) can take a mixture
%   of standard and cell arrays, and will always output a cell array (which
%   for cellfun and array requires the 'UniformOutput' = false flag).
%
% Part of Burgbox

% 2013-01 CB created

nelems = numel(varargin{1});
% ensure all input array arguments have the same size (todo: check shape)
assert(all(nelems == cellfun(@numel, varargin)),...
  'Not all arrays have the same number of elements');
inSize = size(varargin{1});
nout = max(nargout, min(nargout(f), 1));

% function that converts non-cell arrays to cell arrays
ensureCell = @(a) iff(~iscell(a), @() num2cell(a), a);

% make sure all input arguments are cell arrays...
varargin = cellfun(ensureCell, varargin, 'UniformOutput', false);

% ...so now we can concatenate them and treat them as cols in a table and
% read them row-wise
catarrays = cat(ndims(varargin{1}), varargin{:});
linarrays = reshape(catarrays, nelems, numel(varargin));

fout = cell(nout, 1);
arg = cell(nout, nelems);

% iterate over each element of input array(s), apply f, and save each (variable
% number of) output.
for i = 1:nelems
  [fout{1:nout}] = f(linarrays{i,:});
  arg(1:nout,i) = fout(1:nout);
end

varargout = cell(nargout - 1, 1);
for i = 1:nout
  if i == 1
    C1 = reshape(arg(i,:), inSize);
  else
    varargout{i - 1} = reshape(arg(i,:), inSize);
  end
end

end

