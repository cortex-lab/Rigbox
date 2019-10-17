function varargout = KbQueueCheck(deviceIndex, keyPress)
% KBQUEUECHECK Simulates output for a given key press
%   This is a mock function shadowing KbQueueCheck for use in tests.  To
%   set the output for a given deviceIndex, call with a cell array of the
%   output or the name of the key you want to simulate as the second
%   argument.
%
%   Inputs:
%     deviceIndex - The device id to check.  For the default device, use -1
%       or [].
%     keyPress - Either a cell array whose length equals the number of
%       output arguments in KbQueueCheck or the char whose key you wish to
%       simulate as pressed.
%
%   All outputs set by keyPress (any unset values will be empty).  If the
%   behaviour for deviceIndex is not set, the PTB function is called and
%   its output returned.
%
%   Examples:
%     global INTEST
%     INTEST = true; % Pass safety check
%     KbQueueCheck([], 'q'); % Simulate 'q' key press
%     [~, firstPress] = KbQueueCheck();
%     assert(firstPress(KbName('q')) > 0)
%     clear KbQueueCheck INTEST % Reset after test
%
%     % Simulate zero keyboard interaction for a given device
%     KbQueueCheck(1, [{false}, repmat({zeros(1,256)},1,4)]);
%     assert(~KbQueueCheck(1))
%     
% 2019-09 MW created


% [pressed, firstPress, firstRelease, lastPress, lastRelease] =
% KbQueueCheck(deviceIndex, keyPress)
persistent KbQueue
global INTEST

if nargin < 1; deviceIndex = -1; end
nargs = 5; % The number of output arguments in KbQueueCheck

% If no map exists create a new one to store mock mod dates
if isempty(KbQueue)
  KbQueue = containers.Map('KeyType', 'int32', 'ValueType', 'any');
end

if nargin < 2
  % Check the INTEST flag to ensure that calling mock was intended
  if isempty(INTEST) || ~INTEST
    warning('Rigbox:tests:KbQueueCheck:notInTest', ...
      ['Mock called without INTEST flag;', ...
      'If called within test, first set INTEST to true.'])
  end
  % Check that a date was previously set for this file
  if ~isKey(KbQueue, deviceIndex)
    % If not set, throw warning and return real mod date
    warning('Rigbox:tests:KbQueueCheck:keypressNotSet', ...
      'Mock called but date not set, returning actual')
    orig = pwd;
    mess = onCleanup(@() cd(orig));
    PTB = fileparts(which('SetupPsychtoolbox'));
    cd(fullfile(PTB, 'PsychBasic'));
    output = cell(1, nargs);
    [output{:}] = KbQueueCheck(iff(deviceIndex > -1, deviceIndex, []));
  else
    % If set, return saved value
    output = pick(KbQueue, deviceIndex);
    if isa(output, 'fun.CellSeq')
      if isempty(output.rest) % No more in sequence, remove entry from map
        KbQueue.remove(deviceIndex);
      else % Reassign rest
        KbQueue(deviceIndex) = output.rest;
      end
      output = output.first;
      if ischar(output) % Convert to actual output
        idx = KbName(output);
        output = cell(1, nargs);
        output{2} = zeros(size(KbName('KeyNames')));
        output{2}(idx) = GetSecs();
      end
    else % One-shot: remove key from map
      KbQueue.remove(deviceIndex);
    end
  end
else % Set mock
  if iscell(keyPress) || isa(keyPress, 'fun.CellSeq')
    % Assume all output args set
    output = keyPress;
  else
    % Assign only second output
    output = cell(1, nargs);
    output{2} = zeros(size(KbName('KeyNames')));
    output{2}(KbName(keyPress)) = GetSecs();
  end
  KbQueue(iff(isempty(deviceIndex), -1, deviceIndex)) = output; % Set our output
  if isempty(INTEST) || ~INTEST
    fprintf('Set date for %s.  Please set INTEST flag to true\n', p);
  end
  % Return empty on setting date
  output = cell(1, nargout);
end

output = output(1:nargout);
[varargout{1:nargout}] = deal(output{:});