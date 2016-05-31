function b = subjectExists(ref)
%DAT.SUBJECTEXISTS Check whether subject(s) exist(s)
%   b = DAT.SUBJECTEXISTS(ref) returns logical values indicating whether
%   each subject in 'ref' exists (which can be either a single string
%   reference or a cell array of string references).
%
% Part of Rigbox

% 2013-03 CB created

b = file.exists(fullfile(dat.reposPath('expInfo', 'master'), ref));

end