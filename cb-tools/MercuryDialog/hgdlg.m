% Copyright 2010 The MathWorks, Inc.
% hgdlg brings up the GUI for interaction with Mercurial
function varargout = hgdlg(varargin)
% HGDLG M-file for hgdlg.fig
%      HGDLG, by itself, creates a new HGDLG or raises the existing
%      singleton*.
%
%      H = HGDLG returns the handle to a new HGDLG or the handle to
%      the existing singleton*.
%
%      HGDLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HGDLG.M with the given input arguments.
%
%      HGDLG('Property','Value',...) creates a new HGDLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before hgdlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to hgdlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help hgdlg

% Last Modified by GUIDE v2.5 28-Apr-2010 17:20:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @hgdlg_OpeningFcn, ...
                   'gui_OutputFcn',  @hgdlg_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before hgdlg is made visible.
function hgdlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to hgdlg (see VARARGIN)

% Choose default command line output for hgdlg

if verLessThan('MATLAB','7.4')
    errordlg('Please use MATLAB R2007a or later.','Unsupported release');
    try
        close(handles.hgwindow);
    catch
    end
end
wb = waitbar(0.0,'');
if ~isfield(handles,'output')
    waitbar(0.0,wb,'querying vdiff support...');
    handles.output = hObject;
    [handles.have_vdiff null] = system('hg help vdiff');
    waitbar(0.1,wb,'querying purge support...');
    [handles.have_purge null] = system('hg help purge');
    if handles.have_purge ~= 0
        set(handles.purge_entry,'Enable','off');
    end
    waitbar(0.2,wb,'querying rebase support...');
    [handles.have_rebase null] = system('hg help rebase');
    hgia_setup;
    cfgfile = [matlabroot filesep 'toolbox' filesep 'local' filesep 'hg_cfg.mat'];
    if exist(cfgfile,'file') && ~isempty(whos('-file',cfgfile,'hg_cfg'))
        waitbar(0.3,wb,'loading config file...')
        x = load(cfgfile,'hg_cfg');
        hg_cfg = x.hg_cfg;
        waitbar(0.4,wb,'applying config...')
        if isfield(hg_cfg,'show_added')
            set(handles.show_added,'Checked',hg_cfg.show_added);
        end
        if isfield(hg_cfg,'show_deleted')
            set(handles.show_deleted,'Checked',hg_cfg.show_deleted);
        end
        if isfield(hg_cfg,'show_removed')
            set(handles.show_removed,'Checked',hg_cfg.show_removed);
        end
        if isfield(hg_cfg,'show_modfied')
            set(handles.show_modified,'Checked',hg_cfg.show_modified);
        end
        if isfield(hg_cfg,'show_unknown')
            set(handles.show_unknown,'Checked',hg_cfg.show_unknown);
        end
        if isfield(hg_cfg,'show_clean')
            set(handles.show_clean,'Checked',hg_cfg.show_clean);
        end
        if isfield(hg_cfg,'show_subtree')
            set(handles.show_subtree,'Checked',hg_cfg.show_subtree);
        end
        if isfield(hg_cfg,'show_autosave')
            set(handles.autosave_entry,'Checked',hg_cfg.show_autosave);
        end
        if isfield(hg_cfg,'show_slprj')
            set(handles.slprj_entry,'Checked',hg_cfg.show_slprj);
        end
        if isfield(hg_cfg,'show_rtw')
            set(handles.rtw_entry,'Checked',hg_cfg.show_rtw);
        end
    end
end
options = get_excludes(handles);
if strcmp(get(handles.show_modified,'Checked'),'on')
    options = [options ' -m'];
end
if strcmp(get(handles.show_added,'Checked'),'on')
    options = [options ' -a'];
end
if strcmp(get(handles.show_removed,'Checked'),'on')
    options = [options ' -r'];
end
if strcmp(get(handles.show_deleted,'Checked'),'on')
    options = [options ' -d'];
end
if strcmp(get(handles.show_clean,'Checked'),'on')
    options = [options ' -c'];
end
if strcmp(get(handles.show_unknown,'Checked'),'on')
    options = [options ' -u'];
