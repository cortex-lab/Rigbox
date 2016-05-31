classdef ThresholdEventInfo < exp.EventInfo
  %EXP.THRESHOLDEVENTINFO Provides information about a threshold reached
  %   Includes the base class information and additionally and ID to
  %   identify the threshold reached
  %
  % Part of Rigbox

  % 2012-11 CB created    
  
  properties
    Id %Some sort of code to identify the threshold reached
  end
  
  methods
    function obj = ThresholdEventInfo(event, time, experiment, id)
      obj = obj@exp.EventInfo(event, time, experiment);
      obj.Id = id;
    end
  end
  
end