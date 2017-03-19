function s = bin(edges, pos, x, combineFun)
%BIN Bins data according to a position
%   s = BIN(edges, pos, [x], [combineFun]) bins the data 'x' according to
%   it's corresponding position 'pos' into bins with edges specified by
%   'edges'. If 'x' is not passed, it defaults to an array of ones of the
%   same size as pos (i.e. so that a series of ones are binned with the
%   specified positions). 
%
% Part of Burgbox

% 2014-04 CB created

if nargin < 3 || isempty(x)
  % if not specified, x is an array of ones
  x = ones(size(pos));
  if iscell(pos)
    x = mapToCell(@(p) ones(size(p)), pos);
  end
end

if nargin < 4
  % default way to combine across a bin is simply to sum values
  combineFun = @(M) sum(M, 1);
end

nBins = numel(edges);

if ~iscell(pos)
  [~, binIdx] = histc(pos, edges);
  nData = sum(binIdx > 0);  
  s = full(combineFun(sparse(1:nData, binIdx(binIdx > 0), x(binIdx > 0),...
    nData, nBins)));
else
  % multiple data sets to bin, so build up our bin array with recursive
  % calls
  nSets = numel(pos);
  s = zeros(nSets, nBins);
  for ii = 1:nSets
    s(ii,:) = bin(edges, pos{ii}, x{ii}, combineFun);
  end
end

end