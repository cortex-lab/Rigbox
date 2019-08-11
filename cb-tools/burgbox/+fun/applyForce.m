function [ex, exElems] = applyForce(funs, varargin)
%FUN.APPLYFORCE Calls function on each element continuing on exceptions
%  Execute multiple functions with all values of varargin.  Allows the
%  creation of a single function handle that can execute multiple others.
%
%  Example:
%    f = Figure; % Create a figure and run multiple functions upon close
%    f.CloseFcn = @() fun.apply({@(~)job1, @(a)job2(a)}, var);
%
%  Inputs:
%    funs (cell) - Array of function handles to be executed
%    varargin - Arguments to be passed to each function in funs
%
%  Outputs:
%    ex (MException) - Array of exceptions encountered during execution
%    exElems (cell) - Array containing cell of function handles and their 
%      inputs that caused an exception
%
% See also FUN.APPLY
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

