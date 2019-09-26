% preconditions:

% Get the `hw.DaqController` object from within the rig's hardware devices:
rig = hw.devices;
rigFields = fieldnames(rig);
% Get a cell array of each object in the `rig` struct.
rigObjs = cellfun(@(x) rig.(x), rigFields, 'UniformOutput', 0);
% Get the index of the `hw.DaqController` object in `rigObjs`
dcIdxInRig = cellfun(@(x) isa(x, 'hw.DaqController'),... 
                     rigObjs, 'UniformOutput', 0);
try
  % Get the `hw.DaqController` object from `rig` based on its fieldname.
  dc = rig.(rigFields{[dcIdxInRig{:}]});
catch
  error('Rigbox:hw:checkRewardValveCalibration:dcNotFound',...
        ['Could not find a ''hw.DaqController'' object in this rig''s \n'...
         '''hardware.mat'' file.']);
end

% Get the `hw.RewardValveControl` object from within the rig's 
% `hw.DaqController` `SignalGenerators`:
sgClassNames = arrayfun(@class, dc.SignalGenerators,... 
                        'UniformOutput', false);
rvChanIdx = cellfun(@(x) strcmpi('hw.RewardValveControl', x),... 
               sgClassNames);

chan = dc.DaqChannelIds{rvChanIdx}; % NI-DAQ channel we are outputting reward to
amt = 5.0; % volume of reward (in mL)

%% Test 1: Ensure that the class of the Signal Generator output to is valid
chanIdx = contains(dc.DaqChannelIds, chan);

% Get the `hw.ControlSignalGenerator` object from which to deliver reward.
signalGen = dc.SignalGenerators(chanIdx);

assert(strcmpi(class(signalGen), 'hw.RewardValveControl'),... 
       ['The class of the Signal Generator is not a class which can '...
        'deliver reward']);
    
%% Test 2: Ensure that proper name-value pair arguments are used
% Ensure rig hardware is freed up:
clearvars -except amt chan
daqreset;

try
  hw.checkRewardValveCalibration(amt, chan)
catch ex
  errSep = strfind(ex.identifier, ':');
  errName = ex.identifier(errSep(end)+1:end);
  assert(strcmpi(errName, 'nameValueMismatch'));
end

try
  daqreset;
  hw.checkRewardValveCalibration('amt', 5.0, 'chan', 'invalidCh')
catch ex
    errSep = strfind(ex.identifier, ':');
    errName = ex.identifier(errSep(end)+1:end);
    assert(strcmpi(errName, 'rvNotFound'));
end