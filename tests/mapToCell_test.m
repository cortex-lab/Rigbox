function tests = mapToCell_test
% Tests for mapToCell function:
%   1. Test for handling non-cell array inputs
%   2. Test for cell array inputs
%   3. Test for output assignments
%
tests = functiontests(localfunctions);
end

function testNonCellArrays(testCase)
% Test behaviour of passing non-cell arrays to mapToCell
C = mapToCell(@identity, 'hello'); % char arr
testCase.verifyEqual(C, {'h','e','l','l','o'}, ...
  'Expected char array to be parsed as ''letter'' array')

C = mapToCell(@identity, "hello"); % str
testCase.verifyEqual(C, {"hello"}, 'Unexpected use of string input')

C = mapToCell(@plus, 'hello', 1:5); % arr
testCase.verifyEqual(C, {105 103 111 112 116}, ...
  'Unexpected use of multiple non-cell inputs')
end

function testMixedArrays(testCase)
% Test working with mix of array types and single cell array
C = mapToCell(@plus, 'hello', num2cell(1:5)); % Mix
testCase.verifyEqual(C, {105 103 111 112 116}, ...
  'Unexpected use of multiple non-cell inputs')

C = mapToCell(@(A)circshift(A,2), {'hello', 'bye'}); % cell
testCase.verifyEqual(C, {'lohel', 'yeb'})
end

function testOutputAssigning(testCase)
% Test assinging of output variables and error handling.  Output variables
% must always be cells

% Test assignment of >1 outputs
[a, b, c] = mapToCell(@(a,b)deal(plus(a,b)), 1:3, 3:-1:1);
testCase.verifyTrue(isequal(a,b,c,{4,4,4}), 'Failed to assign all outputs')

% Test with 0 output arguments assinged
k = [];
mapToCell(@grow, 1:3);
testCase.verifyEqual(k,[2,3,4])

% Tests error thown with assignment mismatch
msg = [];
try
  [a, b] = mapToCell(@identity, {'hello'}); %#ok<ASGLU> % err
catch ex
  msg = ex.message;
end
testCase.verifyMatches('Number of input and output variables do not match', msg)

  function grow(a)
    % Mini function for testing function mapping without output assignment
    %   persistent k
    k = [k a+1];
  end
end