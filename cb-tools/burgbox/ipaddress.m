function str = ipaddress(host)
%   IPADDRESS Get the IP address(es) of host(s)
%
% Part of Burgbox

% 2013-07 CB created

if nargin < 1
  host = hostname;
end

if iscell(host)
  str = mapToCell(@ipaddress, host);
else
  address = java.net.InetAddress.getByName(host);
  str = char(address.getHostAddress);
end

end

