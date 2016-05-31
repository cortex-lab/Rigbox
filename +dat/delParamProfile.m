function delParamProfile(expType, profileName)
%DAT.DELPARAMPROFILE Deletes the named parameter sets for experiment type
%   TODO
%
% Part of Rigbox

% 2013-07 CB created

%path to repositories
fn = 'parameterProfiles.mat';
repos = fullfile(dat.reposPath('expInfo'), fn);

%load existing profiles for specified expType
profiles = dat.loadParamProfiles(expType);
%remove the params with the field named by profile
profiles = rmfield(profiles, profileName);
%wrap in a struct for saving
set.(expType) = profiles;

%save the updated set of profiles to each repos
cellfun(@(p) save(p, '-struct', 'set', '-append'), repos);

end