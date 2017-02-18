function [passed, failed] = filter(fun, A)
%fun.filter Summary of this function goes here
%   Detailed explanation goes here


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

