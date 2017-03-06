function l = filterExists(path, keepExists)
%FILE.FILTEREXISTS Returns sublist from path of files that exist
%   SUBSET = FILE.FILTEREXISTS(PATHLIST, [keepExists])
%
% Part of Burgbox

% 2013-07 CB created

if nargin < 2
  keepExists = true;
end

if keepExists
  l = path(file.exists(path));
else
	l = path(~file.exists(path));
end

end

