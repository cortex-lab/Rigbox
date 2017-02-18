% Copyright 2010 The MathWorks, Inc.
% hgmodellog: queries the model log
function hgmodellog(block)
    [r,log] = system(['hg log --template "{rev}: {desc|firstline}\n" ' bdroot '.mdl']);
    if r ~= 0
        log = '[no hg repository]';
    end
    if log(end) == sprintf('\n')
        log(end) = [];
    end
    set(block,'log',log);
    set(block,'MaskDisplay','');
    set(block,'MaskDisplay','fprintf(''%s'',get(gcbh,''log''))');
end
