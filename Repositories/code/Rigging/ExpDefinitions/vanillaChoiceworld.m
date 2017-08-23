function vanillaChoiceworld(t, events, parameters, visStim, inputs, outputs, audio)
% vanillaChoiceworld(t, events, parameters, visStim, inputs, outputs, audio)
% 170309 - AP
%
% Choice world that adapts with behavior
%
% Task structure: 
% Start trial
% Resetting pre-stim quiescent period
% Stimulus onset
% Fixed cue interactive delay
% Infinite time for response, fix stim azimuth on response
% Short ITI on reward, long ITI on punish, then turn stim off
% End trial


%% Fixed parameters

% Reward
rewardSize = 2;

% Trial choice parameters
% Staircase trial choice
% (how often staircase trials appear - every staircaseTrials trials)
staircaseTrials = 2; 
% (how many hits to move forward on the staircase)
staircaseHit = 3;
% (how many misses to move backward on the staircase)
staircaseMiss = 1;

% Stimulus/target
% (which contrasts to use)
contrasts = [1,0.5,0.25,0.125,0.06,0];
% (which conrasts to use at the beginning of training)
startingContrasts = [true,true,false,false,false,false];
%%%%%%%%%%%%%% NOTE: FOR NOW MAKING THIS TRUE FROM THE BEGINNING
%%%%%%%%%%%%%% THIS IS BECAUSE NEED TO FIX LOOKING FOR OLD CHOICEWORLD:
%%%%%%%%%%%%%% MAKE IT BE THE LAST CHOICEWORLD, NOT THE LAST EXPT
startingContrasts = [true,true,true,true,true,true];
%%%%%%%%%%%%%%
%%%%%%%%%%%%%%
%%%%%%%%%%%%%%
% (which contrasts to repeat on miss)
repeatOnMiss = [true,true,false,false,false,false];
% (number of trials to judge rolling performance)
trialsToBuffer = 50;
% (number of trials after introducing 12.5% contrast to introduce 0%)
trialsToZeroContrast = 500;
sigma = [20,20];
spatialFrequency = 0.01;
stimFlickerFrequency = 5; % DISABLED BELOW
startingAzimuth = 90;
responseDisplacement = 90;

% Timing
prestimQuiescentTime = 0.5;
cueInteractiveDelay = 0.5;
itiHit = 1;
itiMiss = 2;

% Sounds
audioSampleRate = 192e3;

onsetToneAmplitude = 1;
onsetToneFreq = 12000;
onsetToneDuration = 0.1;
onsetToneRampDuration = 0.01;
audioChannels = 2;
toneSamples = onsetToneAmplitude*events.expStart.map(@(x) ...
    aud.pureTone(onsetToneFreq,onsetToneDuration,audioSampleRate, ...
    onsetToneRampDuration,audioChannels));

missNoiseDuration = itiMiss;
missNoiseAmplitude = 0.05;
missNoiseSamples = missNoiseAmplitude*events.expStart.map(@(x) ...
    randn(2, audioSampleRate*missNoiseDuration));

% Wheel parameters
quiescThreshold = 1;
wheelGain = 2;

%% Initialize trial data

trialDataInit = events.expStart.mapn( ...
    contrasts,startingContrasts,repeatOnMiss, ...
    trialsToBuffer,trialsToZeroContrast,staircaseTrials,staircaseHit,staircaseMiss, ...
    @initializeTrialData).subscriptable;

%% Set up wheel 

wheel = inputs.wheel.skipRepeats();

%% Trial event times
% (this is set up to be independent of trial conditon, that way the trial
% condition can be chosen in a performance-dependent manner)

% Resetting pre-stim quiescent period
prestimQuiescentPeriod = at(prestimQuiescentTime,events.newTrial.delay(0)); 
preStimQuiescence = sig.quiescenceWatch(prestimQuiescentPeriod, t, wheel, quiescThreshold); 

% Stimulus onset
%stimOn = sig.quiescenceWatch(preStimQuiescPeriod, t, wheel, quiescThreshold); 
stimOn = at(true,preStimQuiescence); 

% Fixed cue interactive delay
interactiveOn = stimOn.delay(cueInteractiveDelay); 

% Play tone at interactive onset
audio.onsetTone = toneSamples.at(interactiveOn);

% Response
% (wheel displacement zeroed at interactiveOn)
stimDisplacement = wheelGain*(wheel - wheel.at(interactiveOn));

response = keepWhen(interactiveOn.setTrigger(abs(stimDisplacement) ...
    >= responseDisplacement),interactiveOn.to(events.newTrial));

