%% Advanced Signals
% This guide shows you some of the methods available for use outside of the
% Signals Experiment Framework (i.e. outside of an experiment definition
% function).  The intention is to explain the machinary of Signals and to
% demonstrate how to create experiments with a custom UI.  After reading
% this you should have a near complete understanding of how Signals works
% and thus how to create any experiment.

%% Network architecture
% Every signal is part of a network, managed through a |sig.Net| object.
% The network object holds all the ids of all the signals' nodes(1).

% Every signal has an underlying node; a |sig.node.Node| object that
% contains a number of important properties:
% * Net: a handle to the parent network (a sig.Net object)
% * Inputs: an array of input nodes (other sig.node.Node objects)
% * Id: an integer node ID used by the low level C code
% * NetId: an integer ID for the parent network, used by the low level C code
% * CurrValue: the current value that the node holds

net = sig.Net; % Create a new signals network

%% Origin signals
% An origin signal is a special sub-class of the |sig.node.Signal| class
% whose value can be updated directly using the |post| method. The function
% call for creating an origin signal takes two inputs: the parent network 
% and optionally, a string identifier.
%
% These origin signals are the input nodes to the reactive network. All
% other signals are either directly or indirectly dependent on origin
% signals. Origin signals can take values of any type, as demonstrated 
% below.
%
% In the context of a Signals Experiment, the origin signals would be the
% timing signal and signals representing hardware devices (a wheel, lever,
% keyboard, computer mouse, etc...).  These origin Signals are defined
% outside of your experiment definition function (expDef) and are the input
% variables. Your expDef defines the mapping of these input origin
% signals to various hardware outputs (more on this later):
%
%   inputs --> |          | -->               --> |\ /| --> 
%          --> | (expDef) | -->               --> |-X-| -->
%          --> |          | --> outputs       --> |/ \| --> outputs
%
% You can post values to an origin Signal by using the |post| method.  This
% is not possible with other classes of Signals as their values instead
% depend on the values of their input nodes. 
%
% It is worth noting that every Signal has a |Name| property which may be
% set manually or be set based on its inputs.  The name of a Signal may be
% used by visualization functions to describe its functional relationship
% within the network.  The name property of an origin Signal is set as its
% second input.  Signals are handle objects and therefore may be assigned
% to any variable name.  Hence there are two means to identify a Signal:
% it's true name (the string held in the Name property) and the name of the
% variable or variables to which it is assigned. Below a Signal whose name
% is 'input' is created and assigned to the variable `originSignal`.  Two
% values are posted to it, first a double, then a char array:

originSignal = net.origin('input'); % Create an origin signal
originSignal.Node.CurrValue % The current value is empty

post(originSignal, 21) % Post a new value to originSignal
originSignal.Node.CurrValue % The current value is now 21

post(originSignal, 'hello') % Post a new value to originSignal
originSignal.Node.CurrValue % The current value is now 'hello'

% You can see there are two names for this signal.  The string identifier
% ('input') is the Signal object's name, stored in the Name property:
disp(originSignal.Name)

%%%
% Any Signals derived from this will include this identifier in their Name
% property (an example will follow shortly).  The variable name
% 'originSignal' is simply a handle to the Signal object and can be changed
% or cleared without affecting the object it references(3).
%
% Although the value is stored in the Node's CurrValue field, it is not
% intended that you use this field directly.  The purpose of using a
% reactive network is that callbacks will access these values automatically
% if and when they change.  Accessing this property directly will most
% likely lead to unintended behaviour.

%% Demonstration on sig.Signal/output() method
% The output method is a useful function for understanding the relationship
% between signals.  It simply displays a signal's output each time it takes
% a value.  The output method returns an object of the class |TidyHandle|,
% which is like a normal listener handle, however when its lifecyle ends
% it will delete itself.  What this means is that when the handle is no
% longer referenced anywhere (i.e. stored as a variable), the callback will
% no longer function.
net = sig.Net; % Create a new signals network
clc % Clear previous output for clarity

simpleSignal = net.origin('simpleSignal');
h = output(simpleSignal);
class(h)

simpleSignal.post(false) % Value printed to the command window
simpleSignal.post(true)

%%%
% The output method can't be used within an expDef function. It should
% instead be used only for playing around with Signals in the command
% prompt.

%% Timing in signals
% Most experiments require things to occur at specific times.  This can be
% achieved by keeping a timing signal that has a clock value posted to it
% periodically.  In the following example, we will create a 'time' signal
% that takes the value returned by 'now' every second.  We achieve this
% with a fixed-rate timer.  In the context of a Signals Experiment, the
% time signal has a time in seconds from the experiment start posted every
% iteration of a while loop.  Read through the below section then run it as
% a block by pressing ctrl + enter.

