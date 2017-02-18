function b = exists(path)
%FILE.EXISTS Report whether file(s) exist
%   b = FILE.EXISTS(path) return true if the file or directory 'path'
%   exists, false otherwise. If 'path' is a cell array, it will return a
%   logical array of the same size as 'path', with corresponding elements
%   indicating the existence of each path.
%
% Part of Burgbox

% 2013-07 CB created

existfun = @(p) isdir(p) || numel(dir(p)) == 1;

if iscellstr(path)
  b = cellfun(existfun, path);
else
  b = existfun(path);
end

end

