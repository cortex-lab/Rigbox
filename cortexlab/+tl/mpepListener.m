function mpepListener()
%TL.MPEPLISTENER Starts an Mpep UDP listener to start/stop Timeline
%   TL.MPEPLISTENER() starts a blocking listener for Mpep protocol UDP
%   messages to start/stop Timeline when an experiment is started or
%   stopped.
%
% Part of Cortex Lab Rigbox customisations

% 2014-01 CB created

tls = tl.bindMpepServer();
cleanup = onCleanup(tls.close);
tls.listen();

end

