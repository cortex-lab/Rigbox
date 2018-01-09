function subjects = listSubjects(varargin)
%DAT.LISTSUBJECTS Lists recorded subjects
%   subjects = DAT.LISTSUBJECTS([alyxInstance]) Lists the experimental subjects present
%   in experiment info repository ('expInfo').
%
% Optional input argument of an alyx instance will enable generating this
% list from alyx rather than from the directory structure on zserver
%
% Part of Rigbox

% 2013-03 CB created
% 2018-01 NS added alyx compatibility

if nargin>0 && ~isempty(varargin{1}) % user provided an alyx instance
    ai = varargin{1}; % an alyx instance
    
    % get list of all living, non-stock mice from alyx
    s = alyx.getData(ai, 'subjects?stock=False&alive=True');
    
    % determine the user for each mouse
    respUser = cellfun(@(x)x.responsible_user, s, 'uni', false);
    
    % get cell array of subject names
    subjNames = cellfun(@(x)x.nickname, s, 'uni', false);
    
    % determine which subjects belong to this user
    thisUserSubs = sort(subjNames(strcmp(respUser, ai.username)));
    
    % all the subjects
    otherUserSubs = sort(subjNames(~strcmp(respUser, ai.username)));
    
    % the full, ordered list
    subjects = [{'default'}, thisUserSubs, otherUserSubs]';
else
    
    % The master 'expInfo' repository is the reference for the existence of
    % experiments, as given by the folder structure
    expInfoPath = dat.reposPath('expInfo', 'master');
    
    dirs = file.list(expInfoPath, 'dirs');
    subjects = setdiff(dirs, {'misc'}); %exclude the misc directory
end
end