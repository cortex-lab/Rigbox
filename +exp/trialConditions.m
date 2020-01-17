function [pars, hasNext, repeatNum] = trialConditions(globalPars,...
  allCondPars, advanceTrial, reset)
%EXP.TRIALCONDITIONS Returns trial parameter Signals
%   An implementation of the behaviour of the exp.ConditionServer class in
%   Signals; returns a subscriptable trial parameters signal that updates
%   based on the input signals.
%
%   Inputs:
%     globalPars (sig.Signal): holds a struct of parameters intended to be 
%       independent of advanceTrial.
%     allCondPars (sig.Signal): holds a non-scalar struct of parameters
%       which are to be indexed based on advanceTrial.
%     advanceTrial (sig.Signal): when true will cause pars to update to the
%       next set of trial parameters until all have been selected.
%     reset (sig.Signal|numerical): the seed for the conditional parameter
%       indexer, i.e. the value to count from when advanceTrial updates.
%       Default = 0.
%
%   Outputs:
%     pars (sig.Signal): holds a subscriptable scalar struct of all
%       parameters for a given trial; the combined values of globalPars and
%       allCondPars.
%     hasNext (sig.Signal): updates to true so long as not all trial
%       conditions have been used.
%     repeatNum (sig.Signal): holds the number of times in a row the
%      current value of pars as occured. Counts up so long as advanceTrial
%      is false.
%
%   Example:
%     % Use with exp.Parameters class
%     [globalPars, allCondPars, advanceTrial] = sig.test.create();
%     [~, globalStruct, allCondStruct] = toConditionServer(...
%        exp.Parameters(exp.choiceWorldParams));
%     p = trialConditions(globalPars, allCondPars, advanceTrial)
%     post(globalPars, globalStruct); post(allCondPars, allCondStruct)
%     advanceTrial.post(true)
%
% See also EXP.CONDITIONSERVER, EXP.PARAMETERS

% a new 1 (or true) in nextTrial means move on to the next condition,
% whereas a 0 (or false) means repeat this condition
if nargin < 4
  reset = 0;
end

nConds = allCondPars.map(@numel); % The total number of conditions
nextCondNum = advanceTrial.scan(@plus, reset); % This counter can go over nConds
hasNext = nextCondNum <= nConds; % This ensures pars can't go past nConds

% todo: current hack using identity to delay advanceTrial relative to hasNext
repeatLastTrial = advanceTrial.identity().keepWhen(hasNext);
condIdx = repeatLastTrial.scan(@plus, reset); % This counter can't go past nConds
condIdx = condIdx.keepWhen(condIdx > 0);
condIdx.Name = 'condIdx';
repeatNum = repeatLastTrial.scan(@sig.scan.lastTrue, 0) + 1;
repeatNum.Name = 'repeatNum';

condPar = allCondPars(condIdx); % Index our conditions struct array
% pars updates whenever either conditional or global parameters are
% updated.  Global and consitional parameters are merged into one struct
pars = globalPars.merge(condPar).scan(@mergeStruct, struct).subscriptable();
pars.Name = 'pars';
