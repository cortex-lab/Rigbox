classdef RemoteMPEPService < srv.Service
  %SRV.REMOTETLSERVICE UDP-based service for starting and stopping Timeline
  %   A UDP interface that uses the udp function of the Instument Control
  %   Toolbox. Unlike SRV.PRIMITIVEUDPSERVICE, this can send and recieve
  %   messages asynchronously and can be used both to start remote services
  %   and, service side, to listen for remote start/stop commands.
  %
  %   To send a message simply use sentUDP(msg). Use confirmedSend(msg) to
  %   send send a message and await a confirmation (the same message echoed
  %   back).  To receive messaged only, simply use bind() and add a
  %   listener to the MessageReceived event.
  %
  %   Examples:
  %     remoteTL = srv.BasicUDPService('tl-host', 10000, 10000);
  %     remoteTL.start('2017-10-27-1-default'); % Start remote service with
  %     an experiment reference
  %     remoteTL.stop; remoteTL.delete; % Clean up after stopping remote
  %     rig
  % 
  %     experimentRig = srv.BasicUDPService('mainRigHostName', 10000, 10000);
  %     experimentRig.bind(); % Connect to the remote rig
  %     remoteStatus = requestStatus(experimentRig); % Get the status of
  %     the experimental rig
  %     lh = events.listener(experimentRig, 'MessageReceived',
  %     @(srv, evt)processMessage(srv, evt)); % Add a listener to do
  %     something when a message is received.
  %
  %   See also SRV.PRIMITIVEUDPSERVICE, UDP.
  %
  % Part of Rigbox
  
  % 2017-10 MW created
  
  properties (GetObservable, SetAccess = protected)
    Status % Status of remote service
  end
  
  properties
    LocalStatus % Local status to send upon request
    ResponseTimeout = Inf % How long to wait for confirmation of receipt
    Timeline % Holds an instance of Timeline
    Callbacks % Holds callback functions for each instruction
  end
  
  properties (SetObservable, AbortSet = true)
    RemoteHost % Host name of the remote service
    ListenPort = 10000 % Localhost port number to listen for messages on
    RemotePort = 10000 % Which port to send messages to remote service on
    EnablePortSharing = 'off' % If set to 'on' other applications can use the listen port
  end
  
  properties (SetAccess = protected)
    RemoteIP % The IP address of the remote service
    Socket % A handle to the udp object
    LastSentMessage = '' % A copy of the message sent from this host
    LastReceivedMessage = '' % A copy of the message received by this host
  end
  
  properties (Access = private)
    Listener % A listener for the MessageReceived event
    ResponseTimer % A timer object set when expecting a confirmation message (if ResponseTimeout < Inf)
    AwaitingConfirmation = false % True when awaiting a confirmation message
    ConfirmID % A random integer to confirm UDP status response.  See requestStatus()
  end
  
  events (NotifyAccess = 'protected')
    MessageReceived % Notified by receiveUDP() when a UDP message is received
  end
  
  methods
    function delete(obj)
      % To be called before destroying BasicUDPService object.  Deletes all
      % timers, sockets and listeners Tidy up after ourselves by closing
      % the listening sockets
      if ~isempty(obj.Socket)
        fclose(obj.Socket); % Close the connection
        delete(obj.Socket); % Delete the socket
        obj.Socket = []; % Delete udp object
        obj.Listener = []; % Delete any listeners to that object
        if ~isempty(obj.ResponseTimer) % If there is a timer object 
          stop(obj.ResponseTimer) % Stop the timer..
          delete(obj.ResponseTimer) % Delete the timer...
          obj.ResponseTimer = []; % ... and remove it
        end
      end
    end
    
    function obj = RemoteMPEPService(remoteHost, remotePort, listenPort)
      % SRV.REMOTETLSERVICE([remoteHost, remotePort, listenPort])
      %   remoteHost is the hostname of the service with which to send and
      %   receive messages.
      paths = dat.paths(hostname); % Get list of paths for timeline
      obj.Callbacks = struct('Instruction', {'ExpStart', 'BlockStart',...
        'StimStart', 'StimEnd', 'BlockEnd', 'ExpEnd', 'ExpInterrupt'}, 'Callback', @nop);
      obj.Timeline = load(fullfile(paths.rigConfig, 'hardware.mat'), 'timeline'); % Load timeline object
      if nargin < 1; remoteHost = ''; end % Set local port
      obj.RemoteHost = remoteHost; % Set hostname
      obj.RemoteIP = ipaddress(remoteHost); % Get IP address
      if nargin >= 3; obj.ListenPort = listenPort; end % Set local port
      if nargin >= 2; obj.RemotePort = remotePort; end % Set remote port
      obj.Socket = udp(obj.RemoteIP,... % Create udp object
        'RemotePort', obj.RemotePort, 'LocalPort', obj.ListenPort);
      obj.Socket.ReadAsyncMode = 'continuous';
      obj.Socket.BytesAvailableFcnCount = 10; % Number of bytes in buffer required to trigger BytesAvailableFcn
      obj.Socket.BytesAvailableFcn = @obj.receiveUDP; % Add callback to receiveUDP when enough bytes arrive in the buffer
      % Add listener to MessageReceived event, notified when receiveUDP is
      % called.  This event can be listened to by anyone.
      obj.Listener = event.listener(obj, 'MessageReceived', @processMsg);
      % Add listener for when the observable properties are set 
      obj.addlistener({'RemoteHost', 'ListenPort', 'RemotePort', 'EnablePortSharing'},...
        'PostSet',@(src,~)obj.update(src));
      % Add listener for when the remote service's status is requested
      obj.addlistener('Status', 'PreGet', @obj.requestStatus);
    end
    
    function obj = addListener(obj, name, listenPort, callback)
        if nargin<3; callback = @nop; end
        if listenPort==obj.ListenPorts
          error('Listen port already added');
        end
        obj.Sockets(end+1) = udp(obj.RemoteIP, 'RemotePort', obj.RemotePort, 'LocalPort', listenPort);
        obj.Sockets(end).BytesAvailableFcn = @(~,~)obj.receiveUDP(src,evt);
        obj.Sockets(end).Tag = name;
        obj.ListenPorts(end+1) = listenPort;
        obj.Callbacks(end+1) = callback;
    end
    
    function update(obj, src)
      % Callback for setting udp relevant properties.  Some properties can
      % only be set when the socket is closed.
      % Check if socket is open
      isOpen = strcmp(obj.Socket.Status, 'open');
      % Close connection before setting, if required to do so
      if any(strcmp(src.name, {'RemoteHost', 'LocalPort', 'EnablePortSharing'}))&&isOpen
        fclose(obj.Socket);
      end
      % Set all the relevant properties
      obj.RemoteIP = ipaddress(obj.RemoteHost);
      obj.Socket.LocalPort = obj.ListenPort;
      obj.Socket.RemotePort = obj.RemotePort;
      obj.Socket.RemoteHost = obj.RemoteIP;
      if isOpen; bind(obj); end % If socket was open before, re-open
    end
    
    function bind(obj, names)
      if isempty(obj.Sockets)
        warning('No sockets to bind')
        return
      end
      if nargin<2
        % Close all sockets, in case they are open
        arrayfun(@fclose, obj.Sockets)
        % Open the connection to allow messages to be sent and received
        arrayfun(@fopen, obj.Sockets)
      else
        names = ensureCell(names);
        hosts = arrayfun(@(s)s.Tag, obj.Sockets);
        idx = cellfun(@(n)find(strcmp(n,hosts)), names);
        arrayfun(@fopen, obj.Sockets(idx))
      end
    end
    
    function start(obj, ref)
      % Send start message to remotehost and await confirmation
      [expRef, AlyxInstance] = parseAlyxInstance(ref);
      % Convert expRef to MPEP style
      [subject, seriesNum, expNum] = dat.expRefToMpep(expRef);
      % Build start message
      msg = sprintf('ExpStart %s %d %d', subject, seriesNum, expNum);
      % Send the start message
      obj.confirmedSend(msg, obj.RemoteHost);
      % Wait for response
      while obj.AwaitingConfirmation; pause(0.2); end
