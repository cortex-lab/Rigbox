classdef PresetConditionServer < exp.ConditionServer
  %EXP.PRESETCONDITIONSERVER Provides preset trials from an array
  %   See also EXP.CONDITIONSERVER.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  properties
  end
  
  properties (Access = protected)
    ConditionIdx = 0
    TrialParams = []
    GlobalParams = []
    RepeatNum
    TrialData = []
  end
  
  methods
    function obj = PresetConditionServer(globalParams, trialParams)
      obj.GlobalParams = globalParams;
      obj.TrialParams = trialParams;
    end
    
    function p = globalParams(obj)
      p = obj.GlobalParams;
    end

    function p = trialSpecificParams(obj)
      p = obj.TrialParams(obj.ConditionIdx);
      p.repeatNum = obj.RepeatNum;
    end

    function bool = moreTrials(obj)
      bool = obj.ConditionIdx < length(obj.TrialParams) || repeatCondition(obj);
    end    
    
    function update(obj, trialData)
      obj.TrialData = trialData;
    end

    function nextTrial(obj)
      if ~repeatCondition(obj)
        % reset the repeat number (new/non-repeat trials have a repeat
        % number of 1
        obj.RepeatNum = 1; 
        % increment the condition index
        obj.ConditionIdx = obj.ConditionIdx + 1;
      else
        % increment the repeat number
        obj.RepeatNum = obj.RepeatNum + 1; 
      end
      assert(obj.ConditionIdx <= length(obj.TrialParams), 'No more conditions for trials');
      
      % new trial, reset TrialData
      obj.TrialData = [];
    end
    
    function reset(obj)
      obj.TrialData = [];
      obj.ConditionIdx = 0;
      obj.RepeatNum = 0;
    end
    
    function p = param(obj, name)
      % trial parameter takes precedence, if it exists
      % otherwise use the global parameter
      if isfield(obj.TrialParams, name)
        p = obj.TrialParams(obj.ConditionIdx).(name);
      else
        p = obj.GlobalParams.(name);
      end
    end
    
    function b = paramExists(obj, name)
      b = isfield(obj.GlobalParams, name) || isfield(obj.TrialParams, name);
    end
  end

  methods (Access = protected)
    function b = repeatCondition(obj)
      prevData = obj.TrialData;
      b = false;
      if ~isempty(prevData)
        if paramExists(obj, 'repeatIncorrectTrial') &&...
            param(obj, 'repeatIncorrectTrial') && prevData.feedbackType < 0
          b = true;
        elseif paramExists(obj, 'repeatNoResponseTrial') &&...
            param(obj, 'repeatNoResponseTrial') && prevData.feedbackType == 0
          b = true;
        end
      end
    end
  end
  
end

