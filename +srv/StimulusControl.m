classdef StimulusControl < handle
  %SRV.STIMULUSCONTROL Interface to, and info about a remote rig setup
  %   Detailed explanation goes here
  %
  % Part of Rigbox
  
  % 2013-06 CB created
  
  properties
    Uri
    Services = {}  %List of remote services
    Name
    ExpPreDelay = 0
    ExpPostDelay = 0
    ResponseTimeout = 15
  end
  
  properties (Dependent = true)
    %current status of the rig:
    %'disconnected' if not currently connected, 'idle' if connected but no
    %active services on the rig, 'active' if any services are currently
    %running
    Status
    ExpRunnning %Reference of currently running experiment, if any/known
  end
  
  properties (Transient, SetAccess = protected, Hidden)
    Socket
    hSocket%handle to java socket
    NextMsgId = 0
    Responses %Map from message IDs to responses
    LogTimes = zeros(10000,2)
    LogCount = 0
  end
  
  properties (Constant)
    DefaultPort = 2014
  end
  
  events
    Connected
    Disconnected
    ExpStarting
    ExpStarted
    ExpStopped
    ExpUpdate
  end
  
  methods (Static)
    function s = create(name, uri)
      if nargin < 2
        uri = name;
      end
      s = srv.StimulusControl;
      s.Name = name;
      if isempty(regexp(uri, '^ws://', 'once'))
        uri = ['ws://' uri]; %default protocol prefix
      end
      if isempty(regexp(uri, '^ws://.+:\d+$', 'once'))
        uri = sprintf('%s:%i', uri, s.DefaultPort); %default port suffix
      end
      s.Uri = uri;
    end
  end
  
  methods
    function s = char(obj)
      s = obj.Name;
    end
    
    function value = get.Status(obj)
      if ~connected(obj)
        value = 'disconnected';
      else
        r = exchange(obj, {'status'});
        value = r{1};
      end
    end
    
    function value = get.ExpRunnning(obj)
      value = []; % default to empty means none
      if connected(obj)
        r = obj.exchange({'status'});
        if strcmp(r{1}, 'running')
          value = r{2};
        end
      end
    end
    
    function quitExperiment(obj, immediately)
      if nargin < 2
        immediately = false;
      end
      r = obj.exchange({'quit', immediately});
      obj.errorOnFail(r);
    end
    
    function startExperiment(obj, expRef)
      %startExperiment
      %Ensure the experiment ref exists
      assert(dat.expExists(expRef), 'Experiment ref ''%s'' does not exist', expRef);
      
      preDelay = obj.ExpPreDelay;
      postDelay = obj.ExpPostDelay;
      
      r = obj.exchange({'run', expRef, preDelay, postDelay});
      obj.errorOnFail(r);
    end
    
    function connect(obj, block)
      if nargin < 2
        block = false;
      end
      if ~connected(obj)
        obj.Responses = containers.Map;
        if isempty(obj.Socket)
          [obj.Socket, obj.hSocket] = webSocket(obj);
        end
        obj.Socket.connect();
        if block
          %wait until connected (or timeout elapsed)
          timeoutMs = 1000*obj.ResponseTimeout;
          t = systime;
          while (systime - t < timeoutMs) &&...
              ~obj.Socket.isOpen()
            pause(20e-3);
          end
          %           pause(0.6); %bug: need to wait before allow messages to be sent
          assert(obj.Socket.isOpen(),...
            'Could not connect to ''%s''', obj.Uri);
        end
      end
    end
    
    function disconnect(obj)
      if ~isempty(obj.Socket)% && obj.Socket.isOpen()
        obj.Socket.close();
        pause(15e-3); % pause briefly to let any evoked callbacks run
        set(obj.hSocket, 'BinaryReceivedCallback', [],...
          'ClosedCallback', [], 'OpenedCallback', []);% clear callbacks
        delete(obj.hSocket);% delete the handle
        obj.hSocket = [];
        obj.Responses = [];
        obj.Socket = [];
      end
    end
    
    function delete(obj)
      disconnect(obj);
    end
  end
  
  methods %(Access = protected)
    function b = connected(obj)
      b = ~isempty(obj.Socket) && obj.Socket.isOpen();
    end
    
    function [sock, hSock] = webSocket(obj)
      % connect to a WebSocket client
      sock = net.entropy_mill.websocket.Client(obj.Uri);
      hSock = handle(sock, 'CallbackProperties');
      set(hSock,...
        'BinaryReceivedCallback', @obj.onWSReceived,...
        'ClosedCallback', @obj.onWSClosed,...
        'OpenedCallback', @obj.onWSOpened);
    end
    
    function onWSReceived(obj, ~, eventArgs)
      packet = hlp_deserialize(typecast(eventArgs.getMessage(), 'uint8'));
      id = packet.id;
      data = packet.data;
      if isKey(obj.Responses, id)% response to a previous call
        obj.Responses(id) = data;
      else% route notification & misc messages
        switch id
          case 'signals'
