function s = mergeStructs(varargin)
%MERGESTRUCTS Combines multiple structures into one scalar structure
%   s = MERGESTRUCTS(struct1, struct2,...)
%
%   If there are any repeated fields, the first instance of that field
%   takes precedence.  Therefore the order of the input structs affects the
%   resulting merged struct.
%
% See also CATSTRUCTS
%
% Part of Burgbox

% 2013-11 CB created

if nargin ~= 1
  % called with multiple arguments, so call instead with those args in one
  % cell array
  s = mergeStructs(varargin);
else
  cellOfStructs = varargin{1};
  fields = cellfun(@fieldnames, cellOfStructs, 'uni', false);
  fields = cat(1, fields{:});
  data = cellfun(@struct2cell, cellOfStructs, 'uni', false);
  data = cat(1, data{:});
  if verLessThan('matlab', '7.14')
    %2011b and previous the fields will always end up sorted by name
    [uniqueFields, iFields] = unique(fields, 'first');
  else
    [uniqueFields, iFields] = unique(fields, 'stable');
  end
  mergedData = data(iFields);
  s = cell2struct(mergedData, uniqueFields, 1);
end

end

