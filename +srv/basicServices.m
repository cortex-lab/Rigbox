function [services] = basicServices(timelineHost, neuralImgHost, eyeTrackingHost)
%SRV.BASICSERVICES Returns all available experiment services
%   TODO. See also SRV.SERVICE, SRV.FINDSERVICE.
%
% Part of Rigbox

% 2013-06 CB created

%% Some default hosts
if nargin < 1
  timelineHost = 'zoolander';
end

if nargin < 2
  neuralImgHost = 'z2p';
end

if nargin < 3
  eyeTrackingHost = 'zcamp';
end

%% Configure timeline service
timeline = srv.PrimitiveUDPService(timelineHost);
timeline.Title = sprintf('Timeline on %s', timelineHost);
timeline.Id = 'timeline';
timeline.ResponseTimeout = 5;

%% Configure scanimage/neural acquisition service
neuralImg = srv.PrimitiveUDPService(neuralImgHost);
% neuralImg.StartMessageFun = @(ref) ['GOGO' ref '*' hostname];
neuralImg.Title = 'Neural imaging';
neuralImg.Id = 'neural-imaging';
neuralImg.ResponseTimeout = 5;

%% configure eye-tracking acquisition service
eyeTracking = srv.PrimitiveUDPService(eyeTrackingHost, 10000, 10001);
% eyeTracking.StartMessageFun = @(ref) ['YOYO' ref '*' hostname];
eyeTracking.Title = 'Eye-tracking';
eyeTracking.Id = 'eye-tracking';
eyeTracking.ResponseTimeout = 5; %cos it's so slow!
% 
% timeline = srv.PrimitiveUDPService('zoolander');
% timeline.StartMessageFun = @(ref) ['YOYO' ref '*' hostname];
% timeline.Title = 'Timeline';
% timeline.Id = 'timeline';
% timeline.Timeout = 10; %cos it's so slow!

services = {timeline neuralImg eyeTracking};

end

