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
%   `pulse_amt` (numeric): The amount (in uL) of water to deliver per 
%      pulse. (default = 3)
%   'interval' (numeric): The time (in s) to wait between pulses (default =
%      0.2)
%   `valve` (integer, 1 or 2): The number of the valve to calibrate. 
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
dcIdxInRig = cellfun(@(x) isa(x, 'hw.DaqController') || isa(x, 'hw.DaqControllerParallel'),... 
                     rigObjs, 'UniformOutput', 0);
try
  % Get the `hw.DaqController` object from `rig` based on its fieldname.
  dc = rig.(rigFields{[dcIdxInRig{:}]});
catch
  error('Rigbox:hw:checkRewardValveCalibration:dcNotFound',...
        ['Could not find a ''hw.DaqController'' object in this rig''s \n'...
         '''hardware.mat'' file.']);
end

% Set default values for input args.
defaults = struct(...
  'amt', 1.0, ...
  'amt_per_pulse', 2.0, ...
  'interval', 0.1, ...
  'valve', 1);

% Convert user-defined `varargin` into struct.
inputs = cell2struct(varargin(2:2:end)', varargin(1:2:end)');

% Merge `inputs` and `defaults`, making sure fields for `inputs` overwrites
% the same named fields for `defaults`.
argsStruct = mergeStructs(inputs, defaults);

% De-struct input args
amt = argsStruct.amt;
amt_per_pulse = argsStruct.amt_per_pulse;
interval = argsStruct.interval;
valve = argsStruct.valve;

% Get the `hw.RewardValveControl` object.
rv = dc.SignalGenerators(strcmp(dc.ChannelNames, 'reward'));
if isempty(rv)
  error('Rigbox:hw:checkRewardValveCalibration:rvNotFound',...
  ['Could not find a `hw.RewardValveControl` object in this rig''s \n'...
  '`hw.DaqController` object, or an inappropriate `chan` input \n'...
  'argument was given.']);
end
%% Deliver reward

% Get the time to pulse the valve
t = rv.pulseDuration(amt_per_pulse, valve);
% Get the number of pulses required to deliver a reward of amount `amt` in
% increments of `v`.
nPulses = ceil(amt*10e2 / amt_per_pulse); 

% Set-up command, `cmd`, to send to `dc` to deliver reward.
cmd = [0,0];
cmd(valve) = amt_per_pulse;

% Print to screen how long it will take to check this calibration:
totalTInMins = ((interval+t)*nPulses)/60;
fprintf('This calibration check will take approximately %0.2f mins\n',... 
    totalTInMins);

% Deliver command to `dc`.
for pulse_i = 1:nPulses
    dc.command('reward', cmd);
    pause(interval);
end

end