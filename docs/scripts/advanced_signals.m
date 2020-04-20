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
% likely lead to unintended behaviour.  Retrieving the value this was is
% akin to removing something from a factory conveyor belt: once retrieved,
% the state is fixed and will no longer change.

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

%% Subscriptable Origin Signals
% SubscriptableOriginSignals are similar to those returned by the
% |subscriptable| method but with ability to assign values.  A
% subscriptable origin signal can be created with the |subscriptableOrigin|
% of |sig.Net|.  The underlying value of a subscriptable origin signal is a
% struct and each time a value is assigned via subscripts, the field is
% modified in the underlying struct.

net = sig.Net;
S = net.subscriptableOrigin('subscriptable');
% Assign some values
S.one = 1;
S.two = net.origin('two');

%%%
% With each new field assigned, it is added to an underlying struct object.
% As you can see signals may be assigned to fields also.  In fact assigning
% this way is very similar to directly assigning to a struct:
%
%  S.Node.CurrValue
% 
%  ans = 
% 
%    struct with fields:
% 
%      one: 1
%      two: [1×1 sig.node.OriginSignal]
%
% Regardless of a field's value or existence, referencing a field will
% return a Signal.  Once a field has been referenced, each time that field
% is assigned a value the derived signal will update with that value.
% *NB*: If the field is assigned before being referenced then its current
% value will be undefined:

h = [... % Print the value class when S updates
  S.one.onValue(@(v)fprintf('S.one is a ''%s''\n',class(v))), ...
  S.two.onValue(@(v)fprintf('S.two is a ''%s''\n',class(v))), ...
  S.three.onValue(@(v)fprintf('S.three is a ''%s''\n',class(v)))];

S.two = net.origin('two');
S.three = S.two * 4;

clear h
%%%
%    S.one is a 'double'
%    S.two is a 'sig.node.OriginSignal'
%
%    S.one is a 'double'
%    S.two is a 'sig.node.OriginSignal'
%    S.three is a 'sig.node.Signal'
%
% *NB*: Each time any field is assigned a value, all derived signals will
% update, even if they're referencing a different field.  Also note that
% if a field is assigned a signal, the signal derived will have a signal
% object as its current value:
field = S.two;
field.Node.CurrValue % Currently empty

S.two = net.origin('two'); % Assign a signal
field.Node.CurrValue % an OriginSignal

%%%
% To get the value of the signal, rather than the signal itself, you can
% use the |flatten| method on the derived signal or |flattenStruct| on the
% subscriptable origin signal itself (more details later):
field = S.two.flatten();
flat = S.flattenStruct();
S.two = net.origin('two'); % Assign a signal
field.Node.CurrValue % empty
flat.Node.CurrValue.two % empty

%%%
% A struct can be assigned all at once using the |post| method:
net = sig.Net;
S = net.subscriptableOrigin('subscriptable');
a = S.a; % Signal with the value of field 'a'
post(S, struct('a', 1, 'b', 2))

a.Node.CurrValue % 1
%%%
% *NB*: The dot syntax with the |post| method will not work here as it is
% ambiguous:
S.post(struct('a', 1, 'b', 2)) % Doesn't work as expected

%%%
% What is the difference between a SubscriptableOriginSignal and a
% subscriptable OriginSignal? With the former, you can do subscripted
% assignment; with the latter you can only assign values with post:
s = net.origin('structSig');
S = s.subscriptable(); % Returns SubscriptableSignal
a = S.a; % Signal with the value of field 'a'

s.post(struct('a', 1, 'b', 2));
a.Node.CurrValue % 1

S.a = 2 % ERROR Unrecognized property 'a' for class 'sig.node.SubscriptableSignal'.
s.a = 2 % ERROR Unrecognized property 'a' for class 'sig.node.OriginSignal'.
%%%
% Also deep (i.e. 'multi-level') dot syntax subscripted references are not
% possible with a plain SubscriptableSignal, but are with
% SubscriptableOriginSignals.  Note however that unlike with first-level
% subscripting, an error will be thrown if the nested field does not exist.
net = sig.Net;
S = net.subscriptableOrigin('subscriptable');
s = struct('a', struct('b', struct('c', pi)));
a = S.a.b.c;

h = output(a);
post(S,s) % 3.1416


%%%
% SubscriptableOriginSignals are used primarily for parameterizing visual
% stimuli, for example it is returned by |vis.grating|.

%% flattenStruct
% The |flattenStruct| method of SubscriptableOriginSignals returns a signal
% whose value is a struct where any field values that were signals objects
% are replaced by the current values of those signals.  The signal returned
% by this method is a standard non-subscriptable signal and therefore
% cannot have values assigned.  Signals can be derived from this flattend
% struct signal by calling the |subscriptable| field...
net = sig.Net;
a = net.origin('a'); % a Signal
S = net.subscriptableOrigin('subscriptable'); % a SubsciptableOriginSignal
flat = S.flattenStruct; % a flattened signal that will hold a struct
flat_sub = flat.subscriptable; % a SubscriptableSignal
A = flat_sub.A; % Should hold the value of 'a'

