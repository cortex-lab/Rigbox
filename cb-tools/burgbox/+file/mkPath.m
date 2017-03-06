function f = mkPath(varargin)
%FILE.MKPATH Build full file name from parts (same as MATLAB fullfile)
%   F = FILE.MKPATH(filepart1,...,filepartN) builds a full file path from
%   the folders and filename specified. This does exactly the same as fullfile
%   in MATLAB 2012, which allows combining array inputs to create multiple
%   paths and is provided for older versions of MATLAB whose fullfile does
%   not allow array inputs.
%
% Part of Burgbox

% 2013-05 CB created

[varargin{1:end}, singleArgs] = tabulateArgs(varargin{:});

f = cellfun(@fullfile, varargin{1:end}, 'Uni', false);

if singleArgs
  f = f{1};
end

end

