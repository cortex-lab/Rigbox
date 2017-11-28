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

server1Name = '\\zserver.cortexlab.net';
% server2Name = '\\zserver2.cortexlab.net';
% server3Name = '\\zserver3.cortexlab.net'; % 2017-02-18 MW - Currently
% unused by Rigbox
server4Name = '\\zserver4.cortexlab.net';

%% defaults
% path containing rigbox config folders
% p.rigbox = fullfile(server1Name, 'code', 'Rigging'); % Potential conflict with AddRigBoxPaths
p.rigbox = fileparts(which('addRigboxPaths'));
% Repository for local copy of everything generated on this rig
p.localRepository = 'C:\LocalExpData';
% for all data types, under the new system of having data grouped by mouse
% rather than data type
p.mainRepository = fullfile(server1Name, 'Data2', 'Subjects');
% Repository for info about experiments, i.e. stimulus, behavioural,
% Timeline etc
p.expInfoRepository = p.mainRepository;
% Repository for storing two photon movies
p.twoPhotonRepository = p.mainRepository;

% for calcium widefield imaging
p.widefieldRepository = fullfile(server1Name, 'data', 'GCAMP');
% Repository for storing eye tracking movies
p.eyeTrackingRepository = p.mainRepository;

% electrophys repositories
p.lfpRepository = fullfile(server1Name, 'Data', 'Cerebus');
p.spikesRepository = fullfile(server1Name, 'Data', 'multichanspikes');
% directory for organisation-wide configuration files, for now these should
% all remain on zserver
% p.globalConfig = fullfile(p.rigbox, 'config');
p.globalConfig = fullfile(server1Name, 'Code', 'Rigging', 'config');
% directory for rig-specific configuration files
p.rigConfig = fullfile(p.globalConfig, rig);
% repository for all experiment definitions
p.expDefinitions = fullfile(server1Name, 'Code', 'Rigging', 'ExpDefinitions');

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