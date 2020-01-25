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

%% Etc.
% Author: Miles Wells
%
% v0.0.1
