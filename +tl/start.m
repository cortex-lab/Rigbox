function start(expRef, disregardInputs, savePaths)
%TL.START Starts Timeline data acquisition
%   TL.START(expRef, [disregardInputs], [savePaths]) explanation goes here
%
% Part of Rigbox

% 2014-01 CB created

%% Parameter initialisation
global Timeline % Eek!! 'Timeline' is a global variable.

% expected experiment time so data structure is initialised to sensible size
maxExpectedDuration = 2*60*60; %secs

if nargin < 3
  % default is to use default Timeline save paths for given experiment ref
  savePaths = dat.expFilePath(expRef, 'timeline');
end

if nargin < 2 || isempty(disregardInputs)
  disregardInputs = {};
end

%if 'disregardInputs' is a single string, wrap it in a cell
disregardInputs = ensureCell(disregardInputs);

%% Check if it's already running, and if so, stop it
if tl.running
  disp('Timeline already running, stopping first');
  tl.stop();
end

%% Initialise timeline struct
Timeline = struct();
Timeline.expRef = expRef;
Timeline.savePaths = savePaths;
Timeline.isRunning = false;

%% Setup DAQ sessions with appropriate channels
[hw, inputOptions, useInputs] = tl.config();  % get Timeline hardware configuration info

sessions.main = daq.createSession(hw.daqVendor);

% session for sending output pulses, which are acquired by the main
% session and used to compare daq with system time
sessions.chrono = daq.createSession(hw.daqVendor);
sessions.chrono.addDigitalChannel(hw.daqDevice, hw.chronoOutDaqChannelID, 'OutputOnly');

% session for outputing a high signal during acquisition
sessions.acqLive = daq.createSession(hw.daqVendor);
sessions.acqLive.addDigitalChannel(hw.daqDevice, hw.acqLiveDaqChannelID, 'OutputOnly');
sessions.acqLive.outputSingleScan(false); % ensure acq live is false

% session for output of timed pulses
if hw.useClockOutput
  sessions.clockOut = daq.createSession(hw.daqVendor);
  sessions.clockOut.IsContinuous = true;
  clocked = sessions.clockOut.addCounterOutputChannel(...
    hw.daqDevice, hw.clockOutputChannelID, 'PulseGeneration');
  clocked.Frequency = hw.clockOutputFrequency;
  clocked.DutyCycle = hw.clockOutputDutyCycle;
  if isfield(hw, 'clockOutputInitialDelay')
    clocked.InitialDelay = hw.clockOutputInitialDelay;
  end
end

%now remove disregarded inputs from the list
[~, idx] = intersect(useInputs, disregardInputs);
assert(numel(idx) == numel(disregardInputs), 'Not all disregarded inputs were recognised');
useInputs(idx) = [];
inputNames = {inputOptions.name};

% keep track of where each daq input will be saved into the data array
nextInputArrayColumn = 1;

% configure all the inputs we are using
hw.inputs = struct('name', {}, 'arrayColumn', {}, 'daqChannelID', {},...
  'measurement', {}, 'terminalConfig', {});
for i = 1:numel(useInputs)
  in = inputOptions(strcmp(inputNames, useInputs(i)));
  switch lower(in.measurement)
    case 'voltage'
      ch = sessions.main.addAnalogInputChannel(...
        hw.daqDevice, in.daqChannelID, in.measurement);
      if ~isempty(in.terminalConfig)
        ch.TerminalConfig = in.terminalConfig;
      end
    case 'edgecount'
      sessions.main.addCounterInputChannel(hw.daqDevice, in.daqChannelID, in.measurement);
    case 'position'
      ch = sessions.main.addCounterInputChannel(...
        hw.daqDevice, in.daqChannelID, in.measurement);
      % we assume quadrature encoding (X4) for position measurement
      ch.EncoderType = 'X4';
    otherwise
      error('Unknown measurement type ''%s''', in.measurement);
  end
  in.arrayColumn = nextInputArrayColumn;
  hw.inputs(i) = in;
  nextInputArrayColumn = nextInputArrayColumn + 1;
end
% save column index into data array that will contain chrono input
hw.arrayChronoColumn = pick(hw.inputs(elementByName(hw.inputs, 'chrono')), 'arrayColumn');

%% Send a test pulse low, then high to clocking channel & check we read it back
sessions.chrono.outputSingleScan(false);
x1 = sessions.main.inputSingleScan;
sessions.chrono.outputSingleScan(true);
x2 = sessions.main.inputSingleScan;
assert(x1(hw.arrayChronoColumn) < 2.5 && x2(hw.arrayChronoColumn) > 2.5,...
  'The clocking pulse test could not be read back');

%% Configure DAQ acquisition
Timeline.dataListener = sessions.main.addlistener('DataAvailable', @tl.processAcquiredData);
sessions.main.Rate = 1/hw.samplingInterval;
sessions.main.IsContinuous = true;
if ~isempty(hw.daqSamplesPerNotify)
    sessions.main.NotifyWhenDataAvailableExceeds = hw.daqSamplesPerNotify;
else
    sessions.main.NotifyWhenDataAvailableExceeds = sessions.main.Rate;
end

%% Configure timeline struct
Timeline.hw = hw;
Timeline.sessions = sessions;

% initialise daq data array
nSamples = sessions.main.Rate*maxExpectedDuration;
channelDirs = io.daqSessionChannelDirections(sessions.main);
nInputChannels = sum(strcmp(channelDirs, 'Input'));

dataType = 'double'; % default data type for the acquired data array
if isfield(hw, 'dataType')
  dataType = hw.dataType;
end

Timeline.rawDAQData = zeros(nSamples, nInputChannels, dataType);
Timeline.rawDAQSampleCount = 0;
  
%% Start the DAQ acquiring
Timeline.startDateTime = now;
Timeline.startDateTimeStr = datestr(Timeline.startDateTime);
Timeline.nextChronoSign = 1;
sessions.chrono.outputSingleScan(false);
%lastTimestamp is the timestamp of the last acquisition sample, which is
%saved to ensure continuity of acquisition. Here it is initialised as if a
%previous acquisition had been made in negative time, since the first
%acquisition timestamp will be zero
Timeline.lastTimestamp = -Timeline.hw.samplingInterval;
sessions.main.startBackground();

%% Output clocking pulse and wait for first acquisition to complete
% output first clocking high pulse
t = GetSecs;
sessions.chrono.outputSingleScan(Timeline.nextChronoSign > 0);
Timeline.lastClockSentSysTime = (t + GetSecs)/2;

% wait for first acquisition processing to begin
while ~Timeline.isRunning
  pause(5e-3);
end

if isfield(hw, 'acqLiveStartDelay')
  pause(hw.acqLiveStartDelay);
end

% set acquisition live signal to true
sessions.acqLive.outputSingleScan(true);
if isfield(sessions, 'clockOut')
  % start session to send timing output pulses
  sessions.clockOut.startBackground();
end

fprintf('Timeline started successfully for ''%s''.\n', expRef);

end

