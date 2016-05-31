function [hw, inputOptions, useInputs] = config(rig)
%TL.CONFIG Timeline hardware configuration info for rig
%   Detailed explanation goes here
%
% Part of Rigbox

% 2014-01 CB created

if nargin < 1 || isempty(rig)
  rig = hostname; % default rig is hostname
end

  function s = input(name, channelID, measurement, terminalConfig)
    if nargin < 4
      % if no terminal config specified, leave empty which means use the
      % DAQ default for that port
      terminalConfig = [];
    end
    s = struct('name', name,...
      'arrayColumn', -1,... % -1 is default indicating unused
      'daqChannelID', channelID,...
      'measurement', measurement,...
      'terminalConfig', terminalConfig);
  end


% measurement types
volts = 'Voltage';
edgeCount = 'EdgeCount';
pos = 'Position';

% List of all the input channels we can acquire and their configuration

%% Defaults
% *******************************
% ******** DO NOT CHANGE ********
% *******************************
hw.daqVendor = 'ni';
hw.daqDevice = 'Dev1';
hw.daqSampleRate = 1000; % samples per second
% n samples queued for each callback, will default to a seconds worth of
% samples if empty
hw.daqSamplesPerNotify = [];
hw.chronoOutDaqChannelID = 'port0/line0'; % for sending timing pulse out
hw.acqLiveDaqChannelID = 'port0/line1'; % output for acquisition live signal
% details of counter output channel for sending clocked pulses
hw.useClockOutput = true;
hw.clockOutputChannelID = 'ctr3'; % on zoolander's DAQ ctr3 output is PFI15
hw.clockOutputFrequency = 60; %Hz
hw.clockOutputDutyCycle = 0.2; %Fraction

% Note: chrono input should use single ended measurement, i.e. relative to
% the DAQ's ground
inputOptions = [...
  input('chrono', 'ai0', volts, 'SingleEnded')... % for reading back self timing wave
  input('syncEcho', 'ai1', volts)... % sync square echo (e.g. driven by vs)
  input('photoDiode', 'ai2', volts)... % monitor light meter (e.g. over sync rec)
  input('audioMonitor', 'ai3', volts)... % monitor of audio output to speakers
  input('eyeCameraStrobe', 'ai4', volts)... % eye/behaviour imaging frame strobe
  input('eyeCameraTrig', 'ai5', volts)... % Timeline-generated eyetracking triggers
  input('piezoCommand', 'ai6', volts)... % Control signal sent to fastZ piezo
  input('piezoPosition', 'ai7', volts)... % The actual position of fastZ Piezo
  input('laserPower', 'ai8', volts)... % laser power mesured by photodiode
  input('pockelsControl', 'ai9', volts)... % Control voltage sent to Pockel's (not very informative once you have the laserPower)
  input('neuralFrames', 'ctr0', edgeCount)... % neural imaging frame counter
  input('rotaryEncoder', 'ctr1', pos)... % rotary encoder position
  input('lickDetector', 'ctr2', edgeCount)... % counter recording pulses from lickometer
  ];

% function to index 'inputOptions' by name, e.g.:
% inputOptions(inputByName('syncEcho'))
% selects the inputOption called 'syncEcho'
inputByName = @(name) elementByName(inputOptions, name);

useInputs = {... % default set of inputs to use
  'chrono',... % Timeline currently needs chrono
  'photoDiode',... % highly recommended to record photo diode signal
  'syncEcho',... % recommended if using vs
  };


