% Copyright 2010 The MathWorks, Inc.
% hgia_revert: revert files in a Mercurial sandbox
function sbchanged = hgia_revert(files,hgroot,op)
    sbchanged = 0;
    if isempty(files)
        title = 'Repository Log';
    elseif ~iscell(files)
        files = {files};
        title = ['Log of File ' files{1}];
    elseif length(files) == 1
        title = ['Log of File ' files{1}];
    else
        title = 'Log of selected files';
    end
    filestr = '';
    for f = 1:length(files)
        file = files{f};
        filestr = [filestr ' ' file];
    end
    if nargin < 2 || isempty(hgroot)
        [r hgroot] = system('hg root');
        if r
            errordlg(hgroot,'Unable to query root');
            return
        end
        hgroot(end) = [];
    end
    if nargin < 3
        if isempty(files)
            op = 'Update';
        else
            op = 'Revert';
        end
    end
    cwd = pwd;
    cd(hgroot);
    revid = hgia_select_revision(title,op,files);
    if isempty(revid)
        cd(cwd);
        return
    end
    wb = waitbar(0.1,'reverting file(s)...');
    [r changes] = system(['hg status -m ' filestr]);
    waitbar(1,wb);
    close(wb);
    if r ~= 0
        cd(cwd);
        errordlg(changes,'Error querying modified files');
        return
    end
    if ~strcmp(changes,'')
        x = questdlg('You have outstanding uncommited changes. By reverting you will lose those changes. Do you want to continue?','Discard Uncommited Changes?','Discard','Stop','Stop');
        if strcmp(x,'Stop')
            cd(cwd);
            return
        end
    end
    
    %% handle unclosed model files
    models = hgia_close_models(files);
    %% perform revert
    if isempty(filestr)
        wb = waitbar(0.1,sprintf('updating to revision %d\n',revid));
        cmd = sprintf('hg update -r %d -C',revid);
    else
        wb = waitbar(0.1,sprintf('reverting to revision %d\n',revid));
        cmd = sprintf('hg revert -r %d %s',revid,filestr);
    end
    sbchanged = 1;
    [r log] = system(cmd);
    waitbar(1,wb);
    close(wb);
    if r ~= 0
        errordlg(['error rolling back: ' log]);
        return
    end
    
    %% reopen previous open model files
    hgia_reopen_models(models);
end
