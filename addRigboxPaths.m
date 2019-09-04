function addRigboxPaths(savePaths)
%ADDRIGBOXPATHS Adds the required paths for using Rigbox
%
%   Part of the Rigging toolbox
%
% 2014-01 CB
% 2017-02 MW Updated to work with 2016b

% Flag for perminantly saving paths
if nargin < 1; savePaths = true; end

%%% MATLAB version and toolbox validation %%%
% MATLAB must be running on Windows
assert(ispc, 'Rigbox currently only works on Windows 7 or later')

% Microsoft Visual C++ Redistributable for Visual Studio 2015 must be
% installed, check for runtime dll file in system32 folder
sys32 = dir('C:\Windows\System32');
assert(any(strcmpi('VCRuntime140.dll',{sys32.name})), 'Rigbox:setup:libraryRequired',...
  ['Requires Microsoft Visual C++ Redistributable for Visual Studio 2015. ',...
   'Click <a href="matlab:web(''%s'',''-browser'')">here</a> to install.'],...
   'https://www.microsoft.com/en-us/download/details.aspx?id=48145')

% Check MATLAB 2017b is running
assert(~verLessThan('matlab', '9.3'), 'Requires MATLAB 2017b or later')

% Check essential toolboxes are installed (common to both master and
% stimulus computers)
toolboxes = ver;
requiredMissing = setdiff(...
  {'Data Acquisition Toolbox', ...
  'Signal Processing Toolbox', ...
  'Instrument Control Toolbox', ...
  'Statistics and Machine Learning Toolbox'},...
  {toolboxes.Name});

assert(isempty(requiredMissing),'Rigbox:setup:toolboxRequired',...
  'Please install the following toolboxes before proceeding: \n%s',...
  strjoin(requiredMissing, '\n'))

% Check that GUI Layout Toolbox is installed (required for the master
% computer only)
isInstalled = strcmp('GUI Layout Toolbox', {toolboxes.Name});
if ~any(isInstalled) ||...
    str2double(strrep(toolboxes(isInstalled).Version,'.', '')) < 230
  warning('Rigbox:setup:toolboxRequired',...
    ['MC requires GUI Layout Toolbox v2.3 or higher to be installed. '...
    'Click <a href="matlab:web(''%s'',''-browser'')">here</a> to install.'],...
    'https://uk.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox')
end

% Check that the Psychophisics Toolbox is installed (required for the
% stimulus computer only)
isInstalled = strcmp('Psychtoolbox', {toolboxes.Name});
if ~any(isInstalled) || str2double(toolboxes(isInstalled).Version(1)) < 3
  warning('Rigbox:setup:toolboxRequired',...
    ['The stimulus computer requires Psychtoolbox v3.0 or higher to be installed. '...
    'Click <a href="matlab:web(''%s'',''-browser'')">here</a> to install.'],...
    'https://github.com/Psychtoolbox-3/Psychtoolbox-3/releases')
end

% Check that the NI DAQ support package is installed (required for the
% stimulus computer only)
info = matlabshared.supportpkg.getInstalled;
if isempty(info) || ~any(contains({info.Name}, 'NI-DAQmx'))
  warning('Rigbox:setup:toolboxRequired',...
    ['The stimulus computer requires the National Instruments support package to be installed. '...
    'Click <a href="matlab:web(''%s'',''-browser'')">here</a> to install.'],...
    'https://www.mathworks.com/hardware-support/nidaqmx.html')
end

%%% Paths for adding 
% Add the main Rigbox directory, containing the main packages for running
% the experiment server and mc programmes
root = fileparts(mfilename('fullpath')); 
addpath(root);

% The cb-tools directory contains numerious convenience functions which are
% utilized by the main code.  Those within the 'burgbox' directory were
% written by Chris Burgess.  
addpath(fullfile(root, 'cb-tools'), fullfile(root, 'cb-tools', 'burgbox')); 

% Add CortexLab paths.  These are mostly extra classes that allow Rigbox to
% work with other software developed by CortexLab, including MPEP
addpath(fullfile(root, 'cortexlab'));

% Add wheelAnalysis paths.  This is a package for computing wheel velocity,
% classifying movements, etc.
addpath(fullfile(root, 'wheelAnalysis'), ...
  fullfile(root, 'wheelAnalysis', 'helpers'));

