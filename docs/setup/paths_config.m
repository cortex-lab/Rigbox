%% Introduction 
% The |dat.paths| function is used for configuring important paths for the
% computers which Rigbox runs on. These include paths to:
%
% 
% # either the shared folder(s) OR the remote server(s) on which 
% organization-wide configuration files, subject data and experiment data 
% is stored, and a local directory for generating redundant copies of this 
% data.
% # optionally, paths to a remote database (if using Alyx), and a local
% redundant copy of that database
% # optionally, paths to any other directories for storing additional
% back-ups (e.g. for working analyses, tapes, etc...)
% # optionally, a path to a custom config file for the local computer.
%
%
%% Setting up the paths
% |dat.paths| is simply a function that returns a struct of directory paths
% to various things.  Much of the code in Rigbox calls this function to
% determine where to save and load data.  
%
% Running the |addRigboxPaths| function should result in a copy of the
% |paths_template| file being moved to the |+dat| folder. If running `which
% dat.paths` shows this isn't the case, manually copy the template (see
% below) and open the file.  The inline comments should explain each field.
open dat.paths

%% Manually copying the paths template
% You can manually copy |docs\setup\paths_template.m| to Rigbox's |+dat|
% folder using the Windows file explorer, or run the following lines in 
% MATLAB to do so:

% ensure Rigbox has been properly installed.
assert(exist('addRigboxPaths','file') == 2, ...
  'Rigbox not installed.  Please run addRigboxPaths.m before continuing')
root = fileparts(which('addRigboxPaths')); % Location of Rigbox root dir
source = fullfile(root, 'docs', 'setup', 'paths_template.m');
destination = fullfile(root, '+dat', 'paths.m');
assert(copyfile(source, destination), 'Failed to copy the template file')

%% Etc.
% Author: Miles Wells
%
% v0.0.1

%% Setting up the paths
% In order to use Rigbox, a 'paths' file must be placed in a |+dat| folder
% somewhere in the MATLAB path. This file is a simple function that returns
% a struct of paths to directories that Rigbox requires for running
% experiments and managing data. You can copy |docs/setup/paths_template.m|
% to |+dat/paths.m|, then customise the file according to your setup. The
% paths used by the wider Rigbox code are found in the 'essential paths'
% section of the |paths_template.m| file. These paths are required to run
% experiments. Any number of custom repositories may be set, allowing them
% to be queried using functions such as DAT.REPOSPATH and DAT.EXPPATH (see
% below).
%
% It may be prefereable to keep the paths file in a shared network drive
% where all rigs can access it.  This way only one file needs updating when
% a path gets changed.  You can also override and add to the fields set by
% the paths file in a rig specific manner.  To do this, create your paths
% as a struct with the name `paths` and save this to a MAT file called
% `paths` in your rig specific config folder:
rigConfig = getOr(dat.paths('exampleRig'), 'rigConfig');
customPathsFile = fullfile(rigConfig, 'paths.mat');
paths.mainRepository = 'overide/path'; % Overide main repo for `exampleRig`
paths.addedRepository = 'new/custom/path'; % Add novel repo

save(customPathsFile, 'paths') % Save your new custom paths file.

% More info in the paths template:
root = getOr(dat.paths, 'rigbox');
opentoline(fullfile(root, 'docs', 'setup', 'paths_template.m'), 75)