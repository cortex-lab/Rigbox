function p = expParams(ref)
%DAT.EXPPARAMS Loads the parameters struct for given experiment(s)
%   p = DAT.EXPPARAMS(ref) returns the parameters variable saved for each
%   experiment by its reference. 'ref' can be a single string (in which 
%   case we return a single result), or a cell array of strings, in which
%   case a cell array of parameter variables is returned corresponding to
%   each experiment. Any experiments without saved parameters will return
%   empty, [].
%
%   If there are multiple remote 'main' repositories, all are searched
%   precedence is given to experiments on the master repository.
%
% See also DAT.LOADBLOCK, DAT.EXPFILEPATH
%
% Part of Rigbox

% 2013-03 CB created

%If ref is not an array, wrap it so code below works generally
[ref, singleArg] = ensureCell(ref);
%Get the paths where parameters for each experiment will be, if any
files = dat.expFilePath(ref, 'parameters', 'remote');
%Check which param files exist and load those into results array
matching = @(p) file.exists(ensureCell(p));
seq = cellfun(@(f)sequence(ensureCell(f)),files);
p = mapToCell(@(p)iff(isempty(p), [], @() loadVar(p,'parameters')), ...
  fun.map(@(p)p.filter(matching).first, seq)); %mu = 0.0490; std = 0.0075
% p = mapToCell(@loadFun, files); %mu = 0.0443; std = 0.0035

if singleArg
  %If single arg was passed in (i.e. not a cell array, but just a ref,
  %make sure we return a single result (i.e. a single parameter variable,
  %not a cell array of them.
  p = p{1};
end