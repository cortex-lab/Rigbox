function c = valveDeliveryCalibration(openTimeRange, scalesPort, openValue,...
  closedValue, daqChannel, daqDevice)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if nargin < 3 || isempty(openValue)
  openValue = 5;
end
if nargin < 4 || isempty(closedValue)
  closedValue = 0;
end
if nargin < 5 || isempty(daqChannel)
  daqChannel = 'ao0';
end
if nargin < 6
  daqDevice = 'dev1';
end
% configure a weighing scale for weighing the deliveries
scales = hw.WeighingScale;
scales.ComPort = scalesPort;
scales.init;

% configure a daq controller for controlling the valve
daqController = hw.DaqController;
daqController.ChannelNames = {'rewardValve'};
daqController.DaqIds = daqDevice;
daqController.DaqChannelIds = {daqChannel};
daqController.SignalGenerators = hw.RewardValveControl;
daqController.SignalGenerators.ClosedValue = closedValue;
daqController.SignalGenerators.DefaultValue = closedValue;
daqController.SignalGenerators.OpenValue = openValue;
daqController.SignalGenerators.DefaultCommand = 3;
try
  daqController.createDaqChannels();
  c = hw.calibrate('rewardValve', daqController, scales, openTimeRange(1), openTimeRange(2));
  daqController.DaqSession.delete();
  scales.cleanup();
catch ex
  scales.cleanup();
  rethrow(ex)
end

end

