function b = strEndsWith(s, endings)
%STRENDSWITH True if text ends with pattern 
%   Returns true is one or more of `endings` are found in `s`.  Both inputs
%   may be a single char array or cellstr.
%
%   Note that MATLAB implemented a similar function, ENDSWITH, in R2016b.

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