S.A = a; % assign signal to subscriptable origin signal
a.post(5); % post a value
flat.Node.CurrValue % struct with fields A: 5
A.Node.CurrValue % 5

%%%
% Note that as usual the order is important as signals in general will only
% take a value at the time their inputs update, therefore if we created
% 'flat' after posting to 'a', the value of 'flat' would be empty because
% the update happened before 'flat' existed.
%
% The flattened signal will update whenever a field is updated in the
% parent signal.  There is currently a bug where the flattened signal will
% update even when not all of the field values have a current value.  This
% will change in the future, however for now you can use the following to
% ensure that flattened signal updates only when all fields have values:
toColumn = @(A)A(:);
isInitialized = @(l)~any(toColumn(cellfun('isempty', struct2cell(l))));
flat = S.flattenStruct.filter(isInitialized);
% In more recent version of MATLAB:
isInitialized = @(l)~any(cellfun('isempty', struct2cell(l)), 'all');
flat = S.flattenStruct.filter(isInitialized);

%% flatten
% The |flatten| method is useful for when you have a signal that is itself
% holding a signal object.  Calling |flatten| on this will return a signal
% that updates with the underlying value
net = sig.Net;
S = net.subscriptableOrigin('subscriptable'); % Create subscriptable
sig = net.origin('signal'); % Some example signal
sig.post(pi); % Give it a value

a = S.field; % Derive a new signal from a field
a_flat = S.field.flatten(); % Derive a new signal and flatten it

% Display the class of 'a' and 'a_flat' signals
h = [a.onValue(@(v)fprintf('a is a ''%s''\n',class(v))), ...
  a_flat.onValue(@(v)fprintf('a_flat is a ''%s''\n',class(v)))];

S.field = 12; % Assign a double to field
S.field = sig; % Now see difference when we assign a signal
%%%
%    a is a 'double'
%    a_flat is a 'double'
%
%    a is a 'sig.node.OriginSignal'
%    a_flat is a 'double'
%
% *NB*: Flatten only works over one level of nesting, that is you can't
% flatten a signal that holds a signal that holds a signal.

%% fromUIEvent
% The |fromUIEvent| method of |sig.Net| will return a Signal that updates
% each time a UI element callback is triggered.  A
% SubscriptableOriginSignal is returned whose fields are those of the
% event.EventData object returned by the source object:

% Create a signal of WindowKeyPressFcn events from the figure
figh = figure; net = sig.Net;
keyPresses = net.fromUIEvent(figh, 'WindowKeyPressFcn'); 
h = output(keyPresses.Key); % Output key name

%%%
% This method is useful for creating experiments outside of the Signals
% Experiment Framework that require interaction with a GUI.  Any MATLAB
% handle property ending in 'Fcn' may be made intoto a Signal, and more
% broadly anything that takes a callback function with the (source, event)
% signature.

%% onValue
% We saw above how to listen to UI events with Signals, however sometimes
% we also need to set UI properties with a Signal or more broadly, call a
% function with a Signal's value without assigning an output.  The
% |onValue| Signal method takes a function handle that will be called with
% the Signal's value each time it updates.  Any output of this function
% handle is discarded (to keep it, use |map| instead).  
%
% The method itself returns a TidyHandle which must be kept in scope for
% the function handle to be called.  In other words, when the TidyHandle is
% cleared from the workspace, the on value callback no longer occurs, much
% like with a regular listener handle.

% Example: Set the figure background colour each time a signal updates:
f = figure;
net = sig.Net;
s = net.origin('colour');
h = s.onValue(@(c) set(f, 'Color', c));
s.post('w') % Set colour to white

%%%
% For an example of how to interact with plots and UI elements in an
% experiment, see |docs\examples\ringach98.m|.

%% Implementing new Signal methods
% Below is some tips on developing Signals further.  The most common and
% simplest extention of Signals is overloading a builtin MATLAB function to
% work with Signals without having to use |map|.  This makes code more
% readable and intuitive. Second, you may want to add a 'functional' method
% similar to |scan| and |keepWhen|.  There are a number of ways to
% implement such a function and we'll go into each in order of increasing
% performance and descending ease.
%
% If you are adding a method that returns one Signal based on one or more
% others, it should generally be added to both the |sig.node.Signal| class,
% the |sig.Signal| abstract class, and the |sig.VoidSignal| class.

