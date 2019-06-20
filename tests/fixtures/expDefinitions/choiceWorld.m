function choiceWorld(t, events, p, visStim, inputs, outputs, audio)
% ChoiceWorld(t, events, parameters, visStim, inputs, outputs, audio)
%
% A simple training protocol closely following that of our manual training.
% Contrasts are presented randomly (no staircase).  The session is ended
% automatically if after a minimum number of trials either the median
% response time over the last 20 trials is over 5x (default) longer than
% that of the whole session, or if there is a greater than 50% (default)
% decrease in performance over the last 20 trials (compared to total
% performance over the whole session).
%
% The wheel gain changes only after the subject completes over 200 trials
% in a session.  The gain only changes once and remains changed for all
% future sessions.
% 
% There is no longer any change in reward volume, and there is no cue
% interactive delay.

%% Fixed parameters
contrastSet = p.contrastSet.at(events.expStart);
startingContrasts = p.startingContrasts.at(events.expStart); 
repeatOnMiss = p.repeatOnMiss.at(events.expStart); 
trialsToBuffer = p.trialsToBuffer.at(events.expStart);
trialsToZeroContrast = p.trialsToZeroContrast.at(events.expStart);
rewardSize = p.rewardSize.at(events.expStart);
initialGain = p.initialGain.at(events.expStart);
normalGain = p.normalGain.at(events.expStart);
responseWindow = p.responseWindow.at(events.expStart);

% Sounds
audioDevice = audio.Devices('default');
onsetToneFreq = 5000;
onsetToneDuration = 0.1;
onsetToneRampDuration = 0.01;
toneSamples = p.onsetToneAmplitude*events.expStart.map(@(x) ...
    aud.pureTone(onsetToneFreq, onsetToneDuration, audioDevice.DefaultSampleRate, ...
    onsetToneRampDuration, audioDevice.NrOutputChannels));
missNoiseDuration = 0.5;
missNoiseSamples = p.missNoiseAmplitude*events.expStart.map(@(x) ...
    randn(audioDevice.NrOutputChannels, audioDevice.DefaultSampleRate*missNoiseDuration));

%% Initialize trial data
trialDataInit = events.expStart.mapn(...
    contrastSet, startingContrasts, repeatOnMiss, ...
    trialsToBuffer, trialsToZeroContrast, rewardSize,...
    @initializeTrialData).subscriptable;

%% Set up wheel 
wheel = inputs.wheelMM;
quiescThreshold = 1000;
% millimetersFactor = events.newTrial.map2(31*2*pi/(p.encoderRes*4), @times); % convert the wheel gain to a value in mm/deg
gain = events.expStart.mapn(initialGain, normalGain, @initWheelGain);
enoughTrials = events.trialNum > 200;
wheelGain = iff(enoughTrials, normalGain, gain);

%% Trial event times
% (this is set up to be independent of trial conditon, that way the trial
% condition can be chosen in a performance-dependent manner)

% Resetting pre-stim quiescent period
prestimQuiescentPeriod = at(p.prestimQuiescentTime.map(@(A)rnd.exp(A(3),1,A(1:2))), events.newTrial); 
preStimQuiescence = sig.quiescenceWatch(prestimQuiescentPeriod, t, wheel, quiescThreshold); 
% Stimulus onset
stimOn = at(true, preStimQuiescence); % FIXME test whether at is needed here
% Play tone at interactive onset
audio.default = toneSamples.at(stimOn);
% The wheel displacement is zeroed at stimOn
stimDisplacement = wheelGain*(wheel - wheel.at(stimOn));

responseTimeOver = (t - t.at(stimOn)) > responseWindow; % p.responseWindow may be set to Inf
threshold = stimOn.setTrigger(...
  abs(stimDisplacement) >= abs(p.responseDisplacement) | responseTimeOver);
response = cond(...
    responseTimeOver, 3,... % if the response time is over the response = 0
    true, -sign(stimDisplacement)); % otherwise it should be the inverse of the sign of the stimulusDisplacement
response = response.at(stimOn.setTrigger(threshold)); % only update the response signal when the threshold has been crossed

%% Bias
bias = merge(response.keepWhen(response~=3).bufferUpTo(10).map(@sum), ...
  at(0, events.expStart)); % Initialize with 0 at expStart

