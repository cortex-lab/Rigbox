function s = structAssign(s, fields, values)
%STRUCTASSIGN Deep subassign field values
%   Assign values to nested struct fields.
%
%   Inputs:
%     s - struct or object to assign value(s) to 
%     fields - full dot syntax location of field or cell array of fields to
%       assign to.
%     values - either a single value to assign or a numerical/cell array
%       the same length as fields.
%
%   Output:
%     s - struct with values assigned.
%
%   Examples:
%     s = struct('one', struct('two', []));
%     s = structAssign(s, 'one.two', 4)
%     disp(one.two) % 4

fields = regexp(ensureCell(fields), '\.', 'split');

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