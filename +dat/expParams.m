function p = expParams(ref)
%DAT.EXPPARAMS Loads the parameters struct for given experiment(s)
%   p = DAT.EXPPARAMS(ref) returns the parameters variable saved for each
%   experiment by its reference. 'ref' can be a single string (in which 
%   case we return a single result), or a cell array of strings, in which
%   case a cell array of parameter variables is returned corresponding to
%   each experiment. Any experiments without saved parameters will return
%   empty, [].
%
% Part of Rigbox

% 2013-03 CB created

%If ref is not an array, wrap it so code below works generally
[ref, singleArg] = ensureCell(ref);
%Get the paths where parameters for each experiment will be, if any
files = dat.expFilePath(ref, 'parameters', 'master');
%Check which param files exist and load those into results array
p = cell(size(ref));
present = file.exists(files);
p(present) = loadVar(files(present), 'parameters');

if singleArg
  %If single arg was passed in (i.e. not a cell array, but just a ref,
  %make sure we return a single result (i.e. a single parameter variable,
  %not a cell array of them.
  p = p{1};
end

end

