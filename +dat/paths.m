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
% for all data types, under the new system of having data grouped by mouse
% rather than data type
p.mainRepository = fullfile(serverName, 'data', 'subjects');
% Repository for info about experiments, i.e. stimulus, behavioural,
% Timeline etc
p.expInfoRepository = p.mainRepository;

% Repository for storing eye tracking movies
p.eyeTrackingRepository = fullfile(serverName, 'data', 'eyeCamera');

% directory for organisation-wide configuration files, for now these should
% all remain on zserver
% p.globalConfig = fullfile(p.rigbox, 'config');
p.globalConfig = fullfile(serverName, 'code', 'rigging', 'config');
% directory for rig-specific configuration files
p.rigConfig = fullfile(p.globalConfig, rig);
% repository for all experiment definitions
p.expDefinitions = fullfile(serverName, 'code', 'rigging', 'expDefinitions');

%% load rig-specific overrides from config file, if any  
customPathsFile = fullfile(p.rigConfig, 'paths.mat');
if file.exists(customPathsFile)
  customPaths = loadVar(customPathsFile, 'paths');
  if isfield(customPaths, 'centralRepository')
    % 'centralRepository' is deprecated, remove field, if any
    customPaths = rmfield(customPaths, 'centralRepository');
  end
  % merge paths structures, with precedence on the loaded custom paths
  p = mergeStructs(customPaths, p);
end


end