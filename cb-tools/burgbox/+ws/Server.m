classdef Server < handle
  %UNTITLED Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    SWSServer
  end
  
  properties (Access = protected)
    Listener
  end
  
  events
    MessageReceived
  end
  
  methods
    function obj = Server(port)
      using('SuperWebSocket');
      obj.SWSServer = SuperWebSocket.WebSocketServer;
      obj.SWSServer.Setup(port);
      obj.Listener = event.listener(obj.SWSServer, 'Received', @obj.onReceive);
    end
    
    function start(obj)
      obj.SWSServer.Start();
    end
    
    function stop(obj)
      disp('Stopping WebSocketServer');
      obj.SWSServer.Stop();
    end
    
    function delete(obj)
      stop(obj);
    end
  end
  
  methods (Access = protected)
    function onReceive(obj, ~, data)
      session = data.Session;
%       fprintf('%s: Message received\n', datestr(now));
      switch data.Type
        case SuperWebSocket.DataType.Raw
          bytes = uint8(data.Data);
          evtData = ws.SessionEventData(session, bytes);
        case SuperWebSocket.DataType.String
          str = char(data.Data);
          evtData = ws.SessionEventData(session, str);
      end
      notify(obj, 'MessageReceived', evtData);
    end
  end
  
end