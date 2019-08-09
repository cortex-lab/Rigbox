% fun package test
% Preconditions:
% Multiple function handles
i = rand; % Input value
f0 = @(a,b)a+(10/b);
f1 = @(a) a/2;
f2 = @(a) a*2;
f3 = @(a) a^3;
% Create something stateful to check function was called
count = 10;
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

%% Test 6: fun.closeWith
% TODO Test for closeWith

%% Test 7: fun.Seq