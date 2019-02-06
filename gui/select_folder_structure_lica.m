function varargout = select_folder_structure_lica(varargin)
% SELECT_FOLDER_STRUCTURE_LICA MATLAB code for select_folder_structure_lica.fig
%      SELECT_FOLDER_STRUCTURE_LICA, by itself, creates a new SELECT_FOLDER_STRUCTURE_LICA or raises the existing
%      singleton*.
%
%      H = SELECT_FOLDER_STRUCTURE_LICA returns the handle to a new SELECT_FOLDER_STRUCTURE_LICA or the handle to
%      the existing singleton*.
%
%      SELECT_FOLDER_STRUCTURE_LICA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SELECT_FOLDER_STRUCTURE_LICA.M with the given input arguments.
%
%      SELECT_FOLDER_STRUCTURE_LICA('Property','Value',...) creates a new SELECT_FOLDER_STRUCTURE_LICA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before select_folder_structure_lica_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to select_folder_structure_lica_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help select_folder_structure_lica

% Last Modified by GUIDE v2.5 31-Jan-2019 09:59:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @select_folder_structure_lica_OpeningFcn, ...
                   'gui_OutputFcn',  @select_folder_structure_lica_OutputFcn, ...
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


% --- Executes just before select_folder_structure_lica is made visible.
function select_folder_structure_lica_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to select_folder_structure_lica (see VARARGIN)

% Choose default command line output for select_folder_structure_lica
handles.output = hObject;

%%%%% Load the image of the csv file
axes(handles.axes1)
matlabImage = imread('option_1_example.png');
image(matlabImage)
axis off
axis image
axes(handles.axes2)
matlabImage = imread('option_2_example.png');
image(matlabImage)
axis off
axis image
axes(handles.axes3)
matlabImage = imread('option_3_example.png');
image(matlabImage)
axis off
axis image

%% Strings to update the text box descriptions
message = '';
message = sprintf('%sUse this option if all of your subject and visit \n', message);
message = sprintf('%sfiles are stored in the same folder.\n', message);
handles.text3.String = message;

movegui(hObject, 'center')
handles.output={};
guidata(handles.figure1, handles);
set(handles.figure1,'WindowStyle','modal');
uiwait(hObject);

% Update handles structure
%guidata(hObject, handles);

% UIWAIT makes select_folder_structure_lica wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = select_folder_structure_lica_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in option2.
function option2_Callback(hObject, eventdata, handles)
% hObject    handle to option2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of option2

% Set the selected folder structure
handles.selectedStructure = 'subjectContainingVisit';

% deselect the other two boxes
handles.option1.Value = 0;
handles.option3.Value = 0;

% Update the GUI
guidata(handles.figure1, handles);


% --- Executes on button press in option1.
function option1_Callback(hObject, eventdata, handles)
% hObject    handle to option1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of option1

% Set the selected folder structure
handles.selectedStructure = 'sameFolder';

% deselect the other two boxes
handles.option2.Value = 0;
handles.option3.Value = 0;

% Update the GUI
guidata(handles.figure1, handles);



% --- Executes on button press in option3.
function option3_Callback(hObject, eventdata, handles)
% hObject    handle to option3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of option3

% Set the selected folder structure
handles.selectedStructure = 'visitContainingSubject';

% deselect the other two boxes
handles.option1.Value = 0;
handles.option2.Value = 0;

% Update the GUI
guidata(handles.figure1, handles);



% --- Executes on button press in continueButton.
function continueButton_Callback(hObject, eventdata, handles)
% hObject    handle to continueButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% First make sure that something has been selected
if (handles.option1.Value + handles.option2.Value + handles.option3.Value) > 0
    
    % Cycle through the different options
    if strcmp(handles.selectedStructure, 'sameFolder')
        
        % User has selected that everything is stored in the same folder,
        % so this means that we can open up the typical Nii loader
        % TODO, tweak the regular hc-ICA one so that we can use both here
        
    elseif strcmp(handles.selectedStructure, 'visitContainingSubject')
        
        % Looking for visit folders where each visit contains all subjects.
        niifiles = input_get_niifiles_visit_containing_subject();
        
    elseif strcmp(handles.selectedStructure, 'subjectContainingVisit')
        
    else
        warndlg('Something has gone wrong with the toolbox. Please report this error.', 'Error');
    end
    
else
   warndlg('Please select one of the data organization options.', 'Warning');
end

