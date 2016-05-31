function entries = logEntries(subject)
%DAT.LOGENTRIES Retrieve all log entries for specified subject
%   e = DAT.LOGENTRIES(SUBJECT) Detailed explanation goes here
%
% Part of Rigbox

% 2013-03 CB created

%log on central repos is definitive one
p = dat.logPath(subject, 'master');
entries = loadVar(p, 'log');

%% Fix logs without id field
if ~isfield(entries, 'id')
  %this was a pre- 'id' log so add the field with appropriate values
  warning('Adding missing id field to whole log');
  ids = num2cell(1:numel(entries));
  [entries(:).id] = ids{:};
  superSave(p, struct('log', entries));
end

end

