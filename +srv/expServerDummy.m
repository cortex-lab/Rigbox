function expServerDummy()
%SRV.EXPSERVER Start the presentation server
%   TODO
%
% Part of Rigbox

% 2013-06 CB created

%% Parameters
warning('off', 'Rigbox:setup:toolboxRequired')
warning('off', 'Rigbox:setup:javaNotSetup')
warning('off', 'Rigbox:setup:libraryRequired')
warning('off', 'toStr:isstruct:Unfinished')

addRigboxPaths(false)

global running
listenPort = io.WSJCommunicator.DefaultListenPort;

%% Initialisation
% communicator for receiving commands from clients
communicator = io.WSJCommunicator.server(listenPort);
listener = event.listener(communicator, 'MessageReceived',...
  @(~,msg) handleMessage(msg.Id, msg.Data, msg.Sender));
communicator.EventMode = false;
communicator.open();

experiment = []; % currently running experiment, if any

% get rig hardware
rig = hw.devices('trainingRig', false);

cleanup = onCleanup(@() fun.applyForce({
  @() communicator.close(),...
  @() delete(listener),...
  }));

log('Started presentation server on port %i', listenPort);

running = true;

%% Main loop for service
while running
  if communicator.IsMessageAvailable
    [msgid, msgdata, host] = communicator.receive();
    handleMessage(msgid, msgdata, host);
  end
    
  % pause a little while to allow other OS processing
  pause(5e-3);
end

%% Helper functions
  function handleMessage(id, data, host)
    if strcmp(id, 'goodbye')
      % client disconnected
      log('''%s'' disconnected', host);
    else
      command = data{1};
      args = data(2:end);
      if ~strcmp(command, 'status')
        % log the command received
        log(sprintf('Received ''%s''', command));
      end
      switch command
        case 'status'
          % status request
          if isempty(experiment)
            communicator.send(id, {'idle'});
          else
            communicator.send(id, {'running' experiment.Data.expRef});
          end
        case 'run'
          % exp run request
          [expRef, preDelay, postDelay, Alyx] = args{:};
          Alyx.Headless = true; % Supress all dialog prompts
          if dat.expExists(expRef)
            log('Starting experiment ''%s''', expRef);
            communicator.send(id, []);
            try
              communicator.send('status', {'starting', expRef});
              aborted = runExp(expRef, preDelay, postDelay, Alyx);
              log('Experiment ''%s'' completed', expRef);
              communicator.send('status', {'completed', expRef, aborted});
            catch runEx
              communicator.send('status', {'expException', expRef, runEx.message});
              log('Exception during experiment ''%s'' because ''%s''', expRef, runEx.message);
              rethrow(runEx);%rethrow for now to get more detailed error handling
            end
          else
            log('Failed because experiment ref ''%s'' does not exist', expRef);
            communicator.send(id, {'fail', expRef,...
              sprintf('Experiment ref ''%s'' does not exist', expRef)});
          end
        case 'quit'
          if ~isempty(experiment)
            immediately = args{1};
            AlyxInstance = args{2};
            if immediately
              log('Aborting experiment');
            else
              log('Ending experiment');
            end
            if ~isempty(AlyxInstance)&&isempty(experiment.AlyxInstance)
              experiment.AlyxInstance = AlyxInstance;
            end
            experiment.quit(immediately);
            send(communicator, id, []);
            running = false;
          else
            log('Quit message received but no experiment is running\n');
          end
        case 'updateAlyxInstance' %recieved new Alyx Instance from Stimulus Control
            AlyxInstance = args{1}; %get struct
            if ~isempty(AlyxInstance)
              experiment.AlyxInstance = AlyxInstance; %set property for current experiment
            end
            send(communicator, id, []); %notify Stimulus Controllor of success
      end
    end
  end

  function aborted = runExp(expRef, preDelay, postDelay, Alyx)
    %otherwise using system clock, so zero it
    rig.clock.zero();
    
    % prepare the experiment
    params = dat.expParams(expRef);
    experiment = srv.prepareExp(params, rig, preDelay, postDelay,...
      communicator);
    communicator.EventMode = true; % use event-based callback mode
    experiment.AlyxInstance = Alyx; % add Alyx Instance
    experiment.run(expRef); % run the experiment
    communicator.EventMode = false; % back to pull message mode
    aborted = strcmp(experiment.Data.endStatus, 'aborted');
    % clear the active experiment var
    experiment = [];
    
    % save a copy of the hardware in JSON
    name = dat.expFilePath(expRef, 'hw-info', 'master');
    fid = fopen([name(1:end-3) 'json'], 'w');
    fprintf(fid, '%s', obj2json(rig));
    fclose(fid);
    try
      Alyx.registerFile([name(1:end-3) 'json']);
    catch
    end
  end

  function log(varargin)
    message = sprintf(varargin{:});
    timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
    fprintf('[%s] %s\n', timestamp, message);
  end

  function setClock(user, clock)
    if isfield(rig, user)
      rig.(user).Clock = clock;
    end
  end
log('Stopped presentation server'); %#ok<*UNRCH>
end