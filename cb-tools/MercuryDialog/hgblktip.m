% Copyright 2010 The MathWorks, Inc.
% hgblktip: support function for display 'hg tip' in a block
function hgblktip(block)
    [r,tip] = system('hg tip');
    if r ~= 0
        tip = '[no hg repository]';
    elseif tip(end) == sprintf('\n')
        tip(end) = [];
    end
    set(block,'tip',tip);
    set(block,'MaskDisplay','');
    set(block,'MaskDisplay','fprintf(''%s'',get(gcbh,''tip''))');
end
