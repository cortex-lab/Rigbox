%catStructs test

% preconditions: set up some non-scalar structs
len = 15;
rep = @(s) repmat(s,1,len);

A = rep(struct('a', 1:5, 'b', 'HU', 'c', []));
B = rep(struct('b', 76, 'd', magic(6)));
C = rep(struct('e', 1));
for i = 1:length(C)
  C(i).e = i;
end

%% Test 1: Struct concatination
% Test concatination and order precedence
s = catStructs({B,C});
assert(isequal(fieldnames(s), {'b'; 'd'; 'e'}) & length(s) == 2*len, ...
  'Failed to concatinate structs')

expected = [rep({B(1).b}), cell(1,len); % B.b
  rep({B(1).d}), cell(1,len); % B.d
  cell(1,len), num2cell(1:len)]; % C.e
assert(isequal(struct2cell(s), expected), 'Unexpected values or order');

s = catStructs({C,B}); % Changed cell order
expected = [expected(:,16:end) expected(:,1:15)];
assert(isequal(struct2cell(s), expected), 'Unexpected values or order');

%% Test 2: Shape and missing values
% Test using orthogonal structs and setting missing values
missingValue = randi(100);
s = catStructs({A,B,C}, missingValue);
assert(isequal(fieldnames(s), {'a'; 'b'; 'c'; 'd'; 'e'}) & length(s) == 3*len, ...
  'Failed to concatinate structs')

expected = [rep({A(1).a}), repmat({missingValue},1,2*len); % A.a
  rep({A(1).b}), rep({B(1).b}), rep({missingValue}); % A.b, B.b
  repmat({missingValue}, 1, 3*len); % A.c
  rep({missingValue}), rep({B(1).d}),rep({missingValue}); % B.d
  repmat({missingValue},1,2*len), num2cell(1:len)];
assert(isequal(struct2cell(s), expected), 'Unexpected values or order');

s = catStructs({A,struct('a',{})}, missingValue);

% Test dimention mismatches
s1 = catStructs({A, B', C});
s2 = catStructs({A, B, C}');
s3 = catStructs({A', B, C', struct('a',{})});
assert(isequal(s1, s2, s3), 'Unexpected effect of input shape')

% Note that the following produces a struct with no fields, despite the
% inputs having fields
assert(isequal(catStructs({struct('a',{}), struct('b',{})}), struct.empty))