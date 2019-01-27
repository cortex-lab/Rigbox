classdef BallUDPService < srv.BasicUDPService
  %SRV.BALLUDPSERVICE Interface for MouseBall UDPs
  %   A UDP interface that uses the udp function of the Instument Control
  %   Toolbox. Unlike SRV.PRIMITIVEUDPSERVICE, this can recieve messages
  %   asynchronously.
  %
  %   Examples:
  %     net = sig.Net;
  %     ball = net.subscriptableOrigin('ball');
  %     ballSocket = srv.BallUDPService(ballHost, ball);
  %
  %   See also SRV.BASICUDPSERVICE, UDP.
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
    
    function obj = BallUDPService(ball, remoteHost)
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
       [s.time, s.Ax, s.Ay, s.Bx, s.By] = deal(C{:});
       post(obj.Ball, s);
       disp(['Received ''' obj.LastReceivedMessage ''' from ' obj.RemoteHost])
      end
    end
end