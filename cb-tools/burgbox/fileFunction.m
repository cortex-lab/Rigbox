function f = fileFunction(path, mfile)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if nargin < 2
  [path, mfile] = fileparts(path);
else
  [~, mfile] = fileparts(mfile);
end

f = @call;

  function varargout = call(varargin)
    addpath(path);
    try
      f = str2func(['@' mfile]);
      [varargout{1:nargout}] = f(varargin{:});
    catch ex
      rmpath(path);
      rethrow(ex);
    end
    rmpath(path);
  end

end

