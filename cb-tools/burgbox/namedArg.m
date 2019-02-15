function [present, value, defIdx] = namedArg(args, name)
%NAMEDARG Returns value from name,value argument pairs
%   [present, value] = NAMEDARG(args, name) returns flag for presence and
%   value of the argument 'name' in a list potentially containing adjacent
%   (name, value) pairs.
%
% Part of Burgbox

% 2014-02 CB created

defIdx = find(cellfun(@(a) strcmpi(a, name), args), 1);
if ~isempty(defIdx)
  present = true;
  value = args{defIdx + 1};
else
  present = false;
  value = nil;
end

end

