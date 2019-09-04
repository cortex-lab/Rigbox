%cellsprintf test
% preconditions:
formatSpec = '%3$s\\%2$03d\\%1$#+6.2f\\%4$to';

%% Test 1: Tests single cell string
% Test behaviour of cellprintf when given a number of cell arrays
A = {17.2511543; 5.61600001; 19.4733993; -14e10};
B = {76; 39; -57; NaN};
C = {'ABC'; 'abc'; 'cba'; ''};
D = {false; true; 'p'; 2};

expected = {...
    'ABC\076\+17.25\00000000000';
    'abc\039\ +5.62\07740000000';
    'cba\-57\+19.47\10270000000';
    '\NaN\-140000000000.00\10000000000'};

actual = cellsprintf(formatSpec, A, B, C, D);
assert(isequal(actual, expected))

%% Test 1: Tests single inputs
% Test that formating consistent with sprintf using signal input
testArgs = {43.542542, 5, "hi", 4};
expected = {sprintf(formatSpec, testArgs{:})};
actual = cellsprintf(formatSpec, testArgs{:});

assert(isequal(actual, expected))