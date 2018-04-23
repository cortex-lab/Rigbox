function passed = rmEmpty(A)
%RMEMPTY Returns input array with empty elements removed
%   Simply removes all empty elements of the input array and returns it
%
% See also FUN.EMPTYSEQ, EMPTYELEMS, FUN.FILTER
% 2018 MW created


if iscell(A)
  empty = cellfun('isempty', A);
else
  empty = arrayfun(@isempty, A);
end

passed = A(~empty);