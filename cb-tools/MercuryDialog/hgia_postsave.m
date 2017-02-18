% Copyright 2010 The MathWorks, Inc.
% hgia_postsave: post save hook to commit model changes after saving the model
function hgia_postsave
    msg = inputdlg( 'Commit message:', ['Commit model ' bdroot ' to repository?'], 4);
    if isempty(msg)
      return
    end
    if isempty(msg{1})
      return
    end
    cmd = sprintf('hg commit -m "%s" %s.mdl',msg{1}, bdroot);
    [r log] = system(cmd);
    if r ~= 0
        errordlg(log,'Error committing');
    end
end