%% Update performance at response
% (NOTE: this cannot be done at endTrial: concurrent events break things)

% Update performance
trialData = stimDisplacement.at(response).scan(@updateTrialData,trialDataInit).subscriptable;

% Set trial contrast (chosen when updating performance)
trialContrast = trialData.trialContrast;


%% Give feedback and end trial

% Give reward on hit
water = at(rewardSize,trialData.hit);  
outputs.reward = water;
totalWater = water.scan(@plus,0);

% Play noise on miss
audio.missNoise = missNoiseSamples.at(trialData.miss);

% ITI defined by outcome
iti = response.delay(trialData.hit.at(response)*itiHit + trialData.miss.at(response)*itiMiss);

% Stim stays on until the end of the ITI
stimOff = iti;

% End trial at the end of the ITI
endTrial = iti;

%% Visual stimulus

% Azimuth control
% Stim fixed in place before interactive and after response, wheel-conditional otherwise
stimAzimuth = cond( ...
    events.newTrial.to(interactiveOn), startingAzimuth*trialData.trialSide, ...
    interactiveOn.to(response), startingAzimuth*trialData.trialSide + stimDisplacement);

% Stim flicker
stimFlicker = sin((t - t.at(stimOn))*stimFlickerFrequency*2*pi) > 0;

stim = vis.grating(t, 'square', 'gaussian');
stim.sigma = sigma;
stim.spatialFrequency = spatialFrequency;
stim.phase = 2*pi*events.newTrial.map(@(v)rand);
stim.azimuth = stimAzimuth;
%stim.contrast = trialContrast.at(stimOn)*stimFlicker;
stim.contrast = trialContrast.at(stimOn);
stim.show = stimOn.to(stimOff);

visStim.stim = stim;

%% Display and save

% Wheel and stim
events.stimAzimuth = stimAzimuth;

% Trial times
events.stimOn = stimOn;
events.stimOff = stimOff;
events.interactiveOn = interactiveOn;
events.response = response;
events.endTrial = endTrial;

% Performance
events.contrasts = trialData.contrasts;
events.repeatOnMiss = trialData.repeatOnMiss;
events.trialContrast = trialData.trialContrast;
events.trialSide = trialData.trialSide;
events.repeatTrial = trialData.repeatTrial;
events.hit = trialData.hit;
events.miss = trialData.miss;
events.staircase = trialData.staircase;
events.useContrasts = trialData.useContrasts;
events.trialsToZeroContrast = trialData.trialsToZeroContrast;
events.hitBuffer = trialData.hitBuffer;
events.sessionPerformance = trialData.sessionPerformance;
events.totalWater = totalWater;

end

function trialDataInit = initializeTrialData(subject_info, ...
    contrasts,startingContrasts,repeatOnMiss,trialsToBuffer, ...
    trialsToZeroContrast,staircaseTrials,staircaseHit,staircaseMiss)

%%%% Get the subject
% (from events.expStart - MC gives subject after last underscore)
subject_info_underscore_idx = strfind(subject_info,'_');
if ~isempty(subject_info_underscore_idx)
    subject = subject_info(subject_info_underscore_idx(end)+1:end);
else
    % (if there are no underscores, set subject to nothing)
    subject = '';
end

%%%% Initialize all of the session-independent performance values
trialDataInit = struct;

% Store the contrasts which are used
trialDataInit.contrasts = contrasts;
% Store which trials are repeated on miss
trialDataInit.repeatOnMiss = repeatOnMiss;
% Set the first contrast to 1
trialDataInit.trialContrast = 1;
% Set the first trial side randomly
trialDataInit.trialSide = randsample([-1,1],1);
% Set up the flag for repeating incorrect
trialDataInit.repeatTrial = false;
% Initialize hit/miss
%%%%%%%%%%%% NOTE THAT THIS IS WEIRD (FIGURED THIS OUT LATE): 
%%%%%%%%%%%% This sets up the hit/miss signal AFTER a trial (i.e. the first
%%%%%%%%%%%% value is always undefined, the second value represents the
%%%%%%%%%%%% first trial). But this is confusing because contrasts are set
%%%%%%%%%%%% up BEFORE a trial (i.e. the first value is the first trial).
%%%%%%%%%%%% This means that in order to align them, in analysis they need
%%%%%%%%%%%% to be shifted one spot to the left. Maybe this could be done
%%%%%%%%%%%% here, but would be non-trivial, so doing in anaylsis.
trialDataInit.hit = false;
trialDataInit.miss = false;
% Initialize the staircase: 
% [current contrast, hits, misses, staircase trial counter, 
% staircase every n trials, hit requirement, miss requirement]
trialDataInit.staircase = ...
    [contrasts(1),0,0,0, ...
    staircaseTrials,staircaseHit,staircaseMiss];
