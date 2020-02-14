function varargout = distribute(A)
% DISTRIBUTE Assign elements of an array to each output
%  Similar to how deal works
%
% See also DEAL
varargout = mapToCell(@identity, A);