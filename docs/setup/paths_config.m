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
% paths template file being moved to the |+dat| folder. If running `which
% dat.paths` shows this isn't the case, manually copy the template (see
% below) and open the file.  The inline comments should explain each field.
open dat.paths

%% Manually copying the paths template
% The below code should copy |docs\setup\paths_template.m| to
% |+dat\paths.m|:
assert(exist('addRigboxPaths','file') == 2, ...
  'Rigbox not installed.  Please run addRigboxPaths.m before continuing')
root = fileparts(which('addRigboxPaths')); % Location of Rigbox root dir
source = fullfile(root, 'docs', 'setup', 'paths_template.m');
destination = fullfile(root, '+dat', 'paths.m');
assert(copyfile(source, destination), 'Failed to copy the template file')

%% Sharing a folder in Windows
% If you don’t yet have a data server, follow the steps below to set up a
% shared folder on the stimulus server computer:
%
% # Create a folder in C:\ called ‘LocalExpCode’ and one called
% ‘LocalExpData’ (if it doesn’t already exist)
% # Copy everything inside the GitHub\Rigbox\Repositories\data folder into
% ‘LocalExpData’ and everything inside GitHub\Rigbox\Repositories\code into
% ‘LocalExpCode’
% # Right click on the ‘LocalExpData’ folder and select Properties and
% select the Sharing tab and click ‘Share...’
% # Under the drop-down list select ‘Everyone’ and click ‘Add’, then
% ‘Share’.
% # Now click ‘Advanced Sharing…’, make sure the ‘Share this folder’ check
% box is selected.  Click the ‘Permissions’ button and ensure that under
% the ‘Permissions for Everyone’ section, the ‘Full Control’ is allowed.
% # Repeat step 3, 4 and 5 for ‘LocalExpCode’.
% # You should now be able to navigate to these folder from other computers
% on the network be going to \\<StimulusServerName>\LocalExpData (where
% ‘<StimulusServerName>’ is the computer name of the stimulus server)
% # In dat.paths, change line 21 to be the following: serverName =
% '\\<StimulusServerName>';  % where '<StimulusServerName>'    is the
% stimulus server’s computer name
% # On lines 26 and 32, replace ‘data’ with ‘LocalExpData’ and on lines 37
% and 41, replace the word ‘code’ with ‘LocalExpCode’.
% # Save the paths file in Documents\MATLAB\+dat and do the same on the mc
% computer (the two computers must have the same paths).


%% Etc.
% Author: Miles Wells
%
% v0.0.2
