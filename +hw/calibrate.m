function calibration = calibrate(channel, rewardController, scales, tMin, tMax)
%HW.CALIBRATE Performs measured reward deliveries for calibration
%   TODO. This needs sanitising and incoporating into HW.REWARDCONTROLLER
%
% Part of Rigbox

% 2013-01 CB created

% tMin = 30/1000;
% tMax = 80/1000;
interval = 0.1;
delivPerSample = 300;
nPerT = 3;
% interval = 0.1;
% delivPerSample = 100;
% nPerT = 1;
nVolumes = 5;

signalGen = rewardController.SignalGenerators(strcmp(rewardController.ChannelNames, channel));

settleWait = 2; % seconds

t = meshgrid(linspace(tMin, tMax, nVolumes), zeros(1, nPerT));
% t = [10 25 50 100 200 500 1000]/1000;
% t = [1000]/1000;
n = repmat(delivPerSample, size(t));
dw = zeros(size(t));

approxTime = interval*(n - 1) + n.*t + settleWait*numel(t);
approxTime = sum(approxTime(:));

origParamsFun = signalGen.ParamsFun;

%deliver some just to get the scales to a new reading
signalGen.ParamsFun = @(sz) deal(sz(1), sz(3), 1/sum(sz(1:2)));

try
  % rewardController.deliverMultiple(tMax, interval, 50, true);
  rewardController.command([tMax; interval; 50], 'foreground');
  pause(settleWait);
  prevWeight = scales.readGrams; %now take initial reading
  fprintf('Initial scale reading is %.2fg\n', prevWeight);

  startTime = GetSecs;
  fprintf('Deliveries will take approximately %.0f minute(s)\n', ceil(approxTime/60));

  for j = 1:size(t,2)
    for i = 1:size(t,1)
      rewardController.command([t(i,j); interval; n(i,j)], 'foreground');
      % wait just a moment for drops to settle
      pause(settleWait);
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