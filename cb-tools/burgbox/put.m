function m = put(m, name, value)
%PUT Does the same as MATLAB's setfield but more concisely named
%   TODO Document `put` function

if isempty(name)
  m = value;
else
  split = regexp(name, '^(?<first>\w+)\.?(?<rest>.*)', 'names');

  if isa(m, 'containers.Map')
    m(split.first) = put(m(split.first), split.rest, value);
  elseif isnumeric(m) && ishandle(m)
    %TODO: Make this correctly recursive, ala
    % set(recur_get, recur_name, value)
    set(m, name, value);
  else
    m.(split.first) = put(m.(split.first), split.rest, value);
  end
end

end

