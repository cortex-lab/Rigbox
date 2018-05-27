function [services] = basicServices()
%SRV.BASICSERVICES Returns all available experiment services
%   TODO. See also EXP.SERVICE, EXP.FINDSERVICE.
%
% Part of Rigbox

% 2013-06 CB created

%% Some default hosts
if nargin < 1
  mpepDataHosts = {'zenith'};
end

%% configure eye-tracking acquisition service
mpepDataHosts = io.MpepUDPDataHosts(mpepDataHosts);
% mpepDataHosts = srv.RemoteMPEPService(mpepDataHosts);
mpepDataHosts.open;
mpepDataHosts.Title = 'mPEP Data Hosts';
mpepDataHosts.Id = 'mpep-data-hosts';
mpepDataHosts.ResponseTimeout = 60;

services = {mpepDataHosts};

% timelineHost = 'zgood';
% timeline = srv.PrimativeUDPService(timelineHost);
% timeline.Title = sprintf('Timeline on %s', timelineHost);
% timeline.Id = 'timeline';
% timeline.ResponseTimeout = 5;
% services = {timeline};

end

