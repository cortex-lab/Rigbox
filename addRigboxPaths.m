function addRigboxPaths(savePaths)
%ADDRIGBOXPATHS Adds the required paths for using Rigbox
%
%   Part of the Rigging toolbox
% TODO: 
% - Paths to 'cortexlab' and 'cb-tools' were incorrect
% - Consider renaming above folder to something more informative 
%
% 2014-01 CB
% 2017-02 MW Updated to work with 2016b

if nargin < 1
  savePaths = true;
end

rigboxPath = fileparts(mfilename('fullpath')); 
cbToolsPath = fullfile(rigboxPath, 'cb-tools'); % Assumes 'cb-tools' in same 
% directory as Rigbox, was not the case

% 2017-02-17 GUI Layout Toolbox should be installed as matlab toolbox
toolboxes = ver;
isInstalled = strcmp('GUI Layout Toolbox', {toolboxes.Name});
if any(isInstalled)
    fprintf('GUI Layout Toolbox version %s is currently installed\n', toolboxes(isInstalled).Version)
else
    warning('MC requires GUI Layout Toolbox v2.3 or higher to be installed')
end
    
cortexLabAddonsPath = fullfile(rigboxPath, 'rigbox-cortexlab'); % doesn't exist 2017-02-13
if ~isdir(cortexLabAddonsPath) % handle two possible alternative paths
  cortexLabAddonsPath = fullfile(rigboxPath, 'cortexlab'); % doesn't exist in Rigbox directory 2017-02-13
end

addpath(...
  cortexLabAddonsPath,... % add the Rigging cortexlab add-ons
  rigboxPath,... % add Rigbox itself
  cbToolsPath,... % add cb-tools root dir
  fullfile(cbToolsPath, 'burgbox')); % Burgbox

if savePaths
  assert(savepath == 0, 'Failed to save changes to MATLAB path');
end

cbtoolsjavapath = fullfile(cbToolsPath, 'java');
javaclasspathfile = fullfile(prefdir, 'javaclasspath.txt');
fid = fopen(javaclasspathfile, 'a+');
fseek(fid, 0, 'bof');
closeFile = onCleanup( @() fclose(fid) );
javaclasspaths = first(textscan(fid,'%s', 'CommentStyle', '#',...
  'Delimiter','')); % this will crash on 2014b, but not in 2016b
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