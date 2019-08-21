%% Test 1: predicate evaluation
% Test that iff returns the correct consequent
x = 0;
assert(iff(x > 0, false, true), 'Failed to return correct consequent')

x = 1;
assert(~iff(x > 0, false, true), 'Failed to return correct consequent')

%% Test 2: predicate function
% Test behaviour when predicate is a function handle
f = fun.always(false);
assert(iff(f, false, true), 'Failed to evaluate function predicate')

%% Test 3: function handle evaluation
% Test the evaluation of function handles by iff
y = 12;
pred = @(x)iff(x, @()[y y], @(){y});

assert(isequal(pred(true), [12 12]), 'Failed to evaluate consequent')
assert(isequal(pred(false), {12}), 'Failed to evaluate alternate')

%% Test 4: mixed statements
% Test statement with mixed values and function handles
y = 34;
pred = @(x)iff(x, @()y^2, y^2);

assert(pred(y > 30) == 1156 && pred(y < 35) == 1156)

%% Test 5: evaluating consequent with no output args
% Test evalution when no outputs assigned
count = 5;
m = containers.Map(1:count, num2cell(rand(1,count)));
cond = @(pred) iff(pred, @() m.remove(count), @() nop);

cond(false);
assert(m.length == count, 'Failed to evaluate correct consequent')

cond(true);
assert(m.length == count-1, 'Failed to evaluate correct consequent')
