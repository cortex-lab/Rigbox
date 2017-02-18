% Copyright 2010 The MathWorks, Inc.
% hgia_archive: create an archive from a committed revision
function hgia_archive()
    revid = hgia_select_revision('Select Revision for Archive','Archive');
    if isempty(revid)
        return
    end
    rev = sprintf('%d',revid);
    filter = {
        '*.zip','.zip File';...
        '*.diff','.diff File';...
        '*','Directory';...
        '*.tgz','.tgz File';...
        '*.tbz2','.tbz2 File';...
        '*.tar','.tar File';...
        '*.tar.gz','.tar.gz File';...
        '*.tar.bz2','.tar.bz2 File';...
        };
    [name,path,ft] = uiputfile(filter,'Select Archive File and Type');
    if name == 0
        return
    end
    type = {'zip','','files','tgz','tbz2','tar','tgz','tbz2'};
    if ft ~= 3
        ext = filter{ft,1}(2:end);
        el = length(ext)-1;
        if length(name) < el || ~strcmp(name(end-el:end),ext)
            name = [name ext];
        end
    end
    wb = waitbar(0.2,'creating archive...');
    if ft == 2
        cmd = ['hg diff -c ' rev ' > ' path filesep name];
    else
        cmd = ['hg archive -t ' type{ft} ' -r ' rev ' ' path filesep name];
    end
    waitbar(1,wb);
    close(wb);
    [r log] = system(cmd);
    if r
        errordlg(log,'Error creating archive');
    end
end
