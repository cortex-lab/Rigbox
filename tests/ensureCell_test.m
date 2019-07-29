%% Test 1: Wrapping a non cell
arr = 1:10;
[cellArr, wrapped] = ensureCell(arr);
expected = {arr};

assert(iscell(cellArr) && isequal(cellArr, expected), 'Failed to wrap array in cell')
assert(wrapped, 'Failed to return correct status')

%% Test 2: Pass in a cell array
arr = {pi};
[cellArr, wrapped] = ensureCell(arr);
assert(isequal(arr, cellArr), 'Failed to deal with cell input')
assert(~wrapped, 'Failed to return correct status')