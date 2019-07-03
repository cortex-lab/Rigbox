function subjects = listSubjects()
%DAT.LISTSUBJECTS Lists recorded subjects
%   subjects = DAT.LISTSUBJECTS() Lists the experimental subjects present
%   in main experiment repository ('mainRepository').
%
% See also ALYX.LISTSUBJECTS
%
% Part of Rigbox

% 2013-03 CB created

% The master 'main' repository is the reference for the existence of
% experiments, as given by the folder structure
mainPath = dat.reposPath('main', 'remote');

dirs = unique(cellflat(rmEmpty(file.list(mainPath, 'dirs'))));
subjects = dirs(~cellfun(@(d)startsWith(d, '@'), dirs)); % exclude misc directories