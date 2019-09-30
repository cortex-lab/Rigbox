classdef DummyCommunicator < io.Communicator
  %IO.DUMMYCOMMUNICATOR io.Communicator implementation that does nothing
  %   Placeholder io.Communicator for things that expect one. i.e. this
  %   does nothing when send is called, and returns nothing when receive is
  %   called.
  %
  % Part of Burgbox

  % 2013-03 CB created  
  
  properties
    EventMode = 'off'
  end
  
  properties (SetAccess = protected)
    IsMessageAvailable = false
  end
  
  properties (Constant)
    DefaultListenPort = []
  end
  
  methods
    function send(obj, msgId, data)
      % do nothing
    end
    
    function [msgId, data, host] = receive(obj, within)
      % do nothing
      msgId = [];
      data = [];
      host = [];
    end
    
    function open(obj)
      %do nothing
    end
    
    function close(obj)
      % do nothing
    end
  end
  
end

