function [arr, meta] = loadArr(path)
%loadArr Fast load an array from a binary file
%   [arr, meta] = LOADARR(path) loads the numeric or character array saved
%   in <path>.bin and any associated meta data previously saved with it
%   (from <path>.mat). See also saveArr.
%
%   Note that both files are required (<path>.bin and <path>.mat) to load
%   the array.
%
% Part of Burgbox

% 2013-08 CB created

pathInfo = path;

% Check whether file exists
if ~exist([path '.mat'], 'file')
    % if not, check whether file name contains 'channel...'
    [dirPath, name] = fileparts(path);
    if ~isempty(strfind(name, '_channel'))
        % if so, delete '_channel...' from file name and check whether new
        % file exists
        newName = regexprep(name, '_channel\d*', '');
        if ~exist(fullfile(dirPath, [newName '.mat']), 'file')
            display('File does not exist.')
            
            arr = [];
            meta = [];
            return
        end
        pathInfo = fullfile(dirPath, newName);
    end
end

% load the info file
s = load([pathInfo '.mat']);

if nargout > 1
  if isfield(s, 'meta')
    meta = s.meta;
  else
    meta = [];
  end
end

%load the array data from binary file
binpath = [path '.bin'];
fid = fopen(binpath);
try
  arr = reshape(fread(fid, inf, ['*' s.arrPrecision]), s.arrSize);
  fclose(fid);
catch ex
  fclose(fid);
  rethrow(ex);
end

end