%% Update performance at response
responseData = vertcat(stimDisplacement, events.trialNum, response, bias);
trialData = responseData.at(response).scan(@updateTrialData, trialDataInit).subscriptable;
% trialData = response.scan(@updateTrialData, trialDataInit, 'pars', stimDisplacement, events.trialNum, bias).subscriptable;
% Set trial contrast (chosen when updating performance)
trialContrast = trialData.trialContrast.at(events.newTrial);
hit = trialData.hit.at(response); 

%% Task disengagement
% Response time = duration (seconds) between new trial and response
rt = t.at(stimOn).map2(t, @(a,b)diff([a,b])).at(response);
% The median response time over the last 20 trials
windowedRT = rt.buffer(20).map(@median);
% The median response time over all trials
baselineRT = rt.bufferUpTo(1000).map(@median); 
% tooSlow is true when windowed rt is x times longer than median rt for the
% session, where x is the rtCriterion
tooSlow = windowedRT > baselineRT*p.rtCriterion;
% noResponse is true when mouse fails to respond for over x seconds, where
% x is maxRespWindow
% noResponse = t-t.at(events.newTrial) > p.maxRespWindow;

% A rolloing buffer of performance (proportion of last 20 trials that were
% correct) - this includes repeat on incorrect trials
windowedPerf = hit.buffer(20).map(@(a)sum(a)/length(a));
% Proportion of all trials that were correct
baselinePerf = hit.bufferUpTo(1000).map(@(a)sum(a)/length(a));
% True when there is an x% decrease in performance over the last 20 trials
% compared to the session average, where x is pctPerfDecrease
poorPerformance = iff(trialData.proportionLeft == 0.5, ...
  (baselinePerf - windowedPerf)/baselinePerf > p.pctPerfDecrease/100, false);
% poorPerformance = (baselinePerf - windowedPerf)/baselinePerf > p.pctPerfDecrease/100;

% The subject is identified as disengaged from the task when, after
% minTrials have been completed, the subject is either too slow or exhibits
% a significant drop in performance.  If the subject has not completed the
% minimum number of trials in 45 minutes it is also classed as disengaged.
disengaged = iff(events.trialNum > p.minTrials, tooSlow, ...
  events.expStart.delay(60*45));
% The session is finished when either the session has been running for x
% seconds, where x is trialDataInit.endAfter (20min on the first day, 40min
% on the seconds, Inf otherwise), or when the subject is disengaged
% finish = merge(at(true, disengaged),...
%     at(true, events.expStart.delay(trialDataInit.endAfter)));
finish = cond(disengaged, true,...
    events.expStart.delay(trialDataInit.endAfter), true);

% When finish takes a value (it may only sample true), this is posted to
% events.expStop to trigger the end of the session
expStop = events.expStop;
expStop.Node.Listeners = [expStop.Node.Listeners, ...
  into(finish, expStop)];

%% Give feedback and end trial
% Ensures reward size is not re-calculated at the response time
rewardSize = trialData.rewardSize.at(events.newTrial); 
% NOTE: there is a 10ms delay for water output, because otherwise water and
% stim output compete and stim is delayed
outputs.reward = rewardSize.at(hit==true).delay(0.01);
% Play noise on miss
audio.default = missNoiseSamples.at(delay(hit==false, 0.01));
% ITI defined by outcome
iti = iff(hit==1, p.itiHit, p.itiMiss);
% Stim stays on until the end of the ITI
stimOff = threshold.delay(iti);

%% Visual stimulus
% Azimuth control
% 1) stim fixed in place until interactive on
% 2) wheel-conditional during interactive  
% 3) fixed at response displacement azimuth after response
trialSide = trialData.trialSide.at(stimOn);
azimuth = cond( ...
    stimOn.to(threshold), p.startingAzimuth*trialSide + stimDisplacement, ...
    threshold.to(events.newTrial), ...
    p.startingAzimuth*trialSide + ...
    iff(response~=3, -response*abs(p.responseDisplacement), trialSide*abs(p.responseDisplacement)));

