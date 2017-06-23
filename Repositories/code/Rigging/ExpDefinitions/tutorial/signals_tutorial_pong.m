function signals_tutorial_pong(t, events, pars, visStim, inputs, outputs, audio)
% 
% Setting up a simple version of pong is a great way to illustrate a lot of
% the common methods and strategies for setting up a Signals protocol. 
% 
% Create a wheel-controlled player paddle, a computer-controlled paddle
% which moves towards the ball, and a ball which moves around the screen
% and bounces off walls and paddles but resets when it gets missed by a
% paddle. 
%
%
% Some caution about a problem you'll run into:
% 
% This will bring up a really important issue of signals: truly
% co-dependent signals are impossible, because if signal1 and signal2 need
% information from each other, but you can only define one at a time, you
% cannot write 
% signal1 = f(signal2);
% signal2 = f(signal1); 
% because in the first line signal2 is not defined yet. 
% 
% You'll run into this when you try to make the computer paddle move
% towards the ball (computer paddle needs to know where the ball is to
% update it's position) while the ball needs to bounce off of the paddle
% (the ball needs to know where the paddle is to update it's position).
% This is solved by updating co-dependent parameters simultaneously using
% the scan function. In other words, try keeping all computer-controlled
% parameters in a structure which is intialized (seeded) with certain
% values and then updated via scan. Feed relevant player-data into this by
% having it be the source signal for the scan.
%
% I've found that the easiest way to think about setting up protocols is in
% three aspects: 1) define the strucure of the game, 2) define a
% player-controlled aspect of the game, 3) feed the player-controlled
% aspect of the game into something that updates player-controlled aspects
% of the game at events defined by the game structure. 
%
% In ChoiceWorld, for instance, you can only have performance-driven
% updating of trial conditions if the structure of the game is agnostic to
% whether a trial was a hit or a miss. This is because you want to define
% task conditions to update on a response, which means that the update has
% to be defined after defining what a response is, which means a response
% has to be defined independent of what task condition is.




