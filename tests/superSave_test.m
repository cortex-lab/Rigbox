% superSave test
% Preconditions:
savePath = {'fixtures'};
savePath{2} = fullfile(savePath{1},'subjects');
varName = 'testData.mat';

assert(exist(savePath{1},'dir') == 7, 'No fixtures folder found')
assert(isempty(file.list(savePath{2})), ...
  'test subjects folder not empty, manually delete and re-run test')

%% Test 1: Saving to one existing dir
% Save a MAT file to a single existing directory
var = struct('testPars', magic(6)); % Create a test var to save
fullpath = fullfile(savePath{1}, varName); % Make the save path(s)
mess = onCleanup(@()clearFiles(fullpath)); % Ensure our mess is cleared
superSave(fullpath, var) % Run

% Checks...
assert(exist(fullpath, 'file') == 2, 'Failed to save file')
loaded = load(fullpath);
assert(isequal(loaded, var), 'Variable modified during save')
% cleanup(fullpath)

%% Test 2: Saving to multiple dirs
% Save variable to multiple locations and test saving to none-existent dir
var = struct('testPars', magic(6)); % Create a test var to save
if exist(savePath{2},'dir') == 7
  % Delete second path if it exists
  assert(rmdir(savePath{2}, 's'), 'Failed to remove test subjects folder')
end
fullpath = fullfile(savePath, varName); % Make the save path(s)
mess = onCleanup(@()clearFiles(fullpath)); % Ensure our mess is cleared
superSave(fullpath, var) % Run

% Checks...
assert(all(file.exists(fullpath)), 'Failed to save files')
loaded = load(fullpath{1});
loaded2 = load(fullpath{2});
assert(isequal(loaded, loaded2, var), 'Variables modified during save')

%% Test 3: Save order
% Check the order of saving and behaviour when error occurs
var = struct('testPars', magic(6)); % Create a test var to save
fullpath = fullfile(savePath, varName); % Make the save path(s)
mess = onCleanup(@()clearFiles(fullpath)); % Ensure our mess is cleared
fullpath = [fullpath(1) '\\fakepath\bad' fullpath(2)]; % Insert bad path

% Checks
try
  superSave(fullpath, var) % Run
  assert(false, 'Failed to throw error')
catch
end
fullpath(2) = []; % Remove fake path for speed reasons
assert(all(file.exists(fullpath) == [true, false]), ...
  'Unexpected save behaviour using bad paths')

%% Helper function
function clearFiles(p)
% CLEANUP Remove saved test files and folders
%  p - a path str or cell array thereof
p = ensureCell(p);
% Delete second path if it exists
if numel(p) > 1 && exist(fileparts(p{end}),'dir') == 7
  assert(rmdir(fileparts(p{end}), 's'), ...
    'Failed to remove test subjects folder')
end
% Remove any remaining files
cellfun(@(f) delete(f), p(file.exists(p)), ...
  'ErrorHandler', @(s)warning(s.identifier,s.message))
end