% Stim flicker
% stimFlicker = sin((t - t.at(stimOn))*stimFlickerFrequency*2*pi) > 0;
stim = vis.grating(t, 'sine', 'gaussian');
stim.sigma = p.sigma;
stim.spatialFreq = p.spatialFreq;
stim.phase = 2*pi*events.newTrial.map(@(v)rand);
stim.azimuth = azimuth;
%stim.contrast = trialContrast.at(stimOn)*stimFlicker;
stim.contrast = trialContrast;
stim.show = stimOn.to(stimOff);

visStim.stim = stim;

%% Display and save
% events.pPerf = (baselinePerf - windowedPerf)/baselinePerf > p.pctPerfDecrease/100;
% Wheel and stim
events.azimuth = azimuth;

% Trial times
events.prestimQuiescentPeriod = prestimQuiescentPeriod;
events.stimulusOn = stimOn;
events.interactiveOn = stimOn;
events.stimulusOff = stimOff;
events.feedback = iff(hit==1, hit, -1);
events.threshold = threshold;
% End trial samples a false when the next trial is to be a repeat trial.
% NB: the identity function is used to ensure that stimOff takes a value
% before endTrial
events.endTrial = at(~trialData.repeatTrial, stimOff.identity);
% Used to identify what form of disengagement has occured
events.disengaged = skipRepeats(keepWhen(cond(...
  tooSlow, 'long RT',...
  true, 'false'), events.trialNum > p.minTrials));
events.windowedRT = windowedRT.map(fun.partial(@sprintf, '%.1f sec'));
events.baselineRT = baselineRT.map(fun.partial(@sprintf, '%.1f sec'));
events.pctDecrease = map(((baselinePerf - windowedPerf)/baselinePerf)*100, fun.partial(@sprintf, '%.1f%%'));
events.endAfter = trialDataInit.endAfter/60;

% Trial side probability
events.bias = bias;

% Performance
events.contrastSet = trialData.contrastSet;
events.repeatOnMiss = trialData.repeatOnMiss;
events.contrastLeft = iff(trialData.trialSide == -1, trialData.trialContrast, trialData.trialContrast*0);
events.contrastRight = iff(trialData.trialSide == 1, trialData.trialContrast, trialData.trialContrast*0);
% events.trialSide = trialData.trialSide;
events.hit = hit;
events.response = at(iff(response==3, 0, response), threshold);
events.useContrasts = trialData.useContrasts;
events.trialsToZeroContrast = trialData.trialsToZeroContrast;
events.hitBuffer = trialData.hitBuffer;
events.wheelGain = wheelGain;
events.totalWater = outputs.reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));

