%mergeStructs test

% preconditions: set up some scalar structs
A = struct('a', 1:5, 'b', 'HU', 'c', []);
B = struct('b', 76, 'd', magic(6));
C = struct('e', 1);

% First test merge of unique fields
s = mergeStructs(B,C);
assert(isequal(fieldnames(s), unique([fieldnames(B); fieldnames(C)])), ...
  'Not all fields were merged') % Check fields
% FETCH returns the value of field f, looking first in struct x and if not
% there then struct y
fetch = @(f,x,y)iff(isfield(x,f), @()x.(f), @()y.(f));
correct = cellfun(@(f)isequal(s.(f), fetch(f,B,C)), fieldnames(s));
assert(all(correct), 'Unexpected field values') % Check values

% Test order precedence
ab = mergeStructs(A,B);
ba = mergeStructs(B,A);
correct = [cellfun(@(f)isequal(ab.(f), fetch(f,A,B)), fieldnames(ab)); ...
  cellfun(@(f)isequal(ba.(f), fetch(f,B,A)), fieldnames(ba))];
assert(all(correct), 'Unexpected field precedence') % Check values

% Test cell inputs
assert(isequal(mergeStructs({A,C}), mergeStructs(A,C)), ...
  'Variable behaviour on cell input')
