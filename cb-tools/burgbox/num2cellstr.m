function cstr = num2cellstr(A)
%NUM2CELLSTR Convert an array of numbers to a cell array of strings
%   cstr = NUM2CELLSTR(a) converts the numeric array 'a' to a cell array of
%   the corresponding formated number strings.
%
% Part of Burgbox

% 2013-02 CB created

cstr = reshape(regexp(sprintf('%g#', A),'[0-9\(-|+)\.e]*', 'match'), size(A));
end