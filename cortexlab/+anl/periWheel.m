function [wdx, perit] = periWheel(block, perit, locit)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if nargin < 3
  locit = [block.trial.stimulusCueStartedTime];
end

if nargin < 2
  perit = -3:0.01:3;
end

midperit = perit(:);
midperit = mean([midperit(1:end-1) midperit(2:end)], 2)';
surrperit = [(2*perit(1)-midperit(1)) midperit (2*perit(end)-midperit(end))];

sampleTimes = bsxfun(@plus, surrperit, locit(:));
wxByStim = interp1(block.inputSensorPositionTimes, block.inputSensorPositions, sampleTimes);
wdx = diff(wxByStim, [], 2);

end

