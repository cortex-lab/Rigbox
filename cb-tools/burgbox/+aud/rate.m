function hz = rate(pahandle)
%AUD.RATE Returns the current sampling rate of an audio device
%   TODO
%
% Part of Burgbox

% 2013-05 CB created

status = PsychPortAudio('GetStatus', pahandle);
hz = status.SampleRate;

end

