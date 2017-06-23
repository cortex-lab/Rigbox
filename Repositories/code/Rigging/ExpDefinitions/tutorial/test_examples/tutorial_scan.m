function tutorial_scan(t, events, pars, visStim, inputs, outputs, audio)
% Learn the scan function: add 1 to a value every other trial
% Also teaches how to use structures as signals

%% This is a simple updating value
% Initialize the value at 0
oddTrials = 0;
evenTrials = 0;
% Whenever there's a new trial, update the value
oddTrials = skipRepeats(events.trialNum.scan(@odd_trial,oddTrials));
evenTrials = skipRepeats(events.trialNum.scan(@even_trial,evenTrials));

% (Note that this command never reaches the function...?)
%value = events.trialNum.mapn(@scan_function,value);

%% This is an updating structure
% Nice try - but structures are unusable in this context
% trials.odd = 0;
% trials.even = 0;
% trials = events.trialNum.scan(@struct_update,trials);

% The workaround is to make it a signal in the beginning of the experiment.
% The 'subscriptable' command must be used in order to access the fields,
% and it must be called agan whenever it updates. I also purposfully
% named initial vs trials_signals to illustrate that you're creating a new
% signal which has those properties based on the initial one, it's not like
% you're updating the initial one.
trials.odd = 0;
trials.even = 0;
initial_trials_signal = events.expStart.map(@(x) trials);
trials_signal = events.trialNum.scan(@struct_update,initial_trials_signal).subscriptable;

% To compare to map, comment out the last and try this one - note that
% these aren't signals so they can't be put directly into events, but check
% out on debug: it doesn't update trials_structure, it starts from 0 every
% time
%trials_signal = events.trialNum.mapn(trials_signal,@struct_update_map);

% NOTE: can't do skipRepeats like this OR in the function. The only way I
% see to skip repeats is by transforming each field individually (see below
% in the events section)
%trials_signal = events.trialNum.scan(@struct_update,trials_signal).subscriptable;


%% Define events to save
events.oddTrials = oddTrials;
events.evenTrials = evenTrials;
events.oddTrialsStruct = skipRepeats(trials_signal.odd);
events.evenTrialsStruct = skipRepeats(trials_signal.even);
events.endTrial = events.newTrial.delay(1);

end

function nTrials = odd_trial(nTrials,trialNum)
% Add 1 on every odd numbered trial
nTrials = nTrials + mod(trialNum,2);
end

function nTrials = even_trial(nTrials,trialNum)
% Add 1 on every even numbered trial
nTrials = nTrials + mod(trialNum-1,2);
end

function nTrials_struct = struct_update(nTrials_struct,trialNum)
% Add 1 on even and odd trials respectively
keyboard
nTrials_struct.odd = nTrials_struct.odd + mod(trialNum,2);
nTrials_struct.even = nTrials_struct.even + mod(trialNum-1,2);
end

function nTrials_struct = struct_update_map(trialNum,nTrials_struct)
% Add 1 on even and odd trials respectively
keyboard
nTrials_struct.odd = nTrials_struct.odd + mod(trialNum,2);
nTrials_struct.even = nTrials_struct.even + mod(trialNum-1,2);
end








