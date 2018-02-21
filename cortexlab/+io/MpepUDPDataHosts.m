classdef MpepUDPDataHosts < srv.Service
  %IO.MPEPUDPDATAHOSTS Control data hosts with the MPEP protocol
  %   TODO
  %
  % Part of Cortex Lab Rigbox customisations
  
  % 2014-01 CB created
  % 2015-07 DS record UDP message to timeline
  % 2016-12 MW update for new timeline object
  
  properties (Dependent, SetAccess = protected)
    Connected
  end
  
  properties
    LocalPort = 1103
    RemotePort = 1001
    DaqVendor
    DaqDevId
    DigitalOutDaqChannelId
    Verbose = false % whether to output I/O messages etc
    Timeline % An instance of timeline for for recording UDP messages
    AlyxInstance % An instance of Alyx for registering files, etc.
  end
  
  properties (SetAccess = protected)
    RemoteHosts = {} %cell array of remote hostnames (strings)
    StimNum
    Socket
  end
  
  properties (Dependent)
    ResponseTimeout
  end
  
  properties (Dependent, SetAccess = protected)
    StimOn
    Status
  end
  
  properties (Access = private)
    ExpRef
    pResponseTimeout = 10
    % When an mpep UDP is sent out, the message is saved here to later check
    % the same message is received back
    LastSentMessage
    DigitalOutSession
    Timer
    RemoteIPs
  end
  
  methods
    function obj = MpepUDPDataHosts(remoteHosts, timeline)
      if nargin<2; timeline = []; end
      obj.Timeline = timeline;
      obj.RemoteHosts = remoteHosts;
    end
    
    function value = get.StimOn(obj)
      value = ~isempty(obj.StimNum);
    end
    
    function open(obj)
      obj.Socket = pnet('udpsocket', obj.LocalPort); % bind listening socket
      % Set timeout to intial value
      pnet(obj.Socket, 'setreadtimeout', obj.ResponseTimeout);
      % Save IP addresses for remote hosts
      obj.RemoteIPs = ipaddress(obj.RemoteHosts);
      % Open the DAQ session, if configured
      if ~isempty(obj.DigitalOutDaqChannelId)
        obj.DigitalOutSession = daq.createSession(obj.DaqVendor);
        obj.DigitalOutSession.addDigitalChannel(...
          obj.DaqDevId, obj.DigitalOutDaqChannelId, 'OutputOnly');
        obj.DigitalOutSession.outputSingleScan(false);
      end
    end
    
    function close(obj)
      % Cleanup timeout timer, close network socket and release DAQ session
      if ~isempty(obj.Timer)
        stop(obj.Timer);
        delete(obj.Timer);
        obj.Timer = [];
      end
      if ~isempty(obj.Socket)
        pnet(obj.Socket, 'close');
        obj.Socket = [];
      end
      if ~isempty(obj.DigitalOutSession)
        release(obj.DigitalOutSession);
        obj.DigitalOutSession = [];
      end
    end
    
    function delete(obj)
      close(obj);
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
    
    function expStarted(obj, ref)
      obj.ExpRef = ref; % save the experiment reference
      % Send the ExpStart UDP
      [subject, seriesNum, expNum] = dat.expRefToMpep(obj.ExpRef);
      expStartMsg = sprintf('ExpStart %s %d %d', subject, seriesNum, expNum);
      confirmedBroadcast(obj, expStartMsg);
      
      % Send the BlockStart UDP
      % start a block (we only use one per experiment)
      blockStartMsg = sprintf('BlockStart %s %d %d 1', subject, seriesNum, expNum);
      confirmedBroadcast(obj, blockStartMsg);
    end
    
    function stimStarted(obj, num, duration)
      validateResponses(obj); % validate any outstanding responses
      obj.StimNum = num;
      % Send the StimStart UDP
      [subject, seriesNum, expNum] = dat.expRefToMpep(obj.ExpRef);
      msg = sprintf('StimStart %s %d %d 1 %d %d',...              %2014/4/8 DS: why trial number is always 1???
        subject, seriesNum, expNum, obj.StimNum, duration + 1);
      confirmedBroadcast(obj, msg);
      
     
      % Create a timeout timer
      timeoutTimer = timer('StartDelay', duration, 'TimerFcn', @(t,d) stimEnded(obj, num));
      % Set digital out line up if any
      if ~isempty(obj.DigitalOutSession)
        obj.DigitalOutSession.outputSingleScan(true);
        if obj.Verbose
          fprintf('DAQ digital out -> true\n');
        end
      end
      start(timeoutTimer); % start timeout timer
      obj.Timer = timeoutTimer;
    end
    
    function stimEnded(obj, num)
      if nargin < 2
        num = obj.StimNum;
      end
      if obj.Verbose
          fprintf('stimEnd(%i)\n', num);
      end
      if obj.StimOn && obj.StimNum == num
        tic;
        obj.StimNum = [];
        if ~isempty(obj.Timer)
          % stop and delete the timeout timer
          stop(obj.Timer);
          delete(obj.Timer);
          obj.Timer = [];
        end
        % Set digital out line down if any
        if ~isempty(obj.DigitalOutSession)
          obj.DigitalOutSession.outputSingleScan(false);
          if obj.Verbose
            fprintf('DAQ digital out -> false\n');
          end
        end
        % Send the StimEnd UDPS
        [subject, seriesNum, expNum] = dat.expRefToMpep(obj.ExpRef);
        msg = sprintf('StimEnd %s %d %d 1 %d', subject, seriesNum, expNum, num);
        broadcast(obj, msg);
        
         if ~isempty(obj.Timeline)&&isfield(obj.Timeline, 'IsRunning')&&obj.Timeline.IsRunning
           obj.Timeline.record('mpepUDP', msg); % record the UDP event in Timeline
         end
         dt = toc;
         if obj.Verbose
           fprintf('waiting took %.3fs\n', dt);
         end
      end
    end
    
    function expEnded(obj)
      % If StimStart was sent without corresponding StimEnd, send it now
      if obj.StimOn
        stimEnded(obj);
      end
      validateResponses(obj); % validate any outstanding responses
      
      % Send the BlockEnd UDP
      [subject, seriesNum, expNum] = dat.expRefToMpep(obj.ExpRef);
      blockEndMsg = sprintf('BlockEnd %s %d %d 1', subject, seriesNum, expNum);
      confirmedBroadcast(obj, blockEndMsg);
      
      % Send the ExpEnd UDP
      % Start a block (we only use one per experiment)
      expEndMsg = sprintf('ExpEnd %s %d %d', subject, seriesNum, expNum);
      confirmedBroadcast(obj, expEndMsg);
      
      obj.ExpRef = [];
    end
    
    function start(obj, expRef, ai)  
      % Deal with Alyx instance first
      if ~isempty(ai)
        obj.AlyxInstance = ai;
        UDP_msg = Alyx.parseAlyxInstance(expRef, ai);
        [subject, seriesNum, expNum] = dat.expRefToMpep(expRef);
        alyxmsg = sprintf('alyx %s %d %d %s', subject, seriesNum, expNum, UDP_msg);
        confirmedBroadcast(obj, alyxmsg);
      end
      
      % Equivalent to startExp(expRef)
      expStarted(obj, expRef);
    end
    
    function stop(obj)
      % Equivalent to endExp()
      expEnded(obj);
    end
    
    function ok = ping(obj)
      obj.broadcast('hello');
      try
        ok = awaitResponses(obj);
      catch
        ok = false;
      end
    end
    
    function b = get.Connected(obj)
      if ~isempty(obj.Socket)
        b = ping(obj);
      else
        b = false(size(obj.RemoteHosts));
      end
    end
    
    function confirmedBroadcast(obj, msg)
      broadcast(obj, msg);
      validateResponses(obj);
      if ~isempty(obj.Timeline)&&isfield(obj.Timeline, 'IsRunning')&&obj.Timeline.IsRunning
        obj.Timeline.record('mpepUDP', msg); % record the UDP event in Timeline
      end
    end
    
    function broadcast(obj, msg)
      % Send UDP to all remote hosts
      cellfun(@(host) obj.sendPacket(msg, host), obj.RemoteHosts);
      obj.LastSentMessage = msg;
    end
    
    function validateResponses(obj)
      % If a recent UDP message was sent and the response hasn't been
      % received and checked that it matches what was sent, check it now.
      if ~isempty(obj.LastSentMessage)
        ok = awaitResponses(obj);
        assert(all(ok), 'A valid UDP confirmation was not received within timeout period');
      end
    end
    
    function ok = awaitResponses(obj)
      % Check response is what we sent (with Timeout)
      expecting = obj.LastSentMessage;
      % IP address of remote hosts we are expecting confirmation from
      waiting = ipaddress(obj.RemoteHosts);
      ok = false(size(waiting));
      % Receive 'num remote hosts' of packets
      for i = 1:numel(obj.RemoteHosts)
        tic
        [msg, ip] = obj.readPacket;
        dt = toc;
        match = find(strcmp(waiting, ip), 1);
        assert(~isempty(match),...
          'Received UDP packet after %.2fs from unexpected IP address ''%s'',\nmessage was ''%s''\nAwaiting response from %s',...
          dt, ip, msg, strjoin(obj.RemoteHosts, ', '));
        waiting(match) = []; % remove matching IP from confirmation list
        ok(i) = isequal(expecting, msg);
      end
      obj.LastSentMessage = [];
    end
    
    function sendPacket(obj, msg, host)
      % Send the packet with 'msg'
      pnet(obj.Socket, 'write', msg);
      pnet(obj.Socket, 'writepacket', host, obj.RemotePort);
      if obj.Verbose
        fprintf('OUT to %s: %s\n', host, msg);
      end
    end
    
    function [msg, ip] = readPacket(obj)
      pnet(obj.Socket, 'readpacket');
      msg = pnet(obj.Socket, 'read');
      ip = sprintf('%i.%i.%i.%i', pnet(obj.Socket, 'gethost'));
      if obj.Verbose
        match = find(strcmp(obj.RemoteIPs, ip), 1);
        if isempty(match)
          host = ip;
        else
          host = obj.RemoteHosts{match};
        end
        fprintf('IN from %s: %s\n', host, msg);
      end
    end
    
  end
end

