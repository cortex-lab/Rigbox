function str = mat2DStrTo1D(str)
%mat2DStrTo1D Convert a 2D string array to a newlined 1D
%   Takes a MATLAB two dimensional string, treats each row as a line, and
%   turns it into a 1D string with each line separated by newline
%   characters. White space enclosing each line is stripped.
%
% Part of Burgbox

% 2013-09 CB created

if iscellstr(str)
  str = mapToCellArray(@matStr2Lines, str);
else
  str = strJoin(deblank(num2cell(str, 2)), '\n');
end

end