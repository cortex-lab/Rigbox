function b = strStartsWith(s, beginnings)
%STRSTARTSWITH True if text starts with pattern
%   Returns true is one or more of `beginnings` are found in `s`.  Both
%   inputs may be a single char array or cellstr.
%
%   Note that MATLAB implemented a similar function, STARTSWITH, in R2016b.

if iscell(beginnings) % multiple beginnings endings to check
  rexp = regexptranslate('escape', beginnings);
  rexp = sprintf('^(%s)', strJoin(rexp, '|'));
  b = ~strcmp(regexp(s, rexp, 'match', 'once'), '');
else % single beginning to check
  beginning = beginnings;
  if iscellstr(s) % multiple strings to check
    b = cellfun(@single, s);
  else % single string to check
    b = single(s);
  end
end

  function b = single(str)
    begi = strfind(str, beginning);
    b = ~isempty(begi) && begi == 1;
  end


end