function rdx = wheelResponseDeltas(block)
%anl.wheelResponseDeltas Relative wheel turn during each response period
%   Detailed explanation goes here

gotrials = [block.trial.responseMadeID] <3; % responseMade love trials

tr = block.trial(gotrials);

rEnd = [tr.inputThresholdCrossedTime];
rStart = [tr.interactiveStartedTime];

wt = block.inputSensorPositionTimes;
wx = block.inputSensorPositions;

wfindbefore = @(evt)find(wt<=evt, 1, 'last');
wfindafter = @(evt)find(wt>=evt, 1, 'first');

% find the first wheel sample after each interactive onset
widxRStart = arrayfun(wfindafter, rStart);
% find the last wheel sample before each inputThresholdCrossedTime
widxREnd = arrayfun(wfindbefore, rEnd);

rdx = Inf(size(gotrials));
rdx(gotrials) = wx(widxREnd) - wx(widxRStart);

end

