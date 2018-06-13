function varargout = viewCovariateDisplay(varargin)
%
% Created to view the covariates and make sure they are lined up
%   properly with the nii files.
%
% order of varargin is: covariates (X), covariateNames, niifiles

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

% Last Modified by GUIDE v2.5 12-Jun-2018 16:17:41

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

movegui(hObject, 'center')

% Choose default command line output for viewCovariateDisplay
handles.output = hObject;

% Get the arguments from varargin
handles.X = varargin{1};
handles.covariateNames = varargin{2};
handles.varNamesX = varargin{2};
handles.niifilesFull = varargin{3};
handles.covTypes = varargin{4};
handles.covariates = varargin{5};
handles.interactions = varargin{6};
handles.varInModel = varargin{7};
handles.varInCovFile = varargin{8};

% List of all covariates included in the design matrix, the covariates for
% the hcica model are selected from this list
handles.rawCovariateList = handles.covariates.Properties.VariableNames(handles.varInCovFile==1);
handles.includedCovariateList = handles.covariates.Properties.VariableNames(handles.varInModel==1);


handles.N = size(handles.X); handles.ncov = size(handles.varInCovFile, 1); handles.N=handles.N(1);

% Set the listbox of parameters in the design matrix
handles.varsInCovFile.String = handles.rawCovariateList;

% Set the listbox of parameters in the hc-ICA model
handles.varsInModel.String = handles.includedCovariateList;

% Fill out the continuous and categorical covariate listboxes
handles.catListbox.String = handles.rawCovariateList(handles.covTypes == 1);
handles.contListbox.String = handles.rawCovariateList(handles.covTypes == 0);


% Make the table the correct dimension
newTable = cell(handles.N, size(handles.X, 2)+1);
% fill out all of the covariates
for row = 1:handles.N
    [pathstr,name, ext] = fileparts(handles.niifilesFull{row});
    newTable(row, 1) = {name};
    for col=1:size(handles.X, 2)
        newTable(row, col+1) = {handles.X(row, col)};
    end
end
handles.covFileDisplay.Data = newTable;

% set the column names of the display table to be correct
handles.covFileDisplay.ColumnName = ['Subject',...
    handles.covariateNames];

% Go through the headers and assign them to lists based on whether or not
% they are categorical
handles.totalVarNum = numel(handles.covTypes);
handles.nCategorical = sum(handles.covTypes);
set( findobj( 'tag', 'intMenu1' ), 'String', handles.covariates.Properties.VariableNames(handles.varInModel==1) );
set( findobj( 'tag', 'intMenu2' ), 'String', handles.covariates.Properties.VariableNames(handles.varInModel==1) );


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

% Find the element of "varInModel" this corresponds to
sumVar = cumsum(handles.varInModel);
ind1Val = find(sumVar == val1);
ind2Val = find(sumVar == val2);
val1 = ind1Val(1);
val2 = ind2Val(1);

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

        % Press the invisible update button
        guidata(hObject, handles);
        updateDisplayButtonInvisible_Callback(handles.updateDisplayButtonInvisible, 1, handles);
    
    end
end


%updateCodingScheme;


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if sum(handles.varInModel) > 0
    global data;
    
    % Verify that something has changed
    hasChanged = 0;
    if ~all(size(data.interactions) == size(handles.interactions))
        hasChanged = 1;
    else
        if ~all(all(data.interactions == handles.interactions))
            hasChanged = 1;
        elseif ~all(all(data.covTypes == handles.covTypes))
            hasChanged = 1;
        elseif ~all(all(data.varInModel == handles.varInModel))
            hasChanged = 1;
        end
    end
    
    if hasChanged == 1
        data.preprocessingComplete = 0;
        data.tempiniGuessObtained = 0;
        data.iniGuessComplete = 0;
    end
    
    data.X = handles.X;
    data.interactions = handles.interactions;
    data.varNamesX = handles.varNamesX;
    data.covTypes = handles.covTypes;
    data.varInModel = handles.varInModel;
    delete(handles.figure1);
