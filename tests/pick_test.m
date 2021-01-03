% pick test
% Preconditions:
m = containers.Map({'number', 'word'}, {1, 'apple'});
s2 = struct('a', 30, 'b', 'hi', 'c', 'go'); % scalar struct
s = struct; % A non-scalar struct
for i = 1:6
  s(i).char = datestr(now-i);
  s(i).num = 100+i;
  s(i).c = i;
end

%% Test 1: Numeric indicies
% For arrays, numeric keys mean indices.  Test struct, numeric, string,
% char and cell array types
assert(all(pick(2:2:10, [1 2 4]) == [2 4 8]), ...
  'Failed to index from numrical array')
assert(isequal(pick(s, [1 2 4]), s([1 2 4])), ...
  'Failed to index from non-scalar structure')
assert(all(pick(num2cell(2:2:10), [1 2 5]) == [2 4 10]), ...
  'Failed to index from cell array')
assert(all(pick('abcde', [1 2 5]) == 'abe'), ...
  'Failed to index from char array')
assert(all(pick(["a","b","c","d","e"], [1 2 5]) == ["a","b","e"]), ...
  'Failed to index from string array')
% Cell output
assert(isequal(pick(2:2:10, [1 2 4], 'cell'), {2 4 8}), ...
  'Failed to index from numrical array with cell output')
assert(isequal(pick(num2cell(2:2:10), [1 2 4], 'cell'), {2 4 8}), ...
  'Failed to index from cell array with cell output')

%% Test 2: fields
% For structs & class objects and string key(s), fetch value of the
% struct's field or object's property
assert(isequal(pick(s, 'char', 'cell'), {s.char}), ...
  'Failed with struct fields and cell output')
assert(isequal(pick(s2, {'a' 'c'}), {30, 'go'}), ...
  'Failed to select multiple fields from scalar struct')
assert(all(pick(s, 'num') == 101:106), ...
  'Failed to select field from non-scalar struct')
assert(isequal(pick(s, {'c' 'num'}), {[s.c], [s.num]}), ...
  'Failed to select multiple fields from non-scalar struct')
assert(isequal(pick(s, {'char' 'num'},'cell'), {{s.char}, {s.num}}), ...
  'Failed to select multiple fields from non-scalar struct and output cell')
obj = hw.Timeline;
assert(pick(obj, 'SamplingInterval') == obj.SamplingInterval, ...
  'Failed to select property from object')
% Test cell array of structs
assert(isequal(pick({s,s2},'c','cell'), {{s.c}, {s2.c}}), ...
  'Failed to select multiple structs with one key')
% Pick from cell with cell output
assert(isequal(pick({s,s2},'c','cell'), {{s.c}, {s2.c}}), ...
  'Failed to select multiple structs with one key')

%% Test 3: containers.Map
% For containers.Map object's with a valid key type, get keyed value
assert(strcmp(pick(m, 'word'), m('word')), 'Failed to get value from key')
assert(isequal(pick(m, {'number', 'word'}), {m('number'), m('word')}), ...
  'Failed to get values from keys')

%% Test 4: defaults
% When picking from structs, objects and maps, you can also specify a 
% default value to be used when the specified key does not exist in your 
% data structure.
expected = {1, 'shintysix'};
assert(isequal(pick(m, {'number', 'wang'}, 'def', 'shintysix'), expected), ...
  'Failed to get default from containers.Map')
result = pick(s, {'num', 'wang'}, 'def', []);
assert(iscell(result) && isempty(result{2}) && all(result{1} == [s.num]), ...
  'Failed to get default from struct')
assert(isequal(pick({s(1),s2},'a','def',1), [1 s2.a]), ...
  'Failed to select multiple structs with one key using default')
assert(pick(hw.Timeline, 'fakeProp', 'def', 45) == 45, ...
  'Failed selecting property from object')

% Test output with multiple defaults / defaults as array.
% When the default is an array we don't distribute the elements to the
% missing values.  If the key is not scalar, a cell should be returned.  
% The default array is delt to every missing value:
actual = pick(s2, {'a','d'}, 'def', 1:3);
expected = {s2.a, 1:3};
assert(isequal(actual, expected), ...
  'failed to assign default array to missing value')

% If the key is scalar, the values should be concatinated with the default:
s = struct('d',(1:3)');
s(3).d = [];
actual = pick(s, 'd', 'def', [4,5,6]');
assert(isequal(actual, [1 4 4; 2 5 5; 3 6 6]), ...
  'failed to concatinate output')

% If the default is a cell array or string array the same rules should
% apply (both these types don't play well with cell2mat):
strArr = ["non", "scalar"];
actual = pick(s2, 'd', 'def', strArr);
assert(isequal(actual, strArr), 'failed to return string array value')

cellArr = cellstr(strArr);
actual = pick(s2, 'd', 'def', cellArr);
assert(isequal(actual, cellArr), 'failed to return unwrapped cell array')
