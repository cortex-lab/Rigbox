function f = memoize(fun, keyfun)
%FUN.MEMOIZE Wrap a function in another that can cache results
%   F = FUN.MEMOIZE(fun, [keyfun]) returns a function that wraps calls to
%   'fun'. Each time the wrapper is called with a novel set of arguments,
%   it will call 'fun' with those arguments and save the result(s) keyed by
%   the arguments. Next time you call the wrapper with the same set of
%   arguments, it will just return the stored same result without calling
%   'fun' again.
%
%   'keyfun' optionally specifies a function that maps the set of arguments
%   to the key for storing with the cached result, for advanced use only.
%
%   This is obviously useful for a very general caching of computationally
%   expensive function calls. Code that normally uses an expensive function
%   can use the original or the wrapped version interchangably.
%
%   A simple example might be MATLAB's 'load' function:
%     mload = FUN.MEMOIZE(@load);
%     x = mload('test.mat'); % actually load the file
%     x = mload('test.mat'); % returns cached version without loading again
%   This example highlights a potential mistake. If you were to rely on the
%   no output version of 'load', in which it creates variables in your
%   workspace 'magically', the second cached call would do nothing. All the
%   wrapping function does is cache the returned args, it does not recreate
%   'side effects' that occur inside your function.
%
%   Note that since each set of arguments passed is used to compare with
%   entries in a lookup table, wrapping functions that you pass large
%   arrays might be very slow. Every element of your array will need to be
%   compared to each in the lookup table when checking the cache.
%
% Part of Burgbox

% 2013-08 CB created

argkeys = {};
outputs = {};

minargsout = min(nargout(fun), 1);

if nargin < 2
  keyfun = @identity;
end

f = @inner;

  function [varargout] = inner(varargin)
    numargsout = max(nargout, minargsout);
    argskey = keyfun(varargin);
    %search for cached matching args
    ncached = numel(argkeys);
    for i = 1:ncached
      if isequal(argkeys{i}, argskey)
        if numel(outputs{i}) >= nargout
          varargout = outputs{i}(1:numargsout);
          fprintf('memoize: using cached result at idx %i/%i\n', i, ncached);
          return
        else
          break
        end
      end
    end
    %nothing cached, call the function and save the result
    [varargout{1:numargsout}] = fun(varargin{:});
    argkeys = [{keyfun(varargin)}; argkeys];
    outputs = [{varargout}; outputs];
  end

end