else
    warndlg('Warning: At least one covariate must be included in the model.')
end


 



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

% Find the element of "varInModel" this corresponds to
sumVar = cumsum(handles.varInModel);
ind1Val = find(sumVar == val1);
ind2Val = find(sumVar == val2);
val1 = ind1Val(1);
val2 = ind2Val(1);


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
                handles.covTypes, handles.varInModel, handles.interactions, 1  );
        else
            intToBeRemoved = find(sum(sum(newIntRow ==...
                handles.interactions, 2) == width(handles.covariates) ));
            handles.interactions(intToBeRemoved,:) = [];
            [ handles.X, handles.varNamesX ] = ref_cell_code( handles.covariates,...
                handles.covTypes, handles.varInModel, handles.interactions, 1  );
        end
        
        newTable = cell(handles.N, size(handles.X, 2)+1);
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


% --- Executes on selection change in varsInCovFile.
function varsInCovFile_Callback(hObject, eventdata, handles)
% hObject    handle to varsInCovFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns varsInCovFile contents as cell array
%        contents{get(hObject,'Value')} returns selected item from varsInCovFile

if strcmp(get(gcf,'selectiontype'),'open')  

    % Get the covariate selected by the user
    selectedCovariate = hObject.Value;
    
    % Add the selected variable to the model, if it is already included
    % then do nothing
    if handles.varInModel(selectedCovariate) == 0
        
        % update varInModel
        handles.varInModel(selectedCovariate) = 1;
        
        % Update the listbox of included covariates
        handles.includedCovariateList = handles.covariates.Properties.VariableNames(handles.varInModel==1);
        handles.varsInModel.String = handles.includedCovariateList;
        
        % Update the list of variables for interactions, have to consider
        % special case where no variables included.
        set( findobj( 'tag', 'intMenu1' ), 'String', handles.includedCovariateList );
        set( findobj( 'tag', 'intMenu2' ), 'String', handles.includedCovariateList );
        % Enable the interaction menu and the corresponding buttons
        set( findobj( 'tag', 'intMenu1' ), 'Enable', 'on' );
        set( findobj( 'tag', 'intMenu2' ), 'Enable', 'on' );
        set( findobj( 'tag', 'interactionButton' ), 'Enable', 'on' );
        set( findobj( 'tag', 'removeInteractionButton' ), 'Enable', 'on' );
        
        % Press the invisible update button
        guidata(hObject, handles);
        updateDisplayButtonInvisible_Callback(handles.updateDisplayButtonInvisible, 1, handles);

    end
    
end 



% --- Executes during object creation, after setting all properties.
function varsInCovFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to varsInCovFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in varsInModel.
function varsInModel_Callback(hObject, eventdata, handles)
% hObject    handle to varsInModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns varsInModel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from varsInModel

if strcmp(get(gcf,'selectiontype'),'open')  

    % Get the covariate selected by the user
    selectedCovariate = hObject.Value;
    
    % Make sure the listbox is not already empty
    if ~isempty(hObject.Value)
        
        % Reset the listbox selection to avoid an error
        handles.varsInModel.Value = 1;

        % Find the element of "varInModel" this corresponds to
        sumVar = cumsum(handles.varInModel);
        indexRemove = find(sumVar == selectedCovariate);
        indexRemove = indexRemove(1);

        % update varInModel
        handles.varInModel( indexRemove ) = 0;

        % Update the listbox of included covariates
        handles.includedCovariateList = handles.covariates.Properties.VariableNames(handles.varInModel==1);
        handles.varsInModel.String = handles.includedCovariateList;

        % Remove any interactions with this variable
        removeList = (handles.interactions * (handles.varInModel==0)) > 0;
        handles.interactions = handles.interactions( (1-removeList) == 1, :);

        % Update the list of variables for interactions, have to consider
        % special case where no variables included.
        if length(handles.includedCovariateList) > 0
            set( findobj( 'tag', 'intMenu1' ), 'Value', 1 );
            set( findobj( 'tag', 'intMenu2' ), 'Value', 1 );
            set( findobj( 'tag', 'intMenu1' ), 'String', handles.includedCovariateList );
            set( findobj( 'tag', 'intMenu2' ), 'String', handles.includedCovariateList );
        else
            set( findobj( 'tag', 'intMenu1' ), 'String', 'N/A' );
            set( findobj( 'tag', 'intMenu2' ), 'String', 'N/A' );
            set( findobj( 'tag', 'intMenu1' ), 'Value', 1 );
            set( findobj( 'tag', 'intMenu2' ), 'Value', 1 );
            % Disable the interaction menu and the corresponding buttons
            set( findobj( 'tag', 'intMenu1' ), 'Enable', 'off' );
            set( findobj( 'tag', 'intMenu2' ), 'Enable', 'off' );
            set( findobj( 'tag', 'interactionButton' ), 'Enable', 'off' );
            set( findobj( 'tag', 'removeInteractionButton' ), 'Enable', 'off' );
        end

        % Press the invisible update button
        guidata(hObject, handles);
        updateDisplayButtonInvisible_Callback(handles.updateDisplayButtonInvisible, 1, handles);
    end