end
if strcmp(get(handles.show_ignored,'Checked'),'on')
    options = [options ' -i'];
end
if strcmp(get(handles.show_subtree,'Checked'),'on')
    options = [options ' .'];
end
if ispc
    xcd();
end
if ~isfield(handles,'hgroot') || ~strncmp(handles.hgroot,pwd,length(handles.hgroot))
    waitbar(0.4,wb,'querying hg root...');
    [r hgroot] = system('hg root');
    if r
        guidata(hObject, handles);
        if hgia_create_repository(handles)
            hgdlg_OpeningFcn(handles.output,[],handles);
        else
            try
                close(handles.hgwindow);
            catch
            end
            close(wb);
            return
        end
        handles.hgroot = [pwd filesep];
    else
        hgroot(end) = filesep;
        handles.hgroot = hgroot;
    end
    if strcmp(get(handles.show_subtree,'Checked'),'off')
        handles.wroot = handles.hgroot;
    else
        handles.wroot = [pwd filesep];
    end
    set(handles.hgwindow,'Name',['Hg repository at ' hgroot]);
end
if strcmp(get(handles.show_subtree,'Checked'),'on')
    dirs = {pwd};
    waitbar(0.5,wb,'reading directory...');
    files = dir;
    for f = 1:length(files)
        if ~files(f).isdir || strcmp(files(f).name,'.') || strcmp(files(f).name,'.hg')
            continue
        end
        if strcmp(files(f).name,'..') && (~isfield(handles,'hgroot') || strcmp([pwd filesep],handles.hgroot))
            continue
        end
        dirs{end+1} = files(f).name;
    end
    set(handles.dirmenu,'Enable','on');
else
    dirs = {handles.hgroot};
    set(handles.dirmenu,'Enable','off');
end
set(handles.dirmenu,'String',dirs);
set(handles.dirmenu,'Value',1);
waitbar(0.6,wb,'updating view...');
hgcmd = ['hg status' options];
%disp(hgcmd);
[r status] = system(hgcmd);
waitbar(1,wb);
close(wb);
if r ~= 0
    guidata(hObject, handles);
    if hgia_create_repository(handles)
        hgdlg_OpeningFcn(handles.output,[],handles);
    else
        try
            close(handles.hgwindow);
        catch
        end
    end
    return
end
files = regexp(status,'\n','split');
if ~isempty(files) && strcmp(files{end},'')
    files = files(1:end-1);
end
filenames = cell(1,length(files));
filestrings = cell(1,length(files));
for f = 1:length(files)
    file = files{f}(3:end);
    switch files{f}(1)
    case '?'
        str = ['UNKNOWN:  ' file];
    case 'C'
        str = ['CLEAN:    ' file];
    case 'M'
        str = ['MODIFIED: ' file];
    case 'A'
        str = ['ADDED:    ' file];
    case 'R'
        str = ['REMOVED:  ' file];
    case '!'
        str = ['LOST:     ' file];
    case 'I'
        str = ['IGNORED:  ' file];
    case ' '
        str = ['RENAMED:  ' file];
    otherwise
        error('unknown file status');
    end
    filenames{f} = files{f}(3:end);
    filestrings{f} = str;
end
handles.filenames = filenames;
handles.filestrings = filestrings;
set(handles.filelist,'String',filestrings);
set(handles.filelist,'Value',1);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes hgdlg wait for user response (see UIRESUME)
% uiwait(handles.hgwindow);


% --- Outputs from this function are returned to the command line.
function varargout = hgdlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isfield(handles,'output')
    varargout{1} = handles.output;
else
    varargout{1} = {};
end


% --- Executes on selection change in filelist.
function filelist_Callback(hObject, eventdata, handles)
% hObject    handle to filelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns filelist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from filelist


% --- Executes during object creation, after setting all properties.
function filelist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in show_grt.
function show_grt_Callback(hObject, eventdata, handles)
% hObject    handle to show_grt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_grt
    hgdlg_OpeningFcn(handles.output,[],handles);
    

