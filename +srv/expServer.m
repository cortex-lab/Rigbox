function expServer(useTimelineOverride, bgColour)
%SRV.EXPSERVER Start the presentation server
%   Principle function for running experiments.  ExpServer listens for
%   commands via TCP/IP Web sockets to start, stop and pause stimulus
%   presentation experiments.
%
%   Inputs:
%     useTimelineOverride (logical) - Flag indicating whether to start
%       Timeline.  If empty the default is the UseTimeline flag in the
%       hardware file.  Timeline may still be toggled by pressing the 't'
%       key.
%     bgColour (1-by-3 double) - The background colour of the stimulus
%       window.  If not specified the background colour specified in the
%       harware file is used.
%
%   Key bindings:
%     t - Toggle Timeline on and off.  The default state is defined in the
%       hardware file but may be overridden as the first input argument.
%     w - Toggle reward on and off.  This switches the output of the first
%       DAQ output channel between its 'high' and 'low' state.  The
%       specific DAQ channel and its default state are set in the hardware
%       file.
%     space - Deliver default reward, specified by the DefaultCommand
%       property in the hardware file.
%     m - Perform water calibration.
%     b - Toggle the background colour between the default and white.
%     g - Perform gamma correction
%
%
% See also MC, io.WSJCommunicator, hw.devices, srv.prepareExp, hw.Timeline
%
% Part of Rigbox

% 2013-06 CB created

%% Parameters
global AGL GL GLU %#ok<NUSED>
listenPort = io.WSJCommunicator.DefaultListenPort;
quitKey = KbName('q');
rewardToggleKey1 = KbName('z');
rewardToggleKey2 = KbName('c');
rewardPulseKey1 = KbName('a');
rewardPulseKey2 = KbName('d');
rewardCalibrationKey1 = KbName('n');
rewardCalibrationKey2 = KbName('m');
viewCalibrationKey = KbName('k');
gammaCalibrationKey = KbName('g');
timelineToggleKey = KbName('t');
toggleBackground = KbName('b');
rewardId = 1;

%% Initialisation
% Pull latest changes from remote
% git.update();
% random seed random number generator
rng('shuffle');
% communicator for receiving commands from clients
communicator = io.WSJCommunicator.server(listenPort);
listener = event.listener(communicator, 'MessageReceived',...
    @(~,msg) handleMessage(msg.Id, msg.Data, msg.Sender));
communicator.EventMode = false;
communicator.open();

experiment = []; % currently running experiment, if any

% set PsychPortAudio verbosity to warning level
oldPpaVerbosity = PsychPortAudio('Verbosity', 2);
Priority(1); % increase thread priority level

% OpenGL
InitializeMatlabOpenGL;

% listen to keyboard events
KbQueueCreate();
KbQueueStart();

% get rig hardware
try
    rig = hw.devices;
    rewardId = find(strcmp(rig.daqController.ChannelNames, 'reward'));
catch ME
    fun.applyForce({
        @() communicator.close(),...
        @() delete(listener),...
        @KbQueueRelease,...
        @() Screen('CloseAll'),...
        @() PsychPortAudio('Close'),...
        @() Priority(0),... %set back to normal priority level
        @() PsychPortAudio('Verbosity', oldPpaVerbosity)...
        });
    rethrow(ME)
end

cleanup = onCleanup(@() fun.applyForce({
    @() communicator.close(),...
    @() delete(listener),...
    @ShowCursor,...
    @KbQueueRelease,...
    @() rig.stimWindow.close(),...
    @() aud.close(rig.audio),...
    @() Priority(0),... %set back to normal priority level
    @() PsychPortAudio('Verbosity', oldPpaVerbosity)...
    }));

% HideCursor();

if nargin < 2
    bgColour = 127*[1 1 1]; % mid gray by default
end
% open the stimulus window
rig.stimWindow.BackgroundColour = bgColour;
rig.stimWindow.open();

