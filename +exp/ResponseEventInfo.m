classdef ResponseEventInfo < exp.EventInfo
  %EXP.RESPONSEEVENTINFO Provides information about a subject's response
  %   Includes the base class information and additionally an ID
  %   identifying the response made. See also EXP.LIAREXPERIMENT,
  %   EXP.REGISTERTHRESHOLDRESPONSE & EXP.STARTRESPONSEFEEDBACK.
  %
  % Part of Rigbox

  % 2012-11 CB created    
  
  properties
    Id %Some sort of code to identify the response made
  end
  
  methods
    function obj = ResponseEventInfo(event, time, experiment, id)
      obj = obj@exp.EventInfo(event, time, experiment);
      obj.Id = id;
    end
  end
  
end