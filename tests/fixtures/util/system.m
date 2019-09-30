function [status, cmdout] = system(varargin)
%SYSTEM Returns preset output status and message for a given input
%   This is a mock function shadowing `system` for use in tests.  To
%   set a status and message for a given input command, call with a
%   2-element cell as the second argument, as in {status, cmdout}.  To set
%   the same output for all commands, use '*' as the first input arg.
%
%   Examples:
%     global INTEST
%     INTEST = true; % Pass safety check
%     system('ls', {0, sprintf('Music\nVideos\n')})
%     assert(system('ls') == 0)
%     clear system INTEST % Reset after test
% 
%     % Set all system commands to fail
%     global INTEST
%     INTEST = true; % Pass safety check
%     system('*', {1, ''})
%     assert(system('ls'))
%     clear system INTEST % Reset after test
% 
% 2019-09 MW created

persistent outputs
global INTEST
command = varargin{1};
[status, cmdout] = deal([]); % Return empty on setting outputs
% If no map exists create a new one to store mock mod dates
if isempty(outputs)
  outputs = containers.Map(...
            'KeyType', 'char', ...
            'ValueType', 'any');
end

if nargin > 1 && iscell(varargin{2}) % Set outputs
  outputs(command) = varargin{2};
  if isempty(INTEST) || ~INTEST
    fprintf('Set date for %s.  Please set INTEST flag to true\n', command);
  end
else % Get outputs
  % Check the INTEST flag to ensure that calling mock was intended
  if isempty(INTEST) || ~INTEST
    warning('Rigbox:tests:system:notInTest', ...
      ['Mock called without INTEST flag;', ...
      'If called within test, please first set INTEST flag to true.'])
  end
  % Check that a command was previously set for this file
  if ~any(isKey(outputs, {command, '*'}))
    % If not set, throw warning and execute system command
    warning('Rigbox:tests:system:outputNotSet', ...
      'Mock called but output not assigned for this command, calling builtin')
    [status, cmdout] = builtin('system', varargin{:});
  else
    % If set, return saved value
    key = iff(outputs.isKey(command), command, '*');
    outputArgs = outputs(key);
    [status, cmdout] = deal(outputArgs{:});
  end
end