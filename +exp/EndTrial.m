classdef EndTrial < exp.Action
  %EXP.ENDTRIAL Instruction to end the current trial in an experiment
  %   Convenience action for use with an EventHandler. This will end the
  %   current trial in the experiment.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  properties
  end
  
  methods
    function perform(obj, eventInfo, dueTime)
      endTrial(eventInfo.Experiment, dueTime);
    end
  end
  
end

