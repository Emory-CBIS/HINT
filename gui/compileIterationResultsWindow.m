function varargout = compileIterationResultsWindow(varargin)
% COMPILEITERATIONRESULTSWINDOW MATLAB code for compileIterationResultsWindow.fig
%      COMPILEITERATIONRESULTSWINDOW, by itself, creates a new COMPILEITERATIONRESULTSWINDOW or raises the existing
%      singleton*.
%
%      H = COMPILEITERATIONRESULTSWINDOW returns the handle to a new COMPILEITERATIONRESULTSWINDOW or the handle to
%      the existing singleton*.
%
%      COMPILEITERATIONRESULTSWINDOW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COMPILEITERATIONRESULTSWINDOW.M with the given input arguments.
%
%      COMPILEITERATIONRESULTSWINDOW('Property','Value',...) creates a new COMPILEITERATIONRESULTSWINDOW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before compileIterationResultsWindow_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to compileIterationResultsWindow_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help compileIterationResultsWindow

% Last Modified by GUIDE v2.5 20-Mar-2018 10:42:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @compileIterationResultsWindow_OpeningFcn, ...
                   'gui_OutputFcn',  @compileIterationResultsWindow_OutputFcn, ...
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


% --- Executes just before compileIterationResultsWindow is made visible.
function compileIterationResultsWindow_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to compileIterationResultsWindow (see VARARGIN)

% Place in the center of the screen
movegui(gcf,'center')

% Choose default command line output for compileIterationResultsWindow
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes compileIterationResultsWindow wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = compileIterationResultsWindow_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushOutput.
function pushOutput_Callback(hObject, eventdata, handles)
% hObject    handle to pushOutput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

folderName = uigetdir(pwd);
if folderName==0
    folderName='';
end
handles.outpath = folderName;
set(findobj('Tag','editOutput'), 'String', folderName);


% --- Executes on button press in pushIter.
function pushIter_Callback(hObject, eventdata, handles)
% hObject    handle to pushIter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname pathname] = uigetfile('.mat')
handles.runinfoLoc = [pathname fname];
set(findobj('Tag','editIter'), 'String', [pathname fname]);




function editOutput_Callback(hObject, eventdata, handles)
% hObject    handle to editOutput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOutput as text
%        str2double(get(hObject,'String')) returns contents of editOutput as a double


% --- Executes during object creation, after setting all properties.
function editOutput_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOutput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editIter_Callback(hObject, eventdata, handles)
% hObject    handle to editIter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editIter as text
%        str2double(get(hObject,'String')) returns contents of editIter as a double


% --- Executes during object creation, after setting all properties.
function editIter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editIter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in filepathDifferentBox.
function filepathDifferentBox_Callback(hObject, eventdata, handles)
% hObject    handle to filepathDifferentBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of filepathDifferentBox
if (handles.filepathDifferentBox.Value == 1)
    set(findobj('Tag','editMask'), 'enable', 'On');
    set(findobj('Tag','pushMask'), 'enable', 'On');
    set(findobj('Tag','editCovfile'), 'enable', 'On');
    set(findobj('Tag','pushCovfile'), 'enable', 'On');
else
    set(findobj('Tag','editMask'), 'enable', 'Off');
    set(findobj('Tag','pushMask'), 'enable', 'Off');
    set(findobj('Tag','editCovfile'), 'enable', 'Off');
    set(findobj('Tag','pushCovfile'), 'enable', 'Off');
end



% --- Executes on button press in pushMask.
function pushMask_Callback(hObject, eventdata, handles)
% hObject    handle to pushMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname pathname] = uigetfile('.nii')
handles.maskLoc = [pathname fname];
set(findobj('Tag','editMask'), 'String', [pathname fname]);



function editMask_Callback(hObject, eventdata, handles)
% hObject    handle to editMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMask as text
%        str2double(get(hObject,'String')) returns contents of editMask as a double


% --- Executes during object creation, after setting all properties.
function editMask_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushCovfile.
function pushCovfile_Callback(hObject, eventdata, handles)
% hObject    handle to pushCovfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname pathname] = uigetfile('.csv')
handles.csvLoc = [pathname fname];
set(findobj('Tag','editCovfile'), 'String', [pathname fname]);



function editCovfile_Callback(hObject, eventdata, handles)
% hObject    handle to editCovfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCovfile as text
%        str2double(get(hObject,'String')) returns contents of editCovfile as a double


% --- Executes during object creation, after setting all properties.
function editCovfile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCovfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushRuninfo.
function pushRuninfo_Callback(hObject, eventdata, handles)
% hObject    handle to pushRuninfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname pathname] = uigetfile('.mat')
handles.runinfoLoc = [pathname fname];
set(findobj('Tag','editRuninfo'), 'String', [pathname fname]);
% Check that the mask file exists
maskf = load( [pathname fname], 'maskf' );
if exist(maskf.maskf) > 0
    set(findobj('Tag','editMask'), 'String', maskf.maskf);
else
    msgbox('The mask file specified in the runinfo file cannot be found. Please set manually.')
    handles.filepathDifferentBox.Value = 1;
    filepathDifferentBox_Callback(hObject, eventdata, handles);
end

function editRuninfo_Callback(hObject, eventdata, handles)
% hObject    handle to editRuninfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRuninfo as text
%        str2double(get(hObject,'String')) returns contents of editRuninfo as a double

% --- Executes during object creation, after setting all properties.
function editRuninfo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRuninfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushCompileResults.
function pushCompileResults_Callback(hObject, eventdata, handles)
% hObject    handle to pushCompileResults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check that the output folder, runinfo file, and iteration results have
% all been provided by the user.
if isempty( get(findobj('Tag','editRuninfo'), 'String') )
    display('Error: missing runinfo file location.')
    msgbox('Error: missing runinfo file location.')
else
    if isempty( get(findobj('Tag','editIter'), 'String') )
        display('Error: missing iteration results file.')
        msgbox('Error: missing iteration results file.')
    else
        % Call the compile function
        compileIterResults( get(findobj('Tag','editOutput'), 'String'),...
            get(findobj('Tag','editRuninfo'), 'String'),...
            get(findobj('Tag','editIter'), 'String'),...
            get(findobj('Tag','editMask'), 'String'))
    end
end
