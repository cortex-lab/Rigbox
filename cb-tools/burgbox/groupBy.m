function [xg, groups] = groupBy(x, gClass, groups)
%GROUPBY Groups elements of on array by one or more criteria
%
% Warning: this function is incredibly useful!
%
%   [xg, groups] = GROUPBY(x, class, [groups]) takes an array of data 'x',
%   with each element's grouping class in array 'class'. It returns 'xg',
%   the rows of 'x' grouped in elements of a cell array. It also returns
%   'groups', a list of the classes of each group in 'xg'.
%
%   Optionally takes the grouping classes, 'groups', to actually include
%   (and in that order), otherwise it defaults to using all unique classes,
%   sorted.
%
%   If the input argument 'classes' is a cell array, each element specifies
%   a different sets of grouping classes to apply in a nested grouping of the
%   data. The output argument 'groups' is always a cell array (i.e.
%   defaults to nested grouping semantics), where if only one level of
%   grouping is specified, it is a singleton array with the grouping
%   classes as the first and only element.
%
%   Some examples to hopefully make all this clearer, starting with:
%
%     data = (-4:4)' % ensure data to group is a column vector
%
%   1) Simplest use, one level of grouping, and grouping classes default to
%   all unique classes:
%     [xg, grps] = GROUPBY(data, sign(data))
%     % now, xg = { [-4;-3;-2;-1] [0] [1;2;3;4] } and grps = { [-1 0 1] }
%
%   2) Now, overriding grouping classes to specify a subset and their order:
%     [xg, grps] = GROUPBY(data, sign(data), [1 -1])
%     % now, xg = { [1;2;3;4] [-4;-3;-2;-1] } and grps = { [1 -1] }
%
%   3) Now, multiple levels of grouping classes (default groups in each):
%     [xg, grps] = GROUPBY(data, {sign(data) mod(data, 2)})
%     % now, xg = { { [-4;-2] [-3;-1] } { [0] [] } { [2;4] [1;3] } } and 
%     % grps = { [-1 0 1] [0 1] }
%   In the last case, note that the data is grouped in nested cell arrays,
%   where at the first level, the data are grouped by the sign (-1, 0 or
%   1), then at the next level, the data are grouped by whether even or odd
%   (i.e. mod(data, 2) = 0 or 1).
%
% Part of Burgbox

% 2013-11 CB created


gClass = ensureCell(gClass);

if isempty(gClass)
  xg = x;
else
  clss = gClass{1}; %group classes considered at this (nesting) level
  if nargin < 3
    % no groups specified so find sorted/unique of each class
    groups = mapToCell(@(c) unique(c), gClass);
  end
  groups = ensureCell(groups);
  %function to select using indices,idx the array in each element of from
  select = @(idx, from) mapToCell(@(e) e(idx), from);
  %do grouping at this level nesting level, and recursively group deeper
  %levels
  if iscellstr(clss)
    nested = @(c) groupBy(x(strcmp(clss, c),:), select(strcmp(clss, c), gClass(2:end)), groups(2:end));
  else
    nested = @(c) groupBy(x(clss == c,:), select(clss == c, gClass(2:end)), groups(2:end));
  end
  xg = mapToCell(nested, groups{1});
end
end