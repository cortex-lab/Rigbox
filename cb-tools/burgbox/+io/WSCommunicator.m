classdef WSCommunicator < io.Communicator
  %IO.WSCOMMUNICATOR Sends & receives messages over a WebSocket
  %   Encapsulates a connection able to send and receive messages carrying
  %   arbritrary data over a WebSocket.
  %
  % Part of Burgbox
  
  % 2014-08 CB created
  
  properties (Dependent, SetAccess = protected)
    IsMessageAvailable
    Role
  end
  
  properties (Constant)
    DefaultListenPort = 2014
  end
  
  properties (Access = protected)
    pRole
    pListenPort
    pServerUri
  end
  
  properties (Transient)
    WebSocket
    EventMode = 'off'
  end
  
  properties (Access = private, Transient)
    Listener
    InBuffer
  end
  
  methods
    function r = get.Role(obj)
      r = obj.pRole;
    end
    
    function b = get.IsMessageAvailable(obj)
      b = ~isempty(obj.InBuffer) && obj.InBuffer.size > 0;
    end
    
    function send(obj, msgId, data)
      bytes = encode(obj, msgId, data);
      switch obj.Role
        case 'client'
          obj.WebSocket.Send(bytes, 0, numel(bytes));
        case 'server'
          %TODO: bug that GetAllSessions does not get very recent ones
          iter = obj.WebSocket.GetAllSessions.GetEnumerator;
          while iter.MoveNext
            iter.Current.Send(bytes, 0, numel(bytes));
          end
        otherwise
          error('Invalid WebSocket role ''%s''', obj.Role);
      end
    end
    
    function [msgId, data, host] = receive(obj)
      if obj.InBuffer.size > 0
        packet = obj.InBuffer.pop();
        host = packet(1);
        message = hlp_deserialize(typecast(packet(2), 'uint8'));
        msgId = message.id;
        data = message.data;
      else
        msgId = [];
        data = [];
        host = [];
      end
    end
    
    function close(obj)
      if ~isempty(obj.WebSocket)
        switch obj.Role
          case 'client'
            switch obj.WebSocket.State
              case {WebSocket4Net.WebSocketState.Open...
                  WebSocket4Net.WebSocketState.Connecting}
                % send goodbye
                send(obj, 'goodbye', []);
                obj.WebSocket.Close();
                obj.WebSocket = [];
            end
          case 'server'
            obj.WebSocket.Stop();
            obj.WebSocket = [];
            %             disp('Stopped WebSocket server');
          otherwise
            error('Invalid WebSocket role ''%s''', obj.Role);
        end
      end
    end
    
    function open(obj)
      % close any existing connection
      close(obj);
      obj.InBuffer = java.util.LinkedList();
      switch obj.Role
        case 'server'
          startServer(obj);
        case 'client'
          startClient(obj);
        otherwise
          error('Invalid WebSocket role ''%s''', obj.Role);
      end
    end
     
    function s = wtf(obj)
      s = obj.WebSocket.State;
    end
  end
  
  methods (Access = protected)
    function bytes = encode(obj, msgId, data)
      message.id = msgId;
      message.data = data;
      bytes = hlp_serialize(message);
    end
    
    function onClosed(obj, ~, eventArgs)
%       fprintf('onClosed\n');
      try
        fakeGoodbye = encode(obj, 'goodbye', []);
        switch obj.Role
          case 'server'
            host = 'tbc';
          case 'client'
            host = first(regexp(obj.pServerUri, 'ws://(.+):', 'tokens', 'once'));
          otherwise
            error('Invalid WebSocket role ''%s''', obj.Role);
        end
        obj.InBuffer.add({host fakeGoodbye});
        disp('WebSocket closed');
      catch ex
        getReport(ex)
      end
    end
    
    function onReceive(obj, ~, eventArgs)
%       fprintf('onReceive\n');
      try
        data = uint8(eventArgs.Data);
        switch obj.Role
          case 'server'
            host = char(eventArgs.Session.RemoteEndPoint.ToString);
          case 'client'
            host = first(regexp(obj.pServerUri, 'ws://(.+):', 'tokens', 'once'));
          otherwise
            error('Invalid WebSocket role ''%s''', obj.Role);
        end
        if obj.EventMode
          % immediately delivery it to listeners
          message = hlp_deserialize(typecast(data, 'uint8'));
          notify(obj, 'MessageReceived',...
            io.MessageReceived(message.id, message.data, host));
        else
          % put the message into the queue
          obj.InBuffer.add({host data});
        end
      catch ex
        getReport(ex)
      end
    end
    
    function startClient(obj)
      % connect to a WebSocket client
      using('WebSocket4Net');
      obj.WebSocket = WebSocket4Net.WebSocket(obj.pServerUri);
      obj.Listener = [
        event.listener(obj.WebSocket, 'DataReceived', @obj.onReceive)...
        event.listener(obj.WebSocket, 'Closed', @obj.onClosed)];
      obj.WebSocket.Open();
      timeoutMs = 10e3;
      t = systime;
      while (systime - t < timeoutMs) &&...
          (obj.WebSocket.State == WebSocket4Net.WebSocketState.Connecting)
        % wait for connection attempt to complete
        pause(30e-3);
      end
      assert(obj.WebSocket.State == WebSocket4Net.WebSocketState.Open,...
        'Could not connect to ''%s''', obj.pServerUri);
    end
    
    function startServer(obj)
      % start a WebSocket server
      
      % close any existing connection
      obj.close();
      using('SuperWebSocket');
      obj.WebSocket = SuperWebSocket.WebSocketServer;
      obj.WebSocket.Setup(obj.pListenPort);
      obj.Listener = event.listener(obj.WebSocket, 'Received', @obj.onReceive);
      obj.WebSocket.Start();
    end
  end
  
  methods (Static)
    function com = client(serverUri)
      com = io.WSCommunicator;
      if isempty(regexp(serverUri, '^ws://', 'once'))
        %add missing protocol prefix
        serverUri = ['ws://' serverUri];
      end
      if isempty(regexp(serverUri, '^ws://.+:\d+$', 'once'))
        %add default listening port suffix
        serverUri = sprintf('%s:%i', serverUri, com.DefaultListenPort);
      end
      com.pRole = 'client';
      com.pServerUri = serverUri;
    end
    
    function com = server(port)
      com = io.WSCommunicator;
      if nargin < 1
        port = com.DefaultListenPort;
      end
      com.pRole = 'server';
      com.pListenPort = port;
    end
  end
  
end