%% Rig-specific overrides
% TODO: instead use rig config MAT-files instead of editing me
% *****************************************************************
% ******** FOR NOW, MAKE YOUR OWN RIGS CONFIG CHANGES HERE ********
% *****************************************************************
%   e.g. override default hw.useInputs:
% useInputs = {'chrono', 'blah', ...};
%   or DAQ channel IDs for inputOptions:
% inputOptions(inputByName('syncEcho')).daqChannelID = 'ai2';
switch rig
  case 'zoolander'
    inputOptions = [inputOptions... % add to existing options
      input('ephysVoltage', 'ai6', volts, 'SingleEnded')]; % ephys
    hw.useClockOutput = true;
    hw.clockOutputFrequency = 30; %30Hz for the eye camera trigger
    hw.clockOutputInitialDelay = 10;
    useInputs = {'chrono', 'photoDiode', 'neuralFrames', 'ephysVoltage'};
    inputOptions(inputByName('photoDiode')).terminalConfig = 'Differential';
    inputOptions(inputByName('eyeCameraTrig')).terminalConfig = 'SingleEnded';
    hw.stopDelay = 1; % allow ScanImage to finish acquiring
    hw.daqSampleRate = 10000; % samples per second
  case 'zcamp3'
    inputOptions = [inputOptions... % add to existing options
      input('rewardCommand', 'ai10', volts, 'SingleEnded')]; % command signal for reward
    
    inputOptions(inputByName('syncEcho')).terminalConfig = 'SingleEnded';
    inputOptions(inputByName('photoDiode')).terminalConfig = 'SingleEnded';
    inputOptions(inputByName('laserPower')).terminalConfig = 'SingleEnded';
    inputOptions(inputByName('pockelsControl')).terminalConfig = 'SingleEnded';
    
    useInputs = {'chrono', 'photoDiode', 'syncEcho', 'neuralFrames',...
      'piezoCommand', 'piezoPosition', 'laserPower', 'pockelsControl', ...
      'audioMonitor', 'rewardCommand', 'rotaryEncoder'};
    
    hw.daqSampleRate = 1000; % samples per second
    hw.stopDelay = 1; % allow ScanImage to finish acquiring
    
  case 'zooropa'
    %hw.chronoOutDaqChannelID = 'ao1'; %DS 2014.2.26 %% port0/line0
    %corresponds to which terminal?
    inputOptions = [inputOptions...
      input('cam2', 'ai5', volts, 'SingleEnded')... % neural imaging frame  14.3.3 DS
      ...%input('cam2', 'ctr1', edgeCount)... %test for choice world 14.9.18
      input('cam1', 'ai7', volts, 'SingleEnded')... % neural imaging frame  16.3.31 DS added singleEnded
      input('ao0', 'ai3', volts)... % copy of Analog output 0 15/12/21 DS
      input('ao1', 'ai4', volts, 'SingleEnded')... % copy of Analog output 1 15/12/21 DS
      input('arduinoBlue', 'ai12', volts, 'SingleEnded')...
      input('arduinoGreen', 'ai13', volts, 'SingleEnded')...
      input('arduinoRed', 'ai15', volts, 'SingleEnded')... % 16/3/31 DS
      ...%input('photoSensor', 'ai8', volts)... % photo sensor on the right of the screesn 14.5.7 DS
      input('illuminator', 'ai8', volts)... %illuminator output
      input('acqLiveEcho', 'ai14', volts)...
      ];
    
    inputOptions(inputByName('rotaryEncoder')).daqChannelID = 'ctr0';
    %inputOptions(inputByName('lickDetector')).measurement = volts;
    inputOptions(inputByName('lickDetector')).daqChannelID = 'ai6';
    inputOptions(inputByName('lickDetector')).measurement = volts;
    inputOptions(inputByName('syncEcho')).terminalConfig = 'SingleEnded'; %16/3/31 DS
    useInputs = {'chrono' 'rotaryEncoder', 'syncEcho', 'cam1', 'cam2',...
      'photoDiode', 'lickDetector','ao0','ao1','illuminator', 'arduinoBlue', ...
      'arduinoGreen', 'arduinoRed','acqLiveEcho'};%{'vsStim' 'rotaryEncoder'};%
    
    % change digital outs
    %hw.chronoOutDaqChannelID = 'port0/line1'; % for sending timing pulse out
    hw.chronoOutDaqChannelID = 'port0/line3'; % for sending timing pulse out. 20141008 DS
    hw.acqLiveDaqChannelID = 'port0/line2'; % output for acquisition live signal
    
