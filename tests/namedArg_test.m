% namedArg test
%  [present, value, idx] = namedArg(args, name)
% preconditions:
args = {'positional', 'nameA', 'valA', 'nameB', 'valB'};

%% Test 1: Arg exists
[present, value, idx] = namedArg(args, 'nameB');
assert(present, 'Failed to find named argument')
assert(strcmp(value, 'valB'), 'Failed to return named value')
assert(idx == 4, 'Failed to return named argument index')

%% Test 2: Arg doesn't exist
[present, value, idx] = namedArg(args, 'nameC');
assert(~present, 'Failed to report absence of named argument')
assert(isempty(value), 'Unexpected value returned')
assert(isempty(idx), 'Unexpected index returned')
