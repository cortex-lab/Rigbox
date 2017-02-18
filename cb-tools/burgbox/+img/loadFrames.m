function [frames, headers] = loadFrames(tiff, firstIdx, lastIdx, stride, progress)
%img.loadFrames Loads the frames of a Tiff file into an array (Y,X,T)
%
%   MOVIE = img.loadFrames(TIFF, [FIRST], [LAST], [STRIDE], [PROGRESS]) loads
%   frames from the Tiff file specified by TIFF, which should be a filename
%   or an already open Tiff object. Optionallly FIRST, LAST and STRIDE
%   specify the range of frame indices to load, and PROGRESS, a handle to a
%   MATLAB progress dialog.
%
% Part of Burgbox

% 2015-11 CB Updated to work without pre-calculating number of frames

initChars = overfprintf(0, 'Loading TIFF frame ');
warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning');

warningsBackOn = onCleanup(...
  @() warning('on', 'MATLAB:imagesci:tiffmexutils:libtiffWarning'));

if ischar(tiff)
  tiff = Tiff(tiff, 'r');
  closeTiff = onCleanup(@() close(tiff));
end

if nargin < 2
  firstIdx = 1;
end
if nargin < 3 || isempty(lastIdx)
  lastIdx = [];
end
if nargin < 4
  stride = 1;
end
if nargout > 1
  loadHeaders = true;
else
  loadHeaders = false;
end

imgSize = [tiff.getTag('ImageWidth') tiff.getTag('ImageLength')];
dataClass = class(read(tiff));
nFrames = ceil((lastIdx - firstIdx + 1)/stride);
if isempty(nFrames)
  initArrFrames = 1000;
else
  initArrFrames = nFrames;
end
frames = zeros([imgSize initArrFrames], dataClass);
w = whos('frames');
bytesPerFrame = w.bytes/initArrFrames;
if loadHeaders
  headers = cell(1, 1000);
end

nMsgChars = 0;
setDirectory(tiff, firstIdx); % seek to the first desired frame

n = 0;
more = true;
tic;
while more
  n = n + 1;
  if mod(n, 100) == 0
    MBPerSec = n*bytesPerFrame/(1024*1024*toc);
    if isempty(nFrames)
      nMsgChars = overfprintf(nMsgChars, '%i (%.1f MB/s)', n, MBPerSec);
    else
      nMsgChars = overfprintf(nMsgChars, '%i/%i (%.1f MB/s)', n, nFrames, MBPerSec);
    end
  end
  if nargin > 4
    waitbar(n/nframes, progress, sprintf('Loading frame %i/%i...', n, nFrames));
  end
  frame = read(tiff);
  if size(frames, 3) < n
    frames = cat(3, frames, zeros(size(frames), dataClass));
    if loadHeaders
      headers = cat(2, headers, size(headers));
    end
  end
  frames(:,:,n) = frame;
  if loadHeaders % load the frame headers if desired
    headers{n} = getTag(tiff, 'ImageDescription');
  end
  if any(n == nFrames) % break if we got all the frames desired
    more = false;
    break
  end
  for i = 1:stride % seek forward by stride
    if lastDirectory(tiff)
      if isempty(nFrames) % all available frames loaded, no minimum req
        more = false;
        break
      else % all available frames loaded, but haven't reached nFrames
        error('Could only load %i of %i frames', n, nFrames);
      end
    end
    nextDirectory(tiff);
  end
end
frames = frames(:,:,1:n);
if loadHeaders
  headers = headers(1:n);
end

overfprintf(initChars + nMsgChars, '');

end