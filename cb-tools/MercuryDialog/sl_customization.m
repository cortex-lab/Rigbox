% Copyright 2010 The MathWorks, Inc.
% integrates Mercury Dialog into Simulink's Tool menu
function sl_customization(cm)
    cm.addCustomMenuFcn('Simulink:ToolsMenu',@HgDlgMenu);
end


function shg_menu = HgDlgMenu
    shg_menu = {@startHgDlg};
end


function schema = startHgDlg(callbackinfo)
    schema = sl_action_schema;
    schema.label = 'Mercury Dialog';
    schema.callback = @hgdlg;
end
