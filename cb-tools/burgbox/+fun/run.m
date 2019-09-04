function out = run(varargin)
%FUN.RUN Returns a single function that executes multiple functions
%   f = FUN.RUN(f1,...) returns a single function 'f' that executes
%   multiple functions, f1 etc, in argument order. Any arguments passed to
%   f will be ignored.
%
% Part of Burgbox

% 2013-05 CB created

if islogical(varargin{1})
  runnow = varargin{1};
  funs = varargin(2:end);
else
  runnow = false;
  funs = varargin;
end

f = @(varargin) cellfun(@(f) f(), funs, 'UniformOutput', false);

if runnow
  f();
  out = [];
else
  out = f;
end

end