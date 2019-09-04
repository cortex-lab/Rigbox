function d = modDate(p)
%FILE.MODDATE Returns date modified of files and folders
%  Returns datenums of files and folders contained in input path(s), p
%  Input:
%    p (char or cellstr) - One or more paths to a file or folder
%  Output:
%    d (array or cell) - 1xn array or cellarray of datenums
%

if iscell(p)
  d = mapToCell(@file.modDate, p);
else
  listing = dir(p);
  d = [listing.datenum];
end

end

