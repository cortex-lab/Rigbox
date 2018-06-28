function habituationWorld(t, evts, p, ~, in, out, ~)
%% habituationWorld
% A simple function that will either output a reward at the end of each
% trial whose length is defined by p.rewardTime, or when the wheel reaches
% a threshold, defined as p.movementThreshold in arbitrary units.  The
% latter mode is chosen by p.useWheel being true.

%% parameters
p.randomiseConditions; % Allows specific condition order
wheel = in.wheel.skipRepeats(); % Wheel signal
wheelDelta = evts.newTrial.at(wheel).scan(@plus, 0); % Wheel integrator
wheelDelta = wheelDelta - wheelDelta.at(evts.newTrial); % Reset each trial

%% feedback
reward = iff(p.useWheel, wheelDelta > p.movementThreshold,... % movement threshold reached
  t - t.at(evts.newTrial) > p.rewardTime); % or at end of trial
out.reward = p.rewardSize.at(reward); % output reward

%% misc
% we want to save these signals so we put them in events with appropriate names
evts.endTrial = evts.newTrial.at(reward);
% evts.wheelDelta = wheelDelta;
% evts.reward = reward;
evts.thr = p.movementThreshold;

try
  p.rewardSize = 3;
  % Random rewards
  p.useWheel = false;
  p.movementThreshold = 1000; % Irrelevant when useWheel is false
  p.rewardTime = randi(120,1,10);
  p.randomiseConditions = true;
  % Rewards for moving wheel
%   p.useWheel = true;
%   p.randomiseConditions = false;
%   p.movementThreshold = 1:100:4000; % Gradually increase threshold
%   p.rewardTime = 10; % Irrelevant when useWheel is true
catch
end

end