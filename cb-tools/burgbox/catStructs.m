function s = catStructs(cellOfStructs, missingValue)
%catStructs Concatenates different structures into one structure array
%   s = catStructs(cellOfStructs, [missingValue])

% 2013-11 CB created

if nargin < 2
  %the default for setting missing values is empty, []
  missingValue = [];
end
fields = unique(cellflat(mapToCell(@fieldnames, cellOfStructs)));

  function t = valueTable(s)
    if ~isrow(s)
      s = reshape(s, 1, []);
    end
    t =  mapToCell(@(f) pick(s, f, 'cell', 'def', missingValue), fields);
    t = vertcat(t{:});
  end

values = mapToCell(@valueTable, cellOfStructs);
values = horzcat(values{:});

if numel(values) > 0
  s = cell2struct(values, fields);
else
  s = struct([]);
end

end

