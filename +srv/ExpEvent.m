classdef ExpEvent < event.EventData
  %SRV.EXPEVENT A message carrying info about an experiment event
  %   TODO. See EXP.EXPERIMENT & EXP.EXPPANEL.
  %
  % Part of Rigbox
  
  % 2013-06 CB created
  
  properties
    Name %name of the event
    Ref %reference of the experiment
    Data %additional (arbritrary) data pertaining to the event
  end
  
  methods
    function e = ExpEvent(name, ref, data)
      if nargin < 3
        data = [];
      end
      e.Name = name;
      e.Ref = ref;
      e.Data = data;
    end  
  end
  
end

