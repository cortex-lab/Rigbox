function l = stackLabel(stack)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

if numel(stack) > 1
  l = mapToCell(@img.stackLabel, stack);
  return
end

  function s = format(format, field)
    if isfield(stack.Info, field)
      val = stack.Info.(field);
      if iscellstr(val)
        val = mkStr(val, ', ');
      end
      s = {sprintf(format, val)};
    else
      s = {};
    end
  end

fields = {'title' 'expRef' 'zoomFactor'};
formats = {'%s' '[%s]' 'X%g'};

parts = mapToCell(@format, formats, fields);
parts = horzcat(parts{:});

tagMap = containers.Map(...
  {'registered' 'fractional change' 'cell filtered'},...
  {'reg' 'fc' 'cell'});
mapfun = @(k) iff(tagMap.isKey(k), @() upper(tagMap(k)), upper(k));
parts = [parts mapToCell(mapfun, stack.Info.tags)];

l = strJoin(parts, ' ');

if isempty(l)
  l = 'Untitled';
end

end

