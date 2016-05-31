function subjects = listSubjects()
%DAT.LISTSUBJECTS Lists recorded subjects
%   subjects = DAT.LISTSUBJECTS() Lists the experimental subjects present
%   in experiment info repository ('expInfo').
%
% Part of Rigbox

% 2013-03 CB created

% The master 'expInfo' repository is the reference for the existence of
% experiments, as given by the folder structure
expInfoPath = dat.reposPath('expInfo', 'master');

dirs = file.list(expInfoPath, 'dirs');
subjects = setdiff(dirs, {'misc'}); %exclude the misc directory

end