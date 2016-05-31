function saveParamProfile(expType, profileName, params)
%DAT.SAVEPARAMPROFILE Stores the named parameters for experiment type
%   TODO
%
% Part of Rigbox

% 2013-07 CB created

%path to repositories
fn = 'parameterProfiles.mat';
repos = fullfile(dat.reposPath('expInfo'), fn);

%load existing profiles for specified expType
profiles = dat.loadParamProfiles(expType);
%add (or replace) the params with a field named by profile
profiles.(profileName) = params;
%wrap in a struct for saving
set = struct;
set.(expType) = profiles;

%save the updated set of profiles to each repos
%where files exist already, append
cellfun(@(p) save(p, '-struct', 'set', '-append'), file.filterExists(repos, true));
%and any that don't we should create from scratch
cellfun(@(p) save(p, '-struct', 'set'), file.filterExists(repos, false));

end