%     hw.useClockOutput = false;
% ** added 2015-12-30 by NS and DS for testing LED
% commented out on 2015-12-31 DS
%     hw.useClockOutput = true;
%         hw.clockOutputFrequency = 50; %Hz
%         hw.clockOutputDutyCycle = 0.5; %Fraction
%         hw.clockOutputInitialDelay = 2;
%         hw.clockOutputChannelID = 'ctr1'; 
        % ** end added for testing LED
    
    %hw.daqSampleRate = 50e3; %18/6/14 DS
    %hw.daqSampleRate = 20e3; %LFR
      hw.daqSampleRate = 5e3; %6/8/14 DS for recording up to 200Hz
    hw.dataType = 'single';
    case 'zpopulation'
    inputOptions = [inputOptions...
        input('Vm', 'ai1', volts)... % membrane potential
        ];
    useInputs = {'chrono', 'photoDiode', 'Vm'};
    hw.daqDevice = 'Dev2';
    hw.daqSampleRate = 20e3;
    case 'zintra2'
    inputOptions = [inputOptions...
        input('Vm1Primary', 'ai3', volts, 'Differential')... % hs1 primary output (Current clamp Vm; voltage clamp Im)
        input('Vm1Secondary', 'ai4', volts, 'Differential')... hs1 primary output (Current clamp Vm; voltage clamp Im)
        input('Vm2Primary', 'ai5', volts, 'Differential')... % membrane potential
        input('Vm2Secondary', 'ai6', volts, 'Differential')... % membrane potential
...%         input('laserCommand', 'ai7', volts)... % command signal for laser shutte
        input('rewardCommand', 'ai1', volts, 'Differential')... % command signal for reward valve
        ];
    %     useInputs = {'chrono', 'photoDiode', 'Vm1Primary', 'lickDetector', 'rewardCommand'}; %2013Aug config
    %     useInputs = {'chrono', 'photoDiode', 'Vm1Primary', 'Vm1Secondary','Vm2Primary'}; %2015Jun config
    useInputs = {'chrono', 'photoDiode', 'Vm1Primary', 'Vm1Secondary','lickDetector', 'rewardCommand','eyeCameraStrobe'}; %2015Oct config
    hw.daqDevice = 'Dev1';
    hw.daqSampleRate = 20e3;
    hw.useClockOutput = true;
    % CPB: uncomment the following to notify every 0.1s
    hw.daqSamplesPerNotify = round(0.1*hw.daqSampleRate);
    hw.stopDelay = 0.1; % small
    inputOptions(inputByName('eyeCameraStrobe')).terminalConfig = 'SingleEnded';
    inputOptions(inputByName('eyeCameraStrobe')).daqChannelID = 'ai7';
  
    case 'zillion'
    hw.useClockOutput = true;
    hw.clockOutputChannelID = 'ctr0'; % on zillion's DAQ ctr0 output is PFI12
    hw.clockOutputFrequency = 30; %Hz
    hw.clockOutputDutyCycle = 0.1; %Fraction
    hw.clockOutputInitialDelay = 2;
    %     inputOptions(inputByName('rotaryEncoder')).daqChannelID = 'ctr0';
    
    inputOptions = [inputOptions ...
        input('wheelPosition', 'ai1', volts, 'SingleEnded')...
      input('laser', 'ai5', volts, 'SingleEnded'),...
        input('piezoLickDetector', 'ai6', volts, 'Differential'),...
      input('waterValve', 'ai7', volts, 'SingleEnded')];
    
    useInputs = {'chrono', 'wheelPosition','photoDiode', 'audioMonitor','rotaryEncoder', 'eyeCameraStrobe', ...
        'laser','piezoLickDetector','waterValve'};
    
    hw.chronoOutDaqChannelID = 'port0/line1'; % for sending timing pulse out
    hw.acqLiveDaqChannelID = 'port0/line2'; % output for acquisition live signal
    hw.stopDelay = 2; % want this to be less than the amount of time the eye
    % computer will wait so triggers stop coming before
    % stopping acquisition
 
    
    case 'zlick'
    hw.useClockOutput = true;
    hw.clockOutputChannelID = 'ctr0'; % on zillion's DAQ ctr0 output is PFI12
    hw.clockOutputFrequency = 30; %Hz
    hw.clockOutputDutyCycle = 0.1; %Fraction
    hw.clockOutputInitialDelay = 2;
    %     inputOptions(inputByName('rotaryEncoder')).daqChannelID = 'ctr0';
    
    inputOptions = [inputOptions ...
        input('wheelPosition', 'ai1', volts, 'SingleEnded')...
      input('laser', 'ai5', volts, 'SingleEnded'),...
        input('piezoLickDetector', 'ai6', volts, 'Differential'),...
      input('waterValve', 'ai7', volts, 'SingleEnded')];
    
    useInputs = {'chrono', 'wheelPosition','photoDiode', 'audioMonitor','rotaryEncoder', 'eyeCameraStrobe', ...
        'laser','piezoLickDetector','waterValve'};
    
    hw.chronoOutDaqChannelID = 'port0/line1'; % for sending timing pulse out
    hw.acqLiveDaqChannelID = 'port0/line2'; % output for acquisition live signal
    hw.stopDelay = 2; % want this to be less than the amount of time the eye
    % computer will wait so triggers stop coming before
    % stopping acquisition
    
    case 'zenith' % was zgood - kilotrode rig
    hw.daqSampleRate = 2500; % to be confident about measuring 1ms laser pulses
