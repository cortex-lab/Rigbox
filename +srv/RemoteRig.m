classdef RemoteRig < handle
  %SRV.REMOTERIG Interface to, and info about a remote rig setup
  %   No Longer used by srv.expServer.  This class uses the
  %   io.TCPCommunicator as its interface (which creates java web sockets).
  %   Replaced by SRV.STIMULUSCONTROL
  %
  % Part of Rigbox

  % 2013-06 CB created  
  
  properties
    Communicator %Experiment server communicator
    Services = {}  %List of remote services
    Name
    ResponseTimeout = 15 %Default timeout for communicator responses
    Messages = struct('id', {}, 'msg', {})
    ExpPreDelay = 0
    ExpPostDelay = 0
  end
  
  properties (Access = protected)
    pConnected = false %whether currently connected to Communicator
    NextMsgId = 0
  end
  
  properties (Dependent = true)
    %current status of the rig:
    %'disconnected' if not currently connected, 'idle' if connected but no
    %active services on the rig, 'active' if any services are currently
    %running
    Status
    ExpRunning %Reference of currently running experiment, if any/known
  end
  
  events
    Connected
    Disconnected
    ExpStarted
    ExpStopped
    ExpUpdate
  end
  
  methods (Static)
    function r = tcp(name, host, port, services)
      if nargin < 4
        services = {};
      end
      if nargin < 3
        port = 9090;
      end
      r = srv.RemoteRig;
      r.Name = name;
      r.Communicator = io.TCPCommunicator.requestor(host, port, 1);
      r.Services = services;
    end
  end
  
  methods
    function s = char(obj)
      s = obj.Name;
    end
    
    function refresh(obj)
      global RemoteRigException %if there's any exceptions it will end up here
      %refresh
      try 
        % if not connected, just return
        if ~obj.pConnected
          return
        end
        %% process any messages that have arrived
        m = obj.takeMessages('status', 1);
        while ~isempty(m)
          m = m{1}; % extract the singleton message
          type = m{1};
          switch type
            case 'completed'
              %experiment stopped without any exceptions
              ref = m{2};
              notify(obj, 'ExpStopped', srv.ExpEvent('completed', ref));
            case 'expException'
              %experiment stopped with an exception
              ref = m{2};
              err = m{3};
              notify(obj, 'ExpStopped', srv.ExpEvent('exception', ref, err));
            case 'update'
              ref = m{2};
              data = m(3:end);
              notify(obj, 'ExpUpdate', srv.ExpEvent('update', ref, data));
          end
          m = obj.takeMessages('status', 1); % check for any more...
        end
        %% now check we're still connected
        m = obj.takeMessages('goodbye', 1);
        if ~isempty(m)
          obj.disconnect(); %server disconnected
        else
          %         try
          %           obj.exchange({'status'});
          %         catch ex
          %           %since status check failed, assume we're disconnected and update
          %           %state accordingly
          %           obj.disconnect();
          %         end
        end
      catch ex
        disp('Exception during RemoteRig refresh:');
        disp(ex);
        RemoteRigException = ex;
        disp(ex.stack);
      end
    end

    function value = get.Status(obj)
      if ~obj.pConnected
        value = 'disconnected';
      else
        r = obj.exchange({'status'});
        value = r{1};          
      end
    end
    
    function value = get.ExpRunning(obj)
      value = []; % default to empty means none
      if obj.pConnected
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
      notify(obj, 'ExpStarted', srv.ExpEvent('started', expRef));
%       if nargin < 3
%         services = obj.Services;
%       end
%       %map any services referenced by id to the service objects
%       services = mapToCellArray(@(s) iff(ischar(s), @() obj.serviceById(s), s), services);
%       %Ensure the requested services are all currently idle
%       statuses = mapToCellArray(@(s) s.Status, obj.Services);
%       assert(strcmp(statuses, 'idle'), 'One or more services are already running');
%       %Begin the services one-by-one. If any fail, try to stop all started
%       %up to that point
%       for i = 1:numel(services)
%         try
%           services{i}.start(expRef);
%         catch ex
%           %stop services that were started up till now
%           applyForce(@(s) s.stop(), services(1:(i- 1)));
%           rethrow(ex); % now rethrow the exception
%         end
%       end
    end
    
    function s = serviceById(obj, name)
      serviceIds = cellfun(@(s) s.Id, obj.Services, 'Uni', false);
      s = obj.Services{strcmp(serviceIds, name)};
    end
    
    function connect(obj)
      if ~obj.pConnected
        obj.Communicator.open();
        obj.pConnected = true;
        notify(obj, 'Connected');
      end
    end
    
    function disconnect(obj)
      if obj.pConnected
        obj.Communicator.close();
        obj.pConnected = false;
        notify(obj, 'Disconnected');
      end
    end
  end
  
%   % utility function for throwing up response errors
%   invalidResponseError = @(m, t) error('Remote response invalid: %s "%s"', m, t);
%   % we got a fail response, so throw an error with details
%   error('Remote request failed with "%s"', data{2});
  
  methods (Access = protected)
    function status = servicesStatus(obj)
      status = cell(size(obj.Services));
      for i = 1:numel(obj.Services)
        status{i} = obj.Services{i}.Status;
      end
    end
    
    function checkMessages(obj)
      %receive all available messages and place into inbox queue
      while obj.Communicator.IsMessageAvailable
        [msgId, data] = obj.Communicator.receive;
        if iscell(data)
          data = {data};
        end
        newMessage = struct('id', msgId, 'msg', data);
        obj.Messages = [obj.Messages, newMessage];
      end
    end
    
    function m = takeMessages(obj, id, n)
      %takeMessages
      
      obj.checkMessages(); %check for more messages
      
      %get indices of messages with specified id
      idx = find(strcmp({obj.Messages.id}, id));
      if nargin >= 3
        %slice first n indices
        idx = idx(1:min(n, length(idx)));
      end
      m = {obj.Messages(idx).msg}; %retreive those messages
      obj.Messages(idx) = []; %remove those messages from the queue
    end
    
    function m = waitForMessage(obj, id)
      t = GetSecs;
      while (GetSecs - t) < obj.ResponseTimeout
        m = takeMessages(obj, id, 1);
        if ~isempty(m)
          m = m{1};
          return
        end
        drawnow; % let callbacks execute
      end
      error('Timeout waiting for message with id ''%s''', id);
    end
    
    function errorOnFail(obj, r)
      if iscell(r) && strcmp(r{1}, 'fail')
        error(r{3});
      end
    end
    
    function response = exchange(obj, message)
      id = num2str(obj.NextMsgId);
      obj.NextMsgId = obj.NextMsgId + 1;
      % send the the command to make the function call
      obj.Communicator.send(id, message); 

      % wait for specified response upto timeout seconds
      response = waitForMessage(obj, id);
    end    
  end
  
end

