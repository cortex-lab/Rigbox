% Test tabulateArgs
n = 10;
str = repmat("string array", 1, n);
argout = cell(1,4);
[argout{:}] = tabulateArgs(45, 'char array', 1:n, str);

% Check output sizes and value type
assert(all(cellfun(@(v)all(size(v)==[1,10]),argout)), ...
  'Not all args the same shape')
assert(isequal(cellfun(@class,argout,'uni',0), ...
  {'cell','cell','double','string'}), ...
  'Unexpected type returned')

% Test inputs with different shapes
try
  ex.message = '';
  [argout{:}] = tabulateArgs(45, 'char array', 1:n, str');
catch ex
end
assert(strcmp(ex.message,'All non-array arguments must be the same shape.'), ...
  'Failed to throw expected input shape error')

% Test tabulation when all inputs single args
[argout{:}] = tabulateArgs(45, 'char array', "string", struct);
assert(isequal(cellflat(argout), {45;'char array';"string";struct}))