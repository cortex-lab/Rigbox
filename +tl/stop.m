function stop()
%TL.STOP Stops Timeline data acquisition
%   TL.STOP() Detailed explanation goes here
%
% Part of Rigbox

% 2014-01 CB created

global Timeline % Eek!! 'Timeline' is a global variable

%% Ensure timeline is actually running
if ~tl.running
  warning('Nothing to do, Timeline is not running!');
  return
end

% kill acquisition output signals
Timeline.sessions.acqLive.outputSingleScan(false); % live -> false
if isfield(Timeline.sessions, 'clockOut')
  % stop sending timing output pulses
  Timeline.sessions.clockOut.stop();
end

% pause to ensure all systems can stop
if isfield(Timeline.hw, 'stopDelay')
  stopDelay = Timeline.hw.stopDelay;
else
  stopDelay = 2;
end
pause(stopDelay); %temporary delay hack

% stop actual DAQ aquisition
Timeline.sessions.main.stop();

% wait before deleting the listener to ensure most recent samples are
% collected
pause(1.5); 
delete(Timeline.dataListener); % now delete the data listener

% turn off the timeline running flag
Timeline.isRunning = false;

% release hardware resources
cellfun(@(s) s.release(), struct2cell(Timeline.sessions));

% for saving the Timeline struct we remove sessions fields
Timeline = rmfield(Timeline, {'sessions' 'dataListener'});
% only keep the used part of the daq input array
sampleCount = Timeline.rawDAQSampleCount;
Timeline.rawDAQData((sampleCount + 1):end,:) = [];

% generate timestamps in seconds for the samples
Timeline.rawDAQTimestamps = ...
  Timeline.hw.samplingInterval*(0:Timeline.rawDAQSampleCount - 1);

% save Timeline to all paths
superSave(Timeline.savePaths, struct('Timeline', Timeline));

fprintf('Timeline for ''%s'' stopped and saved successfully.\n', Timeline.expRef);

end

