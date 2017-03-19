function [arr, meta] = loadMovieFrames(path, from, to, sz, arrPrec)
%loadMovieFrames Fast load specific frames

meta = [];
% load the info file if size is not provided
if nargin < 4
    s = load([path '.mat']);
    sz = s.arrSize;
    arrPrec = s.arrPrecision;

    if nargout > 1
        if isfield(s, 'meta')
            meta = s.meta;
        end
    end
end

% open the binary file
binpath = [path '.bin'];
fid = fopen(binpath);

% first compute number bytes per element
% file size in bytes is the position in bytes of the end of the file
fseek(fid, 0, 'eof'); % seek to end of file
nBytes = ftell(fid); % number of bytes in file
nBytesPerElem = nBytes/prod(sz);

% seek to first frame & compute number of bytes to retrieve up to last
% frame requested
frameSize = prod(sz(1:2));
nFrames = to - from + 1;
fseek(fid, (from - 1)*frameSize*nBytesPerElem, 'bof');
loadSize = [sz(1:2) nFrames]; % actual dimensions to load

%load the array data from binary file
try
  arr = reshape(fread(fid, prod(loadSize), ['*' arrPrec]), loadSize);
  fclose(fid);
catch ex
  fclose(fid);
  rethrow(ex);
end

end