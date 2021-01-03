%% Path conflicts
% A frequent cause of errors is that MATLAB calls 'the wrong' function that
% has the same name as the intended one.  This is called shadowing and the
% precise file MATLAB uses depends on MATLAB's
% <https://uk.mathworks.com/help/matlab/matlab_prog/function-precedence-order.html
% function precedence order>.  
%
% For this reason you should be very careful in the way you use paths on
% shared rigs. Here is a list of things to avoid:
% 
% # Don't ever call savepath from your functions and more generally avoid
% changing the rig paths.
% # Avoid putting your functions in the userpath (usually
% |<User>\Documents\MATLAB|) because this folder is by default at the top
% of the MATLAB path list.
% # Avoid changing directory in your functions
% # Don't start an experiment before checking your current working
% directory.  
%
% Note that Rigbox doesn't need to be in any specific directory to work,
% and besides |addRigboxPaths|, no code will permanently change the working
% directory or search path.

%% Checking your working directory
% It's good idea to make sure your working directory is somewhere safe
% before starting your experiment.  To check you working directory type
% |pwd| into the command window. To change into MATLAB's default directory
% (|<User>\Documents\MATLAB|), call |cd(userpath)|.  To check which file is
% being used, call the function |which| with the name of the function your
% investigating, e.g. |which choiceWorld|.

%% Calling custom functions
% If changing paths, etc. is unavoidable, make sure you leave everything in
% the state it was in afterwards.  
%
% One way is to temporarily change directory using |onCleanup|, which will
% execute even if your function encounters an error:

origDir = pwd; % Get current working directory
mess = onCleanup(@() cd(origDir)); % When exiting the function, change back to original dir
cd(fullfile('my', 'path')) % Change directory to containing mySpecialFunction.m is
mySpecialFunction() % Call your function

%%%
% When returning, MATLAB clears all a function's variables, including
% `mess`, whose delete method calls the anonymous function |@()
% cd(origDir)|
%
% Another way is to use |fileFunction|, which temporarily adds the file to
% the MATLAB path, then removes it after the function is called.  This is
% useful if you need to call a custom function just once:

mySpecialFunction = fileFunction(['my' filesep 'path'], 'mySpecialFunction.m'); % Return function wrapper
% [...]
mySpecialFunction() % Call your function

%% When to add paths
% Changing directory and adding paths can affect performance as MATLAB has
% to rehash all its file and function caches.  If you're constantly calling
% a special function there are two things to consider. Your
% <./gloassay.html expDef> is run only twice per experiment so not being on
% the path doesn't really affect performance, and Rigbox deals with this
% for you.  However if in your expDef a function that is called with |scan|
% or |map| is changing the paths, consider refactoring your code, e.g.
% making whatever function you need to call a local function. Another
% option is to create a
% <https://uk.mathworks.com/help/matlab/matlab_oop/scoping-classes-with-packages.html
% MATLAB package>. That way your function is in its own namespace and you
% will most likely avoid these sorts of conflicts.  For example say I have
% a function called |ls| that I need to constantly call.  If I put it in
% |+john\ls.m| then I can add it to the paths and safely call it without
% worrying about conflicts:

addpath('+john') % Add this package to the search path
john.ls() % Call +john\ls.m
ls() % Call MATLAB's builtin ls

%% Reset on startup
% Another way to avoid these conflicts occuring over time is to reset your
% paths each time MATLAB starts up.  You can do this by adding the
% following to <https://uk.mathworks.com/help/matlab/ref/startup.html
% MATLAB's startup script> (make sure the path locations are correct):

disp 'Resetting paths...'
restoredefaultpath % Restore all paths to factory state

userDir = winqueryreg('HKEY_CURRENT_USER',...
  'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders', ...
  'Personal'); % Get the user directory path, e.g. <User>\Documents

% Change these paths to your install locations
rigbox_path = fullfile(userDir, 'Github', 'rigbox');
ptb_path = fullfile(userDir, 'PTB', 'Psychtoolbox');
add_ons = genpath(fullfile(userDir, 'MATLAB', 'Add-Ons'));

% Add Psychtoolbox paths
disp '...'
disp 'Adding PsychToolbox paths...'
cd(ptb_path)
state = pause('off');
SetupPsychtoolbox;
pause(state);

% Add Rigbox paths
disp 'Adding Rigbox paths...'
cd(rigbox_path)
addRigboxPaths('Strict', false)

% Add Add-Ons folder
addpath(add_ons)

% Return to default working directory
cd(userpath)
clear variables
home % Hide command output history

%% Etc.
% Author: Miles Wells
%
% v1.0.1
%
% <index.html Home> > <./troubleshooting.html Troubleshooting> > Paths Conflicts