end 


% --- Executes during object creation, after setting all properties.
function varsInModel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to varsInModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in catListbox.
function catListbox_Callback(hObject, eventdata, handles)
% hObject    handle to catListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns catListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from catListbox

if strcmp(get(gcf,'selectiontype'),'open') 
    
    % Make sure the listbox is not already empty
    if ~isempty(hObject.Value)
        
        % Numbering of the selected value
        selectedCovariate = hObject.Value;
        hObject.Value = 1; % reset value to avoid invalid integer range
        
        % Match it to a value in the ORIGINAL covTypes
        % 1 - covTypes gives indicator of continuous covariate
        sumVar = cumsum(handles.covTypes);
        selIndex = find(sumVar == selectedCovariate);
        selIndex = selIndex(1);
        
        % Make sure that it is reasonable to change this to continuous
        % - check to make sure the variable is not a string
        columnTypes = varfun(@class,handles.covariates,'OutputFormat','cell');
        if strcmp(columnTypes{selIndex}, 'cell')
            warndlg('Error: This factor is a string, cannot convert to numeric.')
        else
            % Change the covTypes coding
            handles.covTypes(selIndex) = 0;
            
            % Update the categorical and continuous listboxes
            handles.catListbox.String = handles.rawCovariateList(handles.covTypes == 1);
            handles.contListbox.String = handles.rawCovariateList(handles.covTypes == 0);
            
            % Press the invisible update button
            guidata(hObject, handles);
            updateDisplayButtonInvisible_Callback(handles.updateDisplayButtonInvisible, 1, handles);  
        end
    
    end
    
end




% --- Executes during object creation, after setting all properties.
function catListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to catListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in contListbox.
function contListbox_Callback(hObject, eventdata, handles)
% hObject    handle to contListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns contListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from contListbox

if strcmp(get(gcf,'selectiontype'),'open') 
    
    % Make sure the listbox is not already empty
    if ~isempty(hObject.Value)
        
        % Numbering of the selected value
        selectedCovariate = hObject.Value;
        hObject.Value = 1; % reset value to avoid invalid integer range
        
        % Match it to a value in the ORIGINAL covTypes
        % 1 - covTypes gives indicator of continuous covariate
        sumVar = cumsum(1 - handles.covTypes);
        selIndex = find(sumVar == selectedCovariate);
        
        % Make sure that it is reasonable to change this to categorical
        % - check that the number of unique values is not equal to the
        % number of subjects
        if height(unique(handles.covariates(:, selIndex))) == handles.N
            warndlg('Error: The number of unique levels of this factor is equal to the number of subjects, not creating categorical coding.')
        else
            % Change the covTypes coding
            handles.covTypes(selIndex) = 1;
            
            % Update the categorical and continuous listboxes
            handles.catListbox.String = handles.rawCovariateList(handles.covTypes == 1);
            handles.contListbox.String = handles.rawCovariateList(handles.covTypes == 0);
            
            % Press the invisible update button
            guidata(hObject, handles);
            updateDisplayButtonInvisible_Callback(handles.updateDisplayButtonInvisible, 1, handles);
   
        end
    
    end
    
