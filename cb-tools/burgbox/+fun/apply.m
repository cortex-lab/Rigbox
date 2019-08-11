function out = apply(f, varargin)
% FUN.APPLY Apply a varaible number of inputs to one or more functions
%   `f` may by a function handle, cell array of function handles or simply
%   a value to be returned.
% 
%   Examples:
%     fun.apply(@(a) a*2, 1, 2, 3) % [2 4 6]
%     fun.apply({@(a)a*2, @(a)a+1}, 1, 2, 3) % {[2 4 6], [2 3 4]}
%     fun.apply(4, 2, 1) % 4
%
% See also FUN.APPLYFORCE
%
% Part of Burgbox


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

