classdef BallUDPService < srv.BasicUDPService
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
  %   See also SRV.PRIMITIVEUDPSERVICE, UDP.
  %
  % Part of Rigbox
  
  % 2017-10 MW created
  
  properties
    % Holds an instance of timeline for recording messages
    Timeline
    % Holds struct of ball values
    Ball
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
    
    function obj = BallUDPService(ball, remoteHost,listenPort)
      % SRV.BASICUDPSERVICE(remoteHost [remotePort, listenPort])
      %   remoteHost is the hostname of the service with which to send and
      %   receive messages.
      if nargin < 2; remoteHost = ''; end
      obj.RemoteHost = remoteHost;
      obj.ListenPort = 9999;
      obj.Socket = udp(remoteHost, 'LocalPort', obj.ListenPort);
      obj.Socket.ReadAsyncMode = 'continuous';
      obj.Socket.DatagramReceivedFcn = @(~,~)obj.processMsg;
      obj.addlistener({'RemoteHost', 'ListenPort', 'RemotePort', 'EnablePortSharing'},...
        'PostSet',@(src,~)obj.update(src));
      % Set ball origin signal
      obj.Ball = ball;
      obj.bind;
    end
            
    function start(~, ~, ~)
      % Send start message to remotehost and await confirmation
    end
    
    function stop(~)
      % Send stop message to remotehost and await confirmation
    end
                
%     function receiveUDP(obj)
%       obj.LastReceivedMessage = strtrim(fscanf(obj.Socket));
%       % Remove any more accumulated inputs to the listener
% %       obj.Socket.flushinput();
%       notify(obj, 'MessageReceived')
%     end
    
  end
  
  methods (Access = protected)
      function processMsg(obj)
       obj.LastReceivedMessage = strtrim(char(fread(obj.Socket)'));
       C = cellfun(@str2num,strsplit(obj.LastReceivedMessage), 'uni', 0);
       s = obj.Ball;
       [s.time, s.Ax, s.Ay, s.Bx, s.By] = deal(C{:});
%        post(obj.Ball, s);
       disp(['Received ''' obj.LastReceivedMessage ''' from ' obj.RemoteHost])
      end
    end
end