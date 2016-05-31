classdef StartTrial < exp.Action
  %EXP.STARTTRIAL Instruction to start a new trial in an experiment
  %   Convenience action for use with an exp.EventHandler. When activated,
  %   it instructs the experiment to start a new trial.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  properties
  end
  
  methods
    function perform(obj, eventInfo, dueTime)
      startTrial(eventInfo.Experiment, dueTime);
    end
  end
  
end

