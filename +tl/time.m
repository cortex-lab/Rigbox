function secs = time(strict)
%TL.TIME Time relative to Timeline acquisition
%   secs = TL.TIME([strict]) Returns the time in seconds relative to
%   Timeline data acquistion. 'strict' is optional (defaults to true), and
%   if true, this function will fail if Timeline is not running. If false,
%   it will just return the time using Psychtoolbox GetSecs if it's not
%   running. See also TL.PTBSECSTOTIMELINE().
%
% Part of Rigbox

% 2014-01 CB created

global Timeline % Eek!! 'Timeline' is a global variable.

if nargin < 1
  strict = true;
end

if tl.running
  secs = GetSecs - Timeline.currSysTimeTimelineOffset;
elseif strict
  error('Tried to use Timeline clock when Timeline is not running');
else
  % Timeline not running, but not being 'strict' so just return the system
  % time as if it were the Timeline clock
  secs = GetSecs;
end

end

