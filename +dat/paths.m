function p = paths(rig)
%DAT.PATHS Returns struct containing important paths
%   p = DAT.PATHS([RIG])
%   TODO:
%    - Clean up expDefinitions directory
% Part of Rigbox

% 2013-03 CB created

thishost = hostname;

if nargin < 1 || isempty(rig)
  rig = thishost;
end

server1Name = '\\zubjects.cortexlab.net';
server2Name = '\\zserver.cortexlab.net';
basketName = '\\basket.cortexlab.net'; % for working analyses
lugaroName = '\\lugaro.cortexlab.net'; % for tape backup

%% defaults
% path containing rigbox config folders
% p.rigbox = fullfile(server1Name, 'code', 'Rigging'); % Potential conflict with AddRigBoxPaths
p.rigbox = fileparts(which('addRigboxPaths'));
% Repository for local copy of everything generated on this rig
p.localRepository = 'C:\LocalExpData';
p.localAlyxQueue = 'C:\localAlyxQueue';
p.databaseURL = 'https://alyx.cortexlab.net'; % 'https://dev.alyx.internationalbrainlab.org/';
p.gitExe = 'C:\Program Files\Git\cmd\git.exe';
% Day on which to update code (0 = Everyday, 1 = Sunday, etc.)
p.updateSchedule = 2;

% Under the new system of having data grouped by mouse
% rather than data type, all experimental data are saved here.
p.mainRepository = fullfile(server1Name, 'Subjects');

% directory for organisation-wide configuration files, for now these should
% all remain on zserver
% p.globalConfig = fullfile(p.rigbox, 'config');
p.globalConfig = fullfile(server2Name, 'Code', 'Rigging', 'config');
% directory for rig-specific configuration files
p.rigConfig = fullfile(p.globalConfig, rig);
% repository for all experiment definitions
p.expDefinitions = fullfile(server2Name, 'Code', 'Rigging', 'ExpDefinitions');

% repository for working analyses that are not meant to be stored
% permanently
p.workingAnalysisRepository = fullfile(basketName, 'data');

% for tape backups, first files go here:
p.tapeStagingRepository = fullfile(lugaroName, 'bigdrive', 'staging'); 

% then they go here:
p.tapeArchiveRepository = fullfile(lugaroName, 'bigdrive', 'toarchive');


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