end



% --- Executes during object creation, after setting all properties.
function contListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to contListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addAllButton.
function addAllButton_Callback(hObject, eventdata, handles)
% hObject    handle to addAllButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

checkAns = questdlg('Are you sure you want to add all covariates to the model?');
if checkAns
    handles.varInModel = ones(size(handles.varInModel));
    handles.includedCovariateList = handles.covariates.Properties.VariableNames(handles.varInModel==1);
    handles.varsInModel.String = handles.includedCovariateList;
    
    % Update the list of variables for interactions, have to consider
    % special case where no variables included.
    set( findobj( 'tag', 'intMenu1' ), 'String', handles.includedCovariateList );
    set( findobj( 'tag', 'intMenu2' ), 'String', handles.includedCovariateList );
    % Enable the interaction menu and the corresponding buttons
    set( findobj( 'tag', 'intMenu1' ), 'Enable', 'on' );
    set( findobj( 'tag', 'intMenu2' ), 'Enable', 'on' );
    set( findobj( 'tag', 'interactionButton' ), 'Enable', 'on' );
    set( findobj( 'tag', 'removeInteractionButton' ), 'Enable', 'on' );
    
    guidata(hObject, handles);

    % Press the invisible update button
    updateDisplayButtonInvisible_Callback(handles.updateDisplayButtonInvisible, 1, handles);
    
end


% --- Executes on button press in removeAllButton.
function removeAllButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeAllButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkAns = questdlg('Are you sure you want to remove all covariates from the model?');
if checkAns
    
    % Move cursor to avoid an error
    handles.varsInModel.Value = 1;
    
    handles.varInModel = zeros(size(handles.varInModel));
    handles.includedCovariateList = handles.covariates.Properties.VariableNames(handles.varInModel==1);
    handles.varsInModel.String = handles.includedCovariateList;
    
    handles.interactions = zeros(0, handles.ncov);
    
    % disable the list of variables for interactions
    set( findobj( 'tag', 'intMenu1' ), 'String', 'N/A' );
    set( findobj( 'tag', 'intMenu2' ), 'String', 'N/A' );
    set( findobj( 'tag', 'intMenu1' ), 'Value', 1 );
    set( findobj( 'tag', 'intMenu2' ), 'Value', 1 );
    % Disable the interaction menu and the corresponding buttons
    set( findobj( 'tag', 'intMenu1' ), 'Enable', 'off' );
    set( findobj( 'tag', 'intMenu2' ), 'Enable', 'off' );
    set( findobj( 'tag', 'interactionButton' ), 'Enable', 'off' );
    set( findobj( 'tag', 'removeInteractionButton' ), 'Enable', 'off' );
    
    guidata(hObject, handles);
    
    % Press the invisible update button
    updateDisplayButtonInvisible_Callback(handles.updateDisplayButtonInvisible, 1, handles);

end


% --- Executes on button press in updateDisplayButtonInvisible.
function updateDisplayButtonInvisible_Callback(hObject, eventdata, handles)
% hObject    handle to updateDisplayButtonInvisible (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update the reference cell coding
[ handles.X, handles.varNamesX ] = ref_cell_code( handles.covariates,...
        handles.covTypes, handles.varInModel, handles.interactions, 1  );

% Update the table
newTable = cell(handles.N, size(handles.X, 2)+1);
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

guidata(hObject, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if sum(handles.varInModel) > 0
    global data;
    data.X = handles.X;
    data.interactions = handles.interactions;
    data.varNamesX = handles.varNamesX;
    data.covTypes = handles.covTypes;
    data.varInModel = handles.varInModel;
    delete(hObject);
else
    warndlg('Warning: At least one covariate must be included in the model.')
end
