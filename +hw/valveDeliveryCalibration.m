function c = valveDeliveryCalibration(openTimeRange, scalesPort, openValue,...
  closedValue, daqChannel, daqDevice)
%HW.VALVEDELIVERYCALIBRATION Returns a calibration struct for water reward
%   Returns a struct containing a range of valve open-close times and the
%   resulting mean volume of water delivered.  This can be used to
%   calibrate water delivery without having to run SRV.EXPSERVER.
%
%   The calibration requires the use of a weighing scale that can interface
%   with the computer via either USB or serial cable.  For example the
%   ES-300HA 300gx0.01g Precision Scale + RS232 to USB Converter
%
%
% See also HW.REWARDVALVECONTROL, HW.WEIGHINGSCALE, HW.DAQCONTROLLER
%
% Part of Rigbox

% c. 2013 CB created

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
daqController.SignalGenerators.DefaultCommand = 5;
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

