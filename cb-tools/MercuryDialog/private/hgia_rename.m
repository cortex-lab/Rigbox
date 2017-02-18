% Copyright 2010 The MathWorks, Inc.
% hgia_rename: renames a file in a Mercurial repository
function sbchanged = hgia_rename(file,hgroot)
    sbchanged = 0;
    [name,path] = uiputfile(file,'New Filename');
    if name == 0
        return
    end
    newname = [path name];
    wb = waitbar(0.1,'renaming file...');
    if nargin < 2 || isempty(hgroot)
        [r hgroot] = system('hg root');
        if r 
            close(wb);
            errordlg(hgroot,'Unable to query repository root');
            return
        end
        hgroot(end) = filesep;
    end
    if (ispc && strncmpi(hgroot,newname,length(hgroot)) == 0) ...
            || (ispc == 0 && strncmp(hgroot,newname,length(hgroot)) == 0)
        close(wb);
        errordlg('File must reside within sandbox','Invalid Filename');
        return
    end
    newname = newname(length(hgroot)+1:end);
    waitbar(0.2,wb);
    cwd = pwd;
    cd(hgroot);
    [r log] = system(['hg rename "' file '" "' newname '"']);
    cd(cwd)
    sbchanged = 1;
    waitbar(1,wb);
    close(wb);
    if r
        errordlg(log,['Error renaming ' file]);
    end
end
