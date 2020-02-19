%% Writing an experiment definition
% The purpose of this script is to introduce Signals and guide the reader
% towards programming in a less procedural way.  After reading this you
% should will be able to create the experiments you want in Signals, using
% the <glossary.html Signals Experiment Framework>.  The ai will greatly
% reduce the number of errors you will encounter while making your first
% experiment.  

%% Introduction
% The live script that accompanies this document can be found in
% |signals/docs/turorials/using_signals.m|.  This script allows you to run
% the blocks of code shown here and plot the values of signals live.  To
% run a block of code, click on the section of interest and press Ctrl +
% Enter.
%
% For the purposes of demonstration we can create signals using the
% |sig.test.create| function, however in you expDef you can only create new
% signals based on the function's inputs.  More on this later.
% 
%   function expDefFn(t, events, parameters, vs, inputs, outputs, audio)
%
% Example expDefs can be found in |signals/docs/examples|.
%
% The bracketed numbers throughout this script correspond to notes at the
% bottom of the file.  The notes provide extra details about Signals.
% Please report any errors as GitHub issues. Thanks!

%% What are signals?
% When writing an experiment definition (expDef), it's useful to think of
% signals as nodes in a network, where each node holds a value that is the
% result of passing its inputs through a function.  This network is
% 'reactive' in that whenever a node's input values changes, the node
% recalculates its own value.  In this way changes propergate through the
% network asynchronously.
% 
% <<./images/node_graph_phase.png>>
%
% The above node graph would be the result of writing the following:
t = sig.test.create; % returns a signal
phi = 2*pi*3*t; % a new signal, phi, that defines phase over time
%%
% Imagine the signal |t| was a clock signal whose value was a timestamp
% that constantly updated.  The signal |phi| then updates it's value
% every time |t| updates.  In this way you can express relationships
% between variables in an easy to read, mathematical way.  One of these
% variables happens to be time, which means you can define how variables
% change over time.  In the above example we have defined a temporal
% fequency in Hz (the value of |t| in your expDef is in seconds from
% experiment start).  This can then be applied to a visual stimulus
% property, as shown in the example expDef |driftingGrating.m|.

%% Relationships between signals
% Let's start to build a reactive network.  Most of MATLAB's elementary
% operators work with signals in the way you would expect, as demonstrated
% below.  You may type ctrl + enter to run this entire secion at once...
x = sig.test.sequence(-50:1:50, 0.05); % Create a sequence
a = 5; b = 2; c = 8; % Some constants to use in our equation
y = a*x^2 + b*x + c; % Define a quadratic relationship between x and y

% Let's call a little function that will show the relationship between our
% two signals.  The plot updates each time the two input Signals update:
ax = sig.test.plot(x,y,'b-');
xlim(ax, [-50 50]);
%%
% <<SignalsPrimer_01.png>>

%% Mathematical expressions 
% Signals allows a good degree of clarity in defining methematical
% equations, particularly those where time is a direct or indirect variable
%
%%% Example 1: cos(x * pi)
x = sig.test.sequence(0:0.1:10, 0.05); % Create a sequence
y = cos(x * pi);
sig.test.timeplot(x, y, 'mode', [0 2]); % Plot each variable against time
%%
% <<SignalsPrimer_02.png>>

%%
%%% Example 2: x -> degrees
% Let's imagine you needed a Signal that showed the angle of its input
% between 0 and 360 degrees:
x = sig.test.sequence(1:4:1080, 0.005); % Create a sequence
y = iff(x > 360, x - 360*floor(x/360), x); % More about conditionals later

sig.test.plot(x, y, 'b-');
xlim([0 1080]); ylim([0 360])
%%
% <<SignalsPrimer_03.png>>

%% Logical operations
% Note that the short circuit operators && and || are not implemented in
% Signals, always use & and | instead.
x = sig.test.sequence(1:15, 0.2); % Create a sequence
bool = x >= 5 & x < 10; 

ax = sig.test.plot(x, bool, 'bx');
xlim(ax, [0 15]), ylim(ax, [-1 2])
%%
% <<SignalsPrimer_04.png>>

%% mod, floor, ceil
% A simple example of using mod and floor natively with Signals:
x = sig.test.sequence(1:15, 0.2); % Create a sequence

even = mod(floor(x), 2) == 0;
odd = ~even;

sig.test.timeplot(x, even, odd, 'tWin', 1);
%%
% <<SignalsPrimer_05.png>>

%% Arrays
% You can create numerical arrays and matricies with Signals in an
% intuitive way.  *NB* : Whenever you perform an operation on one or more
% Signals objects, always expect a new Signals object to be returned.  In
% the below example we create a 1x3 vector Signal, X, which is not an
% array of Signals but rather a Signal that represents a numrical array.
x = sig.test.sequence(1:5, 0.5); % Create a sequence
X = [x 2*x 3]; % Create an array from signal x
X_sz = size(X); % Reports the size of object's underlying value

ax = sig.test.timeplot(x, X, X_sz, 'tWin', 1);

%% Matrix arithmatic
Xt = X';
Y = X.^3 ./ 2;

% For a full list see doc sig.Signal.

