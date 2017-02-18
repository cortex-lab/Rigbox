function s = structAssign(s, fields, values)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

fields = regexp(fields, '\.', 'split');

for i = 1:numel(fields)
  if iscell(values)
    s = subsasgn(s, struct('type', '.', 'subs', fields{i}), values{i});
  elseif numel(values) > 1
    s = subsasgn(s, struct('type', '.', 'subs', fields{i}), values(i));
  else
    s = subsasgn(s, struct('type', '.', 'subs', fields{i}), values);
  end
end

end