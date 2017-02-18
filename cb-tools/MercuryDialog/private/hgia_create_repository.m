% Copyright 2010 The MathWorks, Inc.
% hgia_create_repository: creates a new repository
function sbchanged = hgia_create_repository(handles)
    if nargin < 1
        handles = [];
    end
    sbchanged = 0;
    c = questdlg('This directory does not seem to have a valid repository. Do you want to create or clone one?','No Repository','Create','Clone','Cancel','Create');
    if isempty(c) || strcmp(c,'Cancel')
        if isfield(handles,'hgwindow')
            close(handles.hgwindow);
        end
        return
    end
    if strcmp(c,'Create')
        [r log] = system('hg init');
        if r
            errordlg(log,'Error Initializing');
            close(handles.hgwindow);
            return
        end
        sbchanged = 1;
%         ignores = {'.svn','CVS','*.asv','*.autosave'};
%         ign_re = {'.svn','CVS','.+\.asv','.+\.autosave'};
%         ign = listdlg('Name','Do you want to ignore certain subdirectories?','ListString',ignores,'SelectionMode','multiple','OKString','Ignore');
%         if ~isempty(ign);
%             hgi = fopen('.hgignore','w');
%             fprintf(hgi,'syntax: regexp\n');
%             for x = 1:length(ign)
%                 fprintf(hgi,'%s\n',ign_re{ign(x)});
%             end
%             fclose(hgi);
%         end
    else
        opts.Resize = 'on';
        rep = inputdlg('Enter a repository URL for cloning:','Select Repository',1,{''},opts);
        if isempty(rep)
            return
        end
        newname = {''};
        if isempty(find(rep{1} == '/',1)) && isempty(find(rep{1} == '\',1)) && exist(rep{1},'file')
            newname = inputdlg('To which directory shall the clone be written?','Target Directory',1,{''},opts);
            if isempty(newname)
                return
            end
        end
        [r log] = system(['hg clone ' rep{1} ' ' newname{1}]);
        if r == 0
            sl = find(rep{1} == '/');
            bs = find(rep{1} == '\');
            if isempty(sl)
                sl(1) = 0;
            end
            if isempty(bs)
                bs(1) = 0;
            end
            if isempty(newname{1})
                if bs(end) > sl(end)
                    dir = rep{1}(bs(end)+1:end);
                else
                    dir = rep{1}(sl(end)+1:end);
                end
            else
                dir = newname{1};
            end
            cd(dir);
            sbchanged = 1;
        else
            mode.Interpreter = 'none';
            mode.WindowStyle = 'modal';
            errordlg(log,'Error Cloning',mode);
            if ~isempty(handles) && isfiled(handles,'hgwindow')
                try
                    close(handles.hgwindow);
                catch
                end
            end
            return
        end
    end % of hgia_create_repository
