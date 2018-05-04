function subjects = listSubjects(varargin)
%DAT.LISTSUBJECTS Lists recorded subjects
%   subjects = DAT.LISTSUBJECTS([alyxInstance]) Lists the experimental subjects present
%   in experiment info repository ('main').
%
% Optional input argument of an alyx instance will enable generating this
% list from alyx rather than from the directory structure on zserver
%
% Part of Rigbox

% 2013-03 CB created
% 2018-01 NS added Alyx compatibility

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
    
    % The master 'main' repository is the reference for the existence of
    % experiments, as given by the folder structure
    mainPath = dat.reposPath('main', 'master');
    
    dirs = file.list(mainPath, 'dirs');
    subjects = dirs(~cellfun(@(d)startsWith(d, '@'), dirs)); % exclude misc directories
end
end