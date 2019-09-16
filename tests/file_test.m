% file package test
% Preconditions:
p = 'fixtures';
p2 = '../docs';
assert(exist(p,'dir') == 7, 'No fixtures folder found')
assert(exist(p2,'dir') == 7, 'No list folder found')

%% Test 1: file.exists & file.filterExists
existFile = first(dirPlus(p)); % Pick a file that exists
assert(~isempty(existFile), 'Failed to find example file in testPath')

% Test with a single file and folder
assert(file.exists(existFile), 'Failed to report file exists')
assert(file.exists(p), 'Failed to report folder exists')

% Test cell array of existing and non-existing files and folders
expected = [true false true false];
paths = {existFile, ... % File exists
  strrep(existFile,'.m','.fake'), ... % File doesn't exist
  p, ... % Folder exists
  fullfile(p, 'fakeDir')}; % Folder doesn't exist

assert(isequal(file.exists(paths), expected), 'Failed on cellstr of paths')

% Test filterExists
assert(isequal(file.filterExists(paths), paths(expected)), ...
  'Failed to filter non-exising files')
assert(isequal(file.filterExists(paths,false), paths(~expected)), ...
  'Failed to filter out exising files')

%% Test 2: file.list
% Test listing files in a single folder
% Check it contains a mix of files and folders
pList = fun.filter(@(s)~any(strcmp(s.name,{'..','.'})), dir(p2));
assert(~all([pList.isdir]) && any([pList.isdir]), ...
  'Test dir must contain mix of files and folders')

% Test listing all
assert(isequal(file.list(p2), {pList.name}'), 'Failed to list files and dirs')
% Test listing files
assert(isequal(file.list(p2,'files'), {pList(~[pList.isdir]).name}'), ...
  'Failed to list only files')
% Test listing folders
assert(isequal(file.list(p2,'dirs'), {pList([pList.isdir]).name}'), ...
  'Failed to list only folders')

% Test listing with cellstr
pCell = {p2, p}; % Cell array of paths to list
result = file.list(pCell);
assert(iscell(result) && numel(result) == 2 && isequal(result{1},{pList.name}'), ...
  'Failed with cellstr input')
% Test listing with string
result = file.list(string(pCell));
assert(iscell(result) && numel(result) == 2 && isequal(result{1},{pList.name}'), ...
  'Failed with cellstr input')

% Test listing non-existent path (shouldn't throw an error)
assert(isempty(file.list(fullfile(p,'fakeDir'))), ...
  'Failed to handle non-existent path')
try
  ex.message = '';
  file.list(p,'fake')
catch ex
end
assert(contains(ex.message, 'not a recognised type'))

%% Test 3: file.modDate
% Test modified date on single path
expected = cellfun(@datenum, pick(dir(p),'date','cell'));
actual = file.modDate(p);
assert(all(actual(:) == expected(:)), 'Failed to return modified datenums')

% Test with cell array
pCell = {p, p2};
expected = cellfun(@datenum, pick(dir(p),'date','cell'));
actual = file.modDate(pCell);
assert(iscell(actual) && numel(actual) == 2 && all(actual{1}(:) == expected(:)), ...
  'Failed to with cellstr input')

% Test with non-existent path
assert(isempty(file.modDate(fullfile(p,'fake.m'))), ...
  'Failed to handle non-existent path')

%% Test 4: file.mkPath
% Test with single args
varName = 'testData.mat';
actual = file.mkPath(p, varName);
assert(strcmp(actual, fullfile(p,varName)), 'Failed to construct path')

% Test with cellstr
n = 3;
dirs = strcat('folder', num2cellstr(1:n));
vars = strcat('data', num2cellstr(1:n), '.mat');
actual = file.mkPath(dirs, p, vars);
correct = [cellfun(@startsWith, actual, dirs),  ...
  cellfun(@(a)contains(a,p), actual),  ...
  cellfun(@endsWith, actual, vars)];

assert(all(correct) && numel(actual) == n, 'Failed to deal with cellstr')