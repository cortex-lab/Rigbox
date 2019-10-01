% structAssign_test
% preconditions
s = struct('one', struct(...
              'two', [], ...
              'three', []), ...
           'four', struct(...
              'five', struct(...
                 'six', [])));

%% Test 1: Assign single value
i = rand;
s = structAssign(s, {'one.two', 'four.five.six'}, i);
assert(s.one.two == i && s.four.five.six == i && isempty(s.one.three))

%% Test 2: Assign numerical array
s = structAssign(s, {'one.two', 'one.three', 'four.five.six'}, 1:3);
assert(all([s.one.two s.one.three s.four.five.six] == 1:3))

%% Test 3: Assign cell array
values = num2cellstr(1:3);
s = structAssign(s, {'one.two', 'one.three', 'four.five.six'}, values);
assert(isequal({s.one.two s.one.three s.four.five.six}, values))

%% Test 4: Assign single field
s = structAssign(s, 'four.five.six', pi);
assert(s.four.five.six == pi)
