function p = logPath(subject, varargin)
%DAT.LOGPATH Get the path a subjects log file
%   p = DAT.LOGPATH(subject, [location]) returns path(s) to the subject's
%   log file. Copies can be held in multiple locations, although the one at
%   the 'master' location is deemed to be the definitive one.
%
% Part of Rigbox

% 2013-03 CB created

%ensure the subject exists
assert(dat.subjectExists(subject), 'Subject "%s" does not exist', subject);
% get path(s) to expInfo repository
reposPath = dat.reposPath('expInfo', varargin{:});

filename = sprintf('%s_log.mat', subject);
subjectPath = file.mkPath(reposPath, subject);
p = file.mkPath(subjectPath, filename);

%if no log file exists yet, create a MAT file with an empty log
paths = ensureCell(p); %code below works best if paths assumed to be cell array
newLogPath = file.filterExists(paths, false);
if ~isempty(newLogPath)
  emptylog = struct('date', {}, 'dateStr', {}, 'type', {}, 'value', {}, 'comments', {}, 'id', {});
  superSave(newLogPath, struct('log', emptylog));
end

end

