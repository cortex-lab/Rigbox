function superSave(path, vars)
%SUPERSAVE Saves variables to multiple MAT-files and can create folders
%   SUPERSAVE(path, vars) saves the fields in 'vars' to one or more
%   MAT-files indicated by 'path', which can be a single string or a
%   cell array with multiple paths. If the folders in the paths do not
%   exist, superSave will attempt to create them before saving.
%
% Part of Burgbox

% 2013-02 CB created

  function saveIndiv(fn)
    pathstr = fileparts(fn);
    % if the containing folder does not exist, create it
    if ~isempty(pathstr) && ~exist(pathstr, 'dir')
      mkdir(pathstr);
    end
    save(fn, '-struct', 'vars');
  end

if iscell(path)
  cellfun(@saveIndiv, path);
else
  saveIndiv(path);
end

end