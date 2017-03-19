function value = fieldOrDefault(v, name, default)
%FIELDORDEFAULT Returns value of a field or a default if non-existent
%   V = FIELDORDEFAULT(s, name, [default]) returns the value of the field
%   'name' in 's', or if no such field exists, returns 'default'. If no
%   default is passed, [] is used.
%
%   This works on structures or class objects (in which case it is the
%   named property).
%
% Part of Burgbox

% 2013-02 CB created

if nargin < 3
  default = [];
end

if ~isempty(v) && isfield(v, name)
  value = v.(name);
else
  value = default;
end

end

