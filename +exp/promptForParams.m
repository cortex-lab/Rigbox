function pars = promptForParams(expDef )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

parsStruct = exp.inferParameters(expDef);
defFunction = parsStruct.defFunction; % save to put back later
parsStruct = rmfield(parsStruct, 'defFunction');
pars = exp.Parameters(parsStruct);
warning('todo: implement modal dialog so we don''t return control until pars confirmed');
parsEditor = eui.ParamEditor(pars, figure);


end

