%% Test 1: Flatten simple nested cell array
arr = {num2cell(1:5)};
flat = cellflat(arr);
expected = num2cell(1:5)';

assert(isequal(flat, expected), 'Failed to remove outer cell')

%% Test 2: Return cell when passed single element arrays
flat = cellflat({});
assert(iscell(flat) && isequal(flat, {}), 'Failed to return as cell')

%% Test 3: Flatten highly nested cell array
arr = {cell(2,1), {num2cell(1:5)}, {{'one'}}, {cell(1,2)}};
flat = cellflat(arr);
expected = [{[]; [];}; num2cell(1:5)'; {'one'; []; []}];

assert(isequal(flat, expected), 'Failed to flatten nested cells')

%% Test 4: Flatten cell array of Signals
net = sig.Net;
A = net.origin('A');
B = net.origin('B');
C = net.origin('C');

arr = [{A}, {{B}}, {{{C}}}];
flat = cellflat(arr);
expected = {A; B; C};

assert(isequal(flat, expected), 'Failed to return flat cell array of Signals')