% Copyright 2010 The MathWorks, Inc.
% diffview: brings up a view for showing diffs
function varargout = diffview(varargin)
% DIFFVIEW M-file for diffview.fig
%      DIFFVIEW, by itself, creates a new DIFFVIEW or raises the existing
%      singleton*.
%
%      H = DIFFVIEW returns the handle to a new DIFFVIEW or the handle to
%      the existing singleton*.
%
%      DIFFVIEW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DIFFVIEW.M with the given input arguments.
%
%      DIFFVIEW('Property','Value',...) creates a new DIFFVIEW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before diffview_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to diffview_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help diffview

% Last Modified by GUIDE v2.5 11-Jul-2009 01:04:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @diffview_OpeningFcn, ...
                   'gui_OutputFcn',  @diffview_OutputFcn, ...
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


% --- Executes just before diffview is made visible.
function diffview_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to diffview (see VARARGIN)

% Choose default command line output for diffview
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
if ~isempty(varargin)
    text = varargin{1}{1};
    set(handles.edit1,'String',text);
    if length(varargin) > 1
        set(handles.diffwindow,'Name',varargin{2});
    end
end
% UIWAIT makes diffview wait for user response (see UIRESUME)
% uiwait(handles.diffwindow);


% --- Outputs from this function are returned to the command line.
function varargout = diffview_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function diffview_resize(hObject, eventdata, handles)
    pos = get(hObject,'Position');
    xs = pos(3);
    ys = pos(4);
    set(handles.edit1,'Position',[10 10 xs-20 ys-20]);
    
