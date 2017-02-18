% Copyright 2010 The MathWorks, Inc.
% hgia_close_models: close model files that are about to be updated
function models = hgia_close_models(files)
    models = {};
    if nargin < 1 
        files = find_system('SearchDepth',0);
        for f = 1:length(files)
            files{f} = [files{f} '.mdl'];
        end
    end
    for f = 1:length(files)
        file = files{f};
        if length(file) > 4 && strcmp(file(end-3:end),'.mdl')
            try
                mdl = bdroot(file(1:end-4));
                saveflag = 0;
                if strcmp(get_param(mdl,'Dirty'),'on')
                    a = questdlg(['Model ' mdl ' has unsaved changes.'],'Unsaved Changes','Save','Discard','Cancel','Cancel');
                    switch a
                        case 'Cancel'
                            cd(cwd);
                            return
                        case 'Save'
                            saveflag = 1;
                        case 'Discard'
                    end
                end
                try
                    close_system(mdl,saveflag);
                catch
                    err = lasterror;
                    errordlg(err.message,['Unable to close model ' mdl]);
                    cd(cwd);
                    return
                end
                models{end+1} = mdl;
            catch
                % the model is not open
            end
        end
    end
end
