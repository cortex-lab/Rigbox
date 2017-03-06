function [sz, dtype, meta] = loadArrInfo(path)
%loadArrInfo Load info associated with an array
%   [sz, dtype, meta] = LOADARRINFO(path) loads the information associated
%   with a fast save/load array. This includes the size of the array, the
%   datatype (e.g. double, single, uint16 etc), and any meta variables
%   previously saved with it. See also loadArr & saveArr.
%
% Part of Burgbox

% 2014-05 CB created

% Check whether file exists
if ~exist([path '.mat'], 'file')
    % if not, check whether file name contains 'channel...'
    [dirPath, name] = fileparts(path);
    if ~isempty(strfind(name, '_channel'))
        % if so, delete '_channel...' from file name and check whether new
        % file exists
        newName = regexprep(name, '_channel\d*', '');
        if ~exist(fullfile(dirPath, [newName '.mat']), 'file')
            display('File does not exist.')
            sz = [];
            dtype = [];
            meta = [];
            return
        end
        path = fullfile(dirPath, newName);
    end
end

s = load([path '.mat']); % load the info file
sz = s.arrSize;
dtype = s.arrPrecision;
if isfield(s, 'meta')
  meta = s.meta;
else
  meta = [];
end

end