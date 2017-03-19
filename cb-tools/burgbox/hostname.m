function str = hostname
%HOSTNAME Returns the network hostname of this machine
%
% Part of Burgbox

% 2013-02 CB created

global RiggingCache

if isfield(RiggingCache, 'hostname')
  str = RiggingCache.hostname;
else
  str = lower(char(getHostName( java.net.InetAddress.getLocalHost)));
  RiggingCache.hostname = str;
end

end
