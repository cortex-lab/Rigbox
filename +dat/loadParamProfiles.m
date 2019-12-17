function p = loadParamProfiles(expType)
%DAT.LOADPARAMPROFILES Loads the parameter sets for given experiment type
%   TODO
%
% Part of Rigbox

% 2013-07 CB created
% 2017-02 MW Param struct now sorted in ASCII dictionary order
narginchk(1,1)
fn = 'parameterProfiles.mat';
mainPath = fullfile(dat.reposPath('main', 'remote'), fn);

p = struct; % default is to return an empty struct

if any(file.exists(mainPath))
  origState = warning;
  warning('off', 'MATLAB:load:variableNotFound'); % suppress not found warnings
  if size(mainPath, 1) > 1
      loaded = mapToCell(@(m)getOr(load(m, expType), expType, struct), mainPath); % load profiles for specific experiment type
%       fnames = unique(cellflat(mapToCell(@fieldnames, loaded)));
%       fvals = mapToCell(@(f)cell2mat(mapToCell(@(l)getOr(l,f), loaded)'), fnames);
%       loaded = struct(expType, cell2struct(fvals,fnames))
      merged = mergeStructs(loaded{:});
      loaded = iff(isempty(fieldnames(merged)), merged, struct(expType, merged));
  else
      loaded = load(mainPath, expType);
  end
  warning(origState);
  if isfield(loaded, expType)
    [~, I] = sort(lower(fieldnames(loaded.(expType))));
    p = orderfields(loaded.(expType), I); % extract those profiles to return
  end
end

end