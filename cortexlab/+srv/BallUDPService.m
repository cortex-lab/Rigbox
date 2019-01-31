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
  %     bind(ballSocket);
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
    function obj = BallUDPService(remoteHost, ball)
      % SRV.BASICUDPSERVICE(remoteHost [remotePort, listenPort])
      %   remoteHost is the hostname of the service with which to send and
      %   receive messages.  
      %
      % See also EXP.SIGNALSEXP
      if nargin < 2; remoteHost = ''; end      
      obj = obj@srv.BasicUDPService(remoteHost, [], 9999);
      % Clear function created by superclass
      obj.Socket.BytesAvailableFcn = '';
      obj.Socket.DatagramReceivedFcn = @(~,~)obj.processMsg;
      % Set ball origin signal
      obj.Ball = ball;
    end
            
    function start(~, ~, ~)
      % Send start message to remotehost and await confirmation
    end
    
    function stop(~)
      % Send stop message to remotehost and await confirmation
    end
                
  end
  
  methods (Access = protected)
      function processMsg(obj)
       % PROCESSMSG Convert UDP string to struct and post to ball Signal
       %  Reads in the buffer as a character array, trims any trailing
       %  spaces and converts to cell array of numbers.  This is then
       %  assigned to the fields of a structure and posted to the origin
       %  Signal stored in obj.Ball
       obj.LastReceivedMessage = strtrim(char(fread(obj.Socket)'));
       C = cellfun(@str2num,strsplit(obj.LastReceivedMessage), 'uni', 0);
       try
         [s.time, s.Ax, s.Ay, s.Bx, s.By] = deal(C{:});
         post(obj.Ball, s);
         disp(['Received ''' obj.LastReceivedMessage ''' from ' obj.RemoteHost])
       catch ex
         warning('BallUDPService:processMsg:Failed', ...
           'Failed to process message ''%s'': %s', ...
           obj.LastReceivedMessage, ex.message)
       end
      end
  end
end