function listing = list(path, type)
%FILE.LIST Lists the files and/or directories in folder(s)
%   l = FILE.LIST(PATH, TYPE)
%   Lists the files and/or folders of a given path (or cell array thereof).
%   The optional type input may be 'all' (default), 'dirs' or 'files'.
%
% Part of Burgbox

% 2013-07 CB created
% 2019-06 MW added cellstr compatibility

narginchk(1,2)
path = convertStringsToChars(path);
if nargin < 2
  type = 'all';
end

if iscell(path)
  listing = mapToCell(@(p)file.list(p, type), path);
  return
else
  listing = dir(path);
end

switch lower(type)
  case 'all'
    %do nothing
  case {'dirs' 'd'}
    listing = listing([listing.isdir]);
  case {'files' 'f'}
    listing = listing(~[listing.isdir]);
  otherwise
    error('''%s'' is not a recognised type to list', type);
end

%remove the . (current directory) and .. (parent directory) entries
listing = setdiff({listing.name}', {'.' '..'});

end