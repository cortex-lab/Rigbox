function experiment = prepareExp(params, rig, preDelay, postDelay, comm)
% parameters should have a create experiment function that takes three
% arguments:
% 1st, the parameters structure for configuring the experiment
% 2nd, the rig hardware structure


experiment = exp.DummySignalsExp(params, rig);

experiment.Type = params.type; %record the experiment type
experiment.PreDelay = preDelay;
experiment.PostDelay = postDelay;
experiment.Communicator = comm;

% %configure actions to start and stop services
% if isfield(params, 'services') && ~isempty(params.services)
%   services = srv.findService(params.services); % Uses basicServices
% %   services = srv.loadService(params.services); % Loads BasicUDPService objects
%   for i = 1:length(services)
%     if isprop(services{i},'Timeline')
%       services{i}.Timeline = rig.timeline;
%     end
%   end
%   startServices = exp.StartServices(services);
%   stopServices = exp.StopServices(services);
%   experiment.addEventHandler(...
%     exp.EventHandler('experimentInit', startServices),...
%     exp.EventHandler('experimentCleanup', stopServices));
% end
end