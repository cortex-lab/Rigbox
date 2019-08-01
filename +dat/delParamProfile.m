function delParamProfile(expType, profileName)
%DAT.DELPARAMPROFILE Deletes the named parameter sets for experiment type
%   TODO
%     - Figure out how to save struct without for-loop in 2016b!
% Part of Rigbox

% 2013-07 CB created

%path to repositories
fn = 'parameterProfiles.mat';
repos = fullfile(dat.reposPath('main'), fn);

%load existing profiles for specified expType
profiles = dat.loadParamProfiles(expType);
%remove the params with the field named by profile
profiles = rmfield(profiles, profileName);
%wrap in a struct for saving
set.(expType) = profiles;

%save the updated set of profiles to each repos
%where files exist already, append
p = file.filterExists(repos, true);
for i = 1:length(p)
    save(p{i}, '-struct', 'set', '-append')
end
%and any that don't we should create from scratch
p = file.filterExists(repos, false);
for i = 1:length(p)
    save(p{i}, '-struct', 'set')
end

end