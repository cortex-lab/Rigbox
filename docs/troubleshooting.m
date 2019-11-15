%% Troubleshooting
% Often finding the source of a problem seems daunghting when faced with a
% huge Rigbox error stack.  Below are some tips on how to quickly get to
% the root of the issue and hopefully solve it.


%%% Update the code %%%
% Check what version of the code you're using and that you're up-to-date:
git.runCmd('status'); % Tells me what branch I'm on
git.update(0); % Update now

% If you're on a development or feature branch try moving to the master
% branch, which should be most stable.  
git.runCmd('checkout master'); git.update(0);


%%% Examining the stack %%%
% Don't be frightened by a wall of red text!  Simply start from the top and
% work out what the errors might mean and what part of code they came from.
% The error at the top is the one that ultimately caused the crash.  Try to
% determine if this is a MATLAB builtin function, e.g. 
%
%   Warning: Error occurred while executing the listener callback for event UpdatePanel defined for class eui.SignalsTest:
%   Error using griddedInterpolant
%   Interpolation requires at least two sample points in each dimension.
% 
%   Error in interp1 (line 151)
%   F = griddedInterpolant(X,V,method);
%
%   TODO Add better example of builtin errors
%
% If you're debugging a signals experiment definition, check for the line
% in your experiment where this particular builtin function was called. NB:
% You can check whether it is specific to your experiment by running one of
% the example experiment definitions such as advancedChoiceWorld.m, found
% in signals/docs/examples.  If this runs without error then you're problem
% may be specific to your experiment.  You should see the name of your
% definition function and exp.SignalsExp in the stack if they are involved.
%
% If you don't know what a function is, try checking the documentation.
% Consider the following:
%
%  Error using open
%  Invalid number of channels
%
%  Error in audstream.fromSignal (line 16)
%    id = audstream.open(sampleRate, nChannels, devIdx);
%  [...]
%
% If you're unsure what `audstream.fromSignal` does, try typing `doc
% audstream`.  This should tell you that the package deals with audio
% devices in signals.  In this case the issue might be that your audio
% settings are incorrect.  Take a look at the audio section of
% `docs\setup\hardware_config.m` and see if you can setup your audio
% devices differently.


%%% Paths %%%
% By far the most common issue in Rigbox relates to problems with the
% MATLAB paths.  Check the following:
% 1. Do you have a paths file in the +dat package?
%  Check the location by running `which dat.paths`.  Check that a file is
%  on the paths and that it's the correct one.
% 2. Check the paths set in this file.
%  Run `p = dat.paths` and inspect the output.  Perhaps a path is set
%  incorrectly for one of the fields.  Note that custom rig paths overwrite
%  those written in your paths file.  More info found in
%  `using_dat_package` and `paths_template`.
% 3. Do you have path conflicts?  
%  Make sure MATLAB's set paths don't include other functions that have the
%  same name as Rigbox ones.  Note that any functions in ~/Documents/MATLAB
%  take precedence over others.  If you keep seeing the following warning
%  check that you've set the paths correctly: 
%   Warning: Function system has the same name as a MATLAB builtin. We
%   suggest you rename the function to avoid a potential name conflict.
%  This warning can occur if the tests folder has been added to the paths
%  by mistake.  Always set the paths by running `addRigboxPaths` and never
%  set them manually as some folders should not be visible to MATLAB.
% 4. Check your working directory
%  MATLAB prioritizes functions found in your working directory over any
%  others in your path list so try to change into a 'safe' folder before
%  re-running your code:
%   pwd % display working directory
%   cd ~/Documents/MATLAB
% 5. Check your variable names
%  Make sure your variable names don't shadow a function or package in
%  Rigbox, for instance if in an experiment definition you create a varible
%  called `vis`, you will no longer be able to access functions in the +vis
%  package from within the function:
%   vis = 23;
%   img = vis.image(t);
%   Error: Reference to non-existent field 'image'.


%%% Reverting %%%
% If these errors only started occuring after updating the code,
% particularly if you hadn't updated in a long time, try reverting to the
% previous version of the code.  This can help determine if the update
% really was the culprit and will allow you to keep using the code on
% outdated machines.  Previous stable releases can be found on the Github
% page under releases.  NB: For the most recent stable code always pull
% directly from the master branch


%%% Posting an issue on Github %%%
% If you're completely stumped, open an issue on the Rigbox Github page (or
% alyx-matlab if you think it's related to the Alyx database).  When
% creating an issue, read the bug report template carefully and be sure to
% provide as much information as possible.
%
% If you tracked down the problem but found the error to be confusing or
% too vague, feel free to post a feature request describing how better to
% present the error.  This is an area in need of improvment. You could also
% make a change yourself and submit a pull request.  For more info see
% CONTRIBUTING.md


%% FAQ
% Below are some frequently asked questions and suggestions for fixing
% them.  Note there are plenty of other FAQs in the various setup scripts
% with more specific information.


%% Error and warning IDs
% Below is a list of Rigbox error & warning IDs.  This list is currently
% incomplete and there aren't yet very standard.  Typically the ID has the
% following structure: module:package:function:error
%
% These are here for search convenience and may soon contain more detailed
% troubleshooting information.

% ..:..:..:copyPaths
% Problem:
%  In order to load various essential configuration files, and to load and
%  save experimental data, user specific paths must be retrieved via calls
%  to |dat.paths|.  This error means the function is not on MATLAB's search
%  path.
%
% Solution:
%  Add your +dat\paths.m file to MATLAB's search path.  A template is
%  present in \docs\setup\paths_template.m.  This file is automatically
%  copied by addRigboxPaths to +dat\.  If you haven't already done so, run
%  |addRigboxPaths| to ensure all other paths have been correctly set.  
%
%  See also README.md for further setup information.
%
% IDs
%  Rigbox:git:update:copyPaths
%  signals:test:copyPaths

% ..:..:noRemoteFile
% Problem:
%  % TODO Add problem & solution for noRemoteFile error
%
% Solution:
%  
%
% IDs
%  Rigbox:mc:noRemoteFile

% ..:..:..:notInTest
% Problem:
%  This occurs when a mock function is called when the INTEST global
%  variable is not set.  These mock functions shadow Rigbox and builtin
%  functions, meaning they have the same name.
%
% Solution:
%  If this function was called during a test, add the following to the top
%  of your test or in the constructor:
%    global INTEST
%    INTEST = true
%  Ensure that this is cleared during the teardown:
%    addteardown(@clear, INTEST) % If in a class
%    mess = onCleanup(@clear, INTEST) % If in a function
%
%  If the mock in question is a class, set the InTest flag instead of the
%  global variable:
%    mock = MockDialog; % An example using MockDialog class
%    mock.InTest = true;
%    addteardown(@clear, MockDialog) % Clear mock class when done
%    mess = onCleanup(@clear, MockDialog) % If in a function
%
%  If you are in not running tests, ensure that tests/fixtures is not in
%  your MATLAB path and that you are in a different working directory.  It
%  is best to remove all Rigbox paths and readd them using `addRigboxPaths`
%
% IDs
%  Rigbox:tests:system:notInTest
%  Rigbox:tests:modDate:notInTest
%  Rigbox:tests:paths:notInTest
%  Rigbox:tests:modDate:missingTestFlag % TODO change name
%  Rigbox:MockDialog:newCall:InTestFalse

% ..:..:..:behaviourNotSet
% Problem:
%  A mock function was called while in a test, however the behaviour for
%  this particular input has not been defined.
%
% Solution:
%  If not testing a specific behavior for this function's output, simply
%  supress the warning in your test, remembering to restore the warning
%  state:
%    origState = warning;
%    addteardown(@warning, origState) % If in a class
%    mess = onCleanup(@warning, origState) % If in a function
%    warning('Rigbox:MockDialog:newCall:behaviourNotSet', 'off')
%
%  If you're specifically testing the behavior when the mock returns a
%  particular output then check that you've set the input-output map
%  correctly: usually this is done by first calling the mock with input
%  identical to function under test as well as the output you want to see.
%  Check the input is formatted correctly.  For more information see the
%  help of the particular mock you are using.
%    
% IDs
%  Rigbox:tests:system:valueNotSet % TODO change name
%  Rigbox:MockDialog:newCall:behaviourNotSet
%  

% ..:..:mkdirFailed
% Problem:
%  MATLAB was unable to create a new folder on the system.
%
% Solution:
%  In general Rigbox code only creates new folders when a new experiment is
%  created.  The folders are usually created in the localRepository and
%  mainRepository locations that are set in your paths file.  If either of
%  these are remote (e.g. a server accessed via SMB) check that you can
%  navigate to the location in Windows' File Explorer (sometimes the access
%  credentials need setting first).  If you can, next check the permissions
%  of these locations.  If the folders are read-only, MATLAB will not be
%  able to create a new experiment folder there.  Either change the
%  permissions or set a different path in |dat.paths|.  One final thing to
%  check is that the folder names are valid: the presence of a folder that
%  is not correctly numbered in the subject's date folder may lead to an
%  invalid expRef.  Withtin a date folder there should only be folders name
%  '1', '2', '3', etc.
%
% IDs
%  Alyx:newExp:mkdirFailed
%  Rigbox:dat:newExp:mkdirFailed
%

% ..:newExp:expFoldersAlreadyExist
% Problem:
%  The folder structure for a newly generated experiment reference is
%  already in place.
%
%  Experiment references are generated based on subject name, today's date
%  and the experiment number, which is found by looking at the folder
%  structure of the main repository.  In a subject's experiment folder for
%  a given date there are numbered folders.  When running a new experiment,
%  the code takes the folder name with the largest number and adds 1.  It
%  then checks that this numbered folder doesn't exist in the other
%  repositories.  If it does, an error is thrown so that no previous
%  experiment data is overwritten.  
%
% Solution:
%  Check the folder structure for all your repositories (namely the
%  localRepository and mainRepository set in |dat.paths|).  It may be that
%  there is an empty experiment folder in the localRepository but not the
%  mainRepository, in which case you can delete it.  Alternatively, if you
%  find a full experiment folder in the local but not the main, copy it
%  over so that the two match.  This will avoid a duplicate expRef being
%  created (remember, new expRefs are created based on the folder structure
%  of the mainRepository only).
%
% IDs
%  Alyx:newExp:expFoldersAlreadyExist
%  Rigbox:dat:newExp:expFoldersAlreadyExist
%

% Other:

% Rigbox:git:runCmd:nameValueArgs
% Rigbox:git:runCmd:gitNotFound
% Rigbox:git:update:valueError

% Rigbox:hw:calibrate:noscales
% Rigbox:hw:calibrate:deadscale
% Rigbox:hw:calibrate:partialPVpair

% Rigbox:srv:unexpectedUDPResponse
% Rigbox:srv:unexpectedUDP
% rigbox:srv:expServer:noHardwareConfig

% Rigbox:tests:pnet:notInTest
% Rigbox:dat:expPath:NotEnoughInputs
% Rigbox:exp:SignalsExp:NoScreenConfig
% Rigbox:exp:Parameters:wrongNumberOfColumns

% Rigbox:dat:expFilePath:NotEnoughInputs

% Rigbox:MockDialog:newCall:EmptySeq

% Rigbox:exp:SignalsExp:noTokenSet

% Rigbox:eui:choiceExpPanel:toolboxRequired
% Rigbox:setup:toolboxRequired

% Alyx:newExp:subjectNotFound
% Alyx:registerFile:InvalidPath
% Alyx:registerFile:UnableToValidate
% Alyx:registerFile:EmptyDNSField
% Alyx:registerFile:InvalidRepoPath
% Alyx:registerFile:InvalidFileType
% Alyx:registerFile:InvalidFileName
% Alyx:registerFile:NoValidPaths

% Alyx:getFile:InvalidID
% Alyx:getExpRef:InvalidID
% Alyx:getFile:InvalidType
% Alyx:expFilePath:InvalidType
% Alyx:url2Eid:InvalidURL

% toStr:isstruct:Unfinished

% squeak.hw
% shape:error
% window:error
