function s = screenSyncAlignment(block, pdt, pdchan)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

pdt = pdt(:); % ensure it's a row vector

[~, vals] = kmeans(pdchan, 2); % find best 2 photodiode value clusters (i.e. it is triggered or untriggered)
thresh = mean(vals); % threshold is mean their mean
pdFlips = abs(diff(pdchan > thresh)) > 0; % look for the flips
% assume flip time is halfway between the threshold crossings
pdFlipTimes = mean([pdt([false ; pdFlips]) pdt([pdFlips ; false])], 2);

blockFlipsTimes = block.stimWindowUpdateTimes;

if numel(pdFlipTimes) - 1 == numel(blockFlipsTimes)
  % in most datasets the first photodiode flip occurs without a
  % corresponding stimWindowUpdate element, so just ignore that one
  pdFlipTimes = pdFlipTimes(2:end);
end

% On b2 scope there is also an extra photodiode flip at the end of the experiment
if numel(pdFlipTimes) - 2 == numel(blockFlipsTimes)
    pdFlipTimes([1 end]) = [];
end

% photodiode now picks up two additional flips at the end of sessions for
% unknown reasons. 2016/06/22 SF
if numel(pdFlipTimes) - 3 == numel(blockFlipsTimes)
    pdFlipTimes([1 end-1 end]) = [];
end

[co, stats] = robustfit(blockFlipsTimes, pdFlipTimes);
assert(stats.ols_s < 0.02, 'Significant error in fit')

s.coeff = co';
s.blockToPdTimeFrame = @(t)t*co(2) + co(1);
s.pdToBlockTImeFrame = @(t)(t - co(1))/co(2);
%offset to place every block flip after corresponding photodiode flip
lag = -max(blockFlipsTimes*co(2) - pdFlipTimes);
toPDTimeFrameLag = @(t)t*co(2) + lag;

if isfield(block.trial, 'stimulusCueStartedTime')
  s.stimOnTimes = follows(...
    toPDTimeFrameLag([block.trial.stimulusCueStartedTime]), pdFlipTimes);
end

if isfield(block.trial, 'stimulusCueEndedTime')
  s.stimOffTimes = follows(...
    toPDTimeFrameLag([block.trial.stimulusCueEndedTime]), pdFlipTimes);
end

  function t = follows(a, b)
    n = numel(a);
    t = zeros(size(a));
    ti = t;
    for ii = 1:n
      ti(ii) = find(b > a(ii), 1);
      t(ii) = b(ti(ii));
    end
    
    d = t - a;
    range = max(d) - min(d);
    assert((range/mean(d)) < 4.2, 'delta range is much larger than the mean');
  end

end