%             fprintf('% i signal updates received\n', numel(data));
            notify(obj, 'ExpUpdate', srv.ExpEvent('signals', [], data));
          case 'status'
            type = data{1};
            switch type
              case 'starting'
                %experiment about to start
                ref = data{2};
                notify(obj, 'ExpStarting', srv.ExpEvent('starting', ref));
              case 'completed'
                %experiment stopped without any exceptions
                ref = data{2};
                notify(obj, 'ExpStopped', srv.ExpEvent('completed', ref));
              case 'expException'
                %experiment stopped with an exception
                ref = data{2}; err = data{3};
                notify(obj, 'ExpStopped', srv.ExpEvent('exception', ref, err));
              case 'update'
                ref = data{2}; args = data(3:end);
                if strcmp(args{1}, 'event') && strcmp(args{2}, 'experimentInit')
                  notify(obj, 'ExpStarted', srv.ExpEvent('started', ref));
                end
                notify(obj, 'ExpUpdate', srv.ExpEvent('update', ref, args));
%                 if numel(args) > 0 && strcmpi(args{1}, 'inputSensorPos')
%                   trec = GetSecs;
%                   tsent = args{3};
%                   obj.LogCount = obj.LogCount + 1;
%                   obj.LogTimes(obj.LogCount,:) = [trec tsent];
%                 end
            end
        end
      end
    end
    
    function onWSOpened(obj, ~, ~)
%       disp('connected');
      notify(obj, 'Connected');
    end
    
    function onWSClosed(obj, ~, ~)
%       disp('disconnected');
      notify(obj, 'Disconnected');
      disconnect(obj);
    end
    
    function send(obj, id, data)
      packet.id = id;
      packet.data = data;
      bytes = hlp_serialize(packet);
      obj.Socket.send(bytes);
    end
    
    function response = exchange(obj, message)
      id = num2str(obj.NextMsgId);
      obj.NextMsgId = obj.NextMsgId + 1;
      obj.Responses(id) = nil; % empty place holder means awaiting
      % send the the command to make the function call
      send(obj, id, message);
      % wait for response
      response = waitForMessage(obj, id);
    end
    
    function msg = waitForMessage(obj, id)
      %wait until message with id arrives (or timeout elapsed)
      timeoutMs = 1000*obj.ResponseTimeout;
      t = systime;
      while isNil(obj.Responses(id)) && (systime - t < timeoutMs)
        pause(1e-3);
      end
      msg = obj.Responses(id);
      assert(~isNil(msg), 'Timed out waiting for message with id ''%s''', id);
      remove(obj.Responses, id); % no longer waiting, remove place holder
    end
    
    function errorOnFail(obj, r)
      if iscell(r) && strcmp(r{1}, 'fail')
        error(r{3});
      end
    end
  end
  
end

