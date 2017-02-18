% Copyright 2010 The MathWorks, Inc.
% hgia_resolved: marks confilcting files as resolved in Mercurial
function sbchanged = hgia_resolved(hgroot,files)
    sbchanged = 0;
    if nargin < 1 || isempty(hgroot)
        [r hgroot] = system('hg root');
        if r
            errordlg(['unable to query hg root: ' hgroot]);
            return
        end
    end
    if nargin < 2
        errordlg('no files have been selected to be marked as resolved');
        return;
    end
    cmd = ['cd ' hgroot ' && hg resolve -m'];
    for f = 1:length(files)
        cmd = [cmd ' ' files{f}];
    end
    wb = waitbar(0.1,'marking resolved...');
    [r log] = system(cmd);
    sbchanged = 1;
    waitbar(1,wb);
    close(wb);
    if r ~= 0
        errordlg(['Error marking files as resolved: ' log]);
    end
end
