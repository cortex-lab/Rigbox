function daqController = daqControllerForValve(daqRewardValve, calibrations, addLaser)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

daqController = hw.DaqController;
daqController.ChannelNames = {'rewardValve'};
daqController.DaqIds = 'Dev1';
daqController.DaqChannelIds = {daqRewardValve.DaqChannelId};
daqController.SignalGenerators = hw.RewardValveControl;
daqController.SignalGenerators.ClosedValue = daqRewardValve.ClosedValue;
daqController.SignalGenerators.DefaultValue = daqRewardValve.ClosedValue;
daqController.SignalGenerators.OpenValue = daqRewardValve.OpenValue;
daqController.SignalGenerators.Calibrations = calibrations;
daqController.SignalGenerators.DefaultCommand = daqRewardValve.DefaultRewardSize;

if nargin > 2 && addLaser
  daqController.DaqChannelIds{2} = 'ao1';
  daqController.ChannelNames{2} = {'laserShutter'};
  daqController.SignalGenerators(2) = hw.PulseSwitcher;
  daqController.SignalGenerators(2).ClosedValue = 0;
  daqController.SignalGenerators(2).DefaultValue = 0;
  daqController.SignalGenerators(2).OpenValue = 5;
  daqController.SignalGenerators(2).DefaultCommand = 10;
  daqController.SignalGenerators(2).ParamsFun = @(sz) deal(10/1000, sz, 25);
end


end