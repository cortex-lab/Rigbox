function addRigboxPaths(savePaths)
%ADDRIGBOXPATHS Adds the required paths for using Rigbox
%
%   Part of the Rigging toolbox
% TODO: 
% - Paths to 'cortexlab' and 'cb-tools' were incorrect
% - Consider renaming above folder to something more informative 
% - Remove GUILayout paths
% - Ask user to install GUI Layout Toolbox
% - Update to work as standalone install from GitHub
%
% 2014-01 CB
% 2017-02 MW Updated to work with 2016b

if nargin < 1
  savePaths = true;
end

rigboxPath = fileparts(mfilename('fullpath')); 
rootPath = fileparts(rigboxPath);
cbToolsPath = fullfile(rootPath, 'cb-tools'); % Assumes 'cb-tools' in same 
% directory as Rigbox, was not the case
guiLayoutPath = fullfile(fullfile(cbToolsPath, 'GUILayout'));

cortexLabAddonsPath = fullfile(rootPath, 'rigbox-cortexlab'); % doesn't exist 2017-02-13
if ~isdir(cortexLabAddonsPath) % handle two possible alternative paths
  cortexLabAddonsPath = fullfile(rootPath, 'cortexlab'); % doesn't exist in Rigbox directory 2017-02-13
end

addpath(...
  cortexLabAddonsPath,... % add the Rigging cortexlab add-ons
  rigboxPath,... % add Rigbox itself
  cbToolsPath,... % add cb-tools root dir
  fullfile(cbToolsPath, 'burgbox'),... % Burgbox
  fullfile(cbToolsPath, 'jsonlab'),... % jsonlab for JSON encoding
  fullfile(cbToolsPath, 'urlread2'),... % urlread2 for http requests
  fullfile(cbToolsPath, 'MercuryDialog'),... % tools to manage code versioning
  guiLayoutPath,... % add GUI Layout toolbox
  fullfile(guiLayoutPath, 'layout'),...
  fullfile(guiLayoutPath, 'Patch'),...
  fullfile(guiLayoutPath, 'layoutHelp')...
  );

if savePaths
  assert(savepath == 0, 'Failed to save changes to MATLAB path');
end

cbtoolsjavapath = fullfile(cbToolsPath, 'java');
javaclasspathfile = fullfile(prefdir, 'javaclasspath.txt');
fid = fopen(javaclasspathfile, 'a+');
fseek(fid, 0, 'bof');
closeFile = onCleanup( @() fclose(fid) );
javaclasspaths = first(textscan(fid,'%s', 'CommentStyle', '#',...
  'Delimiter','')); % this will crash on 2014b
cbtoolsInJavaPath = any(strcmpi(javaclasspaths, cbtoolsjavapath));

if savePaths
%   assert(savepath == 0, 'Failed to save changes to MATLAB path');
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

end