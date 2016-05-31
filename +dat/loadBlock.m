function block = loadBlock(varargin)
%loadBlock Load the designated experiment block(s)
%   BLOCK = loadBlock(EXPREF, [EXPTYPE])
%
%   BLOCK = loadBlock(SUBJECTREF, EXPDATE, EXPSEQ, [EXPTYPE])

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
blockpath = dat.expFilePath(varargin{:}, 'block', 'master');

% the load function takes the path to a MAT-file containing an experiment
% block. If the file exists, it returns the block, if not, it returns an
% 'empty'.
loadFun = @(p) iff(exist(p, 'file'), @() loadVar(p, 'block'), []);

if iscell(blockpath)
  block = mapToCell(filterFun, mapToCell(loadFun, blockpath));
else
  block = filterFun(loadFun(blockpath));
end

end

