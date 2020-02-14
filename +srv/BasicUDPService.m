classdef BasicUDPService < srv.Service
  %SRV.BASICUDPSERVICE Interface to a dumb UDP-based service
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
  %   NB: Requires the Instrument Control Toolbox
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
    StartCallback % Function to be run upon receiving remote start command
    StopCallback % Function to be run upon receiving remote stop command
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
    
    function obj = BasicUDPService(remoteHost, remotePort, listenPort)
      % SRV.BASICUDPSERVICE(remoteHost [remotePort, listenPort])
      %   remoteHost is the hostname of the service with which to send and
      %   receive messages.
      obj.RemoteHost = remoteHost; % Set hostname
      obj.RemoteIP = ipaddress(remoteHost); % Get IP address
      if nargin >= 3; obj.ListenPort = listenPort; end % Set local port
      if nargin >= 2; obj.RemotePort = remotePort; end % Set remote port
      obj.Socket = udp(obj.RemoteIP,... % Create udp object
        'RemotePort', obj.RemotePort, 'LocalPort', obj.ListenPort);
      obj.Socket.ReadAsyncMode = 'continuous';
      obj.Socket.BytesAvailableFcnCount = 10; % Number of bytes in buffer required to trigger BytesAvailableFcn
      obj.Socket.BytesAvailableFcn = @(~,~)obj.receiveUDP; % Add callback to receiveUDP when enough bytes arrive in the buffer
      % Add listener to MessageReceived event, notified when receiveUDP is
      % called.  This event can be listened to by anyone.
      obj.Listener = event.listener(obj, 'MessageReceived', @(src,evt)obj.processMsg(src,evt));
      % Add listener for when the observable properties are set 
      obj.addlistener({'RemoteHost', 'ListenPort', 'RemotePort', 'EnablePortSharing'},...
        'PostSet',@(src,~)obj.update(src));
      % Add listener for when the remote service's status is requested
      obj.addlistener('Status', 'PreGet', @(~,~)obj.requestStatus);
    end
    
    function update(obj, src)
      % Callback for setting udp relevant properties.  Some properties can
      % only be set when the socket is closed.
      % Check if socket is open
      isOpen = strcmp(obj.Socket.Status, 'open');
      % Close connection before setting, if required to do so
      if any(strcmp(src.Name, {'RemoteHost', 'ListenPort', 'RemotePort', 'EnablePortSharing'}))&&isOpen
        fclose(obj.Socket);
      end
      % Set all the relevant properties
      obj.RemoteIP = ipaddress(obj.RemoteHost);
      obj.Socket.LocalPort = obj.ListenPort;
      obj.Socket.RemotePort = obj.RemotePort;
      obj.Socket.RemoteHost = obj.RemoteIP;
      if isOpen; bind(obj); end % If socket was open before, re-open
    end
    
    function bind(obj)
      % Open the connection to allow messages to be sent and received
      if ~isempty(obj.Socket); fclose(obj.Socket); end
      fopen(obj.Socket);
    end
    
    function start(obj, expRef, ai)
      ref = Alyx.parseAlyxInstance(expRef, ai);
      % Send start message to remotehost and await confirmation
      obj.confirmedSend(sprintf('GOGO%s*%s', ref, hostname));
      while obj.AwaitingConfirmation&&...
          ~strcmp(obj.LastReceivedMessage, obj.LastSentMessage)
        pause(0.2);
      end
      if strcmp(obj.Status, 'exception'); error('Confirmation failed'); end
    end
    
    function stop(obj)
      % Send stop message to remotehost and await confirmation
      obj.confirmedSend(sprintf('STOP*%s', hostname));
      while obj.AwaitingConfirmation&&...
          ~strcmp(obj.LastReceivedMessage, obj.LastSentMessage)
        pause(0.1)
      end
      obj.delete
    end
    
    function requestStatus(obj)
      % Request a status update from the remote service
      obj.ConfirmID = randi(1e6);
      obj.sendUDP(sprintf('WHAT%i*%s', obj.ConfirmID, hostname));
      disp('Requested status update from remote service')
    end
        
    function confirmedSend(obj, msg)
      sendUDP(obj, msg)
      obj.AwaitingConfirmation = true;
      % Add timer to impose a response timeout
      if ~isinf(obj.ResponseTimeout)
        obj.ResponseTimer = timer('StartDelay', obj.ResponseTimeout,...
          'TimerFcn', @(src,evt)obj.processMsg(src,evt), 'StopFcn', @(src,~)stop(src));
        start(obj.ResponseTimer) % start the timer
      end
    end
    
    function receiveUDP(obj)
      obj.LastReceivedMessage = strtrim(fscanf(obj.Socket));
      % Remove any more accumulated inputs to the listener
