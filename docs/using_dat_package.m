%% Loading experiments
% Listing all subjects
subjects = dat.listSubjects;

% The subjects list is generated from the folder names in the main
% repository path
mainRepo = getOr(dat.paths, 'mainRepository');
% To get all paths you should save to for the "main" repository:
savePaths = dat.reposPath('main'); % savePaths is a string cell array
% To get the master location for the "main" repository:
loadPath = dat.reposPath('main', 'master'); % loadPath is a string

% List experiments for a given subject
[ref, date, seq] = dat.listExps(subject);

% Return experiment path
p = dat.expPath(ref);
[p, ref] = dat.expPath(subject, now, 1, 'main');

% Check a given experiment exists
bool = expExists(ref);

% Return specific file path
[fullpath, filename] = dat.expFilePath(ref, 'block');
[fullpath, filename] = dat.expFilePath(ref, 'block', 'master', 'json');
[fullpath, filename] = dat.expFilePath(subject, now, 1, 'timeline');

parameters = dat.expParams(ref);
block = dat.loadBlock(ref, expType);
clear BurgboxCache

%% Manually creating experiments
[expRef, expSeq] = newExp(subject, expDate, expParams);

%% Using expRefs
ref = dat.constructExpRef('subject', now, 2);
[subjectRef, expDate, expSequence] = parseExpRef(ref);

%% Loading other things
expType = 'custom';
p = dat.loadParamProfiles(expType);
dat.saveParamProfile(expType, profileName, params);
dat.delParamProfile(expType, profileName);

%% Using the log
% FIXME Remove dat.expLogRequest
% @body expLogRequest clearly an old attempt at logging meta data to a
% server via JSON.  This is now Alyx.
[result, info] = expLogRequest(instruction, varargin); 

e = dat.addLogEntry(subject, timestamp, type, value, comments, AlyxInstance);
p = dat.logPath(subject, 'all');
e = dat.logEntries(subject);
e = dat.updateLogEntry(subject, id, newEntry);