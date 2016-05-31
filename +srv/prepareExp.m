function experiment = prepareExp(params, rig, preDelay, postDelay, comm)

% parameters should have a create experiment function that takes three
% arguments:
% 1st, the parameters structure for configuring the experiment
% 2nd, the rig hardware structure
if isfield(params, 'defFunction')
  experiment = exp.configureSignalsExperiment(params, rig);
else
  assert(isfield(params, 'experimentFun'), 'No experiment creation function in parameters');
  experiment = params.experimentFun(params, rig);
end

experiment.PreDelay = preDelay;
experiment.PostDelay = postDelay;
experiment.Communicator = comm;

%configure actions to start and stop services
if isfield(params, 'services') && ~isempty(params.services)
  services = srv.findService(params.services);
  startServices = exp.StartServices(services);
  stopServices = exp.StopServices(services);
  experiment.addEventHandler(...
    exp.EventHandler('experimentInit', startServices),...
    exp.EventHandler('experimentCleanup', stopServices));
end

%   % add a log entry for the experiment
%   %TODO: in future logging will be handled by the client so that e.g.
%   %comments can be entered by the supervisor and added
% %   expInfo.ref = block.expRef;
% %   expInfo.proportionCorrect = psycho.proportionCorrect(block);
% %   expInfo.rewardType = 'water';
% %   expInfo.rewardTotal = sum([block.rewardDeliveredSizes]); % in microlitres
% %   expInfo.rewardUnits = 'µl'; % in microlitres
% %   data.addLogEntry(subjectRef, block.startDateTime, 'experiment-info', expInfo, '');
% end

end