classdef PrimativeUDPService < srv.Service
  %SRV.PRIMATIVEUDPSERVICE Interface to a dumb UDP-based service
  %   TODO. See also IO.COMMUNICATOR.
  %
  % Part of Rigbox
  
  % 2013-06 CB created
  % 2014-02 CB overhauled
  
  properties (Dependent, SetAccess = protected)
    Status
  end
  
  properties (Dependent)
    ResponseTimeout
  end
  
  properties (SetAccess = protected)
    RemoteIP
    ListenPort = 10000
    RemotePort = 10000
    Socket
  end
  
  properties (Access = private)
    pResponseTimeout = 10
  end
  
  methods
    function delete(obj)
      %Tidy up after ourselves by closing the listening socket
      if ~isempty(obj.Socket)
        pnet(obj.Socket, 'close');
        obj.Socket = [];
      end
    end
    
    function obj = PrimativeUDPService(remoteHost, remotePort, listenPort)
      obj.RemoteIP = ipaddress(remoteHost);
      if nargin >= 3
        obj.ListenPort = listenPort;
      end
      if nargin >= 2
        obj.RemotePort = remotePort;
      end
    end
    
    function value = get.ResponseTimeout(obj)
      value = obj.pResponseTimeout;
    end
    
    function set.ResponseTimeout(obj, value)
      if ~isempty(obj.Socket)
        pnet(obj.Socket, 'setreadtimeout', value);
      end
      obj.pResponseTimeout = value;
    end
    
    function bind(obj)
      if ~isempty(obj.Socket)
        pnet(obj.Socket, 'close');
      end
      obj.Socket = pnet('udpsocket', obj.ListenPort);
      pnet(obj.Socket, 'setreadtimeout', obj.pResponseTimeout);
    end
    
    function start(obj, expRef)
      obj.confirmedSend(sprintf('GOGO%s*%s', expRef, hostname));
    end
    
    function stop(obj)
      obj.confirmedSend(sprintf('STOP*%s', hostname));
    end
    
    function str = get.Status(obj)
      try
        rid = randi(1e6);
        obj.sendUDP(sprintf('WHAT%i*%s', rid, hostname));
        response = obj.receiveUDP;
        % extract portion before asterisk
        parsed = regexp(response, '(?<status>[A-Z]+)(?<id>\d+)\*', 'names');
        assert(strcmp(parsed.id, int2str(rid)), 'Rigbox:srv:unexpectedUDPResponse',...
          'Received UDP message ID did not match sent');
        switch parsed.status
          case 'GOGO'
            str = 'running';
          otherwise
            str = 'idle';
        end
      catch ex
        str = 'unavailable';
      end
    end
    
    function confirmedSend(obj, msg)
      sendUDP(obj, msg)
      % check response back was confirmatory echo
      response = receiveUDP(obj);
      if ~strcmp(response, msg)
        error('Rigbox:srv:unexpectedUDPResponse',...
          'Unexpected UDP response ''%s''', response);
      end
    end
    
    function msg = receiveUDP(obj, attempts)
      if nargin < 2
        attempts = 2;
      end
      % blocking read with timeout
      pnet(obj.Socket, 'readpacket');
      msg = pnet(obj.Socket, 'read');
      senderIP = sprintf('%i.%i.%i.%i', pnet(obj.Socket, 'gethost'));
      if ~strcmp(senderIP, obj.RemoteIP)
        warning('Rigbox:srv:unexpectedUDP',...
          'Ignoring UDP packet from unexpected host (%s) with message ''%s''', senderIP, msg);
        if attempts > 0
          % recursively listen for another message and return that
          msg = receiveUDP(obj, attempts - 1);
        end
      end
    end
    
    function sendUDP(obj, msg)
      if isempty(obj.Socket)
        bind(obj);
      end
      pnet(obj.Socket, 'write', msg);
      pnet(obj.Socket, 'writepacket', obj.RemoteIP, obj.RemotePort);
    end
    
  end
end