% --- Executes on button press in show_ert.
function show_ert_Callback(hObject, eventdata, handles)
% hObject    handle to show_ert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_ert
    hgdlg_OpeningFcn(handles.output,[],handles);


% --- Executes on button press in show_slprj.
function show_slprj_Callback(hObject, eventdata, handles)
% hObject    handle to show_slprj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_slprj
    hgdlg_OpeningFcn(handles.output,[],handles);


% --- Executes on button press in add_button.
function add_file_Callback(hObject, eventdata, handles)
% hObject    handle to add_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fnr = get(handles.filelist,'Value');
    if isempty(fnr)
        return
    end
    if hgia_add_or_remove('add',handles.filenames(fnr(:)),get_excludes(handles),handles.wroot)
        hgdlg_OpeningFcn(handles.output,[],handles);
    end

% --- Executes on button press in delete_button.
function remove_file_Callback(hObject, eventdata, handles)
% hObject    handle to remove_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fnr = get(handles.filelist,'Value');
    if isempty(fnr)
        return
    end
    wb = waitbar(0,'preparing to remove files...');
    nf = length(fnr);
    cwd = pwd;
    if strcmp(get(handles.show_subtree,'Checked'),'off')
        cd(handles.hgroot);
    end    
    for f = 1:length(fnr)
        waitbar(f/nf,wb,sprintf('removing file %s...',strrep(handles.filenames{f},'\','\\')));
        cmd = ['hg rm ' handles.filenames{fnr(f)}];
        [r log] = system(cmd);
        if ~isempty(log)
            errordlg(sprintf('error deleting file "%s":\n%s',handles.filenames{f},log),'Error Removing File','modal');
        end
    end
    cd(cwd);
    close(wb);
    hgdlg_OpeningFcn(hObject,[],handles);


% --- Executes on button press in commit_button.
function commit_button_Callback(hObject, eventdata, handles)
% hObject    handle to commit_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if hgia_commit(handles.wroot)
        hgdlg_OpeningFcn(hObject,[],handles);
    end
    
% --- Executes on button press in history_button.
function history_button_Callback(hObject, eventdata, handles)
% hObject    handle to history_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if hgia_revert('',handles.hgroot)
        hgdlg_OpeningFcn(handles.output,[],handles);
    end
    


% --- Executes when hgwindow is resized.
function hgwindow_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to hgwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    pos = get(hObject,'Position');
    xs = pos(3);
    ys = pos(4);
    if xs < 300
        xs = 300;
    end
    if ys < 200
        ys = 200;
    end
    if xs ~= pos(3) || ys ~= pos(4)
        pos(3) = xs;
        pos(4) = ys;
        set(hObject,'Position',pos);
    end
    pos = [xs-120 10 110 25];
    set(handles.close_button,'Position',pos);
    pos = [xs-250 10 110 25];
    set(handles.history_button,'Position',pos);
    pos = [xs-380 10 110 25];
    set(handles.commit_button,'Position',pos);
    pos = [10 ys-30 xs-20 25];
    set(handles.dirmenu,'Position',pos)
    pos = [10 50 xs-20 ys-80];
    set(handles.filelist,'Position',pos)
%end % of hgwindow_ResizeFcn


% --- Executes on button press in filelog_button.
function file_log_Callback(hObject, eventdata, handles)
% hObject    handle to filelog_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fnr = get(handles.filelist,'Value');
    filename = handles.filenames(fnr(:));
    if hgia_revert(filename,handles.wroot)
        hgdlg_OpeningFcn(handles.output,[],handles);
    end


% --- Executes on button press in show_rtw.
function show_rtw_Callback(hObject, eventdata, handles)
% hObject    handle to show_rtw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_rtw
    hgdlg_OpeningFcn(handles.output,[],handles);


% --- Executes on button press in show_autosave.
function show_autosave_Callback(hObject, eventdata, handles)
% hObject    handle to show_autosave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_autosave
    hgdlg_OpeningFcn(handles.output,[],handles);


% --- Executes on button press in close_button.
function close_button_Callback(hObject, eventdata, handles)
% hObject    handle to close_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.hgwindow);
    

% --------------------------------------------------------------------
function filelist_menu_Callback(hObject, eventdata, handles)
% hObject    handle to filelist_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function file_menu_Callback(hObject, eventdata, handles)
% hObject    handle to file_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function revert_entry_Callback(hObject, eventdata, handles)
% hObject    handle to revert_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function archive_entry_Callback(hObject, eventdata, handles)
% hObject    handle to archive_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hgia_archive();
    
% --------------------------------------------------------------------
function add_files_entry_Callback(hObject, eventdata, handles)
% hObject    handle to add_files_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if hgia_add_or_remove('add',[],[],handles.wroot)
        hgdlg_OpeningFcn(handles.output,[],handles,get_excludes(handles));
    end

% --------------------------------------------------------------------
function remove_files_entry_Callback(hObject, eventdata, handles)
% hObject    handle to remove_files_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if hgia_add_or_remove('remove',[],[],handles.wroot)
        hgdlg_OpeningFcn(handles.output,[],handles);
    end

% --------------------------------------------------------------------
function update_entry_Callback(hObject, eventdata, handles)
% hObject    handle to update_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if hgia_revert('',handles.hgroot,'Update')
        hgdlg_OpeningFcn(handles.output,[],handles);
    end


% --------------------------------------------------------------------
function pull_entry_Callback(hObject, eventdata, handles)
% hObject    handle to pull_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if hgia_push_or_pull('pull')
        hgdlg_OpeningFcn(handles.output,[],handles);
    end


% --------------------------------------------------------------------
function push_entry_Callback(hObject, eventdata, handles)
% hObject    handle to push_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if hgia_push_or_pull('push')
        hgdlg_OpeningFcn(handles.output,[],handles);
    end

% --------------------------------------------------------------------
function repository_menu_Callback(hObject, eventdata, handles)
% hObject    handle to repository_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function close_entry_Callback(hObject, eventdata, handles)
% hObject    handle to close_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.hgwindow);


% --------------------------------------------------------------------
function view_menu_Callback(hObject, eventdata, handles)
% hObject    handle to view_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function slprj_entry_Callback(hObject, eventdata, handles)
% hObject    handle to slprj_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject,'Checked'),'on')
        set(hObject,'Checked','off');
    else
        set(hObject,'Checked','on');
    end
    hgdlg_OpeningFcn(handles.output,[],handles);


