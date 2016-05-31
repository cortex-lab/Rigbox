classdef StartPhase < exp.Action
  %EXP.STARTPHASE Instruction to start a particular experiment phase
  %   Convenience action for use with an exp.EventHandler. This will start
  %   the specified phase in the experiment.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  properties
    Name%the name of the phase to start
  end
  
  methods
    function obj = StartPhase(name)
      obj.Name = name;
    end

    function perform(obj, eventInfo, dueTime)
      startPhase(eventInfo.Experiment, obj.Name, dueTime);
    end
  end
  
end

