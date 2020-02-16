classdef DummyStimulusControl < srv.StimulusControl
  %SRV.STIMULUSCONTROL Interface to, and info about a remote rig setup
  %   This interface is used and mc to communicate with
  %   one another.  The data are sent over TCP/IP through a java Web Socket
  %   (net.entropy_mill.websocket).  This object can be used to send
  %   arbitraty data over the network.  It is used by expServer to send a
  %   receive parrameter structures and status updates in the form of
  %   strings.
  %
  %   NB: This class replaces SRV.REMOTERIG.  See also SRV.SERVICE,
  %   IO.WSJCOMMUNICATOR, EUI.MCONTROL
  %
  % Part of Rigbox
  
  % 2013-06 CB created
  
  properties (Access = private)
    IsConnected = false
    IsRunning = []
  end
  
  events
    QuitExperiment
    StartExperiment
  end
    
  methods
        
    function startExperiment(obj, expRef)
      %startExperiment
      %Ensure the experiment ref exists
      obj.IsRunning = expRef;
      notify(obj, 'StartExperiment', srv.ExpEvent('start', [], expRef))
    end
    
    function quitExperiment(obj, immediately)
      obj.IsRunning = [];
      notify(obj, 'QuitExperiment', srv.ExpEvent('quit', [], immediately))
    end
    
    function connect(obj, block)
      obj.IsConnected = true;
    end
    
    function disconnect(obj)
      obj.IsConnected = false;
      obj.IsRunning = [];
    end
    
    function delete(obj)
      % Do nothing
    end
  end
  
  methods (Access = protected)
    function b = connected(obj)
      b = obj.IsConnected;
    end
    
    function send(obj, id, data)
      % Do nothing
    end
    
    function response = exchange(obj, message)
      switch message{1}
        case 'quit'
          obj.IsRunning = [];
          response = obj.NextMsgId;
        case 'status'
          if ~obj.IsConnected
            response = 'disconnect';
          else
            if isempty(obj.IsRunning)
              response = {'running', obj.IsRunning};
            else
              response = 'idle';
            end
          end
        otherwise
          response = obj.NextMsgId;
      end
    end
    
  end
    
end