% --------------------------------------------------------------------
function rtw_entry_Callback(hObject, eventdata, handles)
% hObject    handle to rtw_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject,'Checked'),'on')
        set(hObject,'Checked','off');
    else
        set(hObject,'Checked','on');
    end
    hgdlg_OpeningFcn(handles.output,[],handles);


% --------------------------------------------------------------------
function autosave_entry_Callback(hObject, eventdata, handles)
% hObject    handle to autosave_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject,'Checked'),'on')
        set(hObject,'Checked','off');
    else
        set(hObject,'Checked','on');
    end
    hgdlg_OpeningFcn(handles.output,[],handles);


% --------------------------------------------------------------------
function show_removed_Callback(hObject, eventdata, handles)
% hObject    handle to show_removed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject,'Checked'),'on')
        set(hObject,'Checked','off');
    else
        set(hObject,'Checked','on');
    end
    hgdlg_OpeningFcn(handles.output,[],handles);


% --------------------------------------------------------------------
function show_added_Callback(hObject, eventdata, handles)
% hObject    handle to show_added (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject,'Checked'),'on')
        set(hObject,'Checked','off');
    else
        set(hObject,'Checked','on');
    end
    hgdlg_OpeningFcn(handles.output,[],handles);


% --------------------------------------------------------------------
function show_deleted_Callback(hObject, eventdata, handles)
% hObject    handle to show_deleted (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject,'Checked'),'on')
        set(hObject,'Checked','off');
    else
        set(hObject,'Checked','on');
    end
    hgdlg_OpeningFcn(handles.output,[],handles);

% --------------------------------------------------------------------
function show_clean_Callback(hObject, eventdata, handles)
% hObject    handle to show_clean (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject,'Checked'),'on')
        set(hObject,'Checked','off');
    else
        set(hObject,'Checked','on');
    end
    hgdlg_OpeningFcn(handles.output,[],handles);


