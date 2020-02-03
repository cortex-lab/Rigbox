function [varargout] = tabulateArgs(varargin)
% TABULATEARGS Turns a bunch of cell or single arguments into rows
%   [A1,...,AN,singleArg] = tabulateArgs(A1,...,AN) returns the mixed-size
%   inputs as a cell array with any single element inputs replicated to be
%   the same number of elements as the other inputs.  All non-single inputs
%   must have the same number of elements.  Char arrays are considered to
%   be a single element.  All output args thus have the same number of
%   elements. If all inputs are single elements, they are returned
%   unchanged (i.e. not as a cell).  Also returns a flag indicating whether
%   all inputs were single elements.
%
%   Examples:
%     [name, useFlag, singleArg] = tabulateArgs({'huxley', 'cajal'}, true)
%     useFlag == {[1], [1]} % Now a cell array with equal size to `name`
%     singleArg == false % numel(name) > 1 thus not all args were singles
%
%     [name, useFlag, singleArg] = tabulateArgs('huxley', true)
%     useFlag == 1 % Unchanged
%     singleArg == true % All inputs were single elements
%
% Part of Burgbox

% 2013-03 CB created

singleArg = cellfun(@(arg) ~iscell(arg) && numel(arg) == 1 || ischar(arg), varargin);
allSingleArgs = all(singleArg);

nonSingleArgs = varargin(~singleArg);

if ~allSingleArgs
  % some arguments aren't single so every non-single arg should be the same
  % size
  sz = size(nonSingleArgs{1});
  flatfun = @(v) v(:);
  assert(all(cellfun(@(arg) all(flatfun(size(arg)) == sz(:)), nonSingleArgs)),...
    'All non-array arguments must be the same shape.');
else
  sz = [1, 1];
end

% now make all arguments the same shape, by leaving non-single ones the
% same, and replicating cell wrapped single ones to match the non-single shapes
argSet = mapToCell(@(arg, sin) iff(sin, @() repmat({arg}, sz), arg),...
  varargin, num2cell(singleArg));

varargout = argSet;
varargout{end + 1} = allSingleArgs;

end

