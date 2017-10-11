classdef Service < handle
  %SRV.SERVICE Interface to start/stop a service for an experiment
  %   This is an abstract superclass for an interface object which
  %   srv.expServer uses to start and stop programmes running on other
  %   computers (e.g. remote Timeline, eye camera aquisition software,
  %   etc.)  Currently there are two subclasses:
  %     1. PrimitiveUDPService - uses pnet (from with PsychToolbox) to send
  %     and receive ASCII UDP messages.  This is a stynchronous process.
  %     2. BasicUDPService - uses udp (from the Intrument Control Toolbox
  %     to send and receive ASCII udp messages asynchronously.
  %
  %   The second one is now used by expService.  The list of services
  %   available to each rig is found in the remote.mat file, in the
  %   srv.StimulusControl property 'Services'
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

