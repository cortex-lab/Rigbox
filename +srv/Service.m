classdef Service < handle
  %SRV.SERVICE Interface to start/stop a service for an experiment
  %   TODO
  %
  % Part of Rigbox

  % 2013-06 CB created  
  
  properties
    Title %Nice descriptive name for the service
    Id %Succint unique id for the service for indexing/discovering
  end
  
  properties (Abstract, SetAccess = protected)
    Status
  end
  
  methods (Abstract)
    start(obj, expRef)
    stop(obj)
  end
  
end

