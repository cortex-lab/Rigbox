classdef Communicator < handle
  %IO.COMMUNICATOR Interface for sending/receiving messages
  %   Interface encapsulating some connection able to send and receive
  %   messages carrying arbitrary data.
  %
  %   NB: 2018b and below do not support validation functions in abstract
  %   property definitions.  Hence we have commented them out.
  %
  % Part of Burgbox

  % 2013-03 CB created

  properties (Abstract, SetAccess = protected)
    IsMessageAvailable %logical 
  end
  
  properties (Abstract, Constant)
    DefaultListenPort %int32
  end
  
  properties (Abstract)
    EventMode %matlab.lang.OnOffSwitchState
  end
  
  events
    MessageReceived
  end
  
  methods (Abstract)
    send(obj, msgId, data)
    [msgId, data, host] = receive(obj, within)
    close(obj)
    open(obj)
  end
  
  methods
    function delete(obj)
      close(obj);
    end
  end
  
end

