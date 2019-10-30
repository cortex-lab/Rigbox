function checkRewardValveCalibration(varargin)
% HW.CHECKREWARDVALVECALIBRATION delivers a set amount of reward to check reward valve calibration
%
% This function is used to deliver a set amount of reward via a reward
% valve controlled by a NI-DAQ: a user should check the amount of water
% delivered manually by catching the delivered reward via a falcon tube or
% similar container.
%
% Inputs:
%   `amt` (numeric): The amount (in mL) of water to deliver. (default =
%     5.0)
%   `chan` (string): The channel of the NI-DAQ associated with the reward
%      valve. If not given, `chan` is found by getting the channel 
%      associated with the `hw.RewardValveControl` object in the rig's 
%      `hw.DaqController` object.
%
% Examples:
%   - Check that 5 mL of water is delivered:
%   `hw.checkRewardValveCalibration()`
%   - Check that 10 mL of water is delivered via 'ao1':
%   `hw.checkRewardValveCalibration('amt', 10.0, 'chan', 'ao1')`
%
% See also: `hw.calibrate`, `hw.RewardValveControl`
%
% Todo: Sanitize and integrate into `hw.RewardValveControl`
% Todo: Create appropriate tests using mock objects.

%% Set input arg values and get `hw.RewardValveControl` object from which to deliver reward

% If the name-value pairs don't match up, throw error.
if ~all(cellfun(@ischar, (varargin(1:2:end)))) || mod(length(varargin),2)
  error('Rigbox:hw:checkRewardValveCalibration:nameValueMismatch', ...
        ['If using input arguments, %s requires them to be constructed '... 
         'in name-value pairs'], mfilename);
end

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
chan = dc.DaqChannelIds{rvChanIdx};

% Set default values for input args.
defaults = struct(...
  'amt', 5.0, ...
  'chan', chan);

% Convert user-defined `varargin` into struct.
inputs = cell2struct(varargin(2:2:end)', varargin(1:2:end)');

% Merge `inputs` and `defaults`, making sure fields for `inputs` overwrites
% the same named fields for `defaults`.
argsStruct = mergeStructs(inputs, defaults);

% De-struct input args
amt = argsStruct.amt;
chan = argsStruct.chan;

% Get the `hw.RewardValveControl` object.
rv = dc.SignalGenerators(contains(dc.DaqChannelIds, chan));
if isempty(rv)
  error('Rigbox:hw:checkRewardValveCalibration:rvNotFound',...
  ['Could not find a `hw.RewardValveControl` object in this rig''s \n'...
  '`hw.DaqController` object, or an inappropriate `chan` input \n'...
  'argument was given.']);
end
%% Deliver reward

% Get the most recent, largest delivery volume, `v`, and time, `t`, taken
% to deliver that volume, from the `rv` calibrations table.
v = rv.Calibrations(end).measuredDeliveries(end).volumeMicroLitres;
t = rv.Calibrations(end).measuredDeliveries(end).durationSecs;
% Get the number of pulses required to deliver a reward of amount `amt` in
% increments of `v`.
nPulses = ceil(amt*10e2 / v); 

% Set-up command, `cmd`, to send to `dc` to deliver reward.
interval = 0.2; % interval b/w pulses in s
cmd = [t; interval; nPulses]; % command to output to `dc`

% Print to screen how long it will take to check this calibration:
totalTInMins = ((interval+t)*nPulses)/60;
fprintf('This calibration check will take approximately %0.2f mins\n',... 
    totalTInMins);

% Change `ParamsFun` of `rv` to deliver pulses as 
% [t, nPulses, frequency]. 
origParamsFun = rv.ParamsFun; % we'll reset `ParamsFun` to this
rv.ParamsFun = @(cmd) deal(cmd(1), cmd(3), 1/(sum(cmd(1)+cmd(2))));

% Deliver command to `dc`.
dc.command(cmd, 'foreground');

% Reset `ParamsFun`.
rv.ParamsFun = origParamsFun;

end
