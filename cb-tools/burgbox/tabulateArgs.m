function [varargout] = tabulateArgs(varargin)
%TABULATEARGS Turns a bunch of cell or single arguments into rows
%
% Part of Burgbox

% 2013-03 CB created

% Check if each argument is single, criteria are:
% 1) *not* a cell array of *any* size, AND
% 2) number of elements in whatever they are is 1, UNLESS
% 3) it is a char, in which case it counts a single item (even if len > 1)
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

