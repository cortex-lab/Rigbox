function [] = record(name, event, time)
%TL.RECORD Records an event in Timeline
%   TL.RECORD(name, event, [time]) records an event in the Timeline
%   struct in fields prefixed with 'name', with data in 'event'. Optionally
%   specify 'time', otherwise the time of call will be used (relative to
%   Timeline acquisition).
% 
% Part of Rigbox

% 2014-01 CB created

global Timeline % Eek!! 'Timeline' is a global variable.

if nargin < 3
  % default to time now (using Timeline clock)
  time = tl.time;
end

initLength = 100; % default initial length of event data arrays

timesFieldName = [name 'Times'];
countFieldName = [name 'Count'];
eventFieldName = [name 'Events'];

%% create fields in Timeline struct if not already
if ~isfield(Timeline, timesFieldName)
  Timeline.(timesFieldName) = zeros(initLength,1);
end
if ~isfield(Timeline, countFieldName)
  Timeline.(countFieldName) = 0;
end
if ~isfield(Timeline, eventFieldName)
  Timeline.(eventFieldName) = cell(initLength, 1);
end

%% increment the event count
newCount = Timeline.(countFieldName) + 1;

%% grow arrays if necessary
eventsLength = length(Timeline.(eventFieldName));
if newCount > eventsLength
  Timeline.(eventFieldName){2*eventsLength} = [];
  Timeline.(timesFieldName) = [Timeline.(timesFieldName) ; ...
    zeros(size(Timeline.(timesFieldName)))];
end

%% store the event at the appropriate index
Timeline.(timesFieldName)(newCount) = time;
Timeline.(eventFieldName){newCount} = event;
Timeline.(countFieldName) = newCount;

end

