function cdata = readIcon(filename)
%IMG.ICONREAD read an image file and convert it to CData for a HG icon.
%
% CDATA=ICONREAD(filename)
%   Read an image file and convert it to CData with automatic transparency
%   handling. If the image has transparency data, PNG files sometimes do,
%   the transparency data is used. If the image has no CData, the top left
%   pixel is treated as the transparent color.
%
% Part of Burgbox

% 2014-08 CB created

[cdata, map, alpha] = imread(filename);
if isempty(cdata)
  return;
end

if isempty(map)
  % need to use doubles because nan's only work as doubles
  cdata = double(cdata);
  cdata = cdata/255;
else
  cdata = ind2rgb(cdata,map);
end


% process alpha data
r = cdata(:,:,1);
r(alpha == 0) = NaN;
g = cdata(:,:,2);
g(alpha == 0) = NaN;
b = cdata(:,:,3);
b(alpha == 0) = NaN;
cdata = cat(3,r,g,b);
end