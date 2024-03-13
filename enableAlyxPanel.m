function enableAlyxPanel(varargin)
%enableAlyxPanel Adds the required paths for using the AlyxPanel
%  enableAlyxPanel([savePaths, strict]) or 
%  enableAlyxPanel('SavePaths', true, 'Strict', true)
%
%   Inputs (Optional):
%     savePaths (logical): If true, added paths are saved between sessions
%     strict (logical): Assert toolbox & system requirements are all met
%
% Part of the Rigging toolbox
%
% 2014-01 CB
% 2017-02 MW Updated to work with 2016b
% 2024-03 ATL Added to enable AlyxPanel use only without other features

%%% Input validation %%%
% Allow positional or Name-Value pairs
p = inputParser;
p.addOptional('savePaths', true)
p.addOptional('strict', true)
p.parse(varargin{:});
p = p.Results;

%%% MATLAB version and toolbox validation %%%
toolboxes = ver;
  
if p.strict
  % MATLAB must be running on Windows
  assert(ispc, 'Rigbox currently only works on Windows 10')
  
  % Check MATLAB 2018b is running
  assert(~verLessThan('matlab', '9.5'), 'Requires MATLAB 2018b or later')
  
  % Check that GUI Layout Toolbox is installed (required for the master
  % computer only)
  isInstalled = strcmp('GUI Layout Toolbox', {toolboxes.Name});
  if ~any(isInstalled) ||...
      str2double(erase(toolboxes(isInstalled).Version,'.')) < 230
    warning('Rigbox:setup:toolboxRequired',...
      ['MC requires GUI Layout Toolbox v2.3 or higher to be installed.'...
       ' Click <a href="matlab:web(''%s'',''-browser'')">here</a> to' ...
       ' install.'], ['https://uk.mathworks.com/matlabcentral/fileexchange'...
       '/47982-gui-layout-toolbox'])
  end
end

%%% Add paths %%%
% Add the main Rigbox directory, containing the main packages for running
% the experiment server and mc
root = fileparts(mfilename('fullpath')); 
addpath(root);

% The cb-tools directory contains numerious convenience functions which are
% utilized by the main code. Those within the 'burgbox' directory were
% written by Chris Burgess.  
addpath(fullfile(root, 'cb-tools', 'burgbox')); 

% Add the paths for Alyx-matlab. This submodule allows one to interact
% with an instance of an Alyx database. For more information please visit:
% http://alyx.readthedocs.io/en/latest/
addpath(fullfile(root, 'alyx-matlab'), fullfile(root, 'alyx-matlab', 'helpers'));

%%% Remind user to copy paths file %%%
if ~exist('+dat/paths','file')
  template_paths = fullfile(root, 'docs', 'scripts', 'paths_template.m');
  new_loc = fullfile(root, '+dat', 'paths.m');
  copied = copyfile(template_paths, new_loc);
  % Check that the file was copied
  if ~copied
    warning('Rigbox:setup:copyPaths', 'Please copy the file ''%s'' to ''%s''.',...
      template_paths, new_loc);
  end
end

%%% Validate that paths saved correctly %%%
if p.savePaths
  assert(savepath == 0, 'Failed to save changes to MATLAB path');
end
