function services = loadService(hostnames)
%SRV.LOADSERVICE Returns experiment service(s) with specified hostnames
%   A function that can return a cell array of BasicUDPService objects, one
%   object for each of the hostnames provided. See also SRV.SERVICE,
%   SRV.PREPAREEXP, SRV.BASICUDPSERVICE.
%
% Part of Rigbox

% 2013-06 CB created

hostnames = ensureCell(hostnames);
services = cell(1, length(hostnames));
for h = 1:length(hostnames)
    services{h} = srv.BasicUDPService(hostnames{h});
    services{h}.ResponseTimeout = 5;
end

end