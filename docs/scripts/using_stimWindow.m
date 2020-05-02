%% Using the Window object
% Let's check the Window object is set up correctly and explore some of the
% methods...

%% Loading a stimWindow
% The stimWindow can be instantiated from scratch or loaded from the rig
% hardware file using |hw.devices|.  For more info, see the
% <./hardware_config.html hardware config guide>.

% Create a fresh stimWindow object:
stimWindow = hw.ptb.Window;

% Load a pre-configured window from your hardware file
stimWindow = getOr(hw.devices, 'stimWindow');

%% Setting the background colour
stimWindow.open() % Open the window
stimWindow.BackgroundColour = stimWindow.Green; % Change the background
stimWindow.flip(); % Whoa!

%% Displaying a Gabor patch
% Make a texture and draw it to the screen with |makeTexture| and
% |drawTexture| Let's make a Gabor patch as an example:
sz = 1000; % size of texture matrix
[xx, yy] = deal(linspace(-sz/2,sz/2,sz)');
phi = 2*pi*rand; % randomised cosine phase
sigma = 100; % size of Gaussian window
thetaCos = pi/2; % grating orientation
lambda = 100; % spatial frequency
targetImg = vis.gabor(xx, yy, sigma, sigma, lambda, 0, thetaCos, phi);
blankImg = repmat(stimWindow.Gray, [size(targetImg), 1]);
targetImg = repmat(targetImg, [1 1 3]); % replicate three colour channels
targetImg = round(blankImg.*(1 + targetImg));
targetImg = min(max(targetImg, 0), 255); % Rescale values to 0-255

% Convert the Gabor image to an OpenGL texture and load into buffer.
% For more info: Screen MakeTexture?, Screen PreloadTextures?
tex = stimWindow.makeTexture(round(targetImg));
% Draw the texture into window (More info: Screen DrawTexture?)
stimWindow.drawTexture(tex)
% Flip the buffer:
stimWindow.flip;

%% Clearing the window
% To clear the window, the use the |clear| method:
stimWindow.clear % Re-draw background colour
stimWindow.flip; % Flip to screen

%% Drawing text to the screen
% Drawing text to the screen can be done with the |drawText| method:
[x, y] = deal('center'); % Render the text to the center
[nx, ny] = stimWindow.drawText('Hello World', x, y, stimWindow.Red);
stimWindow.flip;

% The nx and ny outputs may be used again as inputs to add to the text:
[nx, ny] = stimWindow.drawText('Hello World', x, y, stimWindow.Red);
stimWindow.drawText('! What''s up?', nx, ny, stimWindow.Red);
stimWindow.flip;

%% Closing a window
% Finally lets clear and close the window:
stimWindow.clear
stimWindow.close

%% Etc.
% Author: Miles Wells
%
% v1.1.4

%#ok<*ASGLU,*NASGU>