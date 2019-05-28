function [expRef, expSeq] = newExp(subject, expDate, expParams)
%DAT.NEWEXP Create a new unique experiment in the database
%   [ref, seq] = DAT.NEWEXP(subject, expDate, expParams)
%   Create a new experiment by creating the relevant folder tree in the
%   local and main data repositories in the following format:
%
%   subject/
%          |_ YYYY-MM-DD/
%                       |_ expSeq/
%
%   If experiment parameters are passed into the function, they are saved
%   here.
%
%   See also DAT.PATHS
%
% Part of Rigbox

% 2013-03 CB created

if nargin < 2
  % use today by default
  expDate = now;
end

if nargin < 3
  % default parameters is empty variable
  expParams = [];
end

if ischar(expDate)
  % if the passed expDate is a string, parse it into a datenum
  expDate = datenum(expDate, 'yyyy-mm-dd');
end

% check the subject exists in the database
exists = any(strcmp(dat.listSubjects, subject));
assert(exists, sprintf('"%" does not exist', subject));

% retrieve list of experiments for subject
[~, dateList, seqList] = dat.listExps(subject);

% filter the list by expdate
filterIdx = dateList == floor(expDate);

% find the next sequence number
expSeq = max(seqList(filterIdx)) + 1;
if isempty(expSeq)
  % if none today, max will have returned [], so override this to 1
  expSeq = 1;
end

% main repository is the reference location for which experiments exist
[expPath, expRef] = dat.expPath(subject, floor(expDate), expSeq, 'main');
% ensure nothing went wrong in making a "unique" ref and path to hold
assert(~any(file.exists(expPath)), ...
  sprintf('Something went wrong as experiment folders already exist for "%s".', expRef));

% now make the folder(s) to hold the new experiment
assert(all(cellfun(@(p) mkdir(p), expPath)), 'Creating experiment directories failed');

% if the parameters had an experiment definition function, save a copy in
% the experiment's folder
if isfield(expParams, 'defFunction')
  assert(file.exists(expParams.defFunction),...
    'Experiment definition function does not exist: %s', expParams.defFunction);
  assert(all(cellfun(@(p)copyfile(expParams.defFunction, p),...
    dat.expFilePath(expRef, 'expDefFun'))),...
    'Copying definition function to experiment folders failed');
end

% now save the experiment parameters variable
superSave(dat.expFilePath(expRef, 'parameters'), struct('parameters', expParams));

if ~isempty(expParams)
  try  % save a copy of parameters in json
    % First, change all functions to strings
    f_idx = structfun(@(s)isa(s, 'function_handle'), expParams);
    fields = fieldnames(expParams);
    paramCell = struct2cell(expParams);
    paramCell(f_idx) = cellfun(@func2str, paramCell(f_idx),'UniformOutput', false);
    expParams = cell2struct(paramCell, fields);
    % Generate JSON path and save
    jsonPath = fullfile(fileparts(dat.expFilePath(expRef, 'parameters', 'master')),...
      [expRef, '_parameters.json']);
    savejson('parameters', expParams, jsonPath);
    % Register our JSON parameter set to Alyx
  catch ex
    warning(ex.identifier, 'Failed to save paramters as JSON: %s.', ex.message)
  end
end
end