net = sig.Net; % Create a new signals network
clc % Clear previous output for clarity
time = net.origin('t'); % Create a time signal
% NB: The onValue method is very similar to the output method, but allows
% you to define any callback function to be called each time the signal
% takes a value (so long as the handle is still around).  Here we are using
% it to display the formatted value of our 't' signal.  Again, the output
% and onValue methods are not suitable for use within an experiment as the
% handle is deleted.
handle = time.onValue(@(t)fprintf('%.3f sec\n', t*10e4));

t0 = now; % Record current time
% Create a timer that posts the time since t0 to the 'time' signal, at a
% given rate given by 'frequency'.
frequency = 1; % Update the timer every second
tmr = timer('TimerFcn', @(~,~)post(time, now-t0),...
    'ExecutionMode', 'fixedrate', 'Period', 1/frequency);
start(tmr) % Start the timer
disp('Timer started')
% ...Because of the output method, we are seeing the value of the time
% signal displayed every second
pause(3)

%%% Now let's increase the frequency to 10 ms...
stop(tmr) % Stop the timer
frequency = 1e-2; % Frequency now 10x higher
disp('Let''s increase the timer frequency to 10 times per second...')
set(tmr, 'Period', frequency)
pause(1) % Ready... steady... go!
start(tmr)
pause(3) % ...

%%% When we clear the handle, the value is no longer displayed
disp('Clearing the output TidyHandle')
clear handle
pause(1) % ...The values of the 'time' Signal are no longer displayed

%%% Due to the timer, the value of 'time' continues to update
fprintf('%.3f sec\n', time.Node.CurrValue*10e4)
pause(1)% ...
fprintf('%.3f sec\n', time.Node.CurrValue*10e4)
pause(1)

%%% When the timer is stopped, the value of 'time' is no longer updated
disp('Stopping timer');
stop(tmr)
pause(1)% ...
fprintf('%.3f sec\n', time.Node.CurrValue*10e4)
pause(1)% ...
fprintf('%.3f sec\n', time.Node.CurrValue*10e4)
pause(1)% ...
% Let's clear the variables
delete(tmr); clear tmr frequency t0 time

%% Timing 2 - Scheduling
% The net object contains an attribute called Schedule which stores a
% structure of node ids and their due time.  Each time the schedule is run
% using the method runSchedule, the nodes whose  TODO

net = sig.Net; % Create network
frequency = 10e-2; 
tmr = timer('TimerFcn', @(~,~)net.runSchedule,...
    'ExecutionMode', 'fixedrate', 'Period', frequency);
start(tmr) % Run schedule every 10 ms
s = net.origin('input'); % Input signal
delayedSig = s.delay(5); % New signal delayed by 5 sec
h = output(delayedSig); % Let's output its value
h(2) = delayedSig.onValue(@(~)toc); tic
delayedPost(s, pi, 5) % Post to input signal also delayed by 5 sec
disp('Delayed post of pi to input signal (5 seconds)')
% After creating a delayed post, an entry was added to the schedule
disp('Contents of Schedule: '); disp(net.Schedule) 
fprintf('Node id %s corresponds to ''%s'' signal\n\n', num2str(s.Node.Id), s.Node.Name)
% ...
disp('... 5 seconds later...'); pause(5.1)
% ...
% ... a second entry was added to the schedule, this time for 'delayedSig'.
% This was added to the schedule as soon as the value of pi was posted to
% our 'input' signal.
disp('Contents of Schedule: '); disp(net.Schedule) 
fprintf('Node id %s corresponds to ''%s'' signal\n\n',...
    num2str(net.Schedule.nodeid), delayedSig.Node.Name)
% ...
disp('... another 5 seconds later...'); pause(5.1)
% ...
% 3.14
stop(tmr); delete(tmr); clear tmr s frequency h delayedSig

%% Demonstration of sig.Signal/log() method
% Sometimes you want the values of a signal to be logged and timestamped.
% The log method returns a signal that carries a structure with the fields
% 'time' and 'value'.  Log takes two inputs: the signal to be logged and
% an optional clock function to use for the timestamps.  The default clock
% function is GetSecs, a PsychToolbox MEX function that returns the most
% reliable system time available.

net = sig.Net; % Create our network
simpleSignal = net.origin('simpleSignal'); % Create a simple signal to log
loggingSignal = simpleSignal.log(@now); % Log that signal using MATLAB's now function
loggingSignal.onValue(@(a)disp(toStr(a))); % Each time our loggingSignal takes a new value, let's display it

simpleSignal.post(3)
pause(1); fprintf('\n\n')

simpleSignal.post(8)
pause(1); fprintf('\n\n')

simpleSignal.post(false)
pause(1); fprintf('\n\n')

simpleSignal.post('foo')