% --------------------------------------------------------------------
function show_unknown_Callback(hObject, eventdata, handles)
% hObject    handle to show_unknown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject,'Checked'),'on')
        set(hObject,'Checked','off');
    else
        set(hObject,'Checked','on');
    end
    hgdlg_OpeningFcn(handles.output,[],handles);


% --------------------------------------------------------------------
function show_ignored_Callback(hObject, eventdata, handles)
% hObject    handle to show_ignored (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject,'Checked'),'on')
        set(hObject,'Checked','off');
    else
        set(hObject,'Checked','on');
    end
    hgdlg_OpeningFcn(handles.output,[],handles);


% --------------------------------------------------------------------
function show_modified_Callback(hObject, eventdata, handles)
% hObject    handle to show_modified (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject,'Checked'),'on')
        set(hObject,'Checked','off');
    else
        set(hObject,'Checked','on');
    end
    hgdlg_OpeningFcn(handles.output,[],handles);


% --------------------------------------------------------------------
function export_entry_Callback(hObject, eventdata, handles)
% hObject    handle to export_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hgia_export();
    

% --------------------------------------------------------------------
function rename_file_Callback(hObject, eventdata, handles)
% hObject    handle to rename_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fnr = get(handles.filelist,'Value');
    if isempty(fnr)
        return
    end
    filename = handles.filenames(fnr(:));
    if length(filename) ~= 1
        errordlg('To Rename, you must select a single file.');
        return
    end
    if hgia_rename(filename{1},handles.wroot)
        hgdlg_OpeningFcn(handles.output,[],handles);
    end


% --------------------------------------------------------------------
function update_view_Callback(hObject, eventdata, handles)
% hObject    handle to update_view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hgdlg_OpeningFcn(handles.output,[],handles);


% --------------------------------------------------------------------
function show_diff_Callback(hObject, eventdata, handles)
% hObject    handle to show_diff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fnr = get(handles.filelist,'Value');
    if isempty(fnr)
        return
    end
    wb = waitbar(0.1,'querying differences...');
    cwd = pwd;
    cd(handles.wroot);
    waitbar(0.2,wb);
    if isfield(handles,'have_vdiff') && (handles.have_vdiff == 0)
        cmd = 'hg vdiff';
    else
        cmd = 'hg diff -g';
    end
    files = '';
    for f = 1:length(fnr)
        files = [files ' ' handles.filenames{fnr(f)}];
    end
    [r log] = system([cmd files]);
    cd(cwd);
    waitbar(1,wb);
    close(wb);
    if r == 0
        if ~isfield(handles,'have_vdiff') || (handles.have_vdiff ~= 0)
            diffview({log},['Differences of' files]);
        end
    elseif isfield(handles,'have_vdiff') && (handles.have_vdiff == 0)
        % ignore errors by vdiff
        %handles.have_vdiff = 1;
        %guidata(hObject, handles);
        %show_diff_Callback(hObject,eventdata,handles);
    elseif ~isempty(log)
        errordlg(log,'error querying differences');
    end

    
function excludes = get_excludes(handles)
    excludes = '';
    if strcmp(get(handles.autosave_entry,'Checked'),'off')
        if ispc
            excludes = ' -X "re:.*\.asv" -X "re:.*\.autosave$"';
        else
            excludes = ' -X ''re:.*\.asv'' -X ''re:.*\.autosave$''';
        end
    end
    if strcmp(get(handles.slprj_entry,'Checked'),'off')
        if ispc
            excludes = [excludes ' -X "re:(.+/|^)slprj/.*"'];
        else
            excludes = [excludes ' -X ''re:(.+/|^)slprj/.*'''];
        end
    end
    if strcmp(get(handles.rtw_entry,'Checked'),'off')
        if ispc
            excludes = [excludes ' -X "re:.*_rtw($|/)"'];
        else
            excludes = [excludes ' -X ''re:.*_rtw($|/)'''];
        end
    end


