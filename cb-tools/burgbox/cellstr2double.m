function X = cellstr2double(C)
%CELLSTR2DOUBLE Faster version of MATLAB's str2double
%   X = CELLSTR2DOUBLE(C) converts string elements of 'C' from real scalar
%   values to an array of correpsonding numbers.
%
% Does a very similar job to MATLAB's str2double but much, much faster for
% large cell arrays.
%
% Part of Burgbox

% 2014-01 CB created

C = ensureCell(C);
X = reshape(sscanf(sprintf('%s#', C{:}), '%g#'), size(C)) ;

end