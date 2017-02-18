% Copyright 2010 The MathWorks, Inc.
% hgsbstatus: queries the current sandbox status
function hgsbstatus(block)
    cmd = 'hg status';
    if ~get(block,'hide_clean')
        cmd = [cmd ' -A'];
    end
    if get(block,'hide_autosave')
        cmd = [cmd ' -X "re:.*\.asv" -X "re:.*\.autosave'];
    end
    [r,status] = system(cmd);
    if r ~= 0
        status = 'no hg repository';
    end
    if status(end) == sprintf('\n')
        status(end) = [];
    end
    set(block,'status',status);
    set(block,'Description',status);
    set(block,'MaskDisplay','');
    set(block,'MaskDisplay','fprintf(''%s'',get(gcbh,''status''))');
end