%% Defaults
try 
% The entire stimulus/target contrast set
p.contrastSet = [1,0.5,0.25,0.125,0.06,0]';
% (which conrasts to use at the beginning of training)
p.startingContrasts = double([true,true,false,false,false,false]');
% (which contrasts to repeat on incorrect)
p.repeatOnMiss = double([true,true,false,false,false,false]');
% (number of trials to judge rolling performance)
p.trialsToBuffer = 50;
% (number of trials after introducing 12.5% contrast to introduce 0%)
p.trialsToZeroContrast = 200;
p.spatialFreq = 1/10;
p.sigma = [7, 7]';
% stimFlickerFrequency = 5; % DISABLED BELOW
p.startingAzimuth = 35; % (degrees)
p.responseDisplacement = 35; % (degrees)
% Starting reward size (this value is ignored after the first session)
p.rewardSize = 3; % (microliters)
% Initial wheel gain
p.initialGain = 8; % ~= 20 @ 90 deg;
p.normalGain = 4; % ~= 10 @ 90 deg;

% Timing
p.prestimQuiescentTime = [0.2, 0.5, 0.35]'; % (seconds)
% p.cueInteractiveDelay = 0.2;
% Inter-trial interval on correct response
p.itiHit = 1; % (seconds)
% Inter-trial interval on incorrect response
p.itiMiss = 2; % (seconds)
p.responseWindow = 60; % (seconds)

% How many times slower the subject must become in order to be marked as
% disengaged
p.rtCriterion = 5; % (multiplier)
% The percent decrease in performance that subject must exhibit to be
% marked as disengaged
p.pctPerfDecrease = 50; % (percent)
% The minimum number of trials to be completed before the subject may be
% classified as disengaged
p.minTrials = 400;
% The maximum number of seconds the subject can take to give a response
% before being classified as disengaged
p.maxRespWindow = 60; % (seconds)

% Audio
p.missNoiseAmplitude = 0.01;
p.onsetToneAmplitude = 0.15;
catch
end
end
function wheelGain = initWheelGain(expRef, initialGain, normalGain)
subject = dat.parseExpRef(expRef);
expRef = dat.listExps(subject);
wheelGain = initialGain;
if length(expRef) > 1
    % Loop through blocks from latest to oldest, if any have the relevant
    % parameters then carry them over
    for check_expt = length(expRef)-1:-1:1
        previousBlockFilename = dat.expFilePath(expRef{check_expt}, 'block', 'master');
        trialNum = [];
        if exist(previousBlockFilename,'file')
            previousBlock = load(previousBlockFilename);
            if isfield(previousBlock.block,'events')&&isfield(previousBlock.block.events,'newTrialValues')
                trialNum = previousBlock.block.events.newTrialValues;
            end
        end
        % Check if the relevant fields exist
        if length(trialNum) > 200
            % Break the loop and use these parameters
            wheelGain = normalGain;
            break
        end       
    end        
end
end

function trialDataInit = initializeTrialData(expRef, ...
    contrastSet,startingContrasts,repeatOnMiss,trialsToBuffer, ...
    trialsToZeroContrast,rewardSize)

%%%% Get the subject
% (from events.expStart - derive subject from expRef)
subject = dat.parseExpRef(expRef);

startingContrasts = logical(startingContrasts)';
repeatOnMiss = logical(repeatOnMiss)';

%%%% Initialize all of the session-independent performance values
trialDataInit = struct;

% Store which trials are repeated on miss
trialDataInit.repeatOnMiss = repeatOnMiss;
% Set up the flag for repeating incorrect
trialDataInit.repeatTrial = false;
% Initialize hit/miss
trialDataInit.hit = nan;

%%%% Load the last experiment for the subject if it exists
% (note: MC creates folder on initilization, so start search at 1-back)
expRef = dat.listExps(subject);
% Check how many days mouse has been trained
[~, dates] = dat.parseExpRef(expRef);
dayNum = find(floor(now) == unique(dates), 1, 'last');
trialDataInit.endAfter = iff(dayNum<3, 60*20*dayNum, Inf);
trialDataInit.endAfter = Inf;

useOldParams = false;
if length(expRef) > 1
    % Loop through blocks from latest to oldest, if any have the relevant
    % parameters then carry them over
    for check_expt = length(expRef)-1:-1:1
        learned = isLearned(expRef{check_expt});
        previousBlockFilename = dat.expFilePath(expRef{check_expt}, 'block', 'master');
        if exist(previousBlockFilename,'file')
            previousBlock = load(previousBlockFilename);
            if ~isfield(previousBlock.block, 'outputs')||...
                    ~isfield(previousBlock.block.outputs, 'rewardValues')||...
                    isempty(previousBlock.block.outputs.rewardValues)
                lastRewardSize = rewardSize;
            else
                lastRewardSize = previousBlock.block.outputs.rewardValues(end);
            end
            
            if isfield(previousBlock.block,'events')
                previousBlock = previousBlock.block.events;
            else
                previousBlock = [];
            end
        end
        % Check if the relevant fields exist
        if exist('previousBlock','var') && all(isfield(previousBlock, ...
                {'useContrastsValues','hitBufferValues','trialsToZeroContrastValues'})) &&...
                length(previousBlock.newTrialValues) > 5 
            % Break the loop and use these parameters
            useOldParams = true;
            break
        end       
    end        
end

if useOldParams
    % If the last experiment file has the relevant fields, set up performance
    
    % Which contrasts are currently in use
    try
      len = length(previousBlock.contrastSetValues)/length(previousBlock.contrastSetTimes);
      trialDataInit.contrastSet = previousBlock.contrastSetValues(end-len+1:end);
    catch
      len = length(contrastSet');
      trialDataInit.contrastSet = contrastSet';
    end
    trialDataInit.useContrasts = previousBlock.useContrastsValues(end-len+1:end);
    
    % The buffer to judge recent performance for adding contrasts
    trialDataInit.hitBuffer = ...
        previousBlock.hitBufferValues(:,end-len+1:end,:);
    
    % The countdown to adding 0% contrast
    trialDataInit.trialsToZeroContrast = previousBlock.trialsToZeroContrastValues(end);
    
    % If zero contrasts have been introduced and lapse rate is < 0.2 for
    % 50% contrasts, remove them.
%     if trialDataInit.trialsToZeroContrast == 0 && ...
%         sum(trialDataInit.hitBuffer(:,2,1))/size(trialDataInit.hitBuffer,1) > 0.8 && ...
%         sum(trialDataInit.hitBuffer(:,2,2))/size(trialDataInit.hitBuffer,1) > 0.8
%       trialDataInit.useContrasts(trialDataInit.contrastSet == 0.5) = false;
%     end
    
    % If the subject did over 200 trials last session, reduce the reward by
    % 0.1, unless it is 2ml
    if length(previousBlock.newTrialValues) > 200 && lastRewardSize > 1.5
        trialDataInit.rewardSize = lastRewardSize-0.1;
    else
        trialDataInit.rewardSize = lastRewardSize;
    end
    if learned
      % Remove repeat on incorrect
      trialDataInit.repeatOnMiss = zeros(1,length(trialDataInit.contrastSet));
    end
    
else
    % If this animal has no previous experiments, initialize performance
    % Store the contrasts which are used
    trialDataInit.contrastSet = contrastSet';
    trialDataInit.useContrasts = startingContrasts;
    trialDataInit.hitBuffer = nan(trialsToBuffer, length(contrastSet), 2); % two tables, one for each side
    trialDataInit.trialsToZeroContrast = trialsToZeroContrast;  
    % Initialize water reward size & wheel gain
    trialDataInit.rewardSize = rewardSize;
end

% Set the first contrast
contrasts = trialDataInit.contrastSet(trialDataInit.useContrasts);
w = ((contrasts~=0) + 1) / length(unique([contrasts, -contrasts]));
trialDataInit.trialContrast = randsample(contrasts, 1, true, w);
trialDataInit.trialSide = iff(rand <= 0.5, -1, 1);
end

function trialData = updateTrialData(trialData,responseData)
% Update the performance and pick the next contrast
stimDisplacement = responseData(1);
response = responseData(3);
% bias normalized by trial number: abs(bias) = 0:1
bias = responseData(4)/10; 
% windowedRT = responseData(2);
% trialNum = responseData(3);

% if trialNum > 50 && windowedRT < 60
%     trialData.wheelGain = 3;
% end
% 
%%%% Get index of current trial contrast
currentContrastIdx = trialData.trialContrast == trialData.contrastSet;

%%%% Define response type based on trial condition
trialData.hit = response~=3 && stimDisplacement*trialData.trialSide < 0;

% Index for whether contrast was on the left or the right as performance is
% calculated for both sides.  If the contrast was on the left, the index is
% 1, otherwise 2
trialSideIdx = iff(trialData.trialSide<0, 1, 2); 
    

%%%% Update buffers and counters if not a repeat trial
if ~trialData.repeatTrial
    %%%% Contrast-adding performance buffer
    % Update hit buffer for running performance
    trialData.hitBuffer(:,currentContrastIdx,trialSideIdx) = ...
        [trialData.hit;trialData.hitBuffer(1:end-1,currentContrastIdx,trialSideIdx)];
end

%%%% Add new contrasts as necessary given performance
% This is based on the last trialsToBuffer trials for rolling performance
% (these parameters are hard-coded because too specific)
% (these are side-dependent)
current_min_contrast = min(trialData.contrastSet(trialData.useContrasts & trialData.contrastSet ~= 0));
trialsToBuffer = size(trialData.hitBuffer,1);
switch current_min_contrast
    
    case 0.5
        % Lower from 0.5 contrast after > 70% correct
        min_hit_percentage = 0.70;
        
        contrast_buffer_idx = ismember(trialData.contrastSet,[0.5,1]);
        contrast_total_trials = sum(~isnan(trialData.hitBuffer(:,contrast_buffer_idx,:)));
        % If there have been enough buffer trials, check performance
        if sum(contrast_total_trials) >= size(trialData.hitBuffer,1)
            % Sample as evenly as possible across pooled contrasts.  Here
            % we pool the columns representing the 50% and 100% contrasts
            % for each side (dim 3) individually, then shift the dimentions
            % so that pooled_hits(1,:) = all 50% and 100% trials on the
            % left, and pooled_hits(2,:) = all 50% and 100% trials on the
            % right.
            pooled_hits = shiftdim(...
                reshape(trialData.hitBuffer(:,contrast_buffer_idx,:),[],1,2), 2);
            use_hits(1) = sum(pooled_hits(1,(find(~isnan(pooled_hits(1,:)),trialsToBuffer/2))));
            use_hits(2) = sum(pooled_hits(2,(find(~isnan(pooled_hits(2,:)),trialsToBuffer/2))));
            min_hits = find(1 - binocdf(1:trialsToBuffer/2,trialsToBuffer/2,min_hit_percentage) < 0.05,1);
            if all(use_hits >= min_hits)
                trialData.useContrasts(find(~trialData.useContrasts,1)) = true;
            end
        end

    case 0.25
        % Lower from 0.25 contrast after > 50% correct
        min_hit_percentage = 0.70;
        
        contrast_buffer_idx = ismember(trialData.contrastSet,current_min_contrast);
        contrast_total_trials = sum(~isnan(trialData.hitBuffer(:,contrast_buffer_idx,:)));
        % If there have been enough buffer trials, check performance
        if sum(contrast_total_trials) >= size(trialData.hitBuffer,1)
            % Sample as evenly as possible across pooled contrasts
            pooled_hits = shiftdim(...
                reshape(trialData.hitBuffer(:,contrast_buffer_idx,:),[],1,2), 2);
            use_hits(1) = sum(pooled_hits(1,(find(~isnan(pooled_hits(1,:)),trialsToBuffer/2))));
            use_hits(2) = sum(pooled_hits(2,(find(~isnan(pooled_hits(2,:)),trialsToBuffer/2))));
            min_hits = find(1 - binocdf(1:trialsToBuffer/2,trialsToBuffer/2,min_hit_percentage) < 0.05,1);
            if all(use_hits >= min_hits)
                trialData.useContrasts(find(~trialData.useContrasts,1)) = true;
            end
        end
        
    case 0.125
        % Lower from 0.125 contrast after > 65% correct
        min_hit_percentage = 0.65;
        
        contrast_buffer_idx = ismember(trialData.contrastSet,current_min_contrast);
        contrast_total_trials = sum(~isnan(trialData.hitBuffer(:,contrast_buffer_idx,:)));
        % If there have been enough buffer trials, check performance
        if sum(contrast_total_trials) >= size(trialData.hitBuffer,1)
            % Sample as evenly as possible across pooled contrasts
            pooled_hits = shiftdim(...
                reshape(trialData.hitBuffer(:,contrast_buffer_idx,:),[],1,2), 2);
            use_hits(1) = sum(pooled_hits(1,(find(~isnan(pooled_hits(1,:)),trialsToBuffer/2))));
            use_hits(2) = sum(pooled_hits(2,(find(~isnan(pooled_hits(2,:)),trialsToBuffer/2))));
            min_hits = find(1 - binocdf(1:trialsToBuffer/2,trialsToBuffer/2,min_hit_percentage) < 0.05,1);
            if all(use_hits >= min_hits)
                trialData.useContrasts(find(~trialData.useContrasts,1)) = true;
            end
        end          
        
end

% 200 trials after 12.5 % contrast introduced, put 6%
% 400 trials after 12.5 % contrast introduced, put 0%
% 600 trials after 12.5 % contrast introduced, remove 50%
if min(trialData.contrastSet(trialData.useContrasts)) <= 0.125 && ...
        trialData.trialsToZeroContrast > 0
    % Subtract one from the countdown
    trialData.trialsToZeroContrast = trialData.trialsToZeroContrast-1;
    
    if trialData.trialsToZeroContrast == 0 && ...
        ~trialData.useContrasts(trialData.contrastSet == 0.06)
      trialData.useContrasts(trialData.contrastSet == 0.06) = true; % Add 6%
      trialData.trialsToZeroContrast = 200; % Reset counter
      
    elseif trialData.trialsToZeroContrast == 0 && ...
        ~trialData.useContrasts(trialData.contrastSet == 0)
      trialData.useContrasts(trialData.contrastSet == 0) = true; % Add 0%
      trialData.trialsToZeroContrast = 200; % Reset counter
      
    elseif trialData.trialsToZeroContrast == 0 && ...
        trialData.useContrasts(trialData.contrastSet == 0)
      trialData.useContrasts(trialData.contrastSet == 0.5) = false; % Remove 50%
    end
end

%%%% Set flag to repeat - skip trial choice if so
if ~trialData.hit && any(trialData.repeatOnMiss==true) && ...
        ismember(trialData.trialContrast,trialData.contrastSet(trialData.repeatOnMiss))
    % If the response is a no-go, repeat the same trial side
    if response ~= 3
      % Otherwise take biased sample from normal distribution
      sd = 0.5; % standard deviation
      r = 0.5 + sd.*randn; % pull number from normal dist with mean 0.5
      trialData.trialSide = iff((r - bias) > 0.5, 1, -1);
      % trialData.trialSide = iff(binornd(1,bias), 
    end
    trialData.repeatTrial = true;
    return
else
    trialData.repeatTrial = false;
end

%%%% Pick next contrast

% Next contrast is random from current contrast set
contrasts = trialData.contrastSet(trialData.useContrasts);
w = ((contrasts~=0) + 1) / length(unique([contrasts, -contrasts]));
trialData.trialContrast = randsample(contrasts, 1, true, w);
%%%% Pick next side
trialData.trialSide = iff(rand <= 0.5, -1, 1);
end
function learned = isLearned(ref)
learned = false;
subject = dat.parseExpRef(ref);
expRef = dat.listExps(subject);
j = 1;
pooledCont = [];
pooledIncl = [];
pooledChoice = [];
for i = length(expRef):-1:1
  p = dat.expFilePath(expRef{i}, 'block', 'master');
  if exist(p,'file')==2
    % Block doesn't exist
    p = fileparts(p);
  else
    fprintf('No block file for session %s: skipping\n', expRef{i})
    continue
  end
  try
    feedback = readNPY(fullfile(p,'_ibl_trials.feedbackType.npy'));
    contrastLeft = readNPY(fullfile(p,'_ibl_trials.contrastLeft.npy'));
    contrastRight = readNPY(fullfile(p,'_ibl_trials.contrastRight.npy'));
    incl = readNPY(fullfile(p,'_ibl_trials.included.npy'));
    choice = readNPY(fullfile(p,'_ibl_trials.choice.npy'));
  catch
    warning('isLearned:ALFLoad:MissingFiles', ...
      'Unable to load files for session %s', expRef{i})
    continue
  end
  % If the zero contrast stimuli have not been introduced, the subject
  % can't have learned.  NB: Unfortunately if the hand of fate not once
  % chose a zero contrast trial then the mouse would fail here, even if it
  % was available to sample.  This is fairly unlikely to happen and this
  % method is much quicker than loading the block file to retreive the
  % actual contrast set.
  contrast = diff([contrastLeft,contrastRight],[],2);
  if ~any(contrast==0)
    fprintf('Low contrasts not yet introduced\n')
    return
  end
  perfOnEasy = sum(feedback==1 & abs(contrast > 0.25)) / sum(abs(contrast > 0.25));
  if length(feedback) > 200 && perfOnEasy > 0.8
    pooledCont = [pooledCont; contrast];
    pooledIncl = [pooledIncl; incl];
    pooledChoice = [pooledChoice; choice];
    if j < 3
      j = j+1;
    else
      % All three sessions meet criteria
      contrastSet = unique(pooledCont);
      nn = arrayfun(@(c)sum(pooledCont==c & pooledIncl), contrastSet);
      pp = arrayfun(@(c)sum(pooledCont==c & pooledIncl & pooledChoice==-1), contrastSet)./nn;
      pars = psy.mle_fit_psycho([contrastSet';nn';pp'], 'erf_psycho_2gammas',...
        [mean(contrastSet), 3, 0.05, 0.05],...
        [min(contrastSet), 10, 0, 0],...
        [max(contrastSet), 30, 0.4, 0.4]);
      if abs(pars(1)) < 16 && pars(2) < 19 && pars(3) < 0.2 && pars(4) < 0.2
        learned = true;
      else
        fprintf('Fit parameter values below threshold\n')
        return
      end
    end
  else
    fprintf('Low trial count or performance at high contrast\n')
    return
  end
end
end