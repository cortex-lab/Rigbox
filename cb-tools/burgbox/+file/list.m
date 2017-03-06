function listing = list(path, type)
%FILE.LIST Lists the files and/or directories in a folder
%   l = FILE.LIST(PATH, TYPE) Detailed explanation goes here
%
% Part of Burgbox

% 2013-07 CB created

if nargin < 2
  type = 'all';
end

listing = dir(path);

switch lower(type)
  case 'all'
    %do nothing
  case {'dirs' 'd'}
    listing = listing([listing.isdir]);
  case {'files' 'f'}
    listing = listing(~[listing.isdir]);
  otherwise
    error('''%s'' is not a recognised type to list');
end

%remove the . (current directory) and .. (parent directory) entries
listing = setdiff({listing.name}', {'.' '..'});

end

