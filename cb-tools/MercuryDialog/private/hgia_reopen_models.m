% Copyright 2010 The MathWorks, Inc.
% hgia_reopen_models: reopens models that were closed to perform a
% sandbox operation
function hgia_reopen_models(models)
    if isempty(models)
        return
    end
    a = questdlg('Do you want to reopen all reverted models?','Reopen reverted models?','Yes','No','Yes');
    if strcmp(a,'Yes')
        for m = 1:length(models)
            try
                open_system(models{m});
            catch
                err = lasterror;
                errordlg(err.message,'Error reopening model');
            end
        end
    end
end
