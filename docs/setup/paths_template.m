function p = paths(rig)
%DAT.PATHS Returns struct containing important paths
%   p = DAT.PATHS([RIG]) Returns a struct of paths that are used by Rigbox
%   to determine the location of config and experiment files.  The rig
%   input is used to generate rig specific paths, including custom paths.
%   The default is the hostname of this computer.
%
%   The main and local repositories are essential for determining where to
%   save experimental data.
%
%   If using a seperate MC computer, the main repository must be accessible
%   to both the stimulus and master computers.
%
% Part of Rigbox

% 2013-03 CB created

thishost = hostname;

if nargin < 1 || isempty(rig)
  rig = thishost;
end

% Some base locations for storing data.  Listing them here means that if we
% change server, only one variable needs changing
server1Name = 'C:\RemoteExpData';
server2Name = userpath; % Usually ~/Documents/MATLAB
basketName = '\\basket.cortexlab.net'; % for working analyses
lugaroName = '\\lugaro.cortexlab.net'; % for tape backup

%% Essential paths
% Below are the paths that are essential for running experiments.  If using
% both an MC and SC, the same mainRepository must be accessible to both
% computers.  In addition, the expDefinitions folder should be shared, or
% at least there should be the same copy of the expDefs on both computers.

% Path to base folder that contains the Rigbox code
p.rigbox = fileparts(which('addRigboxPaths'));
% Repository for local copy of everything generated on this rig
p.localRepository = 'C:\LocalExpData';

% Under the new system of having data grouped by subject
% rather than data type, all experimental data are saved here.
p.mainRepository = fullfile(server1Name, 'Subjects');
% Optional alternate named repos may be defined using the repo name
% followed by a number. These are searched in addition to the master repo.
% This is useful when distributing data over multiple locations, or
% transitioning to a new remote location
p.main2Repository = fullfile(server2Name, 'Data', 'Subjects');

% Directory for organisation-wide configuration files, for now these should
% all remain on zserver
p.globalConfig = fullfile(server2Name, 'Code', 'RigConfig');
% Directory for rig-specific configuration files
p.rigConfig = fullfile(p.globalConfig, rig);
% Repository for all experiment definitions
p.expDefinitions = fullfile(p.rigbox, 'signals', 'docs', 'examples');

%% Non-essential paths
% Database url and local queue for cached posts.  If empty or undefined,
% the AlyxPanel and all Alyx interactions are disabled.  NB: If the
% protocol isn't specified, https:// is automatically prepended.
% p.databaseURL = 'https://alyx.cortexlab.net'; % Uncomment to activate
p.localAlyxQueue = 'C:\localAlyxQueue'; % Location of cached posts
% Location of git for automatic updates
p.gitExe = 'C:\Program Files\Git\cmd\git.exe'; 
% Day on which to update code (0 = Everyday, 1 = Sunday, etc.)
p.updateSchedule = 2; % Update every Monday

% Alternate file repository: unlike alternates defined with a number (e.g.
% 'main2Repository'), 'altRepository' is returned as an alternate to every
% named repo
% p.altRepository = fullfile(server1Name, 'expInfo');
% p.alt2Repository = fullfile(server2Name, 'Data', 'expInfo');

%% user-defined repositories
% The following paths are not used in the main Rigbox code, however may be
% added to this file when using the +dat package for one's own analysis.
% Some examples below:

% Repository for working analyses that are not meant to be stored
% permanently
p.workingAnalysisRepository = fullfile(basketName, 'data');
% For tape backups, first files go here:
p.tapeStagingRepository = fullfile(lugaroName, 'bigdrive', 'staging'); 
% Then they go here:
p.tapeArchiveRepository = fullfile(lugaroName, 'bigdrive', 'toarchive');

%% load rig-specific overrides from config file, if any
% If there is a paths.mat file in the folder location defined on line 43,
% it is loaded and any paths there are override the above defaults 
customPathsFile = fullfile(p.rigConfig, 'paths.mat');
if file.exists(customPathsFile)
  customPaths = loadVar(customPathsFile, 'paths');
  if isfield(customPaths, 'expInfoRepository')
    % 'expInfo' is deprecated, change to 'main'
    p.mainRepository = customPaths.expInfoRepository;
    customPaths = rmfield(customPaths, 'expInfoRepository');
  end
  % merge paths structures, with precedence on the loaded custom paths
  p = mergeStructs(customPaths, p);
end

end