%       % Start a block (we only use one per experiment)
%       msg = sprintf('BlockStart %s %d %d 1', subject, seriesNum, expNum);
%       obj.confirmedSend(msg, obj.RemoteHost);
%       % Wait for response
%       while obj.AwaitingConfirmation; pause(0.2); end
    end
    
    function stop(obj)
      % Send stop message to remotehost and await confirmation
      obj.confirmedSend(sprintf('STOP*%s', obj.RemoteHost));
    end
    
    function requestStatus(obj)
      % Request a status update from the remote service
      obj.ConfirmID = randi(1e6);
      obj.sendUDP(sprintf('WHAT%i*%s', obj.ConfirmID, obj.RemoteHost));
      disp('Requested status update from remote service')
    end
        
    function confirmedSend(obj, msg)
      sendUDP(obj, msg)
      obj.AwaitingConfirmation = true;
      % Add timer to impose a response timeout
      if ~isinf(obj.ResponseTimeout)
        obj.ResponseTimer = timer('StartDelay', obj.ResponseTimout,...
          'TimerFcn', @(~,~)obj.processMsg);
        start(obj.ResponseTimer) % start the timer
      end
    end
    
    function receiveUDP(obj, src, evt)
      obj.LastReceivedMessage = strtrim(fscanf(obj.Socket));
      notify(obj, 'MessageReceived')
      hosts = arrayfun(@(s)s.Tag, obj.Sockets);
      feval(obj.Callbacks{strcmp(hosts, src.Tag)}, src, evt);
    end
    
    function sendUDP(obj, msg)
      % Ensure socket is open before sending message
      if strcmp(obj.Socket.Status, 'closed'); bind(obj); end
      fprintf(obj.Socket, msg); % Send message
      obj.LastSentMessage = msg; % Save a copy of the message
      disp(['Sent message to ' obj.RemoteHost]) % Display success
    end
    
    function echo(obj, src, ~)
      % Echo message
      fclose(src);
      src.RemoteHost = src.DatagramAddress;
      src.RemotePort = src.DatagramPort;
      fopen(src);
      fprintf(obj.Socket, obj.LastReceivedMessage); % Send message
      obj.LastSentMessage = obj.LastReceivedMessage; % Save a copy of the message
      disp(['Echo''d message to ' src.Tag]) % Display success
    end
  end
  
  methods (Access = protected)
    function processMPEPMsg(obj, src, ~)
      % Parse the message into its constituent parts
      msg = dat.mpepMessageParse(obj.LastReceivedMessage);
      % Check that the message was from the correct host, otherwise ignore
      if strcmp(response.host, obj.RemoteHost)
          warning('Received message from %s, ignoring', response.host);
          return
      end
      if obj.AwaitingConfirmation
      % Check the confirmation message is the same as the sent message
        assert(~isempty(response)||... % something received
            strcmp(response.status, 'WHAT')||... % status update
            strcmp(obj.LastReceivedMessage, obj.LastSentMessage),... % is echo
          'Confirmation failed')
      % We no longer need the timer, stop and delete it
        if ~isempty(obj.ResponseTimer)
            stop(obj.ResponseTimer)
            delete(obj.ResponseTimer)
            obj.ResponseTimer = [];
        end
      end
      % At the moment we just disply some stuff, other functions listening
      % to the MessageReceived event can do their thing
      switch response.status
        case 'GOGO'
          if obj.AwaitingConfirmation
            obj.Status = 'running';
            disp(['Service on ' obj.RemoteHost ' running'])
          else
            disp('Received start request')
            obj.LocalStatus = 'starting';
            obj.Timeline.start(dat.parseAlyxInstance(response.body))
            obj.LocalStatus = 'running';
            obj.sendUDP(obj.LastReceivedMessage)
          end
        case 'STOP'
          if obj.AwaitingConfirmation
            obj.Status = 'stopped';
            disp(['Service on ' obj.RemoteHost ' stopped'])
          else
            disp('Received stop request')
            obj.LocalStatus = 'stopping';
            obj.Timeline.stop
            obj.sendUDP(obj.LastReceivedMessage)
          end
        case 'WHAT'
          % TODO fix status updates so that they're meaningful
          parsed = regexp(response.body, '(?<id>\d+)(?<update>[a-z]*)', 'names');
          if obj.AwaitingConfirmation
            try
              assert(strcmp(parsed.id, int2str(obj.ConfirmID)), 'Rigbox:srv:unexpectedUDPResponse',...
                'Received UDP message ID did not match sent');
              switch parsed.update
                case {'running' 'starting'}
                  obj.Status = 'running';
                otherwise
                  obj.Status = 'idle';
              end
            catch
              obj.Status = 'unavailable';
            end
          else % Received status request NB: Currently no way of determining status
             obj.sendUDP([parsed.status parsed.id obj.LocalStatus])
          end
        otherwise
          disp(['Received ''' obj.LastReceivedMessage ''' from ' obj.RemoteHost])
      end
      % Reset AwaitingConfirmation
      obj.AwaitingConfirmation = false;
    end
  end
end