% Initialize the day's performance to plot
% [conditions, number of trials, number of move left choices]
trialDataInit.sessionPerformance = ...
    [sort(unique([-contrasts,contrasts])); ...
    zeros(size(unique([-contrasts,contrasts]))); ...
    zeros(size(unique([-contrasts,contrasts])))];

%%%% Load the last experiment for the subject if it exists
% (note: MC creates folder on initilization, so look for > 1)
expRef = dat.listExps(subject);
if length(expRef) > 1
    previousBlockFilename = dat.expFilePath(expRef{end-1}, 'block', 'master');
    if exist(previousBlockFilename,'file')
        previousBlock = load(previousBlockFilename);
    end
end
if exist('previousBlock','var') && isfield(previousBlock.block,'events') && ...
        all(isfield(previousBlock.block.events, ...
        {'useContrastsValues','hitBufferValues','trialsToZeroContrastValues'}))
    % If the last experiment file has the relevant fields, set up performance
    
    % Which contrasts are currently in use
    trialDataInit.useContrasts = previousBlock.block. ...
        events.useContrastsValues(end-length(contrasts)+1:end);
    
    % The buffer to judge recent performance for adding contrasts
    trialDataInit.hitBuffer = ...
        previousBlock.block. ...
        events.hitBufferValues(:,end-length(contrasts)+1:end);
    
    % The countdown to adding 0% contrast
    trialDataInit.trialsToZeroContrast = previousBlock.block. ...
        events.trialsToZeroContrastValues(end);      
       
else    
    % If this animal has no previous experiments, initialize performance
    trialDataInit.useContrasts = startingContrasts;
    trialDataInit.hitBuffer = nan(trialsToBuffer,length(contrasts));
    trialDataInit.trialsToZeroContrast = trialsToZeroContrast;  
end

end

function trialData = updateTrialData(trialData,stimDisplacement)
% Update the performance and pick the next contrast

%%%% Get index of current trial contrast
currentContrastIdx = trialData.trialContrast == trialData.contrasts;

%%%% Define response type based on trial condition
trialData.hit = stimDisplacement*trialData.trialSide < 0;
trialData.miss = stimDisplacement*trialData.trialSide > 0;

%%%% Update buffers and counters if not a repeat trial
if ~trialData.repeatTrial
    
    %%%% Contrast-adding performance buffer
    % Update hit buffer for running performance
    trialData.hitBuffer(:,currentContrastIdx) = ...
        [trialData.hit;trialData.hitBuffer(1:end-1,currentContrastIdx)];
    
    %%%% Staircase
    % Update staircase trial counter
    trialData.staircase(4) = trialData.staircase(4) + 1;
    if trialData.staircase(4) >= trialData.staircase(5)
        trialData.staircase(4) = 0;
    end
    
    % Update hit/miss counter
    trialData.staircase(2) = trialData.staircase(2) + trialData.hit;
    trialData.staircase(3) = trialData.staircase(3) + trialData.miss;
        
    % Move staircase on hit/miss counter threshold
    if trialData.staircase(2) >= trialData.staircase(6)
        % On hit threshold, move the staircase forward and reset hit/miss
        newStaircaseContrast = trialData.contrasts(...
            min(find(trialData.staircase(1) == trialData.contrasts)+1, ...
            sum(trialData.useContrasts)));
        trialData.staircase(1) = newStaircaseContrast;
        trialData.staircase(2:3) = 0;
    elseif trialData.staircase(3) >= trialData.staircase(7)
        % On miss threshold, move staircase backward and reset hit/miss
        newStaircaseContrast = trialData.contrasts(...
            max(find(trialData.staircase(1) == trialData.contrasts)-1,1));
        trialData.staircase(1) = newStaircaseContrast;
        trialData.staircase(2:3) = 0;
    end
    
    %%% Session performance for plotting
    currCondition = trialData.trialContrast*trialData.trialSide;
    currConditionIdx = trialData.sessionPerformance(1,:) == currCondition;
    trialData.sessionPerformance(2,currConditionIdx) = ...
        trialData.sessionPerformance(2,currConditionIdx) + 1;
    trialData.sessionPerformance(3,currConditionIdx) = ...
        trialData.sessionPerformance(3,currConditionIdx) + (stimDisplacement < 0);
    
end

