function secs = ptbSecsToTimeline(secs)
%TL.PTBSECSTOTIMELINE Convert from Pyschtoolbox to Timeline time
%   secs = TL.PTBSECSTOTIMELINE(secs) takes a timestamp 'secs' obtained
%   from Pyschtoolbox's functions and converts to Timeline-relative time.
%   See also TL.TIME().
%
% Part of Rigbox

% 2014-01 CB created

global Timeline % Eek!! 'Timeline' is a global variable.

assert(Timeline.isRunning, 'Timeline is not running.');
secs = secs - Timeline.currSysTimeTimelineOffset;

end

