function [expRef, expSeq, url] = newExp(subject, expDate, expParams, AlyxInstance)
%DAT.NEWEXP Create a new unique experiment in the database
%   [ref, seq, url] = DAT.NEWEXP(subject, expDate, expParams[, AlyxInstance])
%   Create a new experiment by creating the relevant folder tree in the
%   local and main data repositories in the following format:
%
%   subject/
%          |_ YYYY-MM-DD/
%                       |_ expSeq/
%
%   If experiment parameters are passed into the function, they are saved
%   here, as a mat and in JSON (if possible).  If an instance of Alyx is
%   passed and a base session for the experiment date is not found, one is
%   created in the Alyx database. A corresponding subsession is also
%   created and the parameters file is registered with the sub-session.
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

if (nargin < 4 || isempty(AlyxInstance)) && ~strcmp(subject, 'default')
  % no instance of Alyx, don't create session on Alyx
  AlyxInstance = alyx.loginWindow;
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

% expInfo repository is the reference location for which experiments exist
[expPath, expRef] = dat.expPath(subject, floor(expDate), expSeq, 'expInfo');
% ensure nothing went wrong in making a "unique" ref and path to hold
assert(~any(file.exists(expPath)), ...
  sprintf('Something went wrong as experiment folders already exist for "%s".', expRef));

% now make the folder(s) to hold the new experiment
assert(all(cellfun(@(p) mkdir(p), expPath)), 'Creating experiment directories failed');

if ~strcmp(subject, 'default') % Ignore fake subject
  % if the Alyx Instance is set, find or create BASE session
  expDate = alyx.datestr(expDate); % date in Alyx format
  % Get list of base sessions
  sessions = alyx.getData(AlyxInstance,...
    ['sessions?type=Base&subject=' subject]);
  
  %If the date of this latest base session is not the same date as
  %today, then create a new base session for today
  if isempty(sessions) || ~strcmp(sessions{end}.start_time(1:10), expDate(1:10))
    d = struct;
    d.subject = subject;
    d.procedures = {'Behavior training/tasks'};
    d.narrative = 'auto-generated session';
    d.start_time = expDate;
    d.type = 'Base';
    %       d.users = {AlyxInstance.username};
    
    base_submit = alyx.postData(AlyxInstance, 'sessions', d);
    assert(isfield(base_submit,'subject'),...
      'Submitted base session did not return appropriate values');
    
    %Now retrieve the sessions again
    sessions = alyx.getData(AlyxInstance,...
      ['sessions?type=Base&subject=' subject]);
  end
  latest_base = sessions{end};
  
  %Now create a new SUBSESSION, using the same experiment number
  d = struct;
  d.subject = subject;
  d.procedures = {'Behavior training/tasks'};
  d.narrative = 'auto-generated session';
  d.start_time = expDate;
  d.type = 'Experiment';
  d.parent_session = latest_base.url;
  d.number = expSeq;
  %   d.users = {AlyxInstance.username};
  
  subsession = alyx.postData(AlyxInstance, 'sessions', d);
  assert(isfield(subsession,'subject'),...
    'Failed to create new sub-session in Alyx for %s', subject);
  url = subsession.url;
else
  url = [];
end

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
    if ~strcmp(subject, 'default')
      alyx.registerFile(jsonPath, 'json', url, 'Parameters', [], AlyxInstance);
    end
  catch ex
    warning(ex.identifier, 'Failed to save paramters as JSON: %s.\n Registering mat file instead', ex.message)
    % Register our parameter set to Alyx
    if ~strcmp(subject, 'default')
      alyx.registerFile(dat.expFilePath(expRef, 'parameters', 'master'), 'mat',...
        url, 'Parameters', [], AlyxInstance);
    end
  end
end
end