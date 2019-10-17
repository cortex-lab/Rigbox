function rig = devices(name, ~, mockDev)
% HW.DEVICES Function for injecting mock rig object during tests
%  To set a mock, call with a rig structure as an extra argument.  To avoid
%  errors, set the global INTEST flag to true before calling.
%
%  Example:
%    global INTEST
%    hw.devices('testRig', [], struct('timeline', mock));
%    rig = hw.devices;
%    assert(isa(rig.timeline, 'matlab.mock.classes.Mock'))
%    clear devices INTEST
%    
% 2019-09-30 MW created

global INTEST
persistent mockRig % Store our rig object

if nargin < 1 || isempty(name)
  name = 'testRig';
end

if isempty(mockRig)
  mockRig = struct(...
    'name', name, ...
    'clock', hw.ptb.Clock);
end

% Set mock
if nargin > 2
  mockRig = mergeStruct(mockRig, mockDev);
end

if isempty(INTEST) || ~INTEST
  warning('Rigbox:tests:devices:notInTest', ...
    ['Mock called without INTEST flag;', ...
    'If called within test, first set INTEST to true.'])
end
rig = mockRig;
