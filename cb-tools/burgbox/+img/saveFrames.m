function saveFrames(movie, fn, progress)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


tiff = Tiff(fn, 'w');

[w, h, nFrames] = size(movie);

switch class(movie)
  %TODO: implement more cases as needed
  case 'uint16'
    bits = 16;
    format = 1;
  otherwise
    error('Unknown data type (''%s'') for infering bits per sample', class(movie));
end

tag.ImageWidth = w;
tag.ImageLength = h;
tag.SampleFormat = format;
tag.Photometric = Tiff.Photometric.MinIsBlack;
tag.BitsPerSample = bits;
tag.SamplesPerPixel = 1; %only luminance
tag.RowsPerStrip = 64;
tag.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tag.Compression = Tiff.Compression.Deflate;
tag.Software = 'MATLAB';

digitCount = 0;
for t = 1:nFrames
  fprintf([repmat('\b', 1, digitCount) '%i'], t);
  digitCount = length(num2str(t));
  if nargin > 2
    waitbar(t/nframes, progress, sprintf('Loading frame %i/%i...', t, nframes));
  end
  setTag(tiff, tag);
  write(tiff, movie(:,:,t));
  if t < nFrames
    writeDirectory(tiff);
  end
end
fprintf(repmat('\b', 1, digitCount));
close(tiff);

end

