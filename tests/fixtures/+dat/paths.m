function p = paths(rig)
%DAT.PATHS Returns struct containing important paths for testing
%   p = DAT.PATHS([RIG])
%   TODO:
%    - Clean up expDefinitions directory
% Part of Rigbox

% 2013-03 CB created

thishost = 'testRig';

if nargin < 1 || isempty(rig)
rig = thishost;
end

%% defaults
% path containing rigbox config folders
p.rigbox = fileparts(which('addRigboxPaths'));
% Repository for local copy of everything generated on this rig
p.localRepository = fullfile(p.rigbox, 'tests', 'fixtures', 'local');
p.localAlyxQueue = fullfile(p.rigbox, 'tests', 'fixtures', 'alyxQ');
p.databaseURL = 'https://test.alyx.internationalbrainlab.org';
p.gitExe = 'C:\Program Files\Git\cmd\git.exe';
p.updateSchedule = weekday(now)+1; % Always tomorrow

% Under the new system of having data grouped by mouse
% rather than data type, all experimental data are saved here.
p.mainRepository = fullfile(p.rigbox, 'tests', 'fixtures', 'Subjects');

% directory for organisation-wide configuration files, for now these should
% all remain on zserver
p.globalConfig = fullfile(p.rigbox, 'tests', 'fixtures', 'config');
% directory for rig-specific configuration files
p.rigConfig = fullfile(p.globalConfig, rig);
% repository for all experiment definitions
p.expDefinitions = fullfile(p.rigbox, 'tests', 'data', 'expdefs');

% repository for working analyses that are not meant to be stored
% permanently
p.workingAnalysisRepository = fullfile(p.rigbox, 'tests', 'data');

% for tape backups, first files go here:
p.tapeStagingRepository = fullfile(p.rigbox, 'tests', 'staging'); 

% then they go here:
p.tapeArchiveRepository = fullfile(p.rigbox, 'tests', 'toarchive');


%% load rig-specific overrides from config file, if any  
customPathsFile = fullfile(p.rigConfig, 'paths.mat');
if file.exists(customPathsFile)
customPaths = loadVar(customPathsFile, 'paths');
if isfield(customPaths, 'centralRepository')
% 'centralRepository' is deprecated, remove field, if any
customPaths = rmfield(customPaths, 'centralRepository');
end
if isfield(customPaths, 'expInfoRepository')
% 'expInfo' is deprecated, change to 'main'
p.mainRepository = customPaths.expInfoRepository;
customPaths = rmfield(customPaths, 'expInfoRepository');
end
% merge paths structures, with precedence on the loaded custom paths
p = mergeStructs(customPaths, p);
end

end
