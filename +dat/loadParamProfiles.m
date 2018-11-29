function p = loadParamProfiles(expType)
%DAT.LOADPARAMPROFILES Loads the parameter sets for given experiment type
%   TODO
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