% --------------------------------------------------------------------
function show_subtree_Callback(hObject, eventdata, handles)
% hObject    handle to show_subtree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject,'Checked'),'on')
        set(hObject,'Checked','off');
    else
        set(hObject,'Checked','on');
    end
    hgdlg_OpeningFcn(handles.output,[],handles);


% --------------------------------------------------------------------
function save_options_Callback(hObject, eventdata, handles)
% hObject    handle to save_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hg_cfg = struct;
    hg_cfg.show_autosave = get(handles.autosave_entry,'Checked');
    hg_cfg.show_slprj = get(handles.slprj_entry,'Checked');
    hg_cfg.show_rtw = get(handles.rtw_entry,'Checked');
    hg_cfg.show_added = get(handles.show_added,'Checked');
    hg_cfg.show_removed = get(handles.show_removed,'Checked');
    hg_cfg.show_modified = get(handles.show_modified,'Checked');
    hg_cfg.show_unknown = get(handles.show_unknown,'Checked');
    hg_cfg.show_deleted = get(handles.show_deleted,'Checked');
    hg_cfg.show_clean = get(handles.show_clean,'Checked');
    hg_cfg.show_subtree = get(handles.show_subtree,'Checked');
    save([matlabroot filesep 'toolbox' filesep 'local' filesep 'hg_cfg.mat'],'hg_cfg');
    

% --------------------------------------------------------------------
function commit_entry_Callback(hObject, eventdata, handles)
% hObject    handle to commit_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if hgia_commit(handles.wroot)
        hgdlg_OpeningFcn(hObject,[],handles);
    end


% --------------------------------------------------------------------
function open_file_Callback(hObject, eventdata, handles)
% hObject    handle to open_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fnr = get(handles.filelist,'Value');
    if isempty(fnr)
        return
    end
    cwd = pwd;
    if strcmp(get(handles.show_subtree,'Checked'),'off')
        cd(handles.hgroot);
    end
    for f = 1:length(fnr)
        try
            open(handles.filenames{fnr(f)});
        catch
        end
    end
    cd(cwd);


% --------------------------------------------------------------------
function annotate_file_Callback(hObject, eventdata, handles)
% hObject    handle to annotate_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fnr = get(handles.filelist,'Value');
    if isempty(fnr)
        return
    end
    wb = waitbar(0.1,'querying annotations...');
    cwd = pwd;
    if strcmp(get(handles.show_subtree,'Checked'),'off')
        cd(handles.hgroot);
    end
    waitbar(0.2,wb);
    cmd = 'hg annotate';
    for f = 1:length(fnr)
        cmd = [cmd ' ' handles.filenames{fnr(f)}];
    end
    [r log] = system(cmd);
    cd(cwd);
    waitbar(1,wb);
    close(wb);
    if r
        errordlg(log,'unable annotate');
        return
    end
    diffview({log});


% --------------------------------------------------------------------
function rollback_entry_Callback(hObject, eventdata, handles)
% hObject    handle to rollback_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    a = questdlg(sprintf('The most recent commit, import, pull, push, or unbundle will be undone.\nNo changes on the working directory will be performed.\nDo you really want to rollback the last transaction?'),'Rollback?','Rollback','Cancel','Cancel');
    if strcmp(a,'Rollback')
        [r log] = system('hg rollback -y -q');
        if r
            errordlg(log,'Error during rollback','modal');
        elseif ~isempty(log)
            msgbox(log,'Rollback output','modal');
        end
        hgdlg_OpeningFcn(hObject,[],handles);
    end


% --------------------------------------------------------------------
function commit_file_Callback(hObject, eventdata, handles)
% hObject    handle to commit_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fnr = get(handles.filelist,'Value');
    if isempty(fnr)
        return
    end
    files = cell(1,length(fnr));
    for f = 1:length(fnr)
        files{f} = handles.filenames{fnr(f)};
    end
    if hgia_commit(handles.wroot,files)
        hgdlg_OpeningFcn(hObject,[],handles);
    end
    


% --------------------------------------------------------------------
function resolve_file_Callback(hObject, eventdata, handles)
% hObject    handle to resolve_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if hgia_resolved('')
        hgdlg_OpeningFcn(handles.output,[],handles);
    end


