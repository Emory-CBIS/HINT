function varargout = view_input_summary(varargin)
% VIEW_INPUT_SUMMARY MATLAB code for view_input_summary.fig
%      VIEW_INPUT_SUMMARY, by itself, creates a new VIEW_INPUT_SUMMARY or raises the existing
%      singleton*.
%
%      H = VIEW_INPUT_SUMMARY returns the handle to a new VIEW_INPUT_SUMMARY or the handle to
%      the existing singleton*.
%
%      VIEW_INPUT_SUMMARY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIEW_INPUT_SUMMARY.M with the given input arguments.
%
%      VIEW_INPUT_SUMMARY('Property','Value',...) creates a new VIEW_INPUT_SUMMARY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before view_input_summary_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to view_input_summary_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help view_input_summary

% Last Modified by GUIDE v2.5 06-Feb-2019 12:19:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @view_input_summary_OpeningFcn, ...
                   'gui_OutputFcn',  @view_input_summary_OutputFcn, ...
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


% --- Executes just before view_input_summary is made visible.
function view_input_summary_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to view_input_summary (see VARARGIN)

% Choose default command line output for view_input_summary
%handles.output = hObject;
movegui(hObject, 'center')
handles.output={};
set(handles.figure1,'WindowStyle','modal');

% UIWAIT makes view_input_summary wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Take the arguments to the GUI window
handles.niifiles = varargin{1};
handles.missingFiles = varargin{2};
handles.duplicateFiles = varargin{3};

% Calculate the number in each category
handles.nnii = length(handles.niifiles);
handles.nmissing = length(handles.missingFiles);
handles.nduplicate = length(handles.duplicateFiles);

% Update the static texts
handles.niifileCount.String = num2str(handles.nnii);
handles.missingCount.String = num2str(handles.nmissing);
handles.duplicatedCount.String = num2str(handles.nduplicate);

% Update the listboxes
handles.niifilesListbox.String = handles.niifiles;
handles.missingListbox.String = handles.missingFiles;
handles.duplicatesListbox = handles.duplicateFiles;

% Update handles structure
guidata(hObject, handles);
uiwait(hObject);


% --- Outputs from this function are returned to the command line.
function varargout = view_input_summary_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(hObject);



% --- Executes on selection change in duplicatesListbox.
function duplicatesListbox_Callback(hObject, eventdata, handles)
% hObject    handle to duplicatesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns duplicatesListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from duplicatesListbox


% --- Executes during object creation, after setting all properties.
function duplicatesListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to duplicatesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in missingListbox.
function missingListbox_Callback(hObject, eventdata, handles)
% hObject    handle to missingListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns missingListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from missingListbox


% --- Executes during object creation, after setting all properties.
function missingListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to missingListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in niifilesListbox.
function niifilesListbox_Callback(hObject, eventdata, handles)
% hObject    handle to niifilesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns niifilesListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from niifilesListbox


% --- Executes during object creation, after setting all properties.
function niifilesListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to niifilesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in closeAndContinue.
function closeAndContinue_Callback(hObject, eventdata, handles)
% hObject    handle to closeAndContinue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = 0;
guidata(handles.figure1, handles);
uiresume(handles.figure1);



% --- Executes on button press in closeAndRedo.
function closeAndRedo_Callback(hObject, eventdata, handles)
% hObject    handle to closeAndRedo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = 1;
guidata(handles.figure1, handles);
uiresume(handles.figure1);



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
handles.output = 0; % default is to not reset
guidata(handles.figure1, handles);
uiresume(handles.figure1);
