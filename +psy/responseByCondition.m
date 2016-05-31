function [rMean, n, cond, rVar, trialCond, trialResp] =...
  responseByCondition(block, conditionFun, responseFun, filterFun)
%analyse Summarise responses based on a particular condition
%   [R, N, COND] = responseByCondition(BLOCK, [CONDFUN], [RESPFUN], [FILTFUN]) 
%   returns the mean responses, R for each unique trial condition (returned
%   in COND) across all blocks (in the BLOCK array). The total number of
%   trials for each condition is returned in N. Each (optional) function 
%   should take a block of trials and return: a vector of each trial's 
%   condition (CONDFUN), a vector of trial responses (RESPFUN), a vector of
%   booleans indicating whether to include each trial in the analysis.
%   
%   If any functions aren't specified, the defaults are visual contrast
%   condition, response of second target chosen, and filter out repeat
%   trials.

% convert block to a cell array if not already so code below is general
if ~iscell(block)
  block = num2cell(block);
end

block = psy.stripIncompleteTrials(block);

% function to detect whether new or old block type
oldBlockTypeFun = @(trial) isfield(trial, 'StimStartTime');

if nargin < 2 || isempty(conditionFun)
  % default condition to analyse is visual contrast difference
  conditionFun = @(trial) iff(~oldBlockTypeFun(trial),...
    @() diff(psy.visualContrasts(trial)),...% for new block type
    @() diff(cell2mat({trial.VisTargetContrasts}'), 1, 2)'); % for legacy block type
end

if nargin < 3 || isempty(responseFun)
  % default response is indicator for choice of 2nd target
  responseFun = @(trial) iff(~oldBlockTypeFun(trial),...
    @() [trial.responseMadeID] == 2,... % for new block type
    @() [trial.ResponseTarget] == 2); % for legacy block type
end

if nargin < 4 || isempty(filterFun)
  % default filter is for non-repeat trials, i.e. repeatNum == 1, if
  % repeatNum field exists, otherwise all trials
  
  % function to check if block has repeats field (new block type)
  hasRepeats = @(trial) isfield([trial.condition], 'repeatNum');
  
  % this is a bit complicated but essentially applies one of two filter
  % functions depending on the block type
  filterFun = @(trial) iff(~oldBlockTypeFun(trial),...
    @() iff(hasRepeats(trial),... % new block filter
      @() pick([trial.condition], 'repeatNum') == 1,...
      @() true(size(trial))),...
    @() ~[trial.RepeatOfLast]); % old block filter
end

% filter out blocks with no trials (which may contain a trial struct with
% missing expected fields
nTrials = pick(block, 'numCompletedTrials');
block = block(nTrials > 0);

% generate a filtered trial set for each block
trialSet = mapToCell(@(b) iff(isfield(b, 'trial'),...
  @() b.trial(filterFun(b.trial)),... % for new block type
  @() b.Trials(filterFun(b.Trials))),... % for legacy block type
  block);
% make sure

% concat conditions and responses of *all* blocks
trialCond = cell2mat(cellfun(@(t) reshape(conditionFun(t), [], 1), trialSet(:), 'UniformOutput', false));
trialResp = cell2mat(cellfun(@(t) reshape(responseFun(t), [], 1), trialSet(:), 'UniformOutput', false));

% find the unqiue conditions
cond = unique(trialCond);

% compute total trials for each condition
n = arrayfun(@(c) sum(trialCond == c), cond);

% compute the mean response for each condition
rMean = arrayfun(@(c) mean(trialResp(trialCond == c)), cond);
rVar = arrayfun(@(c) var(trialResp(trialCond == c)), cond);

end