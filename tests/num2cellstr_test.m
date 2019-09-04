%% Test 1: Tests single cell string
% Test creating cellstr from array including decimals, large significant
% figures and logicals
A = [pi, exp(1), 0, true, 1e-15, 1e15];
C = num2cellstr(A);
expected = {'3.14159', '2.71828', '0', '1', '1e-15', '1e+15'};

assert(isequal(C, expected))