%%% Overloading a MATLAB function
% As mentioned above, overloading MATLAB functions makes your expDef more
% readable as you can do away with the |map| method.  Although there is no
% limit to how many methods you can add to Signals, it's probably not worth
% the effort for functions that are very specific or rarely used, however
% feel free to add any that you think are useful.
%
% Below is a checklist of things to do when adding a function:
% 
% # Look up some information about the builtin function before adding it.
% If it is a relatively new function (e.g. introduced in the last version
% of MATLAB) then add a MATLAB version check to the Signals method:
% |assert(verLessThan('matlab','9.7'), 'matlab version 9.7 required')|.  If
% you're planning on adding a number of functions from an optional toolbox
% (e.g. the Financial Toolbox), consider adding them to a seperate class
% (see note 8).
% # The method should be added to |sig.Signal| and should have the same
% name and signature as the function you're implementing.  
% # Using other methods as a guide implement your function by calling
% |map|, |map2| or |mapn| and returning the output. You must provide a
% format specification string to |map|.
% # Add documentation to the function.  This doesn't have to be as in-depth
% as the built in one as users will know to check there.  Make sure to
% mention any differences between the overloaded method and the original
% function, especially if there are differences in inputs.
% # Add a test to |tests/Signals_test.m|. 
% # Add the method to |sig.VoidSignal|.  The method signature must be the
% same as the one in |sig.Signal|. It should return the first
% input only.

%%% Creating a method with current methods
% The simplest way of implementing a method is to create the method using
% some combination of current methods. For example the |buffer| method
% simply chains |bufferUpTo| and |keepWhen|.  Similarly, if you come up
% with a useful scan function, consider making it into a method.  Scan
% functions can be added to the |+sig.scan| package.  These can be normal
% functions such as |sig.scan.lastTrue| or high-order functions such as
% |sig.scan.quiescienceWatch|.  The below curried function was how |buffer|
% was implemented before it was implemented as a transfer function:
%
%   function f = buffering(maxSamples)
%   %SIG.SCAN.BUFFERING Implement buffering with scan
%   %   Returns a function which grows an array up to the size of
%   %   'maxSamples'.
% 
%   f = @buffer;
% 
%     function buff = buffer(buff, val)
%       if size(buff, 2) == maxSamples
%         buff = cat(2, buff(:,2:end), val);
%       else
%         buff = [buff val];
%       end
%     end
% 
%   end
%
% When adding a new method be sure to add full documentation and a test to
% |tests/Signals_test.m|.  Additionally the format specification string may
% be changed.  Once you've added the method to |sig.node.Signal|, it should
% be added to |sig.VoidSignal| also (see above section).

%%% Creating a transfer function
% Implementing methods with existing Signals, however implementing your
% method as a transfer function will improve performance.  Transfer
% functions are called directly by the C code when any input signal
% updates, thus reducing the overhead.
%
% Below are a list of things to do:
% 
% # Create a function in the |+sig.transfer| package and name it the same
% as the Signals method that you will implement.  The function must take
% the following as inputs: network id, inputs node id(s), output node id, a
% method-specific arg.  These inputs must be in the signature even if
% they're not required for the operation.  The output args must be the
% output value and a flag indicating whether the value is to be set.  In
% general the set flag should be false when the one or more of the inputs
% don't have a value set. The input node id that triggered the function
% call will have a current working value, the others will either have a
% current value set or no values.  Take a look at the other transfer
% functions to get an idea of the logic.  The simplest transfer function is
% |sig.transfer.identity|.
% # Add the method to |sig.node.Signal|.  The method should call
% |sig.node.Signal/applyTransferFunction| with the name of the transfer
% function you've created.  It should also set a format specification
% string, which will be passed to |sprintf| when getting the signal's Name
% property.
% # Be sure to add documentation to both the method and the transfer
% function, and ideally the <./using_signals.html using signals> guide.
% # Add the method to |sig.Signal| and |sig.VoidSignal|.
% # Create a test in |tests/Signals_test|.  This test should test both the
% transfer function and the method.

%%% Implementing in mexnet
% The final way to implement a signals method is to add the operation to
% the C code.  This is by far the highest performance implementation and is
% ideal for implementing operations on basic datatypes.  The C code can
% make use of MATLAB's MEX library to do things like matrix arithmetic,
% error handling and type checking.  Below are some steps to implementing
% an operation in mexnet:
%
% # Add your operation to the |transfer| function of
% |mexnet-vs\network\network.c|.  The transfer function contains a switch
% for the op code called by Signals.  Add a new op code case and add a
% call to your transfer function there.  
% # Recompile the MEX code.
% # Add your new op code to the switch block in
% |sig.node.transfererOpCode|.  This is called by the constructor
% |sig.node.Node| to return the op code, which is then passed to mexnet.
% The transfer function name can be anything, as it is only used as a key
% to retrieve the op code.
% # Add your new method to |sig.node.Signal|.  This should call
% |sig.node.Signal/applyTransferFunction| with the name you added to the
% switch block in transfererOpCode.  It should also add a format
% specification string.  
% # Finally, add documentation and tests.  Ideally, also add a
% demonstration of your method to the <./using_signals.html using signals>
% guide.

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

%%%
% 8. Adding toolbox specific methods to a mixin class will allow them to be
% added by the constructor only if the toolbox in question is installed.
% See |fun.Mappable|.

%% FAQ
%%% I'm seeing '-1 is not a valid network id' in the command prompt
% Currently there is a limit of 10 networks at any one time.  If you see
% this you most likely have more than 10 in your workspace.  Run clear all
% and then re-run your code.

%% Etc.
% Author: Miles Wells
%
% v0.0.2

%#ok<*NASGU,*NOPTS>