function varargout = varName(varargin)
%VARNAME Returns the name(s) of the variable(s)
%   [N1,...] = VARNAME(V1,...)

varargout = cell(size(varargin));

for i = 1:nargin
  varargout{i} = inputname(i);
end

end

