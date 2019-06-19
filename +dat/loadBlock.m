function block = loadBlock(varargin)
%DAT.LOADBLOCK Load the designated experiment block(s)
%   BLOCK = loadBlock(EXPREF, [EXPTYPE])
%   BLOCK = loadBlock(SUBJECTREF, EXPDATE, EXPSEQ, [EXPTYPE])
%
%   Loads corresponding block files (if they exist) given one or more
%   experiment references. If there are multiple remote 'main'
%   repositories, all are searched precedence is given to experiments on
%   the master repository.
%
%   Can optionally filter by experiment type, returning only those blocks
%   whose 'expType' field matches the input.  NB: Filtering happens only
%   after loading one block per unique experiment.
%
% See also DAT.EXPPARAMS, DAT.EXPFILEPATH
%
% Part of Rigbox

if nargin == 2 || nargin == 4
  %experiment type was specified in last argument, create a filter function
  %which only returns
  expType = varargin{end};
  filterFun = @(b) iff(isfield(b, 'expType') && strcmp(b.expType, expType), b, []);
  varargin = varargin(1:end - 1);
else
  %experiment type was not specified, filter is identity
  filterFun = @identity;
end

% get the full path for each experiments block
blockpath = dat.expFilePath(varargin{:}, 'block', 'remote');

if iscell(blockpath)
  block = mapToCell(filterFun, mapToCell(@loadFun, blockpath));
else
  block = filterFun(loadFun(blockpath));
end

end

function block = loadFun(p)
% the load function takes the path to a MAT-file containing an experiment
% block. If the file exists, it returns the block, if not, it returns an
% 'empty'.  If a list is provided, the first existing file (if any) is
% loaded and returned
p = ensureCell(p);
I = find(file.exists(p),1);
block = iff(isempty(I), [], @() loadVar(p{I}, 'block'));
end