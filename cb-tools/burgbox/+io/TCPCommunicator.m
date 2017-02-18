classdef TCPCommunicator < io.Communicator
  %IO.TCPCOMMUNICATOR Sends & receives messages over TCP/IP
  %   Encapsulates a connection able to send and receive messages carrying
  %   arbritrary data over TCP/IP.
  %
  % Part of Burgbox

  % 2013-03 CB created  
  
  properties (Dependent, SetAccess = protected)
    IsMessageAvailable
  end
  
  properties (Dependent)
    RemoteHost
    RemotePort
  end
  
  properties (SetAccess = protected)
    pRequestHost
  end
  
  properties (Access = protected)
    jSocket
    jSocketInputStream
    jInputStream
    jOutputStream
    pRequestPort
    pAcceptPort
    pConnectionTimeout
    pConnectionMode
    MessageBuffer
  end
  
  methods  
%     function waitForConnection(obj, localPort)
%       defTimeout = 0.25;
%       while true
%         try
%           acceptConnection(obj, localPort, defTimeout);
%           break
%         catch ex
%           if ~isa(ex.ExceptionObject, 'java.net.SocketTimeoutException')
%             rethrow(ex);
%           end
%         end
%       end
%     end
        
    function val = get.RemotePort(obj)
      if ~isempty(obj.jSocket)
        val = obj.jSocket.getPort();
      else
        val = [];
      end
    end
    
    function val = get.RemoteHost(obj)
      if ~isempty(obj.jSocket)
        val = char(obj.jSocket.getInetAddress().getHostName());
      else
        val = [];
      end
    end

    function b = get.IsMessageAvailable(obj)
      try
        if isempty(obj.MessageBuffer)
          % the following will quickly throw a timeout error if nothing
          % is available
          [id, data] = receive(obj, 2);
          if ~isempty(id)
            obj.MessageBuffer.id = id;
            obj.MessageBuffer.data = data;
          end
        end
        b = ~isempty(obj.MessageBuffer);
      catch err
        % ignore any errors but return false;
        b = false;
      end
    end
    
    function send(obj, msgId, data)
      packet.id = msgId;
      packet.data = data;
      packet = hlp_serialize(packet);
      writeObject(obj.jOutputStream, packet);
      flush(obj.jOutputStream);
    end
    
    function [msgId, data, host] = receive(obj, within)
      if ~isempty(obj.MessageBuffer)
        msgId = obj.MessageBuffer.id; 
        data = obj.MessageBuffer.data;
        host = obj.RemoteHost;
        obj.MessageBuffer = [];
        return
      else
        if nargin < 2
          within = 2;
        end
        within = round(within*1e3); % convert to milliseconds from seconds
        setSoTimeout(obj.jSocket, within);
        
        numBytesAvailable = available(obj.jSocketInputStream);
        
        if numBytesAvailable > 0
          try
            packet = readObject(obj.jInputStream);
            packet = hlp_deserialize(typecast(packet, 'uint8'));
            msgId = packet.id;
            data = packet.data;
          catch err
            disp(err)
            errmsg = 'Invalid packet recieved';
            fprintf('%s: %s', errmsg, err.message);
            error(errmsg);
          end            
        else
          msgId = [];
          data = [];
        end
        host = obj.RemoteHost;
      end
    end

    function close(obj, sendGoodbye)
      if nargin < 2
        sendGoodbye = true; %default to trying to send goodbye
      end
      if ~isempty(obj.jSocket)
        if sendGoodbye
          try
            send(obj, 'goodbye', []);
          catch ex
            %ignore if this fails, we were just being polite!
          end
        end
        obj.jSocket.close();
        obj.jSocket = [];
      end
    end
    
    function open(obj)
      switch obj.pConnectionMode
        case 'accept'
          obj.acceptConnection(obj.pAcceptPort, obj.pConnectionTimeout);
        case 'request'
          obj.requestConnection(obj.pRequestHost, obj.pRequestPort, obj.pConnectionTimeout);
        otherwise
          error('Invalide connection mode ''%s''', obj.pConnectionMode);
      end
    end
    
    function delete(obj)
      close(obj);
    end
  end
  
  methods (Access = protected)
    function acceptConnection(obj, localPort, timeout)
      % accept a tcp connection from client
      
      % close any existing connection
      obj.close();
      
      % convert timeout from secs to millisecs
      timeout = ceil(timeout*1e3);
%       disp('opened server socket')
      serverSocket = java.net.ServerSocket(localPort);
      cleanup = onCleanup(@() serverSocket.close);
      serverSocket.setSoTimeout(timeout);
%       disp('listening')
      socket = serverSocket.accept;
      socket.setSoTimeout(timeout);
      % the order of input and output creation is important (must be
      % reverse of that in requestConnection)
      socketInputStream = socket.getInputStream();
      obj.jInputStream = java.io.ObjectInputStream(socketInputStream);
      socketOutputStream = socket.getOutputStream();
      obj.jOutputStream = java.io.ObjectOutputStream(socketOutputStream);
      obj.jSocket = socket;
      obj.jSocketInputStream = socketInputStream;
    end
    
    function requestConnection(obj, remoteHost, remotePort, timeout)
      % request a tcp connection from a server
      
      % close any existing connection
      obj.close();
      
      % convert timeout from secs to millisecs
      timeout = ceil(timeout*1e3);
      addr = java.net.InetSocketAddress(remoteHost, remotePort);
      socket = java.net.Socket;
      socket.setSoTimeout(timeout);
      socket.connect(addr, timeout);
      % the order of input and output creation is important (must be
      % reverse of that in acceptConnection)
      socketOutputStream = socket.getOutputStream();
      obj.jOutputStream = java.io.ObjectOutputStream(socketOutputStream);
      socketInputStream = socket.getInputStream();
      obj.jInputStream = java.io.ObjectInputStream(socketInputStream);
      obj.jSocket = socket;
      obj.jSocketInputStream = socketInputStream;
    end
  end
  
  methods (Static)
    function com = acceptor(localPort, timeout)
      com = io.TCPCommunicator;
      com.pAcceptPort = localPort;
      com.pConnectionTimeout = timeout;
      com.pConnectionMode = 'accept';
    end
    
    function com = requestor(remoteHost, remotePort, timeout)
      com = io.TCPCommunicator;
      com.pRequestHost = remoteHost;
      com.pRequestPort = remotePort;
      com.pConnectionTimeout = timeout;
      com.pConnectionMode = 'request';
    end
  end
  
end

