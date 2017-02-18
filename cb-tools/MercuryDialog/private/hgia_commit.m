% Copyright 2010 The MathWorks, Inc.
% hgia_commit: commit files to Mercurial
function sbchanged = hgia_commit(hgroot,files)
    sbchanged = 0;
    dlgopts.WindowStyle = 'modal';
    commitmsg = inputdlg('Enter a message for repository log:','Commit Message',5,{''},dlgopts);
    if isempty(commitmsg)
        return
    end
    if nargin < 1 || isempty(hgroot)
        [r hgroot] = system('hg root');
        if r
            errordlg(['unable to query hg root: ' hgroot]);
            return
        end
    end
    if nargin < 2
        files = {};
    end
    commitmsg = strrep(commitmsg{1},'"','\"');
    cmd = ['cd ' hgroot ' && hg commit -m "' commitmsg '"'];
    for f = 1:length(files)
        cmd = [cmd ' ' files{f}];
    end
    wb = waitbar(0.1,'committing...');
    [r log] = system(cmd);
    sbchanged = 1;
    waitbar(1,wb);
    close(wb);
    if r ~= 0
        errordlg(['Error commiting snapshot to repository: ' log]);
    end
end
