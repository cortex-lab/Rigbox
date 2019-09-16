% fun package test
% In addition to the +fun package, test number 8 ('sequence') tests the
% following functions:
%  - sequence
%  - first
%  - rest
%  - isNil
%  - nil

% Preconditions:

% Multiple function handles
i = rand; % Input value
f0 = @(a,b)a+(10/b);
f1 = @(a) a/2;
f2 = @(a) a*2;
f3 = @(a) a^3;
% Create something stateful to check function was called
count = 15;
m = containers.Map(num2cellstr(1:count), num2cell(1:count));
assert(m.Count == count, 'Unexpected key count in containers map')
f4 = @(varargin) m.remove(first(m.keys)); % Remove a key

%% Test 1: fun.apply
% Value input
assert(fun.apply(i,rand) == i, 'Failed to return value')
% Function input
assert(fun.apply(f0,i,1) == i+10, 'Failed to apply function')
% Multiple function handles
expected = {i/2, i*2, i^3};
assert(isequal(fun.apply({f1,f2,f3},i), expected), 'Failed on cell array')
% Applying function without output
expected = m.Count - 1;
fun.apply(f4, rand);
assert(expected == m.Count, 'Failed to apply function without output assignment')

%% Test 2: fun.applyForce
% Test no args in, no errors
count = m.Count - 1; % Key should have been removed
[ex, exElems] = fun.applyForce({f4});
assert(isempty(ex) && isempty(exElems), 'Unexpected output')
assert(m.Count == count, 'Failed to call input function with no args')

% Multiple function handles and error function
f_err = @(varargin) assert(false);
try
  [ex, exElems] = fun.applyForce({f1,f_err,f3,f4},i);
  id = 'MATLAB:assertion:failed';
  assert(isa(ex,'MException') && numel(ex) == 1 && strcmp(ex.identifier, id), ...
    'Failed to return expected exception object')
  assert(isequal(exElems, {f_err, {i}}), 'Failed to return error function')
  assert(m.Count == count-1, 'Failed to execute all functions')
catch
  assert(false, 'Failed to handle exception')
end

%% Test 3: fun.map
% [C1, ...] = fun.map(FUN, A1, ...)
A1 = 1:10;
A2 = num2cell(A1);
result = fun.map(f0,A1,A2);
expected = cellfun(f0, num2cell(A1), A2, 'uni', 0);
assert(isequal(result, expected), 'Unexpected result')
% Test varargout
out = cell(size(A1));
[out{:}] = fun.map(@(~) deal(i), A1);
assert(isequal(repmat({i},size(A1)), out{:}), 'Failed to assign multiple outputs')

%% Test 4: fun.run
% Test multiple function execution.  When f4 is called 1 key from m will be
% removed.
in = {f4, f4, f4};
f = fun.run(in{:});
assert(isa(f, 'function_handle'), 'Unexpected output')
count = m.Count - numel(in); % Expected key count after running f
f(in{:}); % Inputs should be ignored
assert(m.Count == count, 'Failed to execute function handles')

% Test running immediately
f = fun.run(true, in{:}, @nop);
assert(isempty(f), 'Unexpected output')
assert(m.Count == count-numel(in), 'Failed to execute function handles')

%% Test 5: fun.memoize
count = m.Count - 1;
% Test caching of f4 and containers map
f = fun.memoize(f4);
assert(isa(f, 'function_handle'), 'Unexpected output')

% Executing handle should remove key from map and return said map
result = f();
assert(isa(result, 'containers.Map'),  'Unexpected output')
assert(m.Count == count, 'Failed to execute function handle')

% Re-run with no inputs should not execute f4, but instead return cached
% map
result = f(); 
assert(result.Count == count && m.Count == count, ...
  'Failed to execute function handle')

% Evaluate f once more with different inputs should execute f4 and
% decrement key count in m
result = f(10);  count = count - 1;
assert(result.Count == count && m.Count == count, ...
  'Failed to execute function handle')

% Test useing custom key map.  This should cache two variables: one where
% all input is > 0 and otherwise
keyFun = @(a) iff(all([a{:}] > 0), 0, 1);
f = fun.memoize(@(varargin)rand, keyFun);
a = f(true); % Result A
b = f(false); % Result B
assert(isequal(a, f(1,2,3), f(10000), f(1), f(randi(1000))), 'Unexpected output')
assert(isequal(b, f(1,0,3), f(0), f(-1), f(-rand)), 'Unexpected output')
assert(m.Count == count, 'Failed to overwrite previous function')

% Test behaviour when number of output args varies between calls
f = fun.memoize(@deal);
a = f(i); assert(a == i)
[a,b] = f(i);
assert(isequal(a,b), 'Failed to deal with extra output assignment on cached')


%% Test 6: fun.closeWith
% TODO Test for closeWith

%% Test 7: fun.filter
% Test filtering a numerical array
A = -6:2:6;
f = @(a) abs(a) > 3;
[passed, failed] = fun.filter(f, A);

assert(all(abs(passed) > 3) && all(abs(failed) <= 3), ...
  'Failed to filter numerical array')

