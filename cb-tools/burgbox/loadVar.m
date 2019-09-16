function var = loadVar(filename, varName)
%loadVar Loads, caches and returns a specific variable from a MAT-file
%   v = LOADVAR(filename, varName) returns the variable named 'varName'
%   from the MAT-file specified by 'filename'. 
%   
%   Note that this is unlike MATLAB's load function, this actually returns
%   the particular variable requested from the file (rather than a struct 
%   containing it as a field). This is useful for loading a variable in a 
%   tidier one-liner, e.g., rather than:
%
%     dat = load(filename);
%     var = dat.varName;
%
%   or just magically filling the workspace with:
%     load(filename); % now 'var' is magically created
%
%   we use:
%     var = loadVar(filename, 'varName');
%
%   As a bonus we get the value cached so it won't need to be loaded again
%   until it changes. The variable is cached by the full path and 
%   modification date, i.e. if it is modified or moved, it will be
%   reloaded, otherwise it is just retrieved from memory.
%
%   @todo Replace key-value pairs when data modified
%   @body Currently re-loading a modified file caches the data without
%   replacing the previous pair.  This may not be optimal, unless users
%   want to save a version history of a file.
%
% Part of Burgbox

% 2013-02 CB created

global BurgboxCache

if nargin < 2
  varName = [];
end

if isempty(BurgboxCache)
  BurgboxCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
end

if iscell(filename)
  var = mapToCell(@(f) loadVar(f, varName), filename);
else
  file = java.io.File(filename);
  filename = char(file.getCanonicalPath);
  modDate = char(java.util.Date(file.lastModified).toString);
  if ~isempty(varName)
    
    key = [filename '/' varName '/' modDate];
    if BurgboxCache.isKey(key)
      var = BurgboxCache(key);
    else
      data = load(filename, varName);
      var = data.(varName);
      BurgboxCache(key) = var;
    end
  else
    key = [filename '/*/' modDate];
    if BurgboxCache.isKey(key)
      var = BurgboxCache(key);
    else
      var = load(filename);
      BurgboxCache(key) = var;
    end
  end
end

end

