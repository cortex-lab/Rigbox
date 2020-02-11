function p = loadParamProfiles(expType)
%DAT.LOADPARAMPROFILES Loads the parameter sets for given experiment type
%   Loads a struct of parameter structures from a MAT file called
%   'parameterProfiles'. Each field of this struct is a parameter set name
%   for a given expType.  Parameters of a given expType can be saved using
%   the DAT.SAVEPARAMPROFILE function.
%
%   Input:
%     expType (char): The name of the experiment type, e.g. ChoiceWorld.
%
%   Output:
%     p (struct): a scalar struct of parameter sets for the given
%       experiment type.  Each fieldname holds a different parameter
%       structure.  The fields are sorted in ASCII dictionary order.
%
%   Example:
%     dat.saveParamProfile('ChoiceWorld', 'defSet', exp.choiceWorldParams)
%     profiles = dat.loadParamProfiles('ChoiceWorld');
%     p = exp.Parameters(profiles.defSet);
%   
% See also DAT.SAVEPARAMPROFILE, DAT.PATHS
%
% Part of Rigbox

% 2013-07 CB created
% 2017-02 MW Param struct now sorted in ASCII dictionary order

fn = 'parameterProfiles.mat';
masterPath = fullfile(dat.reposPath('main', 'master'), fn);

p = struct; %default is to return an empty struct

if file.exists(masterPath)
  origState = warning;
  warning('off', 'MATLAB:load:variableNotFound'); %suppress not found warnings
  loaded = load(masterPath, expType); %load profiles for specific experiment type
  warning(origState);
  if isfield(loaded, expType)
    [~, I] = sort(lower(fieldnames(loaded.(expType))));
    p = orderfields(loaded.(expType), I); %extract those profiles to return
  end
end

end