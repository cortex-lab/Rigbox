function [present, value, idx] = namedArg(args, name)
%NAMEDARG Returns value from name,value argument pairs
%   [present, value, idx] = NAMEDARG(args, name) returns flag for presence
%   and value of the argument 'name' in a list potentially containing
%   adjacent (name, value) pairs.  Also returns the index of 'name'.
%
% Part of Burgbox

% 2014-02 CB created

idx = find(cellfun(@(a) strcmpi(a, name), args), 1);
if ~isempty(idx)
  present = true;
  value = args{idx + 1};
else
  present = false;
  value = nil;
end

end