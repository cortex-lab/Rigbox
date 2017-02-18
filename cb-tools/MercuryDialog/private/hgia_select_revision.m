% Copyright 2010 The MathWorks, Inc.
% hgia_select_revision: interactively select a revision from the repository
function revid = hgia_select_revision(title,okbutton,files,mode)
    if nargin < 3
        files = [];
    end
    if nargin < 4
        mode = 'single';
    end
    revid = hglogdlg({title,okbutton,files,mode});
end
