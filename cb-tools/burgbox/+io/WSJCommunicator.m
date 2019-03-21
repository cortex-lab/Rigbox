classdef WSJCommunicator < io.Communicator
  %IO.WSCOMMUNICATOR Sends & receives messages over a WebSocket
  %   Encapsulates a connection able to send and receive messages carrying
  %   arbritrary data over a WebSocket.
  %
  % Part of Burgbox
  
  % 2014-08 CB created
  
  properties (Dependent, SetAccess = protected)
    % Flag set to true while there is a message in the buffer
    IsMessageAvailable
    % The role of the Commuicator object, either 'client' or 'server'
    % depending on which constructor method was used
    Role
  end
  
  properties (Constant)
    % The listen port used if one isn't already specified in the URI
    DefaultListenPort = 2014
  end
  
  properties (Access = protected)
    pRole
    pListenPort
    pServerUri
  end
  
  properties (Transient)
    WebSocket
    hWebSocket %handle to java WebSocket
    % When true listeners are notified of new messages via the
    % MessageRecieved event
    EventMode logical = false
  end
  
  properties (Access = private, Transient)
    Listener % TODO This property appears to be unused.  Test before removing
    % Handle to java.util.LinkedList object containing recieved data
    InBuffer
  end
  
  events
    MessageReceived
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
          obj.WebSocket.send(bytes);
        case 'server'
          iter = obj.WebSocket.connections.iterator;
          while iter.hasNext
            iter.next.send(bytes);
          end
        otherwise
          error('Invalid WebSocket role ''%s''', obj.Role);
      end
    end
    
    function sendBytes(obj, bytes)
      switch obj.Role
        case 'client'
          obj.WebSocket.send(bytes);
        case 'server'
          iter = obj.WebSocket.connections.iterator;
          while iter.hasNext
            iter.next.send(bytes);
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
            obj.WebSocket.close();
          case 'server'
            obj.WebSocket.stop();
          otherwise
            error('Invalid WebSocket role ''%s''', obj.Role);
        end
        pause(50e-3); % allow callbacks to execute
        set(obj.hWebSocket, 'BinaryReceivedCallback', [],...
          'ClosedCallback', [], 'OpenedCallback', []);% clear callbacks
        delete(obj.hWebSocket);% delete the handle
        obj.WebSocket = [];
        obj.InBuffer = [];
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
    
    function onOpened(obj, ~, evt)
      evt.getSocket().channel.socket().setTcpNoDelay(true);
    end
    
    function onClosed(obj, ~, evt)
      try
        remoteAddr = evt.getSocket().getRemoteSocketAddress();
        if ~isempty(remoteAddr)
          host = char(remoteAddr.getAddress().toString());
        else
          host = 'UNKNOWN';
        end
%         fprintf('%s: WebSocket to %s closed\n', obj.Role, host);
      catch ex
        getReport(ex)
      end
    end
    
    function onReceive(obj, ~, evt)
      try
        data = int8(evt.getMessage());
        remoteAddr = evt.getSocket().getRemoteSocketAddress();
        if ~isempty(remoteAddr)
          host = char(remoteAddr.getAddress().toString());
        else
          host = 'UNKNOWN';
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
      obj.WebSocket = net.entropy_mill.websocket.Client(obj.pServerUri);
      obj.hWebSocket = handle(obj.WebSocket, 'CallbackProperties');
      set(obj.hWebSocket,...
        'BinaryReceivedCallback', @obj.onReceive,...
        'ClosedCallback', @obj.onClosed);
      obj.WebSocket.connect();
      timeoutMs = 10e3;
      t = systime;
      while (systime - t < timeoutMs) && (obj.WebSocket.isConnecting())
        % wait for connection attempt to complete
        pause(15e-3);
      end
      pause(1e-2);
      rs = obj.WebSocket.getReadyState();
      assert(obj.WebSocket.isOpen(),...
        'Could not connect to ''%s''', obj.pServerUri);
    end
    
    function startServer(obj)
      % start a WebSocket server
      obj.close();% close any existing connection
      obj.WebSocket = net.entropy_mill.websocket.Server(obj.pListenPort);
      obj.hWebSocket = handle(obj.WebSocket, 'CallbackProperties');
      set(obj.hWebSocket,...
        'OpenedCallback', @obj.onOpened,...
        'ClosedCallback', @obj.onClosed,...
        'BinaryReceivedCallback', @obj.onReceive);
      obj.WebSocket.start();
    end
  end
  
  methods (Static)
    function com = client(serverUri)
      com = io.WSJCommunicator;
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
      com = io.WSJCommunicator;
      if nargin < 1
        port = com.DefaultListenPort;
      end
      com.pRole = 'server';
      com.pListenPort = port;
    end
  end
  
end