%%%% Add new contrasts as necessary given performance
% This is based on the last trialsToBuffer trials for rolling performance
% (these parameters are hard-coded because too specific)
% (these are side-independent)
current_min_contrast = min(trialData.contrasts(trialData.useContrasts & trialData.contrasts ~= 0));
trialsToBuffer = size(trialData.hitBuffer,1);
switch current_min_contrast
    
    case 0.5
        % Lower from 0.5 contrast after > 70% correct
        min_hit_percentage = 0.70;
        
        contrast_buffer_idx = ismember(trialData.contrasts,[0.5,1]);
        contrast_total_trials = sum(sum(~isnan(trialData.hitBuffer(:,contrast_buffer_idx))));
        % If there have been enough buffer trials, check performance
        if contrast_total_trials >= size(trialData.hitBuffer,1)
            % Sample as evenly as possible across pooled contrasts
            pooled_hits = reshape(trialData.hitBuffer(:,contrast_buffer_idx)',[],1);
            use_hits = sum(pooled_hits(find(~isnan(pooled_hits),trialsToBuffer)));
            min_hits = find(1 - binocdf(1:trialsToBuffer,trialsToBuffer,min_hit_percentage) < 0.05,1);
            if use_hits >= min_hits
                trialData.useContrasts(find(~trialData.useContrasts,1)) = true;
            end
        end

    case 0.25
        % Lower from 0.25 contrast after > 50% correct
        min_hit_percentage = 0.5;
        
        contrast_buffer_idx = ismember(trialData.contrasts,current_min_contrast);
        contrast_total_trials = sum(sum(~isnan(trialData.hitBuffer(:,contrast_buffer_idx))));
        % If there have been enough buffer trials, check performance
        if contrast_total_trials >= size(trialData.hitBuffer,1)
            % Sample as evenly as possible across pooled contrasts
            pooled_hits = reshape(trialData.hitBuffer(:,contrast_buffer_idx)',[],1);
            use_hits = sum(pooled_hits(find(~isnan(pooled_hits),trialsToBuffer)));
            min_hits = find(1 - binocdf(1:trialsToBuffer,trialsToBuffer,min_hit_percentage) < 0.05,1);
            if use_hits >= min_hits
                trialData.useContrasts(find(~trialData.useContrasts,1)) = true;
            end
        end
        
    case 0.125
        % Lower from 0.25 contrast after > 50% correct
        min_hit_percentage = 0.5;
        
        contrast_buffer_idx = ismember(trialData.contrasts,current_min_contrast);
        contrast_total_trials = sum(sum(~isnan(trialData.hitBuffer(:,contrast_buffer_idx))));
        % If there have been enough buffer trials, check performance
        if contrast_total_trials >= size(trialData.hitBuffer,1)
            % Sample as evenly as possible across pooled contrasts
            pooled_hits = reshape(trialData.hitBuffer(:,contrast_buffer_idx)',[],1);
            use_hits = sum(pooled_hits(find(~isnan(pooled_hits),trialsToBuffer)));
            min_hits = find(1 - binocdf(1:trialsToBuffer,trialsToBuffer,min_hit_percentage) < 0.05,1);
            if use_hits >= min_hits
                trialData.useContrasts(find(~trialData.useContrasts,1)) = true;
            end
        end          
        
end

% Add 0 contrast after trialsToZeroContrast trials with 0.125 contrast
if min(trialData.contrasts(trialData.useContrasts)) <= 0.125 && ...
        trialData.trialsToZeroContrast > 0
    % Subtract one from the countdown
    trialData.trialsToZeroContrast = trialData.trialsToZeroContrast-1;
    % If at zero, add 0 contrast
    if trialData.trialsToZeroContrast == 0
        trialData.useContrasts(trialData.contrasts == 0) = true;
    end    
end

%%%% Set flag to repeat - skip trial choice if so
if trialData.miss && ...
        ismember(trialData.trialContrast,trialData.contrasts(trialData.repeatOnMiss))
    trialData.repeatTrial = true;
    return
else
    trialData.repeatTrial = false;
end

%%%% Pick next contrast

% Define whether this is a staircase trial
staircaseTrial = trialData.staircase(4) == 0;

if ~staircaseTrial
    % Next contrast is random from current contrast set
    trialData.trialContrast = randsample(trialData.contrasts(trialData.useContrasts),1);    
elseif staircaseTrial  
    % Next contrast is defined by the staircase
    trialData.trialContrast = trialData.staircase(1);    
end

%%%% Pick next side (this is done at random)
trialData.trialSide = randsample([-1,1],1);

end


