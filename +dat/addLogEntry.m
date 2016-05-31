function e = addLogEntry(subject, timestamp, type, value, comments)
%DAT.ADDLOGENTRY Adds a new entry to the experiment log
%   e = DAT.ADDLOGENTRY(subject, timestamp, type, value, comments) files a
%   new log entry for 'subject' with the corresponding info.
%
% Part of Rigbox

% 2013-03 CB created

  function s = entry(id)
    dateStr = datestr(timestamp, 'ddd dd-mmm-yyyy HH:MM');
    s = struct('date', timestamp, 'dateStr', dateStr,...
      'type', type, 'value', value, 'comments', comments, 'id', id);
  end

%% load existing log from central repos
log = loadVar(dat.logPath(subject, 'master'), 'log');

%% find next free id
if isempty(log)
  nextidx = 1; %if log is empty, first id is 1
else
  nextidx = max([log.id]) + 1;
end

%% create and store entry
e = entry(nextidx);
log(nextidx) = e;

%% store updated log to *all* repos locations
superSave(dat.logPath(subject, 'all'), struct('log', log));

end

