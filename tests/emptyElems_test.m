%% Test 1: Testing a mixed cell array 
% Create an array where half of the elements should evaluate to empty
arr = {[], {}, nil, struct.empty, 3, @()nop, 1:10, {{}}};
actual = emptyElems(arr);
expected = [true(1,4) false(1,4)];

assert(isequal(actual,expected))