% Test filtering a cell array
C = num2cellstr([1 0 0 1]);
f = @(a) a == '1';
[passed, failed] = fun.filter(f, C);
assert(isequal(passed, {'1','1'}) && isequal(failed, {'0','0'}), ...
  'Failed to filter cell array')

%% Test 8: sequence
%%% EmptySeq %%%
% Test empty input, EmptySeq
n = sequence([]);
assert(isa(n,'fun.EmptySeq') && isNil(n) && isempty(n) && numel(n) == 0, ...
  'Failed to return empty sequence')
assert(iscell(n.toCell) && isempty(n.toCell), 'Failed on EmptySeq to cell')
firstOut = cell(1,5);
[firstOut{:}] = first(n); restOut = rest(n);
assert(isequal(restOut, firstOut{:}, nil), ...
  'Unexpected behaviour with ''first'' and ''rest'' methods')

%%% sequence %%%
% Test error handling in sequence construction
try % creating sequence from unsupported (numerical) array
  sequence(magic(3));
  msg = '';
catch ex
  msg = ex.message;
end
assert(strcmp('Cannot make a sequence from a ''double''', msg), ...
  'Failed to throw expected error')
try % creating sequence from unsupported type
  sequence(magic(3), struct.empty);
  msg = '';
catch ex
  msg = ex.message;
end
assert(contains(msg, 'unrecognised type', 'IgnoreCase', true), ...
  'Failed to throw expected error')

%%% CellSeq %%%
% Test cell sequence and instantiation with sequence function
C = num2cellstr(1:5);
s = sequence(C);
sub = s.take(3); % create a subsequence

assert(isa(s, 'fun.CellSeq'), ...
  'Expected CellSeq to be returned but ''%s'' was instead', class(s));
assert(s.first == '1' && first(s.reverse) == '5')
% Test behaviour of empty CellSeq
assert(fun.CellSeq.empty.isempty && not(s.isempty), 'Failed on isempty')
assert(isNil(map(fun.CellSeq.empty)) && isNil(filter(fun.CellSeq.empty,@nop)))

% Test constructor inputs
s = fun.CellSeq.create(C(:), 3);
assert(s.first == '3' && s.rest.first == '4' && fun.CellSeq.create(C, 7) == nil, ...
  'Failed to set first index in constructor')
assert(s.take(5).first == '3', ...
  'Failed to return subsequence when n > total elements')

%%% CustomSeq %%%
% Test subsequence
assert(isa(sub, 'fun.CustomSeq'), ...
    'Expected CustomSeq to be returned but ''%s'' was instead', class(s));
assert(sub.first == '1' && sub.reverse.first == '3', 'Failed to return subsequence')
assert(isequal(sub.toCell, C(1:3)'), 'Failed to convert CustomSeq to cell')
assert(isNil(s.take(0).first) && isNil(s.take(0).rest), ...
  'Unexpected behaviour when taking 0 elements from sequence')

% Test mapping and filtering
mapped = map(fun.CellSeq.create(C(:)), @str2num);
assert(isa(mapped, 'fun.CustomSeq'), ...
    'Expected CustomSeq to be returned but ''%s'' was instead', class(s));
assert(mapped.first == 1 && mapped.reverse.first == 5, 'Failed to apply map')
filtA = filter(sequence(num2cell(str2double(C))), @(a) a > 3);
assert(isa(filtA, 'fun.CustomSeq'), ...
    'Expected CustomSeq to be returned but ''%s'' was instead', class(s));
assert(filtA.first == 4 && filtA.rest.first == 5, 'Failed to apply filter')
filtB = filter(sequence(num2cell(str2double(C))), @(a) a > 3);
assert(filtB.rest.first == 5 && filtB.first == 4, 'Failed to apply filter')

%%% KeyedSeq %%%
% Test KeyedSeq instantiation with sequence function
s = sequence(m.keys, f4);
assert(isa(s, 'fun.KeyedSeq'), ...
    'Expected KeyedSeq to be returned but ''%s'' was instead', class(s));
% Test constructor inputs
keys = m.keys;
s = fun.KeyedSeq.create(keys, @(k)m(k));
assert(s.first == m(keys{1}) && s.reverse.first == m(keys{end}), ...
  'Failed to apply retrieval function')
s = fun.KeyedSeq.create(keys, @(k)m(k), 3);
n = fun.KeyedSeq.create(keys, @(k)m(k), numel(keys)+1);
assert(s.first == m(keys{3}) && n == nil, ...
  'Failed to set first index in constructor')
% Test isempty method
assert(fun.KeyedSeq.empty.isempty && ~s.isempty, ...
  'Unexpected behaviour of isempty method in KeyedSeq')

%%% first, rest %%%
% Test standalone functions `first` and `rest`
assert(...
  first(C(3:end)) == '3' && ...
  first(3:10) == 3 && ...
  isNil(first(nil)) && ...
  isNil(first([])), ...
  'Function first failed to return expected elements')

s = rest(C);
assert(isa(s, 'fun.CellSeq') && s.first == '2' && isNil(rest([])), ...
  'Function rest failed to return expected elements')