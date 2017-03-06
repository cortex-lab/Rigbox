function b = strStartsWith(s, beginnings)
%STRSTARTSWITH Summary of this function goes here
%   Detailed explanation goes here

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