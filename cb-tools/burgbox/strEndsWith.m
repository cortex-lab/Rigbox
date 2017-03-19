function b = strEndsWith(s, endings)
%STRENDSWITH Summary of this function goes here
%   Detailed explanation goes here

if iscell(endings) % multiple possible endings to check
  rexp = regexptranslate('escape', endings);
  rexp = strJoin(rexp, '|');
  rexp = sprintf('(%s)$', rexp);
  b = ~strcmp(regexp(s, rexp, 'match', 'once'), '');
else % single ending to check
  ending = endings;
  if iscellstr(s) % multiple strings to check
    b = cellfun(@single, s);
  else % single string to check
    b = single(s);
  end
end

  function b = single(str)
    endi = strfind(str, ending);
    b = ~isempty(endi) && (endi + numel(ending) - 1) == numel(str);
  end

end

