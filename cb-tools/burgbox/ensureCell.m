function [a, wrapped] = ensureCell(a)
%ENSURECELL If arg not already a cell array, wrap it in one
%   Detailed explanation goes here

if ~iscell(a)
  a = {a};
  wrapped = true;
else
  wrapped = false;
end

end

