classdef StartResponseFeedback < exp.Action
  %EXP.STARTRESPONSEFEEDBACK Start appropriate feedback phase for response
  %   Convenience action for use with an EventHandler. This will begin
  %   a phase called 'feedbackPositive' or 'feedbackNegative', or none at
  %   all depending on the response event that triggered the action. This
  %   assumes the triggering event was a responseMade event so that the
  %   corresponding event info is a ResponseEventInfo object with an Id
  %   property. This ID is used as an index into the field 
  %   'feedbackForResponse' of the current trial condition data. Feedback
  %   values of < 0 and > 0 will induce negative and positive feedback
  %   respectively, while 0 will not begin any phases. In all cases, the
  %   feedback value is recorded in the experiment's data.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  methods
    function perform(obj, eventInfo, dueTime)
      response = eventInfo.Id;
      experiment = eventInfo.Experiment;
      feedbackForResponse = param(experiment.ConditionServer, 'feedbackForResponse');
      feedback = feedbackForResponse(response);
      log(experiment, 'feedbackType', feedback);
      
      if feedback < 0
        startPhase(experiment, 'feedbackNegative', dueTime);
      elseif feedback > 0
        startPhase(experiment, 'feedbackPositive', dueTime);
      end
    end
  end
  
end