%       obj.Socket.flushinput();
      notify(obj, 'MessageReceived')
    end
    
    function sendUDP(obj, msg)
      % Ensure socket is open before sending message
      if strcmp(obj.Socket.Status, 'closed'); bind(obj); end
      fprintf(obj.Socket, msg); % Send message
      obj.LastSentMessage = msg; % Save a copy of the message
      disp(['Sent message to ' obj.RemoteHost]) % Display success
    end
  end
  
  methods (Access = protected)
      function processMsg(obj, src, evt)
      % Parse the message into its constituent parts
      response = regexp(obj.LastReceivedMessage,...
        '(?<status>[A-Z]{4})(?<body>.*)\*(?<host>\w*)', 'names');
      % Check that the message was from the correct host, otherwise ignore
      if ~isempty(response)&&~any(strcmp(response.host, {obj.RemoteHost hostname}))
        warning('Received message from %s, ignoring', response.host);
        return
      end
      % We no longer need the timer, stop it
      if ~isempty(obj.ResponseTimer)
        stop(obj.ResponseTimer);
        delete(obj.ResponseTimer);
        obj.ResponseTimer = [];
      end
      
      if obj.AwaitingConfirmation
        % Reset AwaitingConfirmation
        obj.AwaitingConfirmation = false;
        try % Check the confirmation message is the same as the sent message
          assert(~isempty(response)&&... % something received
            strcmp(response.status, 'WHAT')||... % status update
            strcmp(obj.LastReceivedMessage, obj.LastSentMessage),... % is echo
            'Confirmation failed')
        catch ex
          obj.Status = 'exception';
          rethrow(ex)
        end
      end
      % At the moment we just disply some stuff, other functions listening
      % to the MessageReceived event can do their thing
      if isempty(response); return; end
      switch response.status
        case 'GOGO'
          if obj.AwaitingConfirmation
            obj.Status = 'running';
            disp(['Service on ' obj.RemoteHost ' running'])
          else
            disp('Received start request')
            obj.LocalStatus = 'starting';
            if ~isempty(obj.StartCallback)&&isa(obj.StartCallback,'function_handle')
              try
              feval(obj.StartCallback, src, evt);
              obj.LocalStatus = 'running';
              obj.sendUDP(obj.LastReceivedMessage)
              catch ex
                obj.LocalStatus = 'exception';
                error('Failed to start service: %s', ex.message)
              end
            end
          end
        case 'STOP'
          if obj.AwaitingConfirmation
            obj.Status = 'stopped';
            disp(['Service on ' obj.RemoteHost ' stopped'])
          else
            disp('Received stop request')
            obj.LocalStatus = 'stopping';
            if ~isempty(obj.StopCallback)&&isa(obj.StopCallback,'function_handle')
              try
              feval(obj.StopCallback, src, evt);
              obj.LocalStatus = 'idle';
              obj.sendUDP(obj.LastReceivedMessage)
              catch
                obj.LocalStatus = 'exception';
                error('Failed to stop service')
              end
            end
          end
        case 'WHAT'
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
          else
            % Ignore if it is our own 
            if strcmp(response.host, hostname); return; end
            try
              obj.sendUDP(['WHAT' parsed.id obj.LocalStatus '*' obj.RemoteHost])
              disp(['Sent status update to ' obj.RemoteHost]) % Display success
            catch
              error('Failed to send status update to %s', obj.RemoteHost)
            end
          end
        otherwise
          disp(['Received ''' obj.LastReceivedMessage ''' from ' obj.RemoteHost])
      end
    end
  end
end