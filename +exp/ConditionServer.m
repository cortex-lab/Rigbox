classdef ConditionServer < handle
  %EXP.CONDITIONSERVER Interface for provision of trial parameters
  %   TODO. E.g see also EXP.PRESETCONDITIONSERVER.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  methods (Abstract)
    s = globalParams(obj)
    s = trialSpecificParams(obj)
    p = param(obj, name)
    bool = moreTrials(obj)
    nextTrial(obj)
    update(obj, trialData)
    reset(obj)
  end
  
end