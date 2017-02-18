% Copyright 2010 The MathWorks, Inc.
% hgsblog: queries the sandbox log
function hgsblog(block)
    [r,log] = system('hg log -l 10 --template "{rev}: {desc}\n"');
    if r ~= 0
        log = 'no hg repository';
    end
    if log(end) == sprintf('\n')
        log(end) = [];
    end
    set(block,'log',log);
    set(block,'MaskDisplay','');
    set(block,'MaskDisplay','fprintf(''%s'',get(gcbh,''log''))');
end
