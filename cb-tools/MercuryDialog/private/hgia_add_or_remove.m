% Copyright 2010 The MathWorks, Inc.
% hgia_add_or_remove: add/remove a file to/from Mercurial
function sbchanged = hgia_add_or_remove(operation,files,options,hgroot)
    sbchanged = 0;
    if strcmp(operation,'add')
        button = 'Add Files';
        exe = 'adding';
    elseif strcmp(operation,'rm')
        button = 'Remove Files';
        exe = 'removing';
    else
        error('invalid operation');
    end
    if nargin < 3
        options = [];
    end
    if nargin < 4
        [r hgroot] = system('hg root');
        if r 
            errordlg('unable to query repository root');
            return
        end
        hgroot(end) = filesep;
    end
    cwd = pwd;    
    if nargin < 2 || isempty(files)
        cmd = ['hg status -u -n ' options];
        wb = waitbar(0.1,'querying unknown files...');
        [r log] = system(cmd);
        waitbar(1,wb);
        close(wb);
        if r ~= 0
            errordlg(log,'Unable To Query Unknown Files');
            return
        end
        files = regexp(log,'\n','split');
        if isempty(files)
            errordlg('Unable to find unknown files.');
            return
        end
        files(end) = [];
        selected = listdlg('Name','Choose Files...','ListString',files,'SelectionMode','multiple','OKString',button,'CancelString','Close','ListSize',[400 300]);
        if isempty(selected)
            return
        end
    else
        selected = 1:length(files);
    end
    cd(hgroot);
    sbchanged = 1;
    wb = waitbar(0,[exe ' selected files...']);
    cmd = ['hg ' operation ' '];
    s = 1;
    while s <= length(selected)
        file = files{selected(s)};
        if length(cmd) + 1 + length(file) > 2047
            [r log] = system(cmd);
            if r 
                close(wb);
                cd(cwd);
                errordlg(log,['Failed to ' operation ' files']);
                return
            end
            waitbar(s/length(selected),wb);
            cmd = ['hg ' operation ' '];
        end
        if isempty(find(file == ' ',1)) && isempty(find(file == '&',1))
            cmd = [cmd ' ' file];
        else
            cmd = [cmd ' "' file '"'];
        end
        s = s+1;
    end
    [r log] = system(cmd);
    if r
        close(wb);
        cd(cwd);
        errordlg(log,['Failed to ' operation ' files']);
        return
    end
    waitbar(1,wb);
    cd(cwd);
    close(wb);
end
