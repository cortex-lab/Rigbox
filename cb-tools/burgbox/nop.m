function [varargout] = nop(varargin)
%nop Does nothing (but can take any number of inputs)
%
% Part of Burgbox

% 2013-09 CB created

if nargout > 0
  [varargout{1:nargout}] = deal([]);
end

end