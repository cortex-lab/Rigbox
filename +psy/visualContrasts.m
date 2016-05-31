function cons = visualContrasts(trials)
%PSY.VISUALCONTRASTS Stimuli visual contrasts for each trial
%   c = PSY.VISUALCONTRASTS(trials) Returns a matrix of visual stimuli
%   contrasts for each trial. Each column is for a different trial, and
%   each row is the contrast of each stimulus present during each trial.
%
% Part of Rigbox

% 2013-06 CB created

condition = [trials.condition];

if numel(condition) > 1
  if isrow(condition(1).visCueContrast)
    cons = cell2mat({condition.visCueContrast}')';  
  else
    cons = cell2mat({condition.visCueContrast});
  end
else
  cons = zeros(2, 0);
end
end

