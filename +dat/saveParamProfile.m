function saveParamProfile(expType, profileName, params)
%DAT.SAVEPARAMPROFILE Stores the named parameters for experiment type
%   Saves a parameter structure in a MAT file called 'parameterProfiles'.
%   Each field of this struct is an expType, and each nested field
%   is the set name.  Parameters of a given expType can be loaded using the
%   DAT.LOADPARAMPROFILES function.
%
%   Inputs:
%     expType (char): The name of the experiment type, e.g. ChoiceWorld.
%     profileName (char): The name of the parameter set being saved.  If
%       the name already exists in the file for a given expType, it is
%       overwritten.
%     params (struct): A parameter structure to be saved.
%
%   Example:
%     dat.saveParamProfile('ChoiceWorld', 'defSet', exp.choiceWorldParams)
%     profiles = dat.loadParamProfiles('ChoiceWorld');
%     p = exp.Parameters(profiles.defSet);
%   
% See also DAT.LOADPARAMPROFILES, DAT.PATHS
%
% Part of Rigbox

% 2013-07 CB created
% 2017-02 MW adapted to work in 2016b

% If main repo folders don't exist yet, create them
repos = dat.reposPath('main');
cellfun(@mkdir, repos(~file.exists(repos)))

% Path to repository files
fn = 'parameterProfiles.mat';
repos = fullfile(repos, fn);

% Load existing profiles for specified expType
profiles = dat.loadParamProfiles(expType);
% Add (or replace) the params with a field named by profile
profiles.(profileName) = params;
% Wrap in a struct for saving
set = struct;
set.(expType) = profiles;

% Save the updated set of profiles to each repos where files exist already,
% append
saveFn = @(p,name,varargin) save(p, '-struct', 'name', varargin{:});
cellfun(@(p) saveFn(p, set, '-append') , file.filterExists(repos, true));

% Any that don't we should create from scratch
cellfun(@(p) saveFn(p, set), file.filterExists(repos, false));