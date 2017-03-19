function out = apply(f, varargin)
%UNTITLED6 TODO
%   Detailed explanation goes here

if iscell(f)
  out = mapToCell(@(f) fun.apply(f, varargin{:}), f);
elseif isa(f, 'function_handle')
  if nargout == 0
    f(varargin{:});
  else
    out = f(varargin{:});
  end
else
  out = f;
end

end

