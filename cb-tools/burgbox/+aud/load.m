function load(pahandle, samples)
%AUD.LOAD Loads sound samples onto an audio device
%   TODO
%
% Part of Burgbox

% 2013-05 CB created

PsychPortAudio('FillBuffer', pahandle, samples);

end

