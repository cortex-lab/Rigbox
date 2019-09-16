function calibration = calibrate(channel, rewardController, scales, tMin, tMax, varargin)
%HW.CALIBRATE Performs measured reward deliveries for calibration
%   This function is used by srv.expServer to return a water calibration.
%   It still requires some scales to be attached to the computer.  
%
%   Inputs:
%     channel (char) - the name of the channel to use.  Must match one of
%       the entries in ChannelNames property of rewardController.
%     rewardController (hw.DaqController) - an object configured to deliver
%       water rewards.
%     scales (hw.WeighingScale) - a digital scale object.
%     tMin (double) - the minimum valve opening time to measure.
%     tMax (double) - the maximum valve opening time to measure.
%     
%   Optional Name-Value pairs:
%     delivPerSample (double) - the number of times to open and close the
%       valve for each sample measurment. Default 300
%     interval (double) - the interval in seconds between repeated open
%       times. Ensures fluid settles in tube before next command.  Default
%       0.1
%     nVolumes (double) - the number of different opening times to measure
%       including tMin and tMax.  Must be > 0.  Default 5
%     nPerT (double) - number of times to repeat each opening time
%       measurment.  An average of these is taken for each of the samples.
%       Default 3
%     settleWait (double) - time in seconds to wait between delivering
%       sample and recording a new weight.  Gives the scale reading time to
%       stabalize.  Default 2 seconds.
%     
%   TODO: Sanitize and integrate into HW.REWARDVALVECONTROL
%
% See also HW.REWARDVALVECONTROL, SRV.EXPSERVER/CALIBRATEWATERDELIVERY
%
% Part of Rigbox

% 2013-01 CB created

% Check inputs
narginchk(5,15)
assert(~mod(length(varargin),2), 'Rigbox:hw:calibrate:partialPVpair', ...
  'Incorrect number of Name-Value pairs')
% Check that the scale is initialized
if isempty(scales.Port) || isempty(scales.readGrams)
  error('Rigbox:hw:calibrate:noscales', ...
    'Unable to communicate with scale. Scales object is not properly initialized')
end

% Parse Name-Value pairs
defaults = struct(...
  'interval', 0.1, ... % seconds
  'delivPerSample', 300, ...
  'nPerT', 3, ...
  'nVolumes', 5, ...
  'settleWait', 2); % seconds
inputs = cell2struct(varargin(2:2:end)', varargin(1:2:end)');
p = mergeStructs(inputs, defaults);

signalGen = rewardController.SignalGenerators(strcmp(rewardController.ChannelNames, channel));
t = meshgrid(linspace(tMin, tMax, p.nVolumes), zeros(1, p.nPerT));
% t = [10 25 50 100 200 500 1000]/1000;
% t = [1000]/1000;
n = repmat(p.delivPerSample, size(t));
dw = zeros(size(t));

approxTime = p.interval*(n - 1) + n.*t + p.settleWait*numel(t);
approxTime = sum(approxTime(:));

origParamsFun = signalGen.ParamsFun;

% deliver some just to check scales are registering changes
fprintf('Checking the scale...\n');

signalGen.ParamsFun = @(sz) deal(sz(1), sz(3), 1/sum(sz(1:2)));

prevWeight = scales.readGrams;
rewardController.command([tMax; p.interval; 50], 'foreground');
pause(p.settleWait);
newWeight = scales.readGrams;
assert(newWeight > prevWeight + 0.02, ...
  'Rigbox:hw:calibrate:deadscale',...
  'Error: Scale is not registering changes in weight. Confirm scale is properly connected and that water is landing into the dish')

prevWeight = newWeight;
fprintf('Initial scale reading is %.2fg\n', prevWeight);

startTime = GetSecs;
fprintf('Deliveries will take approximately %.0f minute(s)\n', ceil(approxTime/60));

try
  for j = 1:size(t,2)
    for i = 1:size(t,1)
      rewardController.command([t(i,j); p.interval; n(i,j)], 'foreground');
      % wait just a moment for drops to settle
      pause(p.settleWait);
      newWeight = scales.readGrams;
      dw(i,j) = newWeight - prevWeight;
      prevWeight = newWeight;
      ml = dw(i,j)/n(i,j);
      fprintf('Weight delta = %.2fg. Delivered %ful per %fms\n', dw(i,j), 1000*ml, 1000*t(i,j));
    end
  end
catch ex
  signalGen.ParamsFun = origParamsFun;
  rethrow(ex)
end
signalGen.ParamsFun = origParamsFun;

endTime = GetSecs;
fprintf('Deliveries took %.2f minute(s)\n', (endTime - startTime)/60);


%different delivery durations appear in each column, repeats in each row
%from the data, make a measuredDelivery structure
ul = 1000*mean(dw./n, 1);
calibration = struct(...
  'durationSecs', num2cell(t(1,:)),...
  'volumeMicroLitres', num2cell(ul));
signalGen.Calibrations(end + 1).dateTime = now;
signalGen.Calibrations(end).measuredDeliveries = calibration;

end