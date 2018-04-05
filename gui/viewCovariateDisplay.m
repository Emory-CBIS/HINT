function varargout = viewCovariateDisplay(varargin)
%
% Created to view the covariates and make sure they are lined up
%   properly with the nii files.
%
% order of varargin is: covariates (X), headers, niifiles

% VIEWCOVARIATEDISPLAY MATLAB code for viewCovariateDisplay.fig
%      VIEWCOVARIATEDISPLAY, by itself, creates a new VIEWCOVARIATEDISPLAY or raises the existing
%      singleton*.
%
%      H = VIEWCOVARIATEDISPLAY returns the handle to a new VIEWCOVARIATEDISPLAY or the handle to
%      the existing singleton*.
%
%      VIEWCOVARIATEDISPLAY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIEWCOVARIATEDISPLAY.M with the given input arguments.
%
%      VIEWCOVARIATEDISPLAY('Property','Value',...) creates a new VIEWCOVARIATEDISPLAY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before viewCovariateDisplay_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to viewCovariateDisplay_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help viewCovariateDisplay

% Last Modified by GUIDE v2.5 22-Mar-2018 10:11:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @viewCovariateDisplay_OpeningFcn, ...
                   'gui_OutputFcn',  @viewCovariateDisplay_OutputFcn, ...
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


% --- Executes just before viewCovariateDisplay is made visible.
function viewCovariateDisplay_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to viewCovariateDisplay (see VARARGIN)

% Choose default command line output for viewCovariateDisplay
handles.output = hObject;

% Get the arguments from varargin
handles.X = varargin{1};
handles.headers = varargin{2};
handles.niifilesFull = varargin{3};
handles.covTypes = varargin{4};
handles.covariateNames = varargin{5};
handles.covariates = varargin{6};
handles.interactions = varargin{7};
%handles.covariateColumnVarMembership = varargin{7};

handles.N = size(handles.X); handles.ncov = handles.N(2); handles.N=handles.N(1);

% Make the table the correct dimension
newTable = cell(handles.N, handles.ncov+1);
% fill out all of the covariates
for row = 1:handles.N
    [pathstr,name, ext] = fileparts(handles.niifilesFull{row});
    newTable(row, 1) = {name};
    for col=1:handles.ncov
        newTable(row, col+1) = {handles.X(row, col)};
    end
end
handles.covFileDisplay.Data = newTable;

% set the column names of the display table to be correct
handles.covFileDisplay.ColumnName = ['Subject', handles.headers];

% Edit the properties of the display lists
% set(findobj('tag', 'continuousVarList'),'min',0);
% set(findobj('tag', 'continuousVarList'),'max',length(handles.isCat));
% set(findobj('tag', 'continuousVarList'),'value',[]);
% set(findobj('tag', 'categoricalVarList'),'min',0);
% set(findobj('tag', 'categoricalVarList'),'max',length(handles.isCat));
% set(findobj('tag', 'categoricalVarList'),'value',[]);

% Go through the headers and assign them to lists based on whether or not
% they are categorical
handles.totalVarNum = numel(handles.covTypes);
handles.nCategorical = sum(handles.covTypes);
set( findobj( 'tag', 'intMenu1' ), 'String', handles.headers );
set( findobj( 'tag', 'intMenu2' ), 'String', handles.headers );


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes viewCovariateDisplay wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = viewCovariateDisplay_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in interactionButton.
function interactionButton_Callback(hObject, eventdata, handles)
% hObject    handle to interactionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% User input two variables for interactions
val1 = get( findobj( 'tag', 'intMenu1' ), 'value');
val2 = get( findobj( 'tag', 'intMenu2' ), 'value');

% Check for same covariate issue
if val1 == val2
    warndlg('Please select two different covariates for new interaction term.')
else
    newIntRow = zeros(1, width(handles.covariates) );
    newIntRow(val1) = 1;
    newIntRow(val2) = 1;
    % setup handles.interactions
    if sum(sum(newIntRow == handles.interactions, 2) == width(handles.covariates) ) > 0
        warndlg('Interaction term already exists.')
    else
        handles.interactions = [handles.interactions; newIntRow];
        % Update the appropriate matrices
        [ handles.X, handles.varNamesX ] = ref_cell_code( handles.covariates, handles.covTypes,...
        handles.interactions, 1  );
    
    newTable = cell(handles.N, handles.ncov+1);
    [~, nCol] = size(handles.X);
    % fill out all of the covariates
    for row = 1:handles.N
        [pathstr,name, ext] = fileparts(handles.niifilesFull{row});
        newTable(row, 1) = {name};
        for col=1:nCol
            newTable(row, col+1) = {handles.X(row, col)};
        end
    end
    handles.covFileDisplay.Data = newTable;

    % set the column names of the display table to be correct
    handles.covFileDisplay.ColumnName = ['Subject', handles.varNamesX];
    
    end
end

guidata(hObject, handles);


%updateCodingScheme;


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global data;
data.X = handles.X
data.interactions = handles.interactions;
data.varNamesX = handles.varNamesX

delete(handles.figure1)


 



% --- Executes on selection change in intMenu1.
function intMenu1_Callback(hObject, eventdata, handles)
% hObject    handle to intMenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns intMenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from intMenu1


% --- Executes during object creation, after setting all properties.
function intMenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to intMenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in intMenu2.
function intMenu2_Callback(hObject, eventdata, handles)
% hObject    handle to intMenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns intMenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from intMenu2


% --- Executes during object creation, after setting all properties.
function intMenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to intMenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in removeInteractionButton.
function removeInteractionButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeInteractionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% User input two variables for interactions
val1 = get( findobj( 'tag', 'intMenu1' ), 'value');
val2 = get( findobj( 'tag', 'intMenu2' ), 'value');

[nInt, nCol] = size(handles.interactions);

% Check for same covariate issue
if val1 == val2
    warndlg('Please select two different covariates interaction removal.')
else
    newIntRow = zeros(1, width(handles.covariates) );
    newIntRow(val1) = 1;
    newIntRow(val2) = 1;
    % setup handles.interactions
    if sum(sum(newIntRow == handles.interactions, 2) == width(handles.covariates) ) > 0
        % Recreate the coding scheme excluding the user-specified
        % interaction
        if nInt == 1
            handles.interactions = zeros(0, nCol);
            [ handles.X, handles.varNamesX ] = ref_cell_code( handles.covariates,...
                handles.covTypes, handles.interactions, 0  );
        else
            intToBeRemoved = find(sum(sum(newIntRow ==...
                handles.interactions, 2) == width(handles.covariates) ));
            handles.interactions(intToBeRemoved,:) = [];
            [ handles.X, handles.varNamesX ] = ref_cell_code( handles.covariates,...
                handles.covTypes, handles.interactions, 0  );
        end
        
        newTable = cell(handles.N, handles.ncov+1);
        [~, nCol] = size(handles.X);
        % fill out all of the covariates
        for row = 1:handles.N
            [pathstr,name, ext] = fileparts(handles.niifilesFull{row});
            newTable(row, 1) = {name};
            for col=1:nCol
                newTable(row, col+1) = {handles.X(row, col)};
            end
        end
        handles.covFileDisplay.Data = newTable;

        % set the column names of the display table to be correct
        handles.covFileDisplay.ColumnName = ['Subject', handles.varNamesX];
    
    % handle the case where the interaction does not exist    
    else
        warndlg('Interaction does not exist.')
    end
end

guidata(hObject, handles);