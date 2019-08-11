function elem = first(coll)
%FIRST Returns the first element of any collection, or 'nil' if empty
%   elem = FIRST(coll) returns the first element of any vector, array, or
%   collection. If 'coll' is empty, nil is returned (see nil function).
%
%   This aids one-liners (e.g. if a function returns an array, and you want
%   only the first element, all in one line), and generality (get the first
%   element of a standard array or cell with the same syntax, instead of
%   (1) or {1}).
%
% See also SEQUENCE, REST
%
% Part of Burgbox

% 2013-02 CB created

if isNil(coll)
  elem = coll;
elseif isempty(coll)
  elem = nil;
elseif iscell(coll)
  elem = coll{1};
else
  elem = coll(1);
end

end

