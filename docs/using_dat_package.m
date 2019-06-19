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
% If you have alternate repos (e.g. 'main2Respository', 'altRepository'),
% use the remote flag to return all of them (used by the below functions):
loadPath = dat.reposPath('main', 'remote');
% To return all paths ending in 'Repository':
endInRepos = dat.reposPath('*');

% List experiments for a given subject
[ref, date, seq] = dat.listExps(subject);

% Return experiment path
% These functions can take the input as both a ref or three inputs
% (subject, date and sequence).  The input may also be a cell array of
% these.
p = dat.expPath(ref); %#ok<*NASGU>
[p, ref] = dat.expPath(subject, now, 1, 'main');

% Check a given experiment exists
bool = dat.expExists(ref);

% Return specific file path
[fullpath, filename] = dat.expFilePath(ref, 'block'); %#ok<*ASGLU>
[fullpath, filename] = dat.expFilePath(ref, 'block', 'master', 'json');
[fullpath, filename] = dat.expFilePath(subject, now, 1, 'timeline');

parameters = dat.expParams(ref);
block = dat.loadBlock(ref, expType);
clearCBToolsCache % Clear the cached block file

%% Manually creating experiments
% The expParams variable will be saved to 'localRepository' and master
% 'mainRepository' paths
[expRef, expSeq] = dat.newExp(subject, expDate, expParams);

%% Using expRefs
ref = dat.constructExpRef('subject', now, 2);
[subjectRef, expDate, expSequence] = dat.parseExpRef(ref);

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