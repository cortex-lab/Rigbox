% loadVar test
% Test for loadVar function and also clearBurgboxCache
root = getOr(dat.paths,'rigbox');
filePath = fullfile(root, 'tests', 'fixtures', 'testData.mat');

% Test the caching of files and clearing of cache
mess = onCleanup(@() fun.applyForce({...
  @()clearCBToolsCache; % Clear cache
  @()iff(file.exists(filePath), @()delete(filePath), [])})); % Delete file
data = rand(6);
save(filePath, 'data')
assert(file.exists(filePath), 'Failed to save test data')
assert(isempty(getCache), 'Clear cache and re-run')

% Loaded data
loaded = loadVar(filePath, 'data');
allTrue = @(v)all(all(v));
assert(allTrue(data == loaded), 'Failed to load data')
cache = getCache;
assert(~isempty(cache) && cache.length == 1, 'Failed to cache data')

% Inject new data into cache
key = cache.keys;
cache(key{:}) = rand(6);
% Retrieve this data from cache via loadVar
loaded = loadVar(filePath,'data');
assert(~allTrue(loaded == data), 'Failed to load from cache')

pause(1) % Modified date works at the resolution of a second
save(filePath, 'data') % Re-save data, changing modified date
loaded = loadVar(filePath, 'data');
assert(allTrue(loaded == data), 'Failed to re-load modified file')
assert(cache.length == 2, 'Failed to cache new data')

% Test loadVar with cell input and without variable names
loaded = loadVar({filePath});
assert(...
  iscell(loaded) && ...
  isstruct(loaded{:}) && ...
  strcmp(fieldnames(loaded{1}), 'data') && ...
  allTrue(loaded{1}.data == data), ...
  'Failed to load all vars from cell array of paths')

% Inject new data into cache
key = cache.keys;
cache(key{1}) = rand(6);
% Retrieve this data from cache via loadVar
loaded = loadVar(filePath);
assert(~allTrue(loaded == data), 'Failed to load from cache')

% Test clearing function
clearCBToolsCache()
assert(isempty(getCache), 'Failed to clear cache')

%% Helper function
function c = getCache
% GETCACHE Return the Burgbox cache variable
global BurgboxCache
c = BurgboxCache;
end