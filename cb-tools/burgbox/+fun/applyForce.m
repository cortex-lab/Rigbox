function [ex, exElems] = applyForce(funs, varargin)
%FUN.APPLYFORCE Calls function on each element continuing on exceptions
%   TODO
%
% Part of Burgbox

% 2013-01 CB created

ex = {};
exElems = {};

[funs, varargin{1:end}] = tabulateArgs(funs, varargin{:});
n = numel(funs);

if numel(varargin) > 0
  argSets = mapToCell(@(varargin) varargin, varargin{:});
else
  argSets = cell(repmat({{}},1,n));
end

for ii = 1:n
  try
%     fprintf('%s on ', func2str(funs{ii}));
%     disp(argSets{ii});
    funs{ii}(argSets{ii}{:});
  catch thisEx
    ex = [ex, thisEx];
    exElems = [exElems, {funs{ii} argSets{ii}}];
  end
end

end

