function [binPath, matPath] = saveArr(path, arr, meta)
%saveArr Fast save an array to a binary file
%   [binPath, matPath] = SAVEARR(path, arr, [meta]) saves the numeric or
%   character array 'arr' as a binary file to <path>.bin for speed, with an
%   associated MAT-file to <path>.mat. Optionally, any arbritrary MATLAB
%   variable 'meta' can be saved in the MAT-file too. See also loadArr.
%
%   Note that both files are required (<path>.bin and <path>.mat) to load
%   the array back again.
%
% Part of Burgbox

% 2013-08 CB created

%create the structure to save as a MAT file
s.arrSize = size(arr);
s.arrPrecision = class(arr);
if nargin >= 3
  s.meta = meta;
end
matPath = [path '.mat'];
binPath = [path '.bin'];
save(matPath, '-struct', 's');
%save the array as a binary file for speed
fid = fopen(binPath, 'w');
try
  fwrite(fid, arr, s.arrPrecision);
  fclose(fid);
catch ex
  fclose(fid);
  rethrow(ex);
end

end

