function d = modDate(p)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if iscell(p)
  listing = cellfun(@dir, p);
else
  listing = dir(p);
end
d = [listing.datenum];

end