% --------------------------------------------------------------------
function Sandbox_Callback(hObject, eventdata, handles)
% hObject    handle to Sandbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function purge_entry_Callback(hObject, eventdata, handles)
% hObject    handle to purge_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    a = questdlg('Do you really want to delete all untracked files and directories?','Perform purge?','Purge','Cancel','Cancel');
    if strcmp(a,'Purge')
        wb = waitbar(0.1,'querying annotations...');
        [r log] = system('hg purge');
        waitbar(1,wb);
        close(wb);
        if r
            errordlg(log,'Error purging');
        end
        hgdlg_OpeningFcn(hObject,[],handles);
    end

% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function about_entry_Callback(hObject, eventdata, handles)
% hObject    handle to about_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    helpdlg(sprintf('Mercury Dialog - Version 1.0\nThis GUI is a frontend for Mercurial, written by Thomas Maier-Komor.\nIf you have questions or comments, please contact thomas.maier-komor@mathworks.de.'),'About Mercury Dialog');


% --- Executes on selection change in dirmenu.
function dirmenu_Callback(hObject, eventdata, handles)
% hObject    handle to dirmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns dirmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dirmenu
    val = get(handles.dirmenu,'Value');
    if val == 1
        return
    end
    dirs = get(handles.dirmenu,'String');
    cd(dirs{val});
    hgdlg_OpeningFcn(hObject,[],handles);


% --- Executes during object creation, after setting all properties.
function dirmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dirmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function tag_entry_Callback(hObject, eventdata, handles)
% hObject    handle to tag_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    tag = inputdlg('Revision Tag:','Enter a tag');
    if isempty(tag)
        return
    end
    mode = questdlg('Do you want to tag the tip revision?','Revision to Tag','Tip','Other','Cancel','Tip');
    switch mode
        case 'Cancel'
            return
        case 'Tip'
            cmd = sprintf('hg tag "%s"', tag{1});
        case 'Other'
            rev = hgia_select_revision('Revision to Tag','Tag');
            if isempty(rev)
                return
            end
            cmd = sprintf('hg tag -r %d "%s"', rev, tag{1});
    end
    [r log] = system(cmd);
    if r
        errordlg(log,'Error tagging');
    end


% --------------------------------------------------------------------
function cbranch_entry_Callback(hObject, eventdata, handles)
% hObject    handle to cbranch_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    name = inputdlg('Branch Name:', 'Enter branch name');
    if isempty(name)
        return
    end
    [r log] = system(['hg branch ' name{1}]);
    if r
        errordlg(log,'Error creating branch');
    end

% --------------------------------------------------------------------
function sbranch_entry_Callback(hObject, eventdata, handles)
% hObject    handle to sbranch_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [r log] = system('hg branches');
    if r
        errordlg(log,'Error querying branches');
        return
    end
    branches = regexp(log,'\n','split');
    if isempty(branches{end})
        branches(end) = [];
    end
    branches = regexprep(branches,' (inactive)','');
    branches = regexp(branches,' +','split');
    branchnames = cell(1,length(branches));
    for b = 1:length(branches)
        branchnames{b} = branches{b}{1};
    end
    s = listdlg('PromptString','Select Branch','ListString',branchnames,'OKString','Actiate','SelectionMode','single');
    if ~isempty(s)
        [r log] = system(sprintf('hg update %s',branchnames{s}));
        if r
            errordlg(log,'Error switching branch');
        end
    end
    hgdlg_OpeningFcn(hObject,[],handles);
    


% --------------------------------------------------------------------
function import_entry_Callback(hObject, eventdata, handles)
% hObject    handle to import_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if hgia_import()
        hgdlg_OpeningFcn(hObject,[],handles);
    end


% --------------------------------------------------------------------
function license_entry_Callback(hObject, eventdata, handles)
% hObject    handle to license_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    mfile = which('hgdlg.m');
    lic_txt_file = fullfile(fileparts(mfile),'license.txt');
    licfile = fopen(lic_txt_file);
    license_str = char(fread(licfile));
    fclose(licfile);
    diffview({license_str'},'License of Mercury Dialog');
    
