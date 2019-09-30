% fileFunction test
% TODO Adapt fileFunction test for signals submodule
% Test executing a file function that is not in MATLAB's paths
p = fullfile('fixtures', 'util', 'MockDialog.m');
[~,funName] = fileparts(p);
% Check file exists and not on path
assert(file.exists(p), 'Test file %s not found', p)
assert(~exist(funName,'file'), 'Remove %s from path and re-run', fileparts(p))

% Test creating executable function handle for test file function
try
  f = fileFunction(p);
  assert(isa(f(), 'MockDialog'), 'Failed to executre file function')
catch ex
  if strcmp(ex.identifier, 'MATLAB:UndefinedFunction')
    assert(false, 'Failed to add file function to path')
  else
    rethrow(ex)
  end
end
assert(~exist(funName,'file'), 'Failed to remove file function from path')

% Test using separate inputs
f = fileFunction(fileparts(p), funName);
assert(isa(f(), 'MockDialog'), 'Failed to execute file function')

% Test error handling
f = fileFunction(p);
try
  f('unexpected input');
  assert(false, 'Failed to throw error')
catch ex
  if strcmp(ex.identifier, 'MATLAB:TooManyInputs')
    assert(~exist(funName,'file'), 'Failed to remove file function from path')
  else
    rethrow(ex)
  end
end