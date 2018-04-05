function varargout = createAScriptAnalysis(varargin)
% CREATEASCRIPTANALYSIS MATLAB code for createAScriptAnalysis.fig
%      CREATEASCRIPTANALYSIS, by itself, creates a new CREATEASCRIPTANALYSIS or raises the existing
%      singleton*.
%
%      H = CREATEASCRIPTANALYSIS returns the handle to a new CREATEASCRIPTANALYSIS or the handle to
%      the existing singleton*.
%
%      CREATEASCRIPTANALYSIS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CREATEASCRIPTANALYSIS.M with the given input arguments.
%
%      CREATEASCRIPTANALYSIS('Property','Value',...) creates a new CREATEASCRIPTANALYSIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before createAScriptAnalysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to createAScriptAnalysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help createAScriptAnalysis

% Last Modified by GUIDE v2.5 22-Mar-2018 14:57:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @createAScriptAnalysis_OpeningFcn, ...
                   'gui_OutputFcn',  @createAScriptAnalysis_OutputFcn, ...
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


% --- Executes just before createAScriptAnalysis is made visible.
function createAScriptAnalysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to createAScriptAnalysis (see VARARGIN)

% Place in center of screen
movegui(gcf,'center')

% Choose default command line output for createAScriptAnalysis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes createAScriptAnalysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = createAScriptAnalysis_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in selectRuninfoButton.
function selectRuninfoButton_Callback(hObject, eventdata, handles)
% hObject    handle to selectRuninfoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Please select the runinfo file.')
[handles.runinfofname handles.runinfopathname] = uigetfile('.mat',...
            'Please select the runinfo file.');
        handles.runinfofl = [handles.runinfopathname handles.runinfofname];
        handles.runinfo = load(handles.runinfofl);

% Set the edit box to display the file location
handles.runinfoFileLocBox.String = {handles.runinfofl};

% Fill out the edit boxes for the output folder, prefix, covariate
% filepath,
% and mask file location
handles.outputDirEditBox.String = {handles.runinfo.outfolder};
handles.maskFileEditBox.String = {handles.runinfo.maskf};
handles.covFileEditbox.String = {handles.runinfo.covfile};
handles.prefixEditBox.String = {handles.runinfo.prefix};

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in generateScriptFileButton.
function generateScriptFileButton_Callback(hObject, eventdata, handles)
% hObject    handle to generateScriptFileButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Path an error checking
disp('add path and error checking')

% Load the runinfo file
runinfoInit = load(handles.runinfofl);

% Open up the new output script


% --- Executes on button press in modifyPathsCheckbox.
function modifyPathsCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to modifyPathsCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of modifyPathsCheckbox



function outputDirEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to outputDirEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of outputDirEditBox as text
%        str2double(get(hObject,'String')) returns contents of outputDirEditBox as a double


% --- Executes during object creation, after setting all properties.
function outputDirEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to outputDirEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function covFileEditbox_Callback(hObject, eventdata, handles)
% hObject    handle to covFileEditbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of covFileEditbox as text
%        str2double(get(hObject,'String')) returns contents of covFileEditbox as a double


% --- Executes during object creation, after setting all properties.
function covFileEditbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to covFileEditbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maskFileEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to maskFileEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maskFileEditBox as text
%        str2double(get(hObject,'String')) returns contents of maskFileEditBox as a double


% --- Executes during object creation, after setting all properties.
function maskFileEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maskFileEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function runinfoSaveLoc_Callback(hObject, eventdata, handles)
% hObject    handle to runinfoSaveLoc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of runinfoSaveLoc as text
%        str2double(get(hObject,'String')) returns contents of runinfoSaveLoc as a double


% --- Executes during object creation, after setting all properties.
function runinfoSaveLoc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to runinfoSaveLoc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in scriptSaveLocButton.
function scriptSaveLocButton_Callback(hObject, eventdata, handles)
% hObject    handle to scriptSaveLocButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folderName = uigetdir(pwd);
if folderName==0
    folderName='';
end
handles.runinfoOutFolder = folderName;
handles.runinfoSaveLoc.String = {handles.runinfoOutFolder};

function runinfoFileLocBox_Callback(hObject, eventdata, handles)
% hObject    handle to runinfoFileLocBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of runinfoFileLocBox as text
%        str2double(get(hObject,'String')) returns contents of runinfoFileLocBox as a double


% --- Executes during object creation, after setting all properties.
function runinfoFileLocBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to runinfoFileLocBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function prefixEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to prefixEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of prefixEditBox as text
%        str2double(get(hObject,'String')) returns contents of prefixEditBox as a double


% --- Executes during object creation, after setting all properties.
function prefixEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prefixEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxitBox_Callback(hObject, eventdata, handles)
% hObject    handle to maxitBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxitBox as text
%        str2double(get(hObject,'String')) returns contents of maxitBox as a double


% --- Executes during object creation, after setting all properties.
function maxitBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxitBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function epsilon1Box_Callback(hObject, eventdata, handles)
% hObject    handle to epsilon1Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epsilon1Box as text
%        str2double(get(hObject,'String')) returns contents of epsilon1Box as a double


% --- Executes during object creation, after setting all properties.
function epsilon1Box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epsilon1Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function epsilon2Box_Callback(hObject, eventdata, handles)
% hObject    handle to epsilon2Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epsilon2Box as text
%        str2double(get(hObject,'String')) returns contents of epsilon2Box as a double


% --- Executes during object creation, after setting all properties.
function epsilon2Box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epsilon2Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in scriptOutputFolderButton.
function scriptOutputFolderButton_Callback(hObject, eventdata, handles)
% hObject    handle to scriptOutputFolderButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Please select location where the generated script will be saved.')
[handles.scriptOutputLoc] =...
    uigetdir('Please select location where the generated script will be saved.');

% Set the edit box to display the file location
handles.scriptOutputFolderLocEdit.String = {handles.scriptOutputLoc};



function scriptOutputFolderLocEdit_Callback(hObject, eventdata, handles)
% hObject    handle to scriptOutputFolderLocEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scriptOutputFolderLocEdit as text
%        str2double(get(hObject,'String')) returns contents of scriptOutputFolderLocEdit as a double


% --- Executes during object creation, after setting all properties.
function scriptOutputFolderLocEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scriptOutputFolderLocEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
