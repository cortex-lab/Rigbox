function [fullpath, filename] = expFilePath(varargin)
%DAT.EXPFILEPATH Full path for file pertaining to designated experiment
%   Returns the path(s) that a particular type of experiment file should be
%   located at for a specific experiment. i.e. if you want to know where a
%   file should be saved to, or where to load it from, use this function.
%
%   e.g. to get the paths for an experiments 2 photon TIFF movie:
%   DAT.EXPFILEPATH('mouse1', datenum(2013, 01, 01), 1, '2p-raw');
%
%   [full, filename] = expFilePath(ref, type, [reposlocation, ext])
%
%   [full, filename] = expFilePath(subject, date, seq, type, [reposlocation, ext])
%
%   Options for reposlocation are: 'all' (default), 'local', 'master' and 'remote'
%   Many options for type, e.g. 'block', '2p-raw', 'eyetracking', etc
%   If ext is specified, the path returned has the extention ext, otherwise
%   the default for that type is used.
%
% Part of Rigbox

% 2013-03 CB created

assert(length(varargin) > 1, 'Error: Not enough arguments supplied.')

parsed = catStructs(regexp(varargin{1}, dat.expRefRegExp, 'names'));
if isempty(parsed) % Subject, not ref
  if nargin > 4
    location = varargin{5};
    varargin(5) = [];
  else
    location = {};
  end
  typeIdx = 4;
else % Ref, not subject
  typeIdx = 2;
  if nargin > 2
    location = varargin{3};
    varargin(3) = [];
  else
    location = {};
  end
end

% tabulate the args to get complete rows
[varargin{1:end}, singleArgs] = tabulateArgs(varargin{:});

fileType = varargin{typeIdx};
extention = iff(any(numel(varargin) == [3,5]), varargin{end},...
  cell(1,length(varargin{1})));
if any(numel(varargin) == [3,5]); varargin(end) = []; end

% convert file types to file suffixes
[repos, suffix, dateLevel] = mapToCell(@typeInfo, fileType(:), extention(:));

reposArgs = cat(2, {repos}, location);

% and the rest are for the experiment reference
[expPath, expRef] = dat.expPath(varargin{1:end - 1}, reposArgs{:});

  function [repos, suff, dateLevel] = typeInfo(type, newExt)
    % whether this repository is at the date level or otherwise deeper at the sequence
    % level (default). FIXME: Date level doesn't work, perhaps this should
    % be modified to work with deeper sequences also? E.g.
    % default\2018-05-04\1\2
    dateLevel = false;
    repos = 'main';
    ext = '.mat'; 
    switch lower(type)
      case 'block' % MAT-file with info about each set of trials
        suff = '_Block';
      case 'hw-info' % MAT-file with info about the hardware used for an experiment
        suff = '_hardwareInfo';
      case '2p-raw' % TIFF with 2-photon raw fluorescence movies
        suff = '_2P.tif';
        ext = '.tif';
      case 'calcium-preview'
        suff = '_2P_CalciumPreview';
        ext = '.tif';
      case 'calcium-reg'
        suff = '_2P_CalciumReg';
        ext = '';
      case 'calcium-regframe'
        suff = '_2P_CalciumRegFrame';
        ext = '.tif';
      case 'timeline' % MAT-file with acquired timing information
        suff = '_Timeline';
      case 'calcium-roi'
        suff = '_ROI';
      case 'calcium-fc' % minimally filtered fractional change frames
        suff = '_2P_CalciumFC';
        ext = '';
      case 'calcium-ffc' % ROI filtered fractional change frames
        suff = '_2P_CalciumFFC';
        ext = '';
      case 'calcium-widefield-svd'
        suff = '_SVD';
        ext = '';
      case 'eyetracking'
        suff = '_eye';
        ext = '';
      case 'parameters' % MAT-file with parameters used for experiment
        suff = '_parameters';
      case 'lasermanip'
        suff = '_laserManip';
      case 'img-info'
        suff = '_imgInfo';
      case 'tmaze'
        suff = '_TMaze';
      case 'expdeffun'
        suff = '_expDef';
        ext = '.m';
      case 'svdspatialcomps'
        dateLevel = true;
      otherwise
        error('"%s" is not a valid file type', type);
    end
    % Append extention to suffix
    ext = iff(isempty(newExt)&&~ischar(newExt), ext, newExt);
    suff = iff((isempty(ext)&&ischar(ext))||(~isempty(ext)&&ext(1)=='.'),...
      [suff, ext], [suff, '.', ext]);
  end

% generate a filename for each experiment
filename = cellsprintf('%s%s', expRef, suffix);

% generate a fullpath for each experiment
fullpath = mapToCell(@(p, f) file.mkPath(p, f), expPath, filename);

if singleArgs
  % passed a single input, so make sure we return one
  fullpath = fullpath{1};
  filename = filename{1};
end

end