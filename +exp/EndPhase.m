classdef EndPhase < exp.Action
  %EXP.ENDPHASE Instruction to end a particular experiment phase
  %   Convenience action for use with an EventHandler. This will end the
  %   specified phase in the experiment.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  properties
    Name%the name of the phase to end
  end
  
  methods
    function obj = EndPhase(name)
      obj.Name = name;
    end

    function perform(obj, eventInfo, dueTime)
      endPhase(eventInfo.Experiment, obj.Name, dueTime);
    end
  end
  
end

