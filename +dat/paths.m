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

%% defaults
% path containing rigbox config folders
p.rigbox = fileparts(which('addRigboxPaths'));
% path to shared repository (accessible to MC and simulus server
% computers)
serverName = fullfile(p.rigbox, 'Repositories');
% Repository for local copy of everything generated on this rig
p.localRepository = 'C:\LocalExpData';
p.localAlyxQueue = 'C:\localAlyxQueue';
p.databaseURL = 'https://alyx.cortexlab.net';
% p.databaseURL = 'https://dev.alyx.internationalbrainlab.org/';
p.gitExe = 'C:\Program Files\Git\cmd\git.exe';
p.updateSchedule = 2; % Day on which to update code (2 = Monday)

% Under the new system of having data grouped by mouse
% rather than data type, all experimental data are saved here.
p.mainRepository = fullfile(serverName, 'data', 'subjects');

% directory for organisation-wide configuration files, for now these should
% all remain on zserver
% p.globalConfig = fullfile(p.rigbox, 'config');
p.globalConfig = fullfile(serverName, 'code', 'Rigging', 'config');
% directory for rig-specific configuration files
p.rigConfig = fullfile(p.globalConfig, rig);
% repository for all experiment definitions
p.expDefinitions = fullfile(serverName, 'code', 'Rigging', 'ExpDefinitions');

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
