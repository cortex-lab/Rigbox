function saveParamProfile(expType, profileName, params)
%DAT.SAVEPARAMPROFILE Stores the named parameters for experiment type
%   TODO
%     - Figure out how to save struct without for-loop in 2016b!
% Part of Rigbox

% 2013-07 CB created
% 2017-02 MW adapted to work in 2016b

%path to repositories
fn = 'parameterProfiles.mat';
repos = fullfile(dat.reposPath('main'), fn);

%load existing profiles for specified expType
profiles = dat.loadParamProfiles(expType);
%add (or replace) the params with a field named by profile
profiles.(profileName) = params;
%wrap in a struct for saving
set = struct;
set.(expType) = profiles;

%save the updated set of profiles to each repos
%where files exist already, append
% cellfun(@(p) save(p, '-struct', 'set', '-append'),
% file.filterExists(repos, true)); % Had to change her to a for loop, sorry
% Chris!
p = file.filterExists(repos, true);
for i = 1:length(p)
    save(p{i}, '-struct', 'set', '-append')
end
%and any that don't we should create from scratch
p = file.filterExists(repos, false);
for i = 1:length(p)
    save(p{i}, '-struct', 'set')
end
% cellfun(@(p) save(p, '-struct', 'set'), file.filterExists(repos, false));

end