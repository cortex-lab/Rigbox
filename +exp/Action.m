classdef Action
  %EXP.ACTION Base-class for actions used with an EventHandler
  %   Extend from EXP.ACTION and override the perform function to do some
  %   action during an experiment. These action objects can be added to an
  %   experiment exp.EventHandler to avoid having to use callback functions
  %   directly. There are many build in EXP.ACTION subtypes which perform 
  %   common actions such as starting and ending trials and
  %   phases. See also EXP.EVENTHANDLER, EXP.STARTTRIAL, EXP.ENDPHASE.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  properties
  end
  
  methods (Abstract)
    perform(obj, eventInfo, dueTime)
  end
  
  methods
  end
  
end

