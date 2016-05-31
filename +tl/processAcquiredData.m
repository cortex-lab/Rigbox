function processAcquiredData(src, event)
%TL.PROCESSACQUIREDDATA Listener for processing acquired Timeline data
%   Listener function for handling Timeline data acquisition. Called by DAQ
%   session with latest chunk of data. This is compiled in an array.
%   Additionally, a clocking pulse is send on each call, and the sample
%   index of the previous one send is found and noted. This is used by the
%   timelineSecs function to convert between system time and acquisition
%   time.
%
% Part of Rigbox

% 2014-01 CB created

global Timeline % Eek!! 'Timeline' is a global variable.

% Timeline is officially 'running' when first acquisition samples are in
Timeline.isRunning = true;
% Assert continuity of this data from previous
assert(abs(event.TimeStamps(1) - Timeline.lastTimestamp - Timeline.hw.samplingInterval) < 1e-8,...
  'Discontinuity of DAQ acquistion detected: last timestamp was %f and this one is %f',...
  Timeline.lastTimestamp, event.TimeStamps(1));

%% Self-clocking:
%The chrono "out" value is flipped at a recorded time, and the sample
%index that this flip is measured is noted

% First, find the index of the flip in the latest chunk of data
clockChangeIdx = find(sign(event.Data(:,Timeline.hw.arrayChronoColumn) - 2.5) == Timeline.nextChronoSign, 1);

%Ensure the clocking pulse was detected
if ~isempty(clockChangeIdx)
  clockChangeTimestamp = event.TimeStamps(clockChangeIdx);
  Timeline.currSysTimeTimelineOffset = Timeline.lastClockSentSysTime - clockChangeTimestamp;
else
  warning('Rigging:Timeline:timing', 'clocking pulse not detected - probably lagging more than one data chunk');
end

%Now send the next clock pulse
Timeline.nextChronoSign = -Timeline.nextChronoSign; % flip next chrono
t = GetSecs; % time before output
Timeline.sessions.chrono.outputSingleScan(Timeline.nextChronoSign > 0); % send next flip
Timeline.lastClockSentSysTime = (t + GetSecs)/2; % record mean before/after time

%% Store new samples into the timeline array
prevSampleCount = Timeline.rawDAQSampleCount;
newSampleCount = prevSampleCount + size(event.Data, 1);

%If necessary, grow input array by doubling its size
while newSampleCount > size(Timeline.rawDAQData, 1)
  disp('Reached capacity of DAQ data array, growing');
  Timeline.rawDAQData = [Timeline.rawDAQData ; zeros(size(Timeline.rawDAQData))];
end

%Now slice the data into the array
Timeline.rawDAQData((prevSampleCount + 1):newSampleCount,:) = event.Data;
Timeline.rawDAQSampleCount = newSampleCount;

%Update continuity timestamp for next check
Timeline.lastTimestamp = event.TimeStamps(end);

end