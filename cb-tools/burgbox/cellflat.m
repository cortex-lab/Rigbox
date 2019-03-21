function flat = cellflat(c)
%cellflat Eliminates nesting from nested cell arrays
%   flat = cellflat(C) returns all elements from cell array `C`, including
%   those nested within further cell arrays (etc) in a single flat cell
%   array.  NB: Cells always returned as a column array.
%
% Part of Burgbox

% 2013-02 CB created

flat = {};

for i = 1:numel(c)
  elem = c{i};
  if iscell(elem)
    elem = cellflat(elem); % recursive call
  end
  if isempty(elem)
    elem = {elem};
  end
  flat = [flat; ensureCell(elem)];
end

end

