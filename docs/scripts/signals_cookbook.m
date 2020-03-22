%% The Signals Cookbook
% This document will contain some solutions to common problems in Signals,
% and some clever bits of code that you can adapt for your own experiments.

%% Trial states
% Here's how you work on data collected over a trial and reset this history
% on new trials.

% For this demonstration we create two signals, 'x' (e.g. an input device),
% and a 'newTrial' event.
[x, newTrial] = sig.test.create;

% Each new trial update the seed with an empty array, thus reinitializing
% our accumulated array.
seed = newTrial.then([]);
trialSamps = x.scan(@horzcat, seed);

%%%
% A second slightly more memory controlled way of doing this is by using a
% buffer signal.  Behind the scenes this initializes an array of a given
% size (in this example 1000 elements).  We then simply create a signal to
% keep track of the current buffer index and slice the array at a different
% point each trial.  You can pick any suffciently large number to initialze
% the buffer with.  It should be larger than the number of samples you
% expect to collect per trial.
n = 1000; % Number of spaces in the buffer
hist = x.bufferUpTo(n); % Collect values of x into buffer
j = mod(x.map(1).scan(@plus,0), n); % Current index in buffer
i = j.at(newTrial); % Index at new trial
slice = iff(i < j, i:j, [i:n 1:j]); % deal with wrap-arounds
trialSamps = hist(slice);

%%%
% Note that it's usually possible to avoid having to do this accumuate a
% heuristic or summary statistic that can be rest each trial.  For instance
% if 'x' in the above example was a rotary encoder and you need the total
% displacement per trial, you could do this without storing the individual
% values in a buffer:

% Trial displacement is the difference between current position and
% position at trial start
displacement = x - x.at(newTrial);

% Trial distance is the sum of absolute position changes, resetting to 0
% at trial start
distance = x.delta().abs().scan(@plus, newTrial.then(0));

%%
[start, choice, amt] = sig.test.create;
nPots = 3;
pots = cell(1,3);
for n = 1:nPots
  pots{n} = start.map(@(~) randi(1000));
end

f = @minus;

chosenPot = choice.selectFrom(pots{:}); % when i == 1, y = A, etc.
choiceHistory = choice.bufferUpTo(1000);

sum(choiceHistory == choice) * amt;


%% Etc.
% Author: Miles Wells
%
% v0.0.1
%
% See also <./using_signals.html Using Signals>.

%#ok<*NASGU>