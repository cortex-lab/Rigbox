function success = installRigboxReqs()
%INSTALLRIGBOXREQS installs Rigbox's required dependencies.
% This function checks to see if 1) the MSVC 2013 libraries, 2) the MSVC
% 2015 libraries, 3) MATLAB's GUI layout toolbox, and 4) Psychtoolbox (and
% it's dependencies) are installed and found on MATLAB's paths. If not, the
% installers for these required dependencies are launched.
%
% Outputs:
%   success : logical
%     A flag that returns true if all requirements were successfully
%     installed and added to MATLAB's paths, and false otherwise.
%
% Examples:
%   success = installRigboxReqs()
%
% See also: `addRigboxPaths`

%%% check to see which requirements are installed %%%

% get the Rigbox `reqs` directory
reqsDir = fullfile(fileparts(which('addRigboxPaths')), 'docs', 'reqs');
% replace backslashes with forward slashes for string comparisons later
reqsDir = strrep(reqsDir, '\', '/'); 
assert(logical(exist(reqsDir, "dir")),...
  ['Could not find Rigbox''s ''reqs'' directory. In MATLAB, please ',...
   'navigate to the ''Rigbox'' directory, and run this function again.']);

% get MATLAB toolboxes and path to MSVC libraries
toolboxes = ver;
sys32Folder = 'C:/Windows/System32';
sys32 = dir(sys32Folder);

% create placeholder for not installed requirements
notInstalled = {};

% check if MSVC 2013 is installed
if ~any(strcmpi('msvcr120.dll',{sys32.name}))
  notInstalled{end+1} = 'MSVC 2013';
end

% check if MSVC 2015 is installed
if ~any(strcmpi('VCRuntime140.dll',{sys32.name}))
  notInstalled{end+1} = 'MSVC 2015';
end

% check if gui layout toolbox is installed
isInstalled = strcmpi('GUI Layout Toolbox', {toolboxes.Name});
if ~any(isInstalled) || str2double(toolboxes(isInstalled).Version(1)) < 2
  notInstalled{end+1} = 'GUI Layout Toolbox';
end

% check if PTB is installed
isInstalled = strcmpi('Psychtoolbox', {toolboxes.Name});
if ~any(isInstalled) || str2double(toolboxes(isInstalled).Version(1)) < 3
  notInstalled{end+1} = 'Psychtoolbox';
end

%%% install missing requirements %%%

% install msvc 2013
if any(strcmpi('MSVC 2013', notInstalled))
  fprintf('Launching Installer for MSVC 2013 libraries...\n');
  cmd = strrep(strcat(reqsDir, '\vcredist_2013_x64.exe'), '\', '/');
  system(cmd);
  % check if install was successful
  if ~any(strcmpi('msvcr120.dll',{sys32.name}))
    warning(...
      ['\nTried installing, but MSVC 2013 libraries were not found in %s.'...
       'Please try manually running the %s installer.'],...
       sys32Folder, cmd); %#ok<*CTPCT>
  else
    fprintf('MSVC 2013 libraries successfully installed.\n');
    % remove msvc 2013 from list of not installed requirements
    notInstalled(strcmp('MSVC 2013', notInstalled)) = [];
  end
end

% install msvc 2015
if any(strcmpi('MSVC 2015', notInstalled))
  fprintf('Launching Installer for MSVC 2015 libraries...\n');
  cmd = strrep(strcat(reqsDir, '\vcredist_2015_x64.exe'), '\', '/');
  system(cmd);
  % check if install was successful
  if ~any(strcmpi('VCRuntime140.dll',{sys32.name}))
    warning(...
      ['\nTried installing MSVC 2015 libraries, but they were not found '...
       'in %s. Please try manually running the %s installer.'],...
       sys32Folder, cmd);
  else
    fprintf('MSVC 2015 libraries successfully installed.\n');
    % remove msvc 2015 from list of not installed requirements
    notInstalled(strcmp('MSVC 2015', notInstalled)) = [];
  end
end

% install gui layout toolbox
if any(strcmpi('GUI Layout Toolbox', notInstalled))
  fprintf('Launching Installer for GUI Layout Toolbox...\n')
  cmd =... 
    strrep(strcat(reqsDir, '\gui_layout_toolbox_2.3.4.mltbx'), '\', '/');
  matlab.addons.install(cmd);
  % check if install was successful
  isInstalled = strcmpi('GUI Layout Toolbox', {toolboxes.Name});
  if ~any(isInstalled) || str2double(toolboxes(isInstalled).Version(1)) < 2
    warning(...
      ['\nTried installing GUI Layout Toolbox, but it was not found in '...
       'MATLAB''s paths. Please try manually running the %s installer.'],...
       cmd);
  else
    fprintf('GUI Layout Toolbox successfully installed.\n')
    % remove gui layout toolbox from list of not installed requirements
    notInstalled(strcmp('GUI Layout Toolbox', notInstalled)) = [];
  end
end

% install PTB and its dependencies
if any(strcmpi('Psychtoolbox', notInstalled))
  fprintf(...
    ['\nPsychtoolbox was not found on the MATLAB paths. '...
     '\nProceeding to install Psychtoolbox and it''s dependencies... \n\n'...
     'If you already have installed any of the following dependencies, \n'...
     'you can simply close the installer, and the installer for the \n'...
     'next dependency will be launched.\n'])

  % install gstreamer
  fprintf(...
    '\nLaunching gstreamer installer. Install *all* offered packages.\n');
  cmd =...
    strrep(strcat(reqsDir,...
                  '/gstreamer-1.0-msvc-x86_64-1.16.2.msi'), '\', '/');
  system(cmd);

  % install svn
  fprintf(...
    '\nLaunching subversion installer. Install *all* offered packages.\n');
  cmd =... 
    strrep(strcat(reqsDir,...
                  '/Slik-Subversion-1.12.0-x64.msi'), '\', '/');
  system(cmd);
  
  % install PTB
  cmd =... 
    strrep(strcat(reqsDir,...
                  '/DownloadPsychtoolbox.m'), '\', '/');
  run(cmd);
  % check if install was successful
  isInstalled = strcmpi('Psychtoolbox', {toolboxes.Name});
  if ~any(isInstalled) || str2double(toolboxes(isInstalled).Version(1)) < 3
    warning(...
      ['\nTried installing Psychtoolbox, but it was not found in '...
       'MATLAB''s paths. Please try manually running the %s script in '...
       'MATLAB.'], cmd);
  else
    fprintf('Psychtoolbox successfully installed.\n')
    % remove Psychtoolbox from list of not installed requirements
    notInstalled(strcmp('Psychoolbox', notInstalled)) = [];
  end
end

% return final status
if ~isempty(notInstalled)
  success = true;
  fprintf(...
    ['All Rigbox requirements are successfully installed. \nPlease restart '...
     'MATLAB, and run the `Rigbox/addRigboxPaths.m` function.\n']);
else
  success = false;
  warning(...
    ['\n%s was not successfully installed. \n'...
     'Please try to run the installer manually. \n'...
     'The installer can be found in `Rigbox/docs/reqs`.\n'],...
     notInstalled{:});
end

end