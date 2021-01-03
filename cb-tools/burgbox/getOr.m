function v = getOr(s, field, default)
% GETOR Returns the structure field or a default if it doesn't exist
%   v = getOr(s, field, [default]) returns either the named field of a
%   structure or a default if the field does not exist. If default is not
%   specified it defaults to []. If a cell array of fields if provided, it
%   returned the value of the first field that exists or the default value.
%
%   Inputs:
%     s (struct) : a scalar structure whose field to query
%     field (char|cellstr|string) : the field name(s) to query
%     default (*) : the default value to return no field(s) exist (default:
%       [])
%
%   Output:
%     v (*) : the struct's field value, or default if field isn't present.
%       If array of fields given, the value of the first present field is
%       returned
%
%   Examples:
%     s = struct('a', 1, 'b', 2, 'c', []);
%     v = getOr(s, 'a') % 1
%     v = getOr(s, "d") % []
%     v = getOr(s, 'e', 5) % 5
%     v = getOr(s, {'d', 'b'}) % 2
%     v = getOr(s, 'c', 4) % []
%
%   NB: You can also retrieve fields using the function `pick`.  Below are
%   some key differences between the two: 
%   - getOr only works on scalar structs, whereas pick can select from
%   non-scalar structs and from class properties, as well as index other
%   input types. 
%   - If an array of fields is given, getOr will return only the first
%   whereas pick returns the values (or default) for all of them. 
%   - getOr will return the value of a field so long as it exists, even if
%   it is empty.  Pick will return the default if the field's value is
%   empty.
%
% See also PICK, GETFIELD

if nargin < 3
  default = [];
end
field = convertCharsToStrings(field); % catch cellstr inputs

fieldExists = isfield(s, field);
if any(fieldExists)
  if ~isStringScalar(field)
    v = s.(field{find(fieldExists, 1)});
  else
    v = s.(field);
  end
else
  v = default;
end

end

