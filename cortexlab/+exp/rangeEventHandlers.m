function [ handlers ] = rangeEventHandlers(jumpInteractiveDelay, trialDelay)
%EXP.RANGEEVENTHANDLERS Basic stimulus-response experiment structure
%   Creates a set of event handlers for a basic stimulus-response-feedback
%   experiment.
%
% Part of Cortex Lab Rigbox customisations

handlers = [];

%% When the experiment first starts running, begin a trial
h = exp.EventHandler('experimentStarted', exp.StartTrial);
h.addCallback(@(info, due) prepareStim(info.Experiment)); % prep stimulus
h.addAction(exp.StartPhase('stimulus')); % start stimulus phase
h.InvalidateStimWindow = true; % make sure the first frame gets drawn
handlers = [handlers, h];

%% When a trial starts running,
h = exp.EventHandler('trialStarted');
% update stimulus - position jump & contrast
h.Delay = false;
h.addCallback(@jump);
h.InvalidateStimWindow = true; % make sure the first frame gets drawn
handlers = [handlers, h];

h = exp.EventHandler('trialStarted', exp.StartPhase('interactive'));
h.Delay = jumpInteractiveDelay; %...configurable delay
h.addCallback(@beginassess);
handlers = [handlers, h];

%% At each assesment point in time, give reward dependent on position
% h = exp.EventHandler('interactiveStarted');
% h.Delay = assessmentDelay;
% % Deliver reward sized, r(x(t))
% h.addCallback(@reward);
% handlers = [handlers, h];

% h = exp.EventHandler('interactiveStarted');
% h.Delay = 2*assessmentDelay;
% % Deliver reward sized, r(x(t))
% h.addCallback(@reward);
% handlers = [handlers, h];
% 
% h = exp.EventHandler('interactiveStarted');
% h.Delay = 3*assessmentDelay;
% % Deliver reward sized, r(x(t))
% h.addCallback(@reward);
% handlers = [handlers, h];
% 
% h = exp.EventHandler('interactiveStarted');
% h.Delay = 4*assessmentDelay;
% % Deliver reward sized, r(x(t))
% h.addCallback(@reward);
% handlers = [handlers, h];
% 
% h = exp.EventHandler('interactiveStarted');
% h.Delay = 5*assessmentDelay;
% % Deliver reward sized, r(x(t))
% h.addCallback(@reward);
% handlers = [handlers, h];


%% Start a new trial/jump
h = exp.EventHandler('interactiveStarted', {exp.EndPhase('interactive'),...
  exp.EndTrial, exp.StartTrial});
h.Delay = trialDelay; %...configurable delay
handlers = [handlers, h];

h = exp.EventHandler('experimentEnded', exp.EndPhase('stimulus'));
handlers = [handlers, h];

  function jump(info, due)
    xprmnt = info.Experiment;
    cond = xprmnt.ConditionServer;
    posDistFun = param(cond, 'posDistFun');
    newx = posDistFun(); % sample a new position
    xprmnt.TargetOffset = newx;
    log(xprmnt, 'newPos', newx);
  end

  function beginassess(info, due)
    xprmnt = info.Experiment;
    xprmnt.LastAssessmentTime = xprmnt.Clock.now;
%     xprmnt = info.Experiment;
%     cond = xprmnt.ConditionServer;
%     rewardFun = param(cond, 'rewardFun');
%     rewardpos = pxpos(xprmnt);
%     fprintf('reward pos = %.2f\n', rewardpos);
%     rewardsize = rewardFun(rewardpos); % sample a new position
%     maxreward = param(cond, 'rewardVolume');
%     log(xprmnt, 'assessmentPos', rewardpos);
%     if maxreward*rewardsize >= 2
%       xprmnt.RewardController.deliverBackground(maxreward*rewardsize);
%     end
  end

end