%     hw.daqSampleRate = 1000;
    
    % These for use with triggering eye camera
%     hw.useClockOutput = true;
%     hw.clockOutputChannelID = 'ctr0'; % on zillion's DAQ ctr0 output is PFI12
%     hw.clockOutputFrequency = 30; %Hz
%     hw.clockOutputDutyCycle = 0.1; %Fraction
%     hw.clockOutputInitialDelay = 2;
    
    % These for use with IR LED sync method
    %         hw.clockOutputFrequency = 0.01; %Hz
    %         hw.clockOutputDutyCycle = 0.001; %Fraction
    %         hw.clockOutputInitialDelay = 1;
    
    hw.acqLiveIsPulse = true;
    hw.acqLivePulsePauseDuration = 0.2;
    %hw.acqLiveStartDelay = 5;
    
  % add new inputs
  inputOptions = [inputOptions...
      input('piezoLickDetector', 'ai6', volts, 'Differential')...
      input('waveOutput', 'ai7', volts, 'SingleEnded')...
      input('openChan1', 'ai3', volts, 'SingleEnded')...
      input('openChan2', 'ai5', volts, 'SingleEnded')...
      input('camSync', 'ai16', volts, 'SingleEnded')...
      input('whiskCamStrobe', 'ai17', volts, 'SingleEnded')...
      input('rewardEcho', 'ai15', volts, 'SingleEnded')...
      input('faceCamStrobe', 'ai12', volts, 'SingleEnded')];
    
    % change existing inputs
    inputOptions(inputByName('photoDiode')).terminalConfig = 'SingleEnded';
    inputOptions(inputByName('eyeCameraStrobe')).terminalConfig = 'SingleEnded';
    inputOptions(inputByName('audioMonitor')).daqChannelID = 'ai8';
    inputOptions(inputByName('rotaryEncoder')).daqChannelID = 'ctr0';
    
%     inputOptions(inputByName('eyeCameraTrig')).terminalConfig = 'SingleEnded';
%     inputOptions(inputByName('eyeCameraTrig')).daqChannelID = 'ai1';

    useInputs = {'chrono', 'photoDiode', 'rotaryEncoder', ...
      'eyeCameraStrobe', 'waveOutput',  'openChan1',  'piezoLickDetector',  ...
      'openChan2', 'camSync', 'whiskCamStrobe', 'rewardEcho', 'audioMonitor',...
      'faceCamStrobe'};
    
    hw.chronoOutDaqChannelID = 'port0/line1'; % for sending timing pulse out
    hw.acqLiveDaqChannelID = 'port0/line3'; % output for acquisition live signal
    hw.stopDelay = 2; % want this to be less than the amount of time the eye
    % computer will wait so triggers stop coming before
    % stopping acquisition
    
    hw.makePlots = true;
    hw.figPosition = [50 50 1700 900];
    hw.figScales = [1 1/2 3 1 1 1 3 1 1 10 1 8 1];
%     hw.daqSamplesPerNotify = round(0.1*hw.daqSampleRate); % plots will update this often, then


    hw.writeDat = true;

    hw.dataType = 'double';
  case 'zurprise'
    inputOptions(inputByName('syncEcho')).terminalConfig = 'SingleEnded';
    inputOptions(inputByName('photoDiode')).terminalConfig = 'SingleEnded';
    inputOptions(inputByName('laserPower')).terminalConfig = 'SingleEnded';
    inputOptions(inputByName('pockelsControl')).terminalConfig = 'SingleEnded';
    
    inputOptions = [inputOptions ...
        input('piezoLickDetector', 'ai4', volts, 'Differential') ...
        input('scanimageTrigger', 'ai5', volts, 'SingleEnded')];
    
    useInputs = {'chrono', 'photoDiode', 'syncEcho', 'neuralFrames',...
      'piezoCommand', 'piezoPosition', 'laserPower', 'pockelsControl', ...
      'audioMonitor', 'rotaryEncoder', 'piezoLickDetector', 'scanimageTrigger'};
  
%     useInputs = {'chrono', 'laserPower', 'scanimageTrigger'};
    
    hw.useClockOutput = false;

    hw.acqLiveStartDelay = 3; % make sure that ScanImage is ready to go

    hw.daqSampleRate = 1000; % samples per second
    hw.stopDelay = 3; % allow ScanImage to finish acquiring
end

hw.samplingInterval = 1/hw.daqSampleRate;

end

