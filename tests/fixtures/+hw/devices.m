function rig = devices(name, init, mockDev)
global INTEST
persistent mockRig % Store our rig object

if isempty(mockRig)
  mockRig = struct(...
    'name', name, ...
    'clock', hw.ptb.Clock);
end
if nargin < 1 || isempty(name)
  name = 'testRig';
end
if nargin < 2
  init = true;
end

% Set mock
if nargin > 2
  mockRig = mergeStruct(mockRig, mockDev);
  rig = mockRig;
  return
end

if isempty(INTEST) || ~INTEST
  warning('Rigbox:tests:devices:notInTest', ...
    ['Mock called without INTEST flag;', ...
    'If called within test, first set INTEST to true.'])
end
rig = mockRig;