%% Logging signals in a registry
% In order to simplify things, one can create a registry which will hold
% the logs of all signals added to it.  When the experiment is over, the
% registry can return all the logged values in the timestampes optionally
% offset to another clock.  This can be useful for returning values in
% seconds since the start of the experiment
net = sig.Net; % Create our network
t0 = now; % Let's use this as our example reference time
events = sig.Registry(@now); % Create our registy
simpleSignal = net.origin('simpleSignal'); % Create a simple signal to log
events.signalA = simpleSignal^2; % Log a new signal that takes the second power of the input signal
events.signalB = simpleSignal.lag(2); % Log another signal that takes the last but one value of the input signal
simpleSignal.post(3) % Post some values to the input signal
simpleSignal.post(3)
simpleSignal.post(8)

s = logs(events, t0); % Return our logged signals as a structure
disp(s)

%% Visual stimuli
[t, setgraphic] = sig.playgroundPTB;
grating = vis.grating(t);    % we want a gabor grating patch
grating.phase = 2*pi*t*3; % with it's phase cycling at 3Hz
grating.show = true;

elements = StructRef;
elements.grating = grating;

setgraphic(elements);

%% Notes
% 1. The sig.Net class itself does not store the nodes in its properties,
% however the underlying mexnet does.  This network is created by calling
% the MEX function createNetwork.  New nodes are created by calling the MEX
% function addNode.  This is done for you in the sig.Net and sig.node.Node
% class constructors.
%
% 2. Two such examples of visualization functions are introduced later,
% |sig.test.plot| and |sig.test.timeplot|.  
%
% 3. Signals objects that are entirely out of scope are cleaned up by
% MATLAB and the underlying C code.  That is, if a Signal is created,
% assigned to a variable, and that variable is cleared then the underlying
% node is deleted if there exist no dependent Signals:
net = sig.Net;
x = net.origin('orphan');
networkInfo(net.Id) % Net with 1/4000 active nodes
clear x
networkInfo(net.Id) % Net with 0/4000 active nodes

%%%
% If the Signal is used by another node that is still in scope, then it
% will not be cleaned up:
x = net.origin('x');
y = x + 2; % y depends of two nodes: 'x' and '2' (a root node)
networkInfo(net.Id) % Net with 3/4000 active nodes
clear x % After clearing the handle 'x', the node is still in the network
networkInfo(net.Id) % Net with 3/4000 active nodes
% The node still exists because another handle to it is stored in the
% Inputs property of the node 'y':
str = sprintf('Inputs to y: %s', strjoin(mapToCell(@(n)n.Name, [y.Node.DisplayInputs]), ', '));
disp(str)
disp(['y.Node.DisplayInputs(1) is a ' class(y.Node.DisplayInputs(1))])

%%%
% 4. The command window message '**net.delete**' simply indicates that a
% Signals network has been deleted, most likely as a result of a net object
% being cleared from the workspace.  The message '0 is not a valid network
% id' is nothing to worry about.  It is simply a result of an over-zealous
% cleanup proceedure in the underlying MEX code.  In future versions this
% will only show up when debugging.
%
% 5. Note that constants are in fact made into signals using the rootNode
% method.  These are nodes that only ever have one value.  There are often
% more nodes in a network than you might expect, for example the following
% line indicates there are at least 4 nodes in the network:
x = mod(floor(x), 1*2)

%%%
% These would be x, 2 (a root node), floor(x) and mod(floor(x), 2)
%
% 6. It should be noted here that you are responsible for handling
% potential problems that may arise from a Signal changing data type:
y = x*5;
x.post(2) % y = 10
x.post({'bad'}) % Undefined operator '*' for input arguments of type 'cell'

%%%
% Within a Signals Experiment this rarely is a problem as parameters may
% not change type, although you may still encounter issues, for example the
% below signal `evts.newTrial` holds the value `true` which must be
% typecast to an int or float before being used with randsample:
side = evts.newTrial.map(@(k)randsample([-1 1], int32(k)));

%%%
% The below line demonstrates how a signal can change type:
s = merge(str, int, mat);

%%%
% 7. Rule exceptions: merge and scan pars There are only two exceptions to
% this. 
%
% merge - a merge signal will take the value of the last updated input
% signal, even if not all of the inputs have taken a value.  To only take
% values once all are updated, use the at/then methods:
s = merge(a, b, c).at(map([a b c], true)); % map(true) for if a, b, c = 0

%%%
% scan - any signals passed into scan after the 'pars' named parameter
% do not cause the scan function to be re-evaluated when they update.  See
% section on scan above for more info.
s = a.scan(f, [], 'pars', b, c); % b and c values used in f when a updates

%% FAQ
%%% I'm seeing '-1 is not a valid network id' in the command prompt
% Currently there is a limit of 10 networks at any one time.  If you see
% this you most likely have more than 10 in your workspace.  Run clear all
% and then re-run your code.

%% Etc.

%#ok<*NASGU,*NOPTS>