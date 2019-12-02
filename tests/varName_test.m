% varName test
[a, b, c] = deal([]);
fun = @(i) varName(i);
assert(fun(a) == 'i', 'Failed to retrieve variable name')

fun = @(x,y,z) varName(x,y,z);
expected = {'x'; 'y'; 'z'};
result = cell(size(expected));
[result{:}] = fun(a,b,c);
assert(isequal(expected, result), 'Unexpected output with multiple inputs')

fun = @(varargin) varName(varargin{:});
assert(isequal(fun(b), ''), 'Unexpected output with varargin')