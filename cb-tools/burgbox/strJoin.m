function str = strJoin(input, separator)
%STRJOIN Concatenate an array into a single string.
%   S = STRJOIN(C, [separator]) takes an array C and returns a string S
%   which concatenates array elements with comma. C can be a cell array
%   of strings, a character array, a numeric array, or a logical array. If
%   'C' is a matrix, it is first flattened to get an array and concateneted.
%   Optionally, the 'separator' between each element can be specified, or
%   the default separator is a single space.
%
% Examples
%
%     >> str = STRJOIN({'this','is','a','cell','array'})
%     str =
%     this is a cell array
%
%     >> str = STRJOIN([1,2,2],'_')
%     str =
%     1_2_2
%
%     >> str = STRJOIN({1,2,2,'string'},'\t')
%     str =
%     1 2 2 string
%
%   Note that MATLAB implemented a similar function, STRJOIN, in R2013a.
%
% Part of Burgbox

% 2014-01 CB created


if nargin < 2
  separator = ' '; % default to single space separator
end

assert(ischar(separator), 'Invalid separator input: %s', class(separator));
separator = strrep(separator, '%', '%%');

if ~isempty(input)
  if ischar(input)
    input = cellstr(input);
  end
  if isnumeric(input) || islogical(input)
    str = [repmat(sprintf(['%.15g', separator], input(1:end-1)),...
      1, ~isscalar(input)), ...
      sprintf('%.15g', input(end))];
  elseif iscellstr(input)
    str = cellStrJoin(input);
  elseif iscell(input)
    for ii = 1:numel(input) %iterate over and handle each element in turn
      elem = input{ii};
      if ischar(elem)
        continue; % leave element as a string
      elseif isnumeric(elem) || islogical(elem)
        input{ii} = sprintf('%.15g', elem); % format number as a string
      elseif iscell(elem)
        % format inner cell array recursively
        input{ii} = strJoin(elem, separator);
      else
        error('burgbox:strJoin:invalidInput', 'Unsupported input class: %s', class(elem));
      end
    end
    str = cellStrJoin(input);
%     str = strJoin(mapToCell(@(x) strJoin(x, separator), input), separator);
  else
    error('burgbox:strJoin:invalidInput', 'Unsupported input class: %s', class(input));
  end
else
  str = '';
end

  function str = cellStrJoin(in)
    str = [repmat(sprintf(['%s', separator], in{1:end-1}),...
      1, ~isscalar(in)), sprintf('%s', in{end})];
  end
end