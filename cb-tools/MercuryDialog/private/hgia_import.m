% Copyright 2010 The MathWorks, Inc.
% hgia_import: wraps Mercurial's import function
function sbchanged = hgia_import()
    sbchanged = 0;
    infile = uigetfile;
    if infile == 0
        return
    end
    wb = waitbar(0.1,'importing...');
    [r log] = system(['hg import ' infile]);
    waitbar(1,wb);
    close(wb);
    if r
        errordlg(log,'Error during import');
    end
    sbchanged = 1;
    return
end