fprintf('\n<q> quit, <w> toggle reward, <t> toggle timeline\n');
fprintf(['<%s> reward pulse left, <%s> reward pulse right, <%s> perform reward calibration left\n' ...
    '<%s>, perform reward calibration right <%s> perform gamma calibration\n'], KbName(rewardPulseKey1), KbName(rewardPulseKey2),...
    KbName(rewardCalibrationKey1), KbName(rewardCalibrationKey2), KbName(gammaCalibrationKey));
log('Started presentation server on port %i', listenPort);

if nargin < 1 || isempty(useTimelineOverride)
    % toggle use of timeline according to rig default setting
    toggleTimeline(rig.timeline.UseTimeline);
else
    toggleTimeline(useTimelineOverride);
end

running = true;
calibration_displayed = false;

%% Main loop for service
while running
    % Check for messages when out of event mode
    if communicator.IsMessageAvailable
        [msgid, msgdata, host] = communicator.receive();
        handleMessage(msgid, msgdata, host);
    end
    
    [~, firstPress] = KbQueueCheck;
    
    % check if the quit key was pressed
    if firstPress(quitKey) > 0
        log('Quitting (quit key pressed)');
        running = false;
    end
    
    % check if the quit key was pressed
    if firstPress(timelineToggleKey) > 0
        toggleTimeline();
    end
    
    % check for reward toggle
    if firstPress(rewardToggleKey1) > 0
        log('Toggling left reward valve');
        curr = rig.daqController.Values;
        curr = curr{rewardId};
        sig = rig.daqController.SignalGenerators(rewardId);
        if curr(1) == sig.OpenValue
            rig.daqController.set_ports('reward', [sig.ClosedValue, curr(2)]);
        else
            rig.daqController.set_ports('reward', [sig.OpenValue, curr(2)]);
        end
    end
    if firstPress(rewardToggleKey2) > 0
        log('Toggling right reward valve');
        curr = rig.daqController.Values;
        curr = curr{rewardId};
        sig = rig.daqController.SignalGenerators(rewardId);
        if curr(2) == sig.OpenValue
            rig.daqController.set_ports('reward', [curr(1), sig.ClosedValue]);
        else
            rig.daqController.set_ports('reward', [curr(1), sig.OpenValue]);
        end
    end
    
    % check for reward pulse
    if firstPress(rewardPulseKey1) > 0
        log('Delivering default reward');
        rig.daqController.command('reward', [1.5,0]);
    end
    if firstPress(rewardPulseKey2) > 0
        log('Delivering default reward');
        rig.daqController.command('reward', [0,1.5]);
    end
    
    % check for reward calibration
    if firstPress(rewardCalibrationKey1) > 0
        log('Performing a reward delivery calibration');
        calibrateWaterDelivery(1);
    end
    if firstPress(rewardCalibrationKey2) > 0
        log('Performing a reward delivery calibration');
        calibrateWaterDelivery(2);
    end
    
    % check for view calibration
    if firstPress(viewCalibrationKey) > 0
        if ~calibration_displayed
            log('Displaying calibration');
            viewCalibration();
            calibration_displayed = true;
        else
            log('Un-displaying calibration');
            Screen('Flip', rig.stimWindow.PtbHandle);
            calibration_displayed = false;
            
        end
    end
    
    % check for gamma calibration
    if firstPress(gammaCalibrationKey) > 0
        log('Performing a gamma calibration');
        calibrateGamma();
    end
    
    if firstPress(toggleBackground) > 0
        log('Changing background to white');
        whiteScreen();
    end
    
    if firstPress(KbName('1')) > 0
        rewardId = 1;
    end
    if firstPress(KbName('2')) > 0
        rewardId = 2;
    end
    
    % pause a little while to allow other OS processing
    pause(5e-3);
