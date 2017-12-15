function updateLogEntry(subject, id, newEntry)
%DAT.UPDATELOGENTRY Updates an existing experiment log entry
%   DAT.UPDATELOGENTRY(subject, id, newEntry)
%   TODO
%
% Part of Rigbox

% 2013-03 CB created

if isfield(newEntry, 'AlyxInstance')
  data = struct('subject', dat.parseExpRef(newEntry.value.ref),...
      'narrative', newEntry.comments);
  alyx.putData(newEntry.AlyxInstance,...
      newEntry.AlyxInstance.subsessionURL,...
      data);
  newEntry = rmfield(newEntry, 'AlyxInstance');
end

%load existing log from central repos
log = pick(load(dat.logPath(subject, 'master')), 'log');
%find the entry with specified id
idx = [log.id] == id;
%ensure one and only one entry with id
assert(sum(idx) == 1, 'Multiple entries with the same id');
%update
log(idx) = newEntry;
%store new log to all repos locations
superSave(dat.logPath(subject), struct('log', log));
end