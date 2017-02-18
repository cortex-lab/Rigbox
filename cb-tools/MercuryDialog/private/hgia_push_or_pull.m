% Copyright 2010 The MathWorks, Inc.
% hgia_push_or_pull: trigger Mercurial's push/pull operation
function sbchanged = hgia_push_or_pull(cmd,have_rebase)
    sbchanged = 0;
    if nargin < 2
        have_rebase = 0;
    end
    switch cmd
        case 'push'
            query = 'outgoing';
            okbutton = 'Push';
            direction = 'to';
        case 'pull'
            query = 'incoming';
            okbutton = 'Pull';
            direction = 'from';
        otherwise
            error('invalid command');
    end
    [r location] = system('hg showconfig paths.default');
    if r
        location = '';
    end
    [r log] = system(['hg ' query ' -q -n --template "{rev}: {desc|firstline}\n"']);
    if r ~= 0
        if ~isempty(log)
            errordlg(log,'Error querying outgoing changes');
        else
            msgbox(['No ' query ' changes to ' cmd '.'],'Done');
        end
        return
    end
    if isempty(log)
        errordlg(['No changes to ' cmd '.'], 'Nothing to Do');
        return
    end
    changes = regexp(log,'\n','split');
    rev = listdlg('Name',['Changesets to ' cmd ' ' direction ' ' location],'ListString',changes,'SelectionMode','single','OKString',okbutton,'CancelString','Close','ListSize',[400 300]);
    if isempty(rev)
        return
    end
    if strcmp(cmd,'pull')
        models = hgia_close_models;
    end
    if have_rebase && strcmp(cmd,'pull')
        rb = questdlg('Do you want to rebase local changes after pull?','Rebase','Create Branch');
        if strcmp(rb,'Rebase')
            cmd = 'pull --rebase';
        end
    end
    id = sscanf(changes{rev},'%d');
    wb = waitbar(0.1,sprintf('%sing revision %d...',cmd,id));
    [r log] = system(sprintf('hg %s -r %d',cmd,id));
    waitbar(1,wb);
    close(wb);
    if r
        errordlg(log,['error during ' cmd]);
    end
    if ~strcmp(cmd,'pull')
        return
    end
    sbchanged = 1;
    [r log] = system('hg heads --template "{rev}:{desc|firstline}\n"');
    if r ~=  0
        errordlg(log,'Error querying heads');
        return
    end
    heads = regexp(log,'\n','split');
    if strcmp(heads{end},'')
        heads(end) = [];
    end
    if length(heads) == 1
        return
    end
    if length(heads) ~= 2
        errordlg(log,'Too many heads');
        [r log] = system('hg rollback');
        if r ~= 0
            errordlg(log,'Error rolling back');
        end
        return
    end
    sel = questdlg(log,'Merge following heads?','Rollback','Merge','Stop','Rollback');
    switch sel
        case 'Stop'
            return
        case 'Merge'
            [r log] = system('hg merge');
            if r ~= 0
                errordlg(log,'Error merging');
            end            
        case 'Rollback'
            [r log] = system('hg rollback');
            if r ~= 0
                errordlg(log,'Error rolling back');
            end
    end
    hgia_reopen_models(models);
end
