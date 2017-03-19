function startTime = play(pahandle, nreps, when, waitForStart)
%AUD.PLAY Plays currently loaded samples on an audio device
%   TODO
%
% Part of Burgbox

% 2013-05 CB created

if nargin < 2
  nreps = 1;
end

if nargin < 3
  when = 0;
end

if nargin < 4
  waitForStart = false;
end

if waitForStart
  startTime = PsychPortAudio('Start', pahandle, nreps, when, double(waitForStart));
else
  PsychPortAudio('Start', pahandle, nreps, when, double(waitForStart));
end

end

