function [fullpath, filename] = expFilePath(varargin)
%DAT.EXPFILEPATH Full path for file pertaining to designated experiment
%   Returns the path(s) that a particular type of experiment file should be
%   located at for a specific experiment. i.e. if you want to know where a
%   file should be saved to, or where to load it from, use this function.
%
%   e.g. to get the paths for an experiments 2 photon TIFF movie:
%   DAT.EXPFILEPATH('mouse1', datenum(2013, 01, 01), 1, '2p-raw');
%
%   [full, filename] = expFilePath(ref, type, [reposlocation])
%
%   [full, filename] = expFilePath(subject, date, seq, type, [reposlocation])
%
%   Options for reposlocation are: 'local' or 'master'
%   Many options for type, e.g. 'block', '2p-raw', 'eyetracking', etc
%
% Part of Rigbox

% 2013-03 CB created

if nargin == 3 || nargin == 5
  % repos argument was passed, save the value and remove from varargin
  location = varargin(end);
  varargin(end) = [];
elseif nargin < 2
  error('Not enough arguments supplied.');
else
  % repos argument not passed
  location = {};
end

% tabulate the args to get complete rows
[varargin{1:end}, singleArgs] = tabulateArgs(varargin{:});

% last argument is the file type
fileType = varargin{end};
% convert file types to file suffixes
[repos, suffix, dateLevel] = mapToCell(@typeInfo, fileType);

reposArgs = cat(2, {repos}, location);

% and the rest are for the experiment reference
[expPath, expRef] = dat.expPath(varargin{1:end - 1}, reposArgs{:});

  function [repos, suff, dateLevel] = typeInfo(type)
    % whether this repository is at the date level or otherwise deeper at the sequence
    % level (default). FIXME: Date level doesn't work, perhaps this should
    % be modified to work with deeper sequences also? E.g.
    % default\2018-05-04\1\2
    dateLevel = false;
    repos = 'main';
    switch lower(type)
      case 'block' % MAT-file with info about each set of trials
        suff = '_Block.mat';
      case 'hw-info' % MAT-file with info about the hardware used for an experiment
        suff = '_hardwareInfo.mat';
      case '2p-raw' % TIFF with 2-photon raw fluorescence movies
        suff = '_2P.tif';
      case 'calcium-preview'
        suff = '_2P_CalciumPreview.tif';
      case 'calcium-reg'
        suff = '_2P_CalciumReg';
      case 'calcium-regframe'
        suff = '_2P_CalciumRegFrame.tif';
      case 'timeline' % MAT-file with acquired timing information
        suff = '_Timeline.mat';
      case 'calcium-roi'
        suff = '_ROI.mat';
      case 'calcium-fc' % minimally filtered fractional change frames
        suff = '_2P_CalciumFC';
      case 'calcium-ffc' % ROI filtered fractional change frames
        suff = '_2P_CalciumFFC';
      case 'calcium-widefield-svd'
        suff = '_SVD';
      case 'eyetracking'
        suff = '_eye';
      case 'parameters' % MAT-file with parameters used for experiment
        suff = '_parameters.mat';
      case 'lasermanip'
        suff = '_laserManip.mat';
      case 'img-info'
        suff = '_imgInfo.mat';
      case 'tmaze'
        suff = '_TMaze.mat';
      case 'expdeffun'
        suff = '_expDef.m';
      case 'svdspatialcomps'
        dateLevel = true;
      otherwise
        error('"%s" is not a valid file type', type);
    end
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

