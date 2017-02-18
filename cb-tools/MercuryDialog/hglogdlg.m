% Copyright 2010 The MathWorks, Inc.
% hglogdlg: GUI for interacting with Mercurial log
function varargout = hglogdlg(varargin)
% HGLOGDLG M-file for hglogdlg.fig
%      HGLOGDLG, by itself, creates a new HGLOGDLG or raises the existing
%      singleton*.
%
%      H = HGLOGDLG returns the handle to a new HGLOGDLG or the handle to
%      the existing singleton*.
%
%      HGLOGDLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HGLOGDLG.M with the given input arguments.
%
%      HGLOGDLG('Property','Value',...) creates a new HGLOGDLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before hglogdlg_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to hglogdlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help hglogdlg

% Last Modified by GUIDE v2.5 16-Jul-2009 11:06:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @hglogdlg_OpeningFcn, ...
                   'gui_OutputFcn',  @hglogdlg_OutputFcn, ...
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


% --- Executes just before hglogdlg is made visible.
function hglogdlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to hglogdlg (see VARARGIN)

% Choose default command line output for hglogdlg
    if ~isfield(handles,'output')
        handles.output = [];
    end
    if ~isempty(varargin)
        args = varargin{1};
    else
        args = {};
    end
    if length(args) >= 1
        set(handles.hglogwindow,'Name',args{1});
    else
        set(handles.hglogwindow,'Name','View of Repository Log');
    end
    if length(args) >= 2
        set(handles.ok_button,'String',args{2});
    else
        set(handles.ok_button,'Visible','off');
    end
    cmd = 'hg log --template "{rev}: {desc|firstline} [{tags}]\n"';
    if length(args) < 3
        files = [];
    else
        files = args{3};
    end
    if length(args) < 4
        set(handles.revision_list,'Max',1);
    else
        if strcmp(args{4},'single')
            set(handles.revision_list,'Max',1);
        else
            set(handles.revision_list,'Max',2);
        end
    end
    if ~isempty(files)
        for f = 1:length(files)
            cmd = [cmd ' ' files{f}];
        end
    end
    wb = waitbar(0.1,'querying revisions...');
    [r log] = system(cmd);
    waitbar(1,wb);
    close(wb);
    if r ~= 0
        errordlg(log,'Unable to query repository log:','modal');
        guidata(hObject, handles);
        uiresume(handles.hglogwindow);
        return
    elseif isempty(log)
        errordlg('Repository is empty.','No Revisions');
        guidata(hObject, handles);
        uiresume(handles.hglogwindow);
        return
    end
    handles.files = files;
    handles.revisions = regexp(log,'\n','split');
    set(handles.revision_list,'String',handles.revisions);
    guidata(hObject, handles);
    uiwait(handles.hglogwindow);


% --- Outputs from this function are returned to the command line.
function varargout = hglogdlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if isfield(handles,'output')
        varargout{1} = handles.output;
    else
        varargout{1} = [];
    end
    if isfield(handles,'hglogwindow')
        close(handles.hglogwindow);
    end


% --- Executes on selection change in revision_list.
function revision_list_Callback(hObject, eventdata, handles)
% hObject    handle to revision_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns revision_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from revision_list


% --- Executes during object creation, after setting all properties.
function revision_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to revision_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in close_button.
function close_button_Callback(hObject, eventdata, handles)
% hObject    handle to close_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.ouptput = [];
    guidata(hObject, handles);
    uiresume(handles.hglogwindow);


% --- Executes on button press in info_button.
function info_button_Callback(hObject, eventdata, handles)
% hObject    handle to info_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    cmd = 'hg log --template "Revision {rev} from {date|isodate}\nAuthor: {author}\nChanged files: {files}\nSummary: {desc}\n\n"';
    rev = get(handles.revision_list,'Value');
    for r = 1:length(rev)
        revstr = handles.revisions{rev(r)};
        cmd = [cmd ' -r' revstr(1:find(revstr==':',1)-1)];
    end
    [r log] = system(cmd);
    if r
        errordlg(log,'Error querying log');
    else
        msgbox(log,'Revision Information');
    end
    

% --- Executes on button press in ok_button.
function ok_button_Callback(hObject, eventdata, handles)
% hObject    handle to ok_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rev = get(handles.revision_list,'Value');
    revid = zeros(1,length(rev));
    for r = 1:length(rev)
        revid(r) = sscanf(handles.revisions{rev(r)},'%d'); 
    end
    handles.output = revid;
    guidata(hObject, handles);
    uiresume(handles.hglogwindow);

% --- Executes when hglogwindow is resized.
function hglogwindow_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to hglogwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    pos = get(hObject,'Position');
    xs = pos(3);
    ys = pos(4);
    if xs < 250
        xs = 250;
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
    set(handles.info_button,'Position',pos);
    pos = [10 10 110 25];
    set(handles.ok_button,'Position',pos);
    pos = [10 50 xs-20 ys-60];
    set(handles.revision_list,'Position',pos)


