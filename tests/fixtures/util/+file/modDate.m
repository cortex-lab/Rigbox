function d = modDate(p, setDate)
%MODDATE Returns preset modification date for a given input
%   This is a mock function shadowing file.modDate for use in tests.  To
%   set a modification date for a given file or folder, call with the
%   datenum as the second argument.
%
%   Example:
%     global INTEST
%     INTEST = true; % Pass safety check
%     p = which('addRigboxPaths');
%     file.modDate(p, now);
%     assert(diff(floor([now, file.modDate(p)])) == 0)
%     clear modDate INTEST % Reset after test
% 
% Part of Rigbox tests

% 2019-09 MW created

persistent dates
global INTEST

d = []; % Return empty on setting date
% If no map exists create a new one to store mock mod dates
if isempty(dates)
  dates = containers.Map(...
            'KeyType', 'char', ...
            'ValueType', 'double');
end

if nargin > 1 % Set date
  % If not setting date, return 
  dates(p) = setDate;
  if isempty(INTEST) || ~INTEST
    fprintf('Set date for %s.  Please set INTEST flag to true\n', p);
  end
else % Get date
  % Check the INTEST flag to ensure that calling mock was intended
  if isempty(INTEST) || ~INTEST
    warning('Rigbox:tests:modDate:notInTest', ...
      ['Mock called without INTEST flag;', ...
      'If called within test, first set INTEST to true.'])
  end
  % Check that a date was previously set for this file
  if ~isKey(dates, p)
    % If not set, throw warning and return real mod date
    warning('Rigbox:tests:modDate:dateNotSet', ...
      'Mock called but date not set, returning actual')
    getDate = @(f) getOr(dir(f), 'datenum');
    d = iff(iscell(p), @()mapToCell(getDate, p), @()getDate(p));
  else
    % If set, return saved value
    d = pick(dates, p);
  end
end