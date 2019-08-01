%% Test 1: returns empty
% Test that nop returns empty array
assert(isequal(nop(1:5), []), 'Failed to return expeted output')

%% Test 2: assigns correct number of outputs
% Test assigning to multiple vars
[a, b, c, d, e] = nop;

assert(isequal([a, b, c, d, e], []), 'Failed to assign multiple outputs')