%% A note about Signals variables
% Signals are objects that constantly update their values each time the
% Signals they depend on update.  A Signal will not a take a value post-hoc
% after a newly defined Signal takes a value.  Consider the following:
net = sig.Net;
x = net.origin('x');
x.post(5)

x.Node.CurrValue % 5
y = x^2;
y.Node.CurrValue % empty; does not evalute 5^2
x.post(3)
y.Node.CurrValue % 9

% In the context of a Signals Experiment, the experiment definition
% function is run once to set up all Signals, before any inputs are posted
% into the network.  More on this later.

% Likewise if you re-define a Signal, any previous Signals will continue
% using the old values and any future Signals will use the new values,
% regardless of whether the variable name is the same.  Remember that
% variable names are simply object handles so clearing or reassigning those
% variable names doesn't necessarily change the underlying object:
y = x^2;
a = y + 2;
y = x^3; % A new Signal object is assigned to the variable y
b = y + 2;

% Looking at the name of your Signals may help you here
% TODO add node digraph
y.Name
a.Name % *(x^3 + 2)
b.Name

%% Signals can derive from multiple signals
% Signals can be defined from any number of other signals, as well as by
% constants(5). Mathematically, Signals can be viewed as variables which,
% any time they take a new value, cause any dependent equations to be
% re-evaluated.

% Create some origin signals to post to
x = net.origin('x'); 
a = net.origin('a');
b = net.origin('b');
c = net.origin('c');

y = a*x^2 + b*x + c;

sig.test.timeplot(x, a, b, c, y);

x.post(1), pause(1)
a.post(pi), pause(1)
b.post(3), pause(1)
c.post(8), pause(1)

a.post(5)


%% Complicated expressions
% Below are some examples of more complex mathematical expressions that can
% be defined in Signals.  Note that |mapn| simply maps the signal values
% through an arbitrary MATLAB function.  On on this later.

%%% Example 1: Upper bound
% $upper bound = \frac{\max(\{|a|,|b|,|c|\})}{|a|} \times  \left(1 +
% \frac{\sqrt{5}}{2}\right)$
%
[a, b, c] = sig.test.create('names', {'a','b','c'}); 

upperBound = max([abs(a), abs(b), abs(c)]) / abs(a) * (1 + sqrt(5))/2;
disp(upperBound.Name)
%%
%  [|a| |b| |c|].map(@max)/|a|*3.2361/2

%%% Example 2: Gabor
% Let's reproduce the equation for generating a Gabor patch, i.e convolving
% a sinusoid with a 2D Gaussian function: 
%
% $G(x,y;\lambda, \theta, \psi, \sigma) = \exp\left(-\frac{x'^2+
% y'^2}{2\sigma^2}\right)\exp\left(2\pi\frac{x'}{\lambda}+\psi\right)$
%
% Where:
%
% $x' = x cos(\theta) + y sin(\theta)$
%
% $y' = -x sin(\theta) + y cos(\theta)$

% Create some input signals for this demonstration.  xx and yy are vectors
% of the x and y coordinates of the Gabor, where (0,0) is the centre of the
% Gabor patch
[xx, yy, theta, sigma, lambda, phi] = sig.test.create(); 

% Create a 2-D grid coordinates based on the coordinates contained in
% vectors xx and yy
[X, Y] = xx.mapn(yy, @meshgrid);

% Calculate the rotated x and y coordinates for the Gabor filter.  The
% rotated coordinates allow us to define an elliptical window rotated by
% theta(1)
Xe = X.*cos(theta(1)) + Y.*sin(theta(1));
Ye = Y.*cos(theta(1)) - X.*sin(theta(1));
% And the rotated coordinates for the grating
Xc = X.*cos(theta(2) - pi/2) + Y.*sin(theta(2) - pi/2);

% Define our Gaussian function
gauss = exp(-Xe.^2./(2*sigma(1)^2) + -Ye.^2./(2*sigma(2)^2));
% The grating function scaled by the wavelegth and translated by the phase
grate = cos( 2*pi*Xc./lambda + phi );
G = gauss.*grate; % Convolve the two functions

% Rename a few of our signals
theta.Name = char(hex2dec('03bb')); % Orientation
sigma.Name = char(hex2dec('03B8')); % Standard deviation of Gaussian envelope
lambda.Name = char(hex2dec('03C3'));% Wavelength
phi.Name = char(hex2dec('03C6')); % Phase offset
Xe.Name = 'x'''; Ye.Name = 'y'''; % Rename to X' and Y'
X.Name = 'x'; Y.Name = 'y'; % Rename to x and y

% And print their names to the command window
fprintf([...
  'Gaussian equation: %s\n',...
  'Grating equation: %s\n',...
  'Convolved: %s\n'],...
  gauss.Name, grate.Name, G.Name)
%%
%  Gaussian equation: (-x'.^2./2*?(1)^2 + -y'.^2./2*?(2)^2).map(@exp)
%  Grating equation: cos((6.2832*(x.*cos((?(2) - 1.5708)) + y.*sin((?(2) - 1.5708)))./? + ?))
%  Convolved: (-x'.^2./2*?(1)^2 + -y'.^2./2*?(2)^2).map(@exp).*cos((6.2832*(x.*cos((?(2) - 1.5708)) + y.*sin((?(2) - 1.5708)))./? + ?))

%% Etc.
%#ok<*NASGU> 