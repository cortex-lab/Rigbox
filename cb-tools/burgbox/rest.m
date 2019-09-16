function s = rest(coll)
%FIRST Returns a sequence of all but the first element in a collection
%   s = REST(coll) returns a sequence of all but the first element in a
%   collection
%
% See also SEQUENCE, FIRST
% 
% Part of Burgbox

% 2013-02 CB created

if isempty(coll)
  s = nil;
else
  s = sequence(coll);
  s = rest(s);
end

end

