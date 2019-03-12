function rarr = repelems(arr, n)
%REPELEMS Repeats each elements a different number of times
%   rarr = REPELEMS(arr, n) repeats each element of 'arr' a number of times
%   specified by the corresponding element of 'n'. e.g.
%     REPELEMS([0 1 2], [2 1 3]) % returns [0 0 1 2 2 2]
%
% See also exp.Parameters/toConditionServer
%
% Part of Burgbox

% 2013-06 CB created

present = n > 0;
n = n(present);
arr = arr(present);

ncum = cumsum(n(:));
idx = zeros(ncum(end), 1);
idx([1; ncum(1:end-1) + 1]) = 1;
idx = cumsum(idx);

rarr = arr(idx);

end