end
ShowCursor();

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
                    [expRef, preDelay, postDelay, AlyxInstance] = args{:};
                    % assert that experiment not already running
                    if ~isempty(experiment)
                        failMsg = sprintf(...
                            'Failed because another experiment (ref ''%s'') running', ...
                            experiment.Data.expRef);
                        log(failMsg);
                        communicator.send(id, {'fail', expRef, failMsg});
                        return
                    end
                    if isempty(AlyxInstance); AlyxInstance = Alyx('',''); end
                    AlyxInstance.Headless = true; % Supress all dialog prompts
                    if dat.expExists(expRef)
                        log('Starting experiment ''%s''', expRef);
                        communicator.send(id, []);
                        try
                            communicator.send('status', {'starting', expRef});
                            aborted = runExp(expRef, preDelay, postDelay, AlyxInstance);
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
                        AlyxInstance = iff(isempty(args{2}), Alyx('',''), args{2});
                        AlyxInstance.Headless = true;
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
                    else
                        log('Quit message received but no experiment is running\n');
                    end
                case 'updateAlyxInstance' %recieved new Alyx Instance from Stimulus Control
                    AlyxInstance = iff(isempty(args{1}), Alyx('',''), args{1});
                    AlyxInstance.Headless = true;
                    if ~isempty(AlyxInstance)
                        experiment.AlyxInstance = AlyxInstance; %set property for current experiment
                    end
                    send(communicator, id, []); %notify Stimulus Controllor of success
            end
        end
    end

    function aborted = runExp(expRef, preDelay, postDelay, Alyx)
        % disable ptb keyboard listening
        KbQueueRelease();
        
        rig.stimWindow.flip(); % clear the screen before
        
        if rig.timeline.UseTimeline
            %start the timeline system
            if isfield(rig, 'disregardTimelineInputs') % TODO Depricated, use hw.Timeline.UseInputs instead
                [~, idx] = intersect(rig.timeline.UseInputs, rig.disregardTimelineInputs);
                rig.timeline.UseInputs(idx) = [];
            else
                % turn off rotary encoder recording in timeline by default so
                % experiment can access it
                idx = ~strcmp('rotaryEncoder', rig.timeline.UseInputs);
                rig.timeline.UseInputs = rig.timeline.UseInputs(idx);
            end
            rig.timeline.start(expRef, Alyx);
        else
            %otherwise using system clock, so zero it
            rig.clock.zero();
        end
        
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
        experiment.delete()
        experiment = [];
        rig.stimWindow.BackgroundColour = bgColour;
        rig.stimWindow.flip(); % clear the screen after
        
        % save a copy of the hardware in JSON
        hwInfo = dat.expFilePath(expRef, 'hw-info', 'master', 'json');
        fid = fopen(hwInfo, 'w');
        fprintf(fid, '%s', obj2json(rig));
        fclose(fid);
        if ~strcmp(dat.parseExpRef(expRef), 'default')
            try
                Alyx.registerFile(hwInfo);
            catch ex
                warning(ex.identifier, 'Failed to register hardware info: %s', ex.message);
            end
        end
        
        if rig.timeline.UseTimeline
            %stop the timeline system
            rig.timeline.stop();
        end
        
        % re-enable ptb keyboard listening
        KbQueueCreate();
        KbQueueStart();
    end

    function calibrateWaterDelivery(valve)
        % Calibrates a valve, and saves it in the config file.
        % valve: 1 or 2, to calibrate the left or right valve
        
        assert(valve == 1 || valve == 2, 'Must calibrate valve 1 or valve 2, other values are invalid')
        
        % Get the old calibrations
        calibFile = fullfile(pick(dat.paths, 'rigConfig'), 'calibrations.mat');
        old_calibrations = load(calibFile);
        
        % Set up the daq controller and scale
        daqController = rig.daqController;
        rig.scale.init();
        
        % Do the calibration
        new_calibration = hw.calibrate(daqController, rig.scale, 20e-3, 200e-3, 'valve', valve);
        ul = [new_calibration.measuredDeliveries.volumeMicroLitres];
        log('Delivered volumes on valve ', num2str(valve), ' ranged from %.1ful to %.1ful', min(ul), max(ul));
        % close the scale
        rig.scale.cleanup();
        
        % Update the apropriate calibrations
        if valve == 1
            calibration1 = new_calibration;
            calibration2 = old_calibrations.calibration2;
        elseif valve == 2
            calibration1 = old_calibrations.calibration1;
            calibration2 = new_calibration;
        end
        
        % save to calibfile
        save(calibFile, 'calibration1', 'calibration2');
        
        % save to hardware.mat, for backwards compatibility
        rigHwFile = fullfile(pick(dat.paths, 'rigConfig'), 'hardware.mat');
        save(rigHwFile, 'daqController', '-append');
    end

    function viewCalibration()
        fig = figure; hold on
        plot([rig.daqController.SignalGenerators(1, 1).Calibrations1(end).measuredDeliveries.durationSecs],...
            [rig.daqController.SignalGenerators(1, 1).Calibrations1(end).measuredDeliveries.volumeMicroLitres], '.-')
        plot([rig.daqController.SignalGenerators(1, 1).Calibrations2(end).measuredDeliveries.durationSecs],...
            [rig.daqController.SignalGenerators(1, 1).Calibrations2(end).measuredDeliveries.volumeMicroLitres],'.-')
        legend({'Left Valve', 'Right Valve'},'location','northwest')
        if isfield(rig.daqController.SignalGenerators(1, 1).Calibrations1(end), 'dateTime')
          title(datestr(rig.daqController.SignalGenerators(1, 1).Calibrations1(end).dateTime))
        end
        xlabel('Duration (sec)'); ylabel('Volume (uL)')
        set(gca, 'fontsize', 16)
        
        plot_values = getframe(fig);
        imageDisplay = Screen('MakeTexture', rig.stimWindow.PtbHandle, plot_values.cdata);
        Screen('DrawTexture', rig.stimWindow.PtbHandle, imageDisplay);
        Screen('Flip', rig.stimWindow.PtbHandle);
        WaitSecs(0.5);
        
    end

    function whiteScreen()
        rig.stimWindow.BackgroundColour = 255;
        rig.stimWindow.flip();
        rig.stimWindow.BackgroundColour = bgColour;
    end

    function calibrateGamma()
        stimWindow = rig.stimWindow;
        DaqDev = rig.daqController.DaqIds;
        lightIn = 'ai0'; % defaults from hw.psy.Window
        clockIn = 'ai1';
        clockOut = 'port1/line0 (PFI4)';
        log(['Please connect photodiode to %s, clockIn to %s and clockOut to %s.\r'...
            'Press any key to contiue\n'],lightIn,clockIn,clockOut);
        pause; % wait for keypress
        stimWindow.Calibration = stimWindow.calibration(DaqDev); % calibration
        pause(1);
        saveGamma(stimWindow.Calibration);
        stimWindow.applyCalibration(stimWindow.Calibration);
        clear('lightIn','clockIn','clockOut','cal');
        log('Gamma calibration complete');
    end

    function saveGamma(cal)
        rigHwFile = fullfile(pick(dat.paths, 'rigConfig'), 'hardware.mat');
        stimWindow = load(rigHwFile,'stimWindow');
        stimWindow = stimWindow.stimWindow;
        stimWindow.Calibration = cal;
        save(rigHwFile, 'stimWindow', '-append');
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

    function t = toggleTimeline(enable)
        if nargin < 1
            enable = ~rig.timeline.UseTimeline;
        end
        if ~enable
            rig.timeline.UseTimeline = false;
            clock = hw.ptb.Clock; % use psychtoolbox clock
        else
            rig.timeline.UseTimeline = true;
            clock = hw.TimelineClock(rig.timeline); % use timeline clock
        end
        rig.clock = clock;
        cellfun(@(user) setClock(user, clock),...
            {'mouseInput', 'lickDetector'});
        
        t = rig.timeline.UseTimeline;
        if enable
            log('Use of timeline enabled');
        else
            log('Use of timeline disabled');
        end
    end
end
