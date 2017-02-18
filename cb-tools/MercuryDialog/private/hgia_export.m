% Copyright 2010 The MathWorks, Inc.
% hgia_export: triggers Mercurial's export function
function hgia_export()
    revid = hgia_select_revision('Select Revisions for Export','Export',[],'multiple');
    if isempty(revid)
        return
    end
    rev = [];
    for r = 1:length(revid)
        rev = [rev sprintf(' %d',revid(r))];
    end
    outfile = uiputfile;
    if outfile == 0
        return
    end;
    wb = waitbar(0.1,'exporting...');
    [r log] = system(['hg export -g -o ' outfile rev]);
    waitbar(wb,1);
    close(wb);
    if r
        errordlg(log,'Error during export');
    end
end
