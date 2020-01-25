% Test for exp.trialConditions
[advanceTrial, globalPars, condPars, seed] = sig.test.create;
% Convenience function for checking current value
match = @(s,v) ~isempty(s.Node.CurrValue) && s.Node.CurrValue == v;
% Keep track of expected trial index
idx = advanceTrial.scan(@plus, merge(seed, condPars.map(0)));

n = 5; % Number of trials; NB: must be greater than 3!
parsStruct = struct('global', rand, 'conditional', 1:n, 'numRepeats', 1);
[~, globalParams, trialParams] = ...
  exp.Parameters(parsStruct).toConditionServer(false);

% Convenience function for checking expected parameters.  Because the
% parameters aren't randomized and the condition parameters are numbered,
% the current conditional parameter should be equal to the current trial
% index.
parsMatch = @(p) ...
  p.Node.CurrValue.global == globalParams.global &&...
  p.Node.CurrValue.conditional == idx.Node.CurrValue;

%% Test 1: Signals condition server without reset
[params, hasNext, repeatNum] = exp.trialConditions(...
  globalPars, condPars, advanceTrial);

% Update parameters
globalPars.post(globalParams)
condPars.post(trialParams)
signalUpdates = params.map(1).scan(@plus, 0); % Count number of updates

% Check parameter updates on first advanceTrial
advanceTrial.post(true)
assert(match(hasNext, true), 'failed to update hasNext signal')
assert(match(repeatNum, 1), 'failed to update repeatNum signal')
assert(parsMatch(params), 'unexpected trial params')

% Check second progression
advanceTrial.post(true)
assert(match(hasNext, true), 'failed to update hasNext signal')
assert(match(repeatNum, 1), 'failed to update repeatNum signal')
assert(parsMatch(params), 'unexpected trial params')

% Check behaviour on advance trial false
advanceTrial.post(false)
assert(match(hasNext, true), 'failed to update hasNext signal')
assert(match(repeatNum, 2), 'failed to update repeatNum signal')
assert(parsMatch(params), 'unexpected trial params')

% Check repeat num after advance trial true
while idx.Node.CurrValue ~= n
  advanceTrial.post(true)
end
assert(match(hasNext, true), 'failed to update hasNext signal')
assert(match(repeatNum, 1), 'failed to update repeatNum signal')
assert(parsMatch(params), 'unexpected trial params')

% Check behaviour when all trials finished
advanceTrial.post(true)
assert(match(hasNext, false), 'failed to update hasNext signal')

% Pars signal should no longer update
advanceTrial.post(true)
assert(match(signalUpdates, idx.Node.CurrValue-1), ...
  'unexpected number of params signal updates')

%% Test 2: Reset input as signal
[params, hasNext, repeatNum] = exp.trialConditions(...
  globalPars, condPars, advanceTrial, seed);

% Update our parameters
globalPars.post(globalParams)
condPars.post(trialParams)
seed.post(0); % Initialize seed
signalUpdates = params.map(1).scan(@plus, 0); % Count number of updates

% Check consistent behaviour with seed being signal
advanceTrial.post(true)
advanceTrial.post(false)
advanceTrial.post(true)
assert(match(hasNext, true), 'failed to update hasNext signal')
assert(match(repeatNum, 1), 'failed to update repeatNum signal')
assert(parsMatch(params), 'unexpected trial params')

% Posting 0 to seed should reset parameter condition index
seed.post(0);
advanceTrial.post(true)
assert(match(hasNext, true), 'failed to update hasNext signal')
assert(match(repeatNum, 1), 'failed to update repeatNum signal')
assert(parsMatch(params), 'unexpected trial params')

seed.post(n-1); % Change seed to second-to-last trial
advanceTrial.post(true)
assert(match(hasNext, true), 'failed to update hasNext signal')
assert(match(repeatNum, 1), 'failed to update repeatNum signal')
assert(parsMatch(params), 'unexpected trial params')

advanceTrial.post(true)
assert(match(hasNext, false), 'failed to update hasNext signal')
assert(match(repeatNum, 1), 'failed to update repeatNum signal')
assert(match(signalUpdates, idx.Node.CurrValue), ...
  'unexpected number of params signal updates')
