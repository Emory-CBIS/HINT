function varargout = loadNii(varargin)
% LOADNII MATLAB code for loadNii.fig
%      LOADNII, by itself, creates a new LOADNII or raises the existing
%      singleton*.
%
%      H = LOADNII returns the handle to a new LOADNII or the handle to
%      the existing singleton*.
%
%      LOADNII('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LOADNII.M with the given input arguments.
%
%      LOADNII('Property','Value',...) creates a new LOADNII or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before loadNii_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to loadNii_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help loadNii

% Last Modified by GUIDE v2.5 15-Mar-2016 01:41:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @loadNii_OpeningFcn, ...
                   'gui_OutputFcn',  @loadNii_OutputFcn, ...
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


% --- Executes just before loadNii is made visible.
function loadNii_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to loadNii (see VARARGIN)

% UIWAIT makes loadNii wait for user response (see UIRESUME)
handles.output={};
guidata(handles.figure1, handles);
set(handles.figure1,'WindowStyle','modal');
uiwait(hObject);

% Choose default command line output for loadNii

%size(getappdata(handles.figure1,'Y'))
%getappdata(handles.figure1,'N')
%getappdata(hObject,'T')
%size(getappdata(hObject,'X'))

%set(hObject,'Visible','off')

%handles.output={100,getappdata(hObject,'Y'),getappdata(hObject,'X')}
%handles.output={100}
%handles.output = {10, getappdata(hObject,'N'), getappdata(hObject,'T')}%...
    %getappdata(hObject,'N'), getappdata(hObject,'T')};

% Update handles structure
% guidata(hObject, handles);




% --- Outputs from this function are returned to the command line.
function varargout = loadNii_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%uiwait(hObject)
%handles.output={100,getappdata(hObject,'Y'),getappdata(hObject,'X')}
varargout{1} = handles.output;

delete(handles.figure1)




function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%% Ask the user how they would like to read in the files
 selection = questdlg('Are your data in the same folder?');
 
 global strMatch;
 
 if strcmp(selection, 'Yes')
    niifiles = uipickfiles('REFilter','\.nii$|\.hdr$');
    setappdata(handles.figure1, 'niifiles', niifiles);
    if isnumeric(niifiles)
        % do nothing
    else
        set(handles.edit4,'String',strcat(strjoin(niifiles,'; ')))
        % Data is all in same folder, so the string to match on should not be
        % important
        strMatch = length(strsplit(niifiles{1}, '/'));
    end
 end
 if strcmp(selection, 'No')
     display('Please select a data set.');
     inputdialogue = ['Please provide the data path, replacing parts of '...
         'the file name that change with an asterick. Example: '...
         '/user/home/data/subject_*/subject*.nii'];
     wildFlTemp = inputdlg(inputdialogue);
     wildFl = wildFlTemp{1};
     % Get all files satisfying the criteria
     listing = dir([wildFl]);
     [nFile, ~] = size(listing);
     niifiles=cell(1,nFile);
     for iFl = 1:nFile
         niifiles{1,iFl} = [listing(iFl).folder, '/', listing(iFl).name];
     end
     setappdata(handles.figure1, 'niifiles', niifiles);
     set(handles.edit4,'String',strcat(strjoin(niifiles,'; ')))
     % Save the first part of the file name
     fileparts = strsplit(wildFl, '/');
     hasWildcard = ~cellfun(@isempty,regexp(fileparts,'*'));
     filepartIndex_temp = find(hasWildcard);
     filepartIndex = filepartIndex_temp;
     % Give hc-ICA this information
     strMatch = filepartIndex;
 end


function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 [filename, pathname] = ...
     uigetfile({'*.nii','*.hdr'},'File Selector');
 if filename==0
    filename='';
 end
 %%%%% check hdr valid img
 maskf = strcat(pathname, filename);
 set(handles.edit5,'String',maskf);
 setappdata(handles.figure1, 'maskf', maskf);
 %uiresume(handles.figure1)


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output={getappdata(handles.figure1,'niifiles'),...
    getappdata(handles.figure1,'maskf'),...
    getappdata(handles.figure1,'covf')};

% write chosen files to output text
%handles = guidata(hObject);
%hh = guidata(object_handle)
global outfilename;
global writelog
if (writelog == 1)
outfile = fopen(outfilename, 'a' );
niinames = getappdata(handles.figure1,'niifiles');
maskname = getappdata(handles.figure1,'maskf');
covname = getappdata(handles.figure1,'covf');
fprintf(outfile, strcat('\n\n----------------- Loading Data -----------------'));
fprintf(outfile, strcat('\nLoaded the following nifti files:\n'));
fprintf(outfile, '%s\n' , niinames{:} );
fprintf(outfile, strcat('\nLoaded the following mask file:\n'));
fprintf(outfile, '%s\n' , maskname );
fprintf(outfile, strcat('\nLoaded the following covariate file:\n'));
fprintf(outfile, '%s\n' , covname );
end
% end text output

guidata(handles.figure1, handles);
uiresume(handles.figure1);

%close(handles.figure1)

% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output={};
guidata(handles.figure1, handles);
uiresume(handles.figure1);


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 [filename, pathname] = ...
     uigetfile({'*.csv'},'File Selector');
 if filename==0
    filename='';
 end
 %%%%% check hdr valid img
 covf = strcat(pathname, filename);
 set(handles.edit6,'String',covf);
 setappdata(handles.figure1, 'covf', covf);



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
