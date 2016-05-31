classdef TrialEventInfo < exp.EventInfo
  %EXP.TRIALEVENTINFO Provides information about a trial event
  %   Includes the base class information and additionally the trial number
  %   (TrialNum property). Current trial events are 'trialStarted' and
  %   'trialEnded'. See also EXP.EXPERIMENT.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  properties
    TrialNum %trial number event is concerned with
  end
  
  methods
    function obj = TrialEventInfo(event, time, experiment, num)
      obj = obj@exp.EventInfo(event, time, experiment);
      obj.TrialNum = num;
    end
  end
  
end

