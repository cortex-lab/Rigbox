function [passed, failed] = filter(fun, A)
%FUN.FILTER Filter elements of an array with a function
%   Filter the elements of array `A` by applying function `fun` on its
%   elements.
%
%   Inputs: 
%     fun (function_handle) - A function that returns a single boolean.
%     A (array) - An array to be filtered.  May be a cell array or any
%       other kind that may be operated on by arrayfun.
%
%   Outputs:
%     passed (array) - The elements for which `fun` returned true.
%     failed (array) - The elements for which `fun` returned false.
%
% Part of Burgbox

if iscell(A)
  indicator = cellfun(fun, A);
else
  indicator = arrayfun(fun, A);
end

passed = A(indicator);

if nargout > 1
  failed = A(~indicator);
end

end