% Add signals paths, this includes all the core code for running signals
% experiments.  This submodule is maintained by Chris Burgess.
addpath(fullfile(root, 'signals'),...
    fullfile(root, 'signals', 'mexnet'),...
    fullfile(root, 'signals', 'util'));
% Add the Java paths for signals
jcp = fullfile(root, 'signals', 'java');
if ~any(strcmp(javaclasspath, jcp)); javaaddpath(jcp); end

% Add the paths for Alyx-matlab.  This submodule allows one to interact
% with an instance of an Alyx database.  For more information please visit:
% http://alyx.readthedocs.io/en/latest/
addpath(fullfile(root, 'alyx-matlab'), fullfile(root, 'alyx-matlab', 'helpers'));

% Add paths for the npy-matlab.  This submodule is maintained by the
% Kwik Team (https://github.com/kwikteam).  It allows for the saving of
% NumPy binary files.  Used by Rigbox to save data as .npy files with the
% ALF (ALex File) naming convention.  For more information please visit:
% https://docs.scipy.org/doc/numpy-dev/neps/npy-format.html
addpath(fullfile(root, 'npy-matlab', 'npy-matlab'));

% Add the Java paths for Java WebSockets used for communications between
% the stimulus computer and the master computer
cbtoolsjavapath = fullfile(root, 'cb-tools', 'java');
javaclasspathfile = fullfile(prefdir, 'javaclasspath.txt');
fid = fopen(javaclasspathfile, 'a+');
fseek(fid, 0, 'bof');
closeFile = onCleanup( @() fclose(fid) );
javaclasspaths = first(textscan(fid,'%s', 'CommentStyle', '#', 'Delimiter',''));
cbtoolsInJavaPath = any(strcmpi(javaclasspaths, cbtoolsjavapath));

%%% Remind user to copy paths file %%%
if ~exist('+dat/paths','file')
  template_paths = fullfile(root, 'docs', 'setup', 'paths_template.m');
  new_loc = fullfile(root, '+dat', 'paths.m');
  copied = copyfile(template_paths, new_loc);
  % Check that the file was copied
  if ~copied
    warning('Rigbox:setup:copyPaths', 'Please copy the file ''%s'' to ''%s''.',...
      template_paths, new_loc);
  end
end

%%% Validate that paths saved correctly %%%
if savePaths
  assert(savepath == 0, 'Failed to save changes to MATLAB path');
  if ~cbtoolsInJavaPath
    fseek(fid, 0, 'eof');
    n = fprintf(fid, '\n#path to CB-tools java classes\n%s', cbtoolsjavapath);
    assert(n > 0, 'Could not write to ''%s''', javaclasspathfile);
    warning('Rigbox:setup:restartNeeded',...
    'Updated Java classpath, please restart MATLAB');
  end
elseif ~cbtoolsInJavaPath
  warning('Rigbox:setup:javaNotSetup',...
    'Cannot use java classes without saving new classpath');
end

%%% Attempt to move dll file for signals %%%
fileName = fullfile(root, 'signals', 'msvcr120.dll');
fileExists = any(strcmp('msvcr120.dll',{sys32.name}));
copied = false;
if isWindowsAdmin % If user has admin privileges, attempt to copy dll file
  if fileExists % If there's already a dll file there prompt use to make backup
    prompt = sprintf(['For signals to work propery, it is nessisary to copy ',...
      'the file \n<strong>', strrep(fileName, '\', '\\'), '</strong> to ',...
       '<strong>C:\\Windows\\System32</strong>.\n',...
      'You may want to make a backup of your existing dll file before continuing.\n\n',...
      'Do you want to proceed? Y/N [Y]: ']);
    str = input(prompt,'s'); if isempty(str); str = 'y'; end
    if strcmpi(str, 'n'); return; end % Return without copying
  end
  copied = copyfile(fileName, 'C:\Windows\System32');
end
% Check that the file was copied
if ~copied
  warning('Rigbox:setup:libraryRequired', ['Please copy the file ',...
    '<strong>%s</strong> to <strong>C:\\Windows\\System32</strong>.'], fileName)
end

function out = isWindowsAdmin()
%ISWINDOWSADMIN True if this user is in admin role.
% 2011 Andrew Janke (https://github.com/apjanke)
if ~NET.isNETSupported; out = false; return; end
wi = System.Security.Principal.WindowsIdentity.GetCurrent();
wp = System.Security.Principal.WindowsPrincipal(wi);
out = wp.IsInRole(System.Security.Principal.WindowsBuiltInRole.Administrator);
end
end