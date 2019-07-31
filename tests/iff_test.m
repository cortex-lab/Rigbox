%% Test 1: predicate evaluation
% Test that iff returns the correct consequent
x = 0;
assert(iff(x > 0, false, true), 'Failed to return correct consequent')

x = 1;
assert(~iff(x > 0, false, true), 'Failed to return correct consequent')

%% Test 2: function handle evaluation
% Test the evaluation of function handles by iff
y = 12;
pred = @(x)iff(x, @()[y y], @(){y});

assert(isequal(pred(true), [12 12]), 'Failed to evaluate consequent')
assert(isequal(pred(false), {12}), 'Failed to evaluate alternate')

%% Test 3: mixed statements
% Test statement with mixed values and function handles
y = 34;
pred = @(x)iff(x, @()y^2, y^2);

assert(pred(y > 30) == 1156 && pred(y < 35) == 1156)