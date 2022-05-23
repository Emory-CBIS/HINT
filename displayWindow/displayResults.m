function varargout = displayResults(varargin)
% displayResults - Function to view the results of the EM algorithm.
%
% Inputs: 
%

% set(findall(gcf,'-property','FontSize'),'FontSize',12)

% See
% https://undocumentedmatlab.com/articles/additional-uicontrol-tooltip-hacks

% Set up the data structure "ddat" with the input information. This
% structure will hold all the data as the user continues to use the viewer.
% This structure can also be saved, making it easy to load the state of the
% viewer at a later time

% Go through the input
ddat = struct();

ddat.Q = cell2mat(varargin(1));
ddat.outdir = varargin{2};
ddat.outpre = varargin{3};
ddat.varNamesX = varargin{4};
ddat.covTypes = varargin{5};
ddat.interactions = varargin{6};
ddat.nVisit = varargin{7};
ddat.validVoxels = varargin{8};
ddat.voxSize = varargin{9};

ddat.user_specified_anatomical_file = '';

ddat.covariateNames = varargin{10};
ddat.covariates = varargin{11};
ddat.variableCodingInformation = varargin{12};
ddat.isPreview = varargin{13};
ddat.originator = varargin{14};


ddat.N = size(ddat.covariates, 1);

% Some other useful quantities
ddat.sagDim = ddat.voxSize(1);
ddat.corDim = ddat.voxSize(2);
ddat.axiDim = ddat.voxSize(3);

% Menu settings
ddat.textSize = 10;
ddat.currentSaveFile = '';

% Determine default sub-population table information
% for categorical covariates - will be the reference group
% for continuous covariates - will be the mean
% Second column is a list of "allowable" values
defaultSubPopTableData = cell(length(ddat.covariateNames), 2);
for iCov = 1:length(ddat.covariateNames)
    if ddat.covTypes(iCov) == 1
        potentialValuesCell = unique(ddat.covariates{:, iCov});
        potentialValuesCat  = strjoin(potentialValuesCell, ', ');
        defaultSubPopTableData{iCov, 2} = potentialValuesCat;
        % Assign reference category
        refCat = ddat.variableCodingInformation.effectsCodingsEncoders{iCov}.referenceCategory;
        defaultSubPopTableData{iCov, 1} = refCat;
    else
        minVal = min(ddat.covariates{:, iCov});
        maxVal = max(ddat.covariates{:, iCov});
        potentialValuesRange  = ['Value in [' num2str(round(minVal, 3))...
            ', ' num2str(round(maxVal, 3)) ']'];
        defaultSubPopTableData{iCov, 2} = potentialValuesRange;
        defaultSubPopTableData{iCov, 1} = round(mean(ddat.covariates{:, iCov}), 3);
    end
end
ddat.defaultSubPopTableData = defaultSubPopTableData;
% Convert to a table
%defaultSubPopTableData = table(defaultSubPopTableData);

% Set the default colormap
ddat.P = length(ddat.varNamesX);

varargout = cell(1);

%% Things that need to be saved
ddat.axiPos = cell(0);
ddat.corPos = cell(0);
ddat.sagPos = cell(0);

ddat.clims{1} = [-2, 2];
ddat.thresholdVal{1} = 0.0;
ddat.colorbarScheme{1} = 'jet';

ddat.drawCrosshair{1} = 0;
ddat.crosshairSettings = {0};

ddat.currentIC{1} = 1;
ddat.currentViewerType{1} = 'Population';
ddat.currentCov = cell(0);
ddat.currentVisit = cell(0);
ddat.viewZScores = cell(0);

% Viewer syncing
ddat.isSynced = cell(0);
ddat.syncTo   = cell(0);
ddat.syncICs = cell(0);
ddat.syncThresholding = cell(0);
ddat.syncColormaps = cell(0);

% Subpopulations
ddat.subpopNames       = cell(0);
ddat.subpopCovSettings = cell(0);
ddat.subpopModelMats   = cell(0);
ddat.subpopBeingEdited = 1;
ddat.currentSubpop = cell(0);

% Contrasts
ddat.currentContrast = cell(0);
ddat.contrastNames = cell(0);
ddat.contrastCoefSettings = cell(0);
ddat.contrastBeingEdited = 1;

% Subjects
ddat.currentSubject = cell(0);
% This holds all 3 visits of the currently loaded subject's data for each
% viewer. Only actually needed for the trajectory view
ddat.currentSubjectMatData = cell(0);

% Specific Linear combination to get the mean at each time point
ddat.LCPopAvgTime = [ones(ddat.nVisit, 1) [-1.0 * ones(1, ddat.nVisit-1); eye(ddat.nVisit-1)] zeros(ddat.nVisit, ddat.P*ddat.nVisit)];

% Effect Information
ddat.currentEffectInfoView = 1;
ddat.currentEffectInfoViewType = 'Population';
ddat.currentEffectCurrentSubpop = 1;
ddat.currentEffectDrawVisit = 0;
ddat.currentEffectCurrentCovariate = 1;

% Effect names depend on if this is a longtidinal study or not
if ddat.nVisit > 1
    ddat.contrastBetaLabels = [compose('Visit %g', 2:ddat.nVisit) ];
    for j = 1:ddat.nVisit
        ddat.contrastBetaLabels = [ddat.contrastBetaLabels strcat(ddat.varNamesX, [' Effect Visit ' num2str(j)])];
    end
else
    ddat.contrastBetaLabels = [strcat(ddat.varNamesX, ' Effect')];
end

ddat.defaultContrastTableData = cell(length(ddat.contrastBetaLabels), 2);
ddat.defaultContrastTableData(:, 1) = ddat.contrastBetaLabels;
ddat.defaultContrastTableData(:, 2) = {0};
% this is for keeping widths of columns the same when user changes them
ddat.currentUserContrastTableExtent = [];


% Construct a mapping from individual covariates (NOT CODED) to
% corresponding element of the parameter vec/ col of model matrix
paramIncludesVar = zeros(length(ddat.covariateNames), length(ddat.varNamesX));
currentIndex = 1;
% Main Effects
for iCov = 1:length(ddat.covariateNames)
    if ddat.covTypes(iCov) == 0
        paramIncludesVar(iCov, currentIndex) = 1;
        currentIndex = currentIndex + 1;
    else
        encoderi = ddat.variableCodingInformation.effectsCodingsEncoders{iCov};
        nleveli = length(encoderi.variableNames);
        for jEC = 1:nleveli
            paramIncludesVar(iCov, currentIndex) = 1;
            currentIndex = currentIndex + 1;
        end
    end
end

% Interactions
for iInt = 1:size(ddat.interactions, 1)
    % figure out how many parameters correspond to this interaction
    covInd = find(ddat.interactions(iInt, :) == 1);
    if ddat.covTypes(covInd(1)) == 0
        ncov1 = 1;
    else
        ncov1 = length(unique(ddat.covariates{:, covInd(1)})) - 1;
    end
    if ddat.covTypes(covInd(2)) == 0
        ncov2 = 1;
    else
        ncov2 = length(unique(ddat.covariates{:, covInd(2)})) - 1;
    end
    
    totalCovColumns = ncov1 * ncov2;
    
    for iCovCol = 1:totalCovColumns
        paramIncludesVar(covInd(1), currentIndex) = 1;
        paramIncludesVar(covInd(2), currentIndex) = 1;
        currentIndex = currentIndex + 1;
    end

end
ddat.paramIncludesVar = paramIncludesVar;

ddat.nViewer = 0;

% Separate structure that contains image related data. This should not get
% stored
ImageData = struct();
ImageData.rawImages = cell(0);
ImageData.imageFilenames = cell(0);
ImageData.imageScaleFactors = cell(0);
ImageData.axiSlices = cell(0);
ImageData.corSlices = cell(0);
ImageData.sagSlices = cell(0);
ImageData.loadedVarCov   = cell(ddat.Q, 1);
ImageData.loadedCoefEsts = cell(ddat.Q, 1);
for iq = 1:ddat.Q
    ImageData.loadedVarCov{iq} = 0;
    ImageData.loadedCoefEsts{iq} = 0;
end
ImageData.VarCov = cell(0);
ImageData.CoefEsts = cell(0);
ImageData.maskingLayer = cell(0);
ImageData.maskingFile  = cell(0);
ImageData.anatomicalFile = '';
ImageData.anatomical = cell(0);
ImageData.anatomicalAxiSlices = cell(0);
ImageData.anatomicalCorSlices = cell(0);
ImageData.anatomicalSagSlices = cell(0);

% Check if an instance of displayResults already running
hs = findall(0,'tag','hint_image_display');
if (isempty(hs))
    hs = addcomponents;
    set(hs.fig,'Visible','on');
    %initialDisp;
    initial_display;
else
    figure(hs);
end

%% GUI Main Component Definition and KeyPress Functions
    function hs = addcomponents
        % Add components, save ddat in a struct
        hs.fig = figure('Units', 'normalized', ...,...
            'position', [0.05 0.15 0.9 0.8],...
            'MenuBar', 'none',...
            'Tag','hint_image_display',...
            'NumberTitle','off',...
            'Name','HINT Results Viewer',...
            'Resize','on',...
            'Visible','off');
            %'WindowKeyPressFcn', @KeyPress);
            
        %% Toolbar
        
        % FILE
        fileMenu = uimenu('Label', 'File');
        
        SaveOpt = uimenu(fileMenu, 'Label', 'Save',...
            'tag', 'saveOpt',...
            'enable', 'off',...
            'Callback', @update_saved_viewer_options);
        SaveAsOpt = uimenu(fileMenu, 'Label', 'Save as',...
            'Callback', @save_viewer_options);
        
        LoadOpt = uimenu(fileMenu, 'Label', 'Load',...
            'Callback', @load_saved_viewer_options);
        
        % Load anatomical file
        LoadAnat = uimenu(fileMenu, 'Label', 'Load Anatomical Image',...
            'Separator','on',...
            'Callback', @load_anatomical);
        
        % Font size
        TextSize = uimenu(fileMenu, 'Label', 'Change Font Size',...
            'Separator','on',...
            'Callback', @change_text_size);
        
        % EXPORTS
        exportMenu = uimenu('Label', 'Export');
        
        SaveNii = uimenu(exportMenu, 'Label', 'Save to .nii',...
            'tag', 'SaveNii',...
            'enable', 'on',...
            'Callback', @save_nifti_file);

        
        % Default Panel - this panel contains the main display windows and options
        % other primary panels are placed on it, so that it can be
        % shrunk/expanded as needed
        
       
        % Primary Panels (layout)
        
        DefaultPanel = uipanel('BackgroundColor','white',...
            'Tag', 'DefaultPanel',...
            'units', 'normalized',...
            'Position',[0.0, 0.0 1.0 1.0], ...;
            'BackgroundColor',get(hs.fig,'color'));
        
        ViewersPanel = uipanel('Tag', 'ViewersPanel',...
            'units', 'normalized',...
            'Position',[0.3, 0.0 0.7 1.0], ...;
            'BackgroundColor',get(hs.fig,'color'));
        
        ControlsPanel = uipanel('Tag', 'ControlsPanel',...
            'units', 'normalized',...
            'Position',[0.0, 0.0 0.3 1.0], ...;
            'BackgroundColor',get(hs.fig,'color'));
        
        %% Contrast and sub population Tab group:
        CSPTabGroup = uitabgroup('Parent', ControlsPanel,...
            'Tag','CSPTabGroup',...
            'units', 'normalized',...
            'Position',[0.0, 0.50000 1.0 0.5]);
        CSPTabGroupTabSubpop = uitab('Parent', CSPTabGroup,...
            'Tag','CSPTabGroupTabSubpop',...
            'Title', 'Sub-Populations');
        CSPTabGroupTabContrast = uitab('Parent', CSPTabGroup,...
            'Tag','CSPTabGroupTabContrast',...
            'Title', 'Linear Combinations');
        
         %% Additional Information Tab Group
        AddInfoTabGroup = uitabgroup('Parent', ControlsPanel,...
            'Tag','AddInfoTabGroup',...
            'units', 'normalized',...
            'Position',[0.0, 0.0 1.0 0.499]);
%         AddInfoTabEffectInfo = uitab('Parent', AddInfoTabGroup,...
%             'Tag','AddInfoTabEffectInfo',...
%             'Title', 'Effect Information');
        AddInfoTabGroupTraj = uitab('Parent', AddInfoTabGroup,...
            'Tag','AddInfoTabGroupTraj',...
            'Title', 'Trajectories');
        %CSPTabGroupTabContrast = uitab('Parent', AddInfoTabGroup,...
        %    'Tag','CSPTabGroupTabContrast',...
        %    'Title', 'Contrasts');
        
        
        %% Sub population Panel
        SubPopulationPanel = uipanel('BackgroundColor',get(hs.fig,'color'),...
            'units', 'normalized',...
            'Parent', CSPTabGroupTabSubpop,...
            'Tag', 'SubPopulationPanel',...
            'Position',[0.0, 0.0 1.0 1.0], ...
            'Title', 'Subpopulation Specification');
        
        SubPopulationSpecificationSubpanel = uipanel('BackgroundColor',get(hs.fig,'color'),...
            'units', 'normalized',...
            'Parent', SubPopulationPanel,...
            'Tag', 'SubPopulationSpecificationSubpanel',...
            'Position',[0.1, 0.51 0.8 0.48], ...
            'Title', 'Edit Subpopulation');
        
        SubPopulationSpecificationTable = uitable('Parent', SubPopulationSpecificationSubpanel,...
            'Tag', 'SubPopulationSpecificationTable',...
            'units', 'normalized',...
            'rowname', ddat.covariateNames,...
            'ColumnWidth', 'auto',...
            'data', ddat.defaultSubPopTableData,...
            'ColumnWidth', {150, 150},...
            'ColumnEditable', [true false],...
            'Position',[0.1, 0.1 0.80 0.8],...
            'CellEditCallback', @verify_subpop_cell_edit);

        SubPopulationListbox = uicontrol('Parent', SubPopulationPanel,...
            'Style', 'listbox',...
            'Tag', 'SubPopulationListbox',...
            'units', 'normalized',...
            'Position',[0.05, 0.15 0.90 0.3],...
            'callback', @subpop_listbox_selection);
        
        SubPopulationAddNew = uicontrol('Parent',SubPopulationPanel,...
                'Tag', 'SubPopulationAddNew',...
                'Style','pushbutton',...
                'String', 'Add New',...
                'units', 'normalized',...
                'Position', [0.09, 0.01 0.21 0.1],...
                'Callback', @add_new_subpopulation_to_listbox);
            
        SubPopulationRename = uicontrol('Parent',SubPopulationPanel,...
                'Tag', 'SubPopulationRename',...
                'Style','pushbutton',...
                'String', 'Rename',...
                'units', 'normalized',...
                'Position', [0.39, 0.01 0.21 0.1],...
                'Callback', @rename_subpopulation_from_listbox);
            
        SubPopulationDelete = uicontrol('Parent',SubPopulationPanel,...
                'Tag', 'SubPopulationDelete',...
                'Style','pushbutton',...
                'String', 'Delete Selected',...
                'units', 'normalized',...
                'Position', [0.69, 0.01 0.21 0.1],...
                'Callback', @delete_subpopulation_from_listbox);
                        
        %% Contrast Panel
        ContrastPanel = uipanel('BackgroundColor',get(hs.fig,'color'),...
            'units', 'normalized',...
            'Parent', CSPTabGroupTabContrast,...
            'Tag', 'ContrastPanel',...
            'Position',[0.0, 0.0 1.0 1.0], ...
            'Title', 'Linear Combination Specification');
        
        ContrastSpecificationSubpanel = uipanel('BackgroundColor',get(hs.fig,'color'),...
            'units', 'normalized',...
            'Parent', ContrastPanel,...
            'Tag', 'ContrastSpecificationSubpanel',...
            'Position',[0.1, 0.51 0.8 0.48], ...
            'Title', 'Edit Contrast');
        
        ContrastSpecificationTable = uitable('Parent', ContrastSpecificationSubpanel,...
            'Tag', 'ContrastSpecificationTable',...
            'units', 'normalized',...
            'rowname', [],...
            'ColumnEditable', [false true],...
            'ColumnWidth', {150, 150},...
            'data', ddat.defaultContrastTableData,...
            'Position',[0.1, 0.1 0.80 0.8],...
            'CellEditCallback', @verify_contrast_cell_edit);
        
        % Below does not work, but could if re-did
        % See 
        % https://www.mathworks.com/matlabcentral/answers/844620-increase-or-decrease-rownames-column-table
        %colStyle = uistyle('BackgroundColor', ContrastSpecificationTable.BackgroundColor(2,:), 'FontWeight','bold'); 
        %addStyle(ContrastSpecificationTable,colStyle,'column',1)
        
        ContrastListbox = uicontrol('Parent', ContrastPanel,...
            'Style', 'listbox',...
            'Tag', 'ContrastListbox',...
            'units', 'normalized',...
            'Position',[0.05, 0.15 0.90 0.3],...
            'callback', @contrast_listbox_selection);
        
        ContrastAddNew = uicontrol('Parent',ContrastPanel,...
                'Tag', 'ContrastAddNew',...
                'Style','pushbutton',...
                'String', 'Add New',...
                'units', 'normalized',...
                'Position', [0.09, 0.01 0.21 0.1],...
                'Callback', @add_new_contrast_to_listbox);
            
        ContrastRename = uicontrol('Parent',ContrastPanel,...
                'Tag', 'ContrastRename',...
                'Style','pushbutton',...
                'String', 'Rename',...
                'units', 'normalized',...
                'Position', [0.39, 0.01 0.21 0.1],...
                'Callback', @rename_contrast_from_listbox);
            
        ContrastDelete = uicontrol('Parent',ContrastPanel,...
                'Tag', 'ContrastDelete',...
                'Style','pushbutton',...
                'String', 'Delete Selected',...
                'units', 'normalized',...
                'Position', [0.69, 0.01 0.21 0.1],...
                'Callback', @delete_contrast_from_listbox);
            
        %% Quantities for the trajectory view
        % This view will only be available for studies with multiple time
        % points/visits
        TrajectoryPanel = uipanel('BackgroundColor',get(hs.fig,'color'),...
            'units', 'normalized',...
            'Parent', AddInfoTabGroupTraj,...
            'Tag', 'TrajectoryPanel',...
            'Position',[0.0, 0.0 1.0 1.0], ...
            'Title', 'Trajectory View',...
            'visible', 'on');
        
        TrajAxesAvg = axes('Parent', TrajectoryPanel, ...
            'units', 'normalized',...
            'Position',[.1 .6 0.35 0.35],...
            'Tag', 'TrajAxesAvg' ); %#ok<NASGU>
        
        TrajAxesCov = axes('Parent', TrajectoryPanel, ...
            'units', 'normalized',...
            'Position',[.1 .1 0.35 0.35],...
            'Tag', 'TrajAxesCov' ); %#ok<NASGU>
        
        TrajAxesSubpop = axes('Parent', TrajectoryPanel, ...
            'units', 'normalized',...
            'Position',[.55 .6 0.35 0.35],...
            'Tag', 'TrajAxesSubpop' ); %#ok<NASGU>
        
        TrajAxesSubj = axes('Parent', TrajectoryPanel, ...
            'units', 'normalized',...
            'Position',[.55 .1 0.35 0.35],...
            'Tag', 'TrajAxesSubj' ); %#ok<NASGU>
        
        %% Effect information panel
%         EffectInformationPanel = uipanel('BackgroundColor',get(hs.fig,'color'),...
%             'units', 'normalized',...
%             'Parent', AddInfoTabEffectInfo,...
%             'Tag', 'EffectInformationPanel',...
%             'Position',[0.0, 0.0 1.0 1.0], ...
%             'Title', 'Effect Trajectory',...
%             'visible', 'on');
%         
%         % Axes showing the effects
%         EffectInformationAxes = axes('Parent', EffectInformationPanel, ...
%             'units', 'normalized',...
%             'Position',[.2 .4 0.6 0.5],...
%             'Tag', 'EffectInformationAxes' ); %#ok<NASGU>
%         
%         EffectInformationControlPanel = uipanel('BackgroundColor',get(hs.fig,'color'),...
%             'units', 'normalized',...
%             'Parent', EffectInformationPanel,...
%             'Tag', 'EffectInformationControlPanel',...
%             'Position',[0.1, 0.0 0.8 0.3], ...
%             'Title', 'Effect Information Options',...
%             'visible', 'on');
%         
%         EffectInformationBrainViewSelect = uicontrol('Parent', EffectInformationControlPanel,...
%                 'Style', 'popupmenu', ...
%                 'Units', 'Normalized', ...
%                 'Position', [0.35, 0.7, 0.40, 0.22], ...
%                 'Tag', 'EffectInformationBrainViewSelect',...
%                 'visible', 'on',...
%                 'String', 'select',...
%                 'Callback', @select_effect_information_brain_view);
%             
%         EffectInformationBrainViewType = uicontrol('Parent', EffectInformationControlPanel,...
%                 'Style', 'popupmenu', ...
%                 'Units', 'Normalized', ...
%                 'Position', [0.35, 0.4, 0.40, 0.22], ...
%                 'Tag', 'EffectInformationBrainViewType',...
%                 'visible', 'on',...
%                 'String', {'Population', 'Covariate', 'Sub-population'},...
%                 'Callback', @select_effect_information_brain_view_type);
%         
%         EffectInformationSubpopDropdown = uicontrol('Parent', EffectInformationControlPanel,...
%             'Style', 'popupmenu', ...
%             'Units', 'Normalized', ...
%             'Position', [0.10, 0.1, 0.4, 0.2], ...
%             'Tag', 'EffectInformationSubpopDropdown',...
%             'visible', 'off',...
%             'String', {'Create a sub-population'},...
%             'Callback', @select_effect_information_subpopulation);
%         
%         EffectInformationCovariateDropdown = uicontrol('Parent', EffectInformationControlPanel,...
%             'Style', 'popupmenu', ...
%             'Units', 'Normalized', ...
%             'Position', [0.10, 0.1, 0.4, 0.2], ...
%             'Tag', 'EffectInformationCovariateDropdown',...
%             'visible', 'off',...
%             'String', ddat.covariateNames,...
%             'Callback', @select_effect_information_covariate);
%         
%         EffectInformationDrawVisitsCheckbox  = uicontrol('Parent', EffectInformationControlPanel,...
%                 'Style', 'checkbox', ...
%                 'Units', 'Normalized', ...
%                 'Position', [0.55, 0.1, 0.40, 0.22], ...
%                 'Tag', ['EffectInformationDrawVisitsCheckbox'],...
%                 'String', 'Display visit averages', ...
%                 'Callback', @toggle_effect_information_show_visit_averages); %#ok<NASGU>
            
%         if ddat.nVisit == 1
%             EffectInformationDrawVisitsCheckbox.Visible = 'off';
%         end
%         
%         EffectInformationSourceText = uicontrol('Parent', EffectInformationControlPanel, ...
%                 'Style', 'Text', ...
%                 'Units', 'Normalized', ...
%                 'String', 'Voxel/IC Source: ',...
%                 'Position', [0.10, 0.7, 0.2, 0.2], ...
%                 'Tag', 'EffectInformationSourceText');
%             
%         EffectInformationViewTypeText = uicontrol('Parent', EffectInformationControlPanel, ...
%                 'Style', 'Text', ...
%                 'Units', 'Normalized', ...
%                 'String', 'View Type: ',...
%                 'Position', [0.10, 0.4, 0.2, 0.2], ...
%                 'Tag', 'EffectInformationViewTypeText');
%         
       
        
        movegui(hs.fig, 'center')
        
    end

    %% Toolbar functions - File
    function save_viewer_options(src, event)
        
        % Ask user to name file
        newName = inputdlg('Input name for saved viewer file', 'File Name');

        if isempty(newName); return; end
        if isempty(strtrim(newName{1})); return; end
        
        newName = strtrim(newName{1});
        
        fname = fullfile(ddat.outdir, [ddat.outpre '_SavedViewer_' newName]);
        ddat.currentSaveFile = fname;
        anatomicalFile = ImageData.anatomicalFile;

        save( ddat.currentSaveFile, 'ddat', 'anatomicalFile');
        
        % enable one-click saving
        set(findobj('tag', 'saveOpt'), 'enable', 'on');
        
    end

    % callback for basic save button
    function update_saved_viewer_options(src, event)
        anatomicalFile = ImageData.anatomicalFile;
        save( ddat.currentSaveFile, 'ddat', 'anatomicalFile');
    end

    function load_saved_viewer_options(src, event)
        
        % Request the file from the user
        [fname, pathname] = uigetfile('.mat', '', ddat.outdir);
        if fname == 0
            return
        end
        tempDdat = load(fullfile(pathname, fname));
        
        if ~isfield(tempDdat, 'ddat')
            disp('This does not appear to be a valid saved viewer file. Cancelling load request.')
            return
        end
                
        % Start by creating viewers (with incorrect positioning)
        for index = 2:tempDdat.ddat.nViewer
            add_brain_view(findobj('tag', 'AddBrainViewButton_1'), matlab.ui.eventdata.ButtonPushedData)
        end
        
        ddat = tempDdat.ddat;
        ImageData.anatomicalFile = tempDdat.anatomicalFile;
        
        % Load the "non followers" first
        %lic(1)
        initialize_anatomical;
        
        % First those that are synced to a different 
        for index = 1:ddat.nViewer
            lic(index)
        end
        
        
        %initial_display;
        
        set_subpopulation_quantities;
        
        set_contrast_quantities;
        
        % enable saving over the current file
        set(findobj('tag', 'saveOpt'), 'enable', 'on');
        
        % Apply potential menu settings
        set(findall(gcf,'-property','FontSize'),'FontSize', ddat.textSize)
         
        
    end

    function load_anatomical(src, event)
        
        [fname, pathname] = uigetfile('.nii', '', ddat.outdir);
        if fname == 0
            return
        end
        
        % Quick check that this file is the right size;
        anatFile = fullfile(pathname, fname);
        tempAnat = load_nii(anatFile);
        
        if ~all(size(tempAnat.img) == ddat.voxSize)
            disp('Mismatch between anatomical size and brain map size.')
            disp('Anatomical image had dimension:')
            disp(size(tempAnat.img))
            disp('Brain maps have size:')
            disp(ddat.voxSize)
            disp('Cancelling anatomical load.')
        end
        
        % Check dimension
                
        ImageData.anatomicalFile = anatFile;
        initialize_anatomical;
        
        for index = 1:ddat.nViewer
            frc(index);
        end
        
    end

    function change_text_size(src, event)

        % Ask user for new text size
        newFontSize = inputdlg(['Current Font Size: ' num2str(ddat.textSize)], 'Font Size');

        % Check for valid input
        if isempty(newFontSize); return; end
        if isempty(strtrim(newFontSize{1})); return; end
        
        % Make sure valid numeric input
        newFontSize = str2num(newFontSize{1});
        if isempty(newFontSize); return; end
        
        ddat.textSize = newFontSize;
        
        set(findall(gcf,'-property','FontSize'),'FontSize', ddat.textSize)
    end

    %% Toolbar functions - Export
    
    function save_nifti_file(src, event)
        
        % Get user input from gui
        saveInfo = display_get_nifti_export_info(ddat.nViewer, ddat.currentViewerType, ddat.outdir);
        
        % check if user canceled request
        if saveInfo.validRequest == false
            return
        end
        
        % Create space for the new nifti image
        newNiftiImage = zeros(ddat.sagDim, ddat.corDim, ddat.axiDim, length(saveInfo.saveViews));
        
        % Construct each page of the new nifti file
        for i = 1:length(saveInfo.saveViews)
            index = saveInfo.saveViews(i);
            
            % If user has requested p-values then z-scores must be created
            useZ = ddat.viewZScores{index};
            if ~strcmp(saveInfo.mapTypeSelection, 'Output brain map');
                if useZ == 0
                    disp(['P-values were requested, converting map ' num2str(index) ' to Z-scores...'])
                    useZ = 1;
                end
            end
            
            % This is the base image - either raw or Z, thresholded
            newNiftiImage(:, :, :, i) = create_full_volume(ImageData.rawImages{index},...
                ddat.thresholdVal{index},...
                ImageData.imageScaleFactors{index},...
                useZ,...
                ImageData.maskingLayer{index}) ;
            
            % If user requested p-values, make the conversion
            if ~strcmp(saveInfo.mapTypeSelection, 'Output brain map')
                pvalues = newNiftiImage(:, :, :, i);
                pvalues = pvalues(ddat.validVoxels);
                % Construct p-values from Z-scores
                pvalues = 2 * (1 - normcdf(abs(pvalues)));

                % If user requested -log p-values, make the conversion
                if strcmp(saveInfo.mapTypeSelection, 'Output -log p-value maps')
                    pvalues = -1.0 * log(pvalues);
                end
                newNiiPage = zeros(ddat.voxSize);
                newNiiPage(ddat.validVoxels) = pvalues;
                newNiftiImage(:, :, :, i) = newNiiPage;
            end
            
            
        end
        
        % Create the corresponding nifti file
        newNii = make_nii(newNiftiImage);
        newNii.hdr.hist.originator = ddat.originator;
        
        % Write out
        % First check if exports directory already exists
        outputDir = fullfile(ddat.outdir, extractBefore(ddat.outpre, '/'), 'exports');
        if not(isfolder(outputDir))
            mkdir(outputDir);
        end
       
        fname = fullfile(outputDir, saveInfo.filename );
        save_nii(newNii, fname);
        
        
    end


    %% 
    
    % full render cycle - shows the select slices
    function frc(indices)
        
        for ind = 1:length(indices)
            
            i = indices(ind);
            
            set_selected_slice(i);
                        
            set_sync_properties(i);
            
            set_ic_properties(i);
            
            set_selected_visit(i);
            
            set_selected_covariate(i);
            
            set_selected_subpopulation(i);
            
            transform_selected_slice(i);
            
            set_brain_slider_positions(i);
            
            set_threshold_quantities(i);

            set_colormap_info(i);

            render_image_slice(i);

            set_selected_voxel_information(i);
                        
            % Update any "Followers"
  
            % Get indices for any followers:
            followerIndices = find([ddat.syncTo{:}] == i);
            followerIndices(followerIndices == i) = [];
            
            for iFollower = 1:length(followerIndices)
                
                followerInd = followerIndices(iFollower);
                
                % Update quantities
                reload_required = copy_over_ddat_quantities(followerInd, i);
                
                if reload_required == 1
                    lic(followerInd)
                else
                    frc(followerInd)
                end
            end
            
        end
        
        % This happens regardless of which index is updated
        % would be more efficient not to redo, but makes tracking difficult
        set_trajectory_views;
        set_mask_dropdown_options;
        %set_effect_information;
        
    end

    function set_ic_properties(index);
        set(findobj('tag', ['ICSelectDropdown_' num2str(index)]), 'value', ddat.currentIC{index});
    end

    % needed for syncing
    function reload_required = copy_over_ddat_quantities(copyToInd, copyFromInd)
        ddat.axiPos{copyToInd} = ddat.axiPos{copyFromInd};
        ddat.corPos{copyToInd} = ddat.corPos{copyFromInd};
        ddat.sagPos{copyToInd} = ddat.sagPos{copyFromInd};
        
        reload_required = 0;

        if ddat.syncICs{copyToInd} == 1
            if ddat.currentIC{copyToInd} ~= ddat.currentIC{copyFromInd}
                ddat.currentIC{copyToInd} = ddat.currentIC{copyFromInd};
                reload_required = 1;
            end
        end
        
        if ddat.syncThresholding{copyToInd} == 1
            ddat.thresholdVal{copyToInd} = ddat.thresholdVal{copyFromInd};
        end
        
        if ddat.syncColormaps{copyToInd} == 1
            ddat.clims{copyToInd} = ddat.clims{copyFromInd};
            ddat.colorbarScheme{copyToInd} = ddat.colorbarScheme{copyFromInd};
        end
        

    end

    % edit images cycle - any changes required to the underlying maps 
   
    function eic(index);
        
        frc(index);
        
    end

    % Load images cycle
    % also calls function to controls visiblity of different parts of the control window
    function lic(index)
        
        % Check if need to load the VarCov matrix for this IC
        if ImageData.loadedVarCov{ddat.currentIC{index}} == 0 && ~ddat.isPreview
            disp('Loading quantities for this IC ...')
            fname = fullfile(ddat.outdir, [ddat.outpre, '_BetaVarEst_IC' num2str(ddat.currentIC{index}) '.mat']);
            varCovTemp = load(fname);
            
            % 1, 1 is S0 variance
            % 2, 2 - J, J are the J-1 visit covariances
            ImageData.VarCov{ddat.currentIC{index}} = varCovTemp.varEstIC;
            
            % Change the indicator to inform that the VarCov has been
            % loaded for this component
            ImageData.loadedVarCov{ddat.currentIC{index}} =1;
            
            fname = fullfile(ddat.outdir, [ddat.outpre, '_all_effect_ests_IC' num2str(ddat.currentIC{index}) '.mat']);
            coefEstsTemp = load(fname);
            ImageData.CoefEsts{ddat.currentIC{index}} = coefEstsTemp.allCoefs;
            ImageData.loadedCoefEsts{ddat.currentIC{index}} = 1;
            disp('... done')
        end
        
        % Control which widgets are visible
        set_widget_visibility(index)
                
        switch ddat.currentViewerType{index}
            case 'Population'
                imagePath = fullfile(ddat.outdir, [ddat.outpre, '_S0_IC_' num2str(ddat.currentIC{index}) '.nii']);
                imageRaw = load_nii(imagePath);
            case 'Covariate Effect'
                imagePath = fullfile(ddat.outdir, [ddat.outpre, '_beta_cov'...
                    num2str(ddat.currentCov{index})...
                    '_IC' num2str(ddat.currentIC{index})...
                    '_visit' num2str(ddat.currentVisit{index})...
                    '.nii']);
                imageRaw = load_nii(imagePath);
            case 'Linear Combination'
                % Placeholder until contrast is selected
                imagePath = '';
                % Handle case where no contrast is specified
                imageRaw = struct();
                imageRaw.img = zeros(size(ImageData.anatomical{1}));
                % This if-statement is to handle value = 1 for dropdown but
                % no contrast specified
                if ~isempty( ddat.contrastNames)
                    imageRaw.img(ddat.validVoxels) = squeeze(...
                        ddat.contrastCoefSettings{ddat.currentContrast{index}}' *...
                        ImageData.CoefEsts{ddat.currentIC{index}}(2:end,:) );
                end
            case 'Sub-Population'
                % Placeholder until sub-population is selected
                imagePath = '';
                % Handle case where no subpopulation is specified
                imageRaw = struct();
                imageRaw.img = zeros(size(ImageData.anatomical{1}));
                if ~isempty( ddat.subpopNames )
                    modelMatrix = ddat.subpopModelMats{ddat.currentSubpop{index}};
                    if ddat.nVisit == 1
                        imageRaw.img(ddat.validVoxels) = squeeze(...
                            modelMatrix *...
                            ImageData.CoefEsts{ddat.currentIC{index}} );
                    else
                        imageRaw.img(ddat.validVoxels) = squeeze(...
                            modelMatrix(ddat.currentVisit{index}, :) *...
                            ImageData.CoefEsts{ddat.currentIC{index}} );
                    end
                end
            case 'Preview'
                imagePath = fullfile(ddat.outdir, ['_iniIC_' num2str(ddat.currentIC{index}) '.nii']);
                imageRaw = load_nii(imagePath);
            case 'Single Subject'
                disp('Creating subjects data...')
                fname = fullfile(ddat.outdir, [ddat.outpre, '_subject_IC_estimates' '.mat']);
                subjectData = load(fname);
                imagePath = '';
                ddat.currentSubjectMatData{index} = squeeze(subjectData.subICmean(:, :, ddat.currentSubject{index}, :));
                imageRaw = struct();
                imageRaw.img = zeros(size(ImageData.anatomical{1}));
                imageRaw.img(ddat.validVoxels) = squeeze(...
                    subjectData.subICmean(ddat.currentIC{index}, :, ddat.currentSubject{index},...
                    ddat.currentVisit{index}));
            otherwise
                    disp('Unrecognized viewer type')
        end
        
        ImageData.rawImages{index} = imageRaw.img;
        ImageData.imageFilenames{index}    = imagePath;
        
        if isempty(ImageData.maskingFile{index})
            ImageData.maskingLayer{index} = ones(ddat.voxSize);
        else
            masktemp = load_nii(ImageData.maskingFile{index});
            ImageData.maskingLayer{index} = masktemp.img;
        end
              
        % Consider moving this to a separate function
        ImageData.imageScaleFactors{index} = zeros(ddat.voxSize);
        
        switch ddat.currentViewerType{index}
            case 'Population'
%                 ImageData.imageScaleFactors{index}(ddat.validVoxels) =...
%                     ImageData.VarCov{ddat.currentIC{index}}(1, 1, :);
                ImageData.imageScaleFactors{index}(ddat.validVoxels) =...
                    std(ImageData.rawImages{index}(ddat.validVoxels));
            case 'Covariate Effect'
                varCovInd = ddat.nVisit + ...
                    ddat.P * (ddat.currentVisit{index}-1) + ...
                    ddat.currentCov{index};
                ImageData.imageScaleFactors{index}(ddat.validVoxels) =...
                    ImageData.VarCov{ddat.currentIC{index}}(varCovInd, varCovInd, :);
            case 'Linear Combination'
                if ~isempty( ddat.contrastNames )
                    ImageData.imageScaleFactors{index}(ddat.validVoxels) =...
                        squeeze(mtimesx(...
                            mtimesx(ddat.contrastCoefSettings{ddat.currentContrast{index}}',...
                            ImageData.VarCov{ddat.currentIC{index}}(2:end,2:end,:)),...
                            ddat.contrastCoefSettings{ddat.currentContrast{index}}...
                        ));
                end
            case 'Sub-Population'
                if ~isempty( ddat.subpopNames )
                    modelMatrix = ddat.subpopModelMats{ddat.currentSubpop{index}};
                    if ddat.nVisit == 1
%                         ImageData.imageScaleFactors{index}(ddat.validVoxels) =...
%                             squeeze(mtimesx(...
%                                 mtimesx(modelMatrix,...
%                                 ImageData.VarCov{ddat.currentIC{index}}),...
%                                 modelMatrix'...
%                             ));
                        ImageData.imageScaleFactors{index}(ddat.validVoxels) =...
                            std(ImageData.rawImages{index}(ddat.validVoxels));
                    else
%                         ImageData.imageScaleFactors{index}(ddat.validVoxels) =...
%                             squeeze(mtimesx(...
%                                 mtimesx(modelMatrix(ddat.currentVisit{index}, :),...
%                                 ImageData.VarCov{ddat.currentIC{index}}),...
%                                 modelMatrix(ddat.currentVisit{index}, :)'...
%                             ));
                        ImageData.imageScaleFactors{index}(ddat.validVoxels) =...
                            std(ImageData.rawImages{index}(ddat.validVoxels));
                    end
                end
            case 'Preview'
                ImageData.imageScaleFactors{index}(ddat.validVoxels) = std(ImageData.rawImages{index}(ddat.validVoxels));
            case 'Single Subject'
                ImageData.imageScaleFactors{index}(ddat.validVoxels) = std(ImageData.rawImages{index}(ddat.validVoxels));
            otherwise
                disp('Unrecognized viewer type')
        end
        
        % end of stuff to move to new function
                
        ImageData.axiSlices{index} = imageRaw.img(:, :, ddat.axiPos{index});
        ImageData.corSlices{index} = squeeze(imageRaw.img(:, ddat.corPos{index}, :));
        ImageData.sagSlices{index} = squeeze(imageRaw.img(ddat.sagPos{index}, :, :));
        
        eic(index);
        
    end

    %% Widget Values
    
    function set_widget_visibility(index)
        
        % Start by turning all off
        set(findobj('tag', ['CovSelectDropdown_' num2str(index)]), 'visible', 'off');
        set(findobj('tag', ['VisitSelectDropdown_' num2str(index)]), 'visible', 'off');
        set(findobj('tag', ['SubPopSelectDropdown_' num2str(index)]), 'visible', 'off');
        set(findobj('tag', ['ContrastSelectDropdown_' num2str(index)]), 'visible', 'off');
        set(findobj('tag', ['SubjectSelectDropdown_' num2str(index)]), 'visible', 'off');
        
        switch ddat.currentViewerType{index}
            
            case 'Population'
   
            case 'Covariate Effect'
                set(findobj('tag', ['CovSelectDropdown_' num2str(index)]), 'visible', 'on');
                if ddat.nVisit > 1
                    set(findobj('tag', ['VisitSelectDropdown_' num2str(index)]), 'visible', 'on');
                end
            case 'Sub-Population'
                if ddat.nVisit > 1
                    set(findobj('tag', ['VisitSelectDropdown_' num2str(index)]), 'visible', 'on');
                end
                set(findobj('tag', ['SubPopSelectDropdown_' num2str(index)]), 'visible', 'on');
            case 'Linear Combination'
                set(findobj('tag', ['ContrastSelectDropdown_' num2str(index)]), 'visible', 'on');
            case 'Single Subject'
                set(findobj('tag', ['SubjectSelectDropdown_' num2str(index)]), 'visible', 'on');
                if ddat.nVisit > 1
                    set(findobj('tag', ['VisitSelectDropdown_' num2str(index)]), 'visible', 'on');
                end
            case 'Preview'
                set(findobj('tag', 'SubPopulationAddNew'), 'enable', 'off');
                set(findobj('tag', 'SubPopulationRename'), 'enable', 'off');
                set(findobj('tag', 'SubPopulationDelete'), 'enable', 'off');
                set(findobj('tag', 'ContrastAddNew'), 'enable', 'off');
                set(findobj('tag', 'ContrastRename'), 'enable', 'off');
                set(findobj('tag', 'ContrastDelete'), 'enable', 'off');
            otherwise
                disp('Unrecognized viewer type')
        end
        
        
    end

    function set_brain_slider_positions(index)
        set(findobj('Tag', ['SagSlider_' num2str(index)] ), 'Value', ddat.sagPos{index});
        set(findobj('Tag', ['CorSlider_' num2str(index)]), 'Value', ddat.corPos{index});
        set(findobj('Tag', ['AxiSlider_' num2str(index)]), 'Value', ddat.axiPos{index});
    end

    function set_selected_visit(index)
        set(findobj('Tag', ['VisitSelectDropdown_' num2str(index)] ), 'Value', ddat.currentVisit{index});
    end

    function set_selected_covariate(index)
        set(findobj('Tag', ['CovSelectDropdown_' num2str(index)] ), 'Value', ddat.currentCov{index});
    end

    function set_selected_subpopulation(index)
        set(findobj('Tag', ['SubPopSelectDropdown_' num2str(index)] ), 'Value', ddat.currentSubpop{index});
    end

    function set_threshold_quantities(index)
        
        
        % Extend range of theshold slider if needed
        if ddat.thresholdVal{index} > get(findobj('Tag', ['thresholdSlider_' num2str(index)]), 'max')
            set(findobj('Tag', ['thresholdSlider_' num2str(index)]), 'max', 1.2 *  ddat.thresholdVal{index});
        end
        
        set(findobj('Tag', ['thresholdSlider_' num2str(index)]), 'Value', ddat.thresholdVal{index});
        set(findobj('Tag', ['thresholdValueBox_' num2str(index)]), 'String', num2str(ddat.thresholdVal{index}));
    end

    function setup_IC_select_dropdown(index);
        newstring = cell(ddat.Q, 1);
        for q = 1:ddat.Q
            newstring{q} = strcat('IC ', num2str(q));
        end
        set(findobj('Tag', ['ICSelectDropdown_' num2str(index)]), 'String', newstring);
    end

    function setup_subject_select_dropdown(index);
        newstring = cell(ddat.N, 1);
        for i = 1:ddat.N
            newstring{i} = strcat('Subject ', num2str(i));
        end
        set(findobj('Tag', ['SubjectSelectDropdown_' num2str(index)]), 'String', newstring);
    end

    %% Functions related to sub-population specification
    
    % This is the main function that feeds subpopulation information to the
    % primary viewing window
    function set_subpopulation_quantities
        
        %% Part 1 - Manage Listbox of Subpopulations
        
        currentSubpops = ddat.subpopNames;
        nSubpop = length(currentSubpops);
        if isempty(currentSubpops)
            set(findobj('tag', 'SubPopulationDelete'), 'enable', 'off');
            set(findobj('tag', 'SubPopulationRename'), 'enable', 'off');
        else
            set(findobj('tag', 'SubPopulationDelete'), 'enable', 'on');
            set(findobj('tag', 'SubPopulationRename'), 'enable', 'on');
        end
                
        % First a safety check that the selected listbox element is not out
        % of bounds (could happen in case of deletion).
        if get(findobj('tag', 'SubPopulationListbox'), 'Value') > nSubpop
            set(findobj('tag', 'SubPopulationListbox'), 'Value', 1);
        end
        % Now set the display listbox
        set(findobj('tag', 'SubPopulationListbox'), 'String', currentSubpops);
        
        %% Part 2 - The edit window for selected subpopulation
                        
        if ddat.subpopBeingEdited > length(ddat.subpopNames)
            newTitle = 'No sub-population selected';
            set(findobj('tag', 'SubPopulationSpecificationTable'), 'enable', 'off');
            set(findobj('tag', 'SubPopulationSpecificationTable'), 'data', {});
        else
            set(findobj('tag', 'SubPopulationSpecificationTable'), 'enable', 'on');
            newTitle = ['Edit Subpopulation: ' ddat.subpopNames{ddat.subpopBeingEdited}];
            newData = ddat.defaultSubPopTableData;
            newData(:, 1) = ddat.subpopCovSettings{ddat.subpopBeingEdited};
            set(findobj('tag', 'SubPopulationSpecificationTable'), 'data', newData);
        end
        set(findobj('tag', 'SubPopulationSpecificationSubpanel'), 'title', newTitle);
                
        %% Part 3 - Trigger update for any viewers
        set_subpop_dropdown_strings;
        
    end
    
    function add_new_subpopulation_to_listbox(src, event)
        currentSubpops = ddat.subpopNames;
        % Code below is to generate a temporary name for the subpopulation
        newSubpopString = 'New Subpopulation ';
        isUnique = 0;
        counter = 1;
        while isUnique == 0
            if all(strcmpi(currentSubpops, [newSubpopString num2str(counter)]) == 0)
                isUnique = 1;
            else
                counter = counter + 1;
            end
        end
        
        index = length(ddat.subpopNames) + 1;
        ddat.subpopNames{index} = [newSubpopString num2str(counter)];
        
        % initialize sub-population covariates to default values
        ddat.subpopCovSettings{index} = ddat.defaultSubPopTableData(:, 1);
        
        % initialize model matrix to default values
        [X, varNamesX] = generate_model_matrix(ddat.covTypes,...
            ddat.variableCodingInformation.varInModel,...
            ddat.subpopCovSettings{index}',...
            ddat.variableCodingInformation.effectsCodingsEncoders,...
            ddat.variableCodingInformation.unitScale,...
            ddat.variableCodingInformation.weighted,...
            ddat.variableCodingInformation.interactionsBase,...
            ddat.covariateNames,...
            ddat.variableCodingInformation.covariateMeans,...
            ddat.variableCodingInformation.covariateSDevs);
        
        % Create the full version of the model matrix (one row per visit)
        if ddat.nVisit > 1
            X = kron(eye(ddat.nVisit), X);
            basicBlock = [-1 * ones(1, ddat.nVisit-1) ; eye(ddat.nVisit - 1)];
            X = [ones(ddat.nVisit, 1) basicBlock X];
        else
            X = [1 X];
        end
        
        ddat.subpopModelMats{index} = X;
        
        set_subpopulation_quantities;
    end

    function delete_subpopulation_from_listbox(src, event)
        
        currentSubpops = ddat.subpopNames;
        
        % Safeguard, but this should not trigger since button should be
        % disabled
        if isempty(currentSubpops); return; end
        
        selectedSubpop = get(findobj('tag', 'SubPopulationListbox'), 'Value');
        
        ddat.subpopNames(selectedSubpop) = [];
        ddat.subpopCovSettings(selectedSubpop) = [];
        ddat.subpopModelMats(selectedSubpop) = [];
        
        if ddat.subpopBeingEdited == selectedSubpop
            ddat.subpopBeingEdited = 1;
        end
        
        for index = 1:ddat.nViewer
            % Shift the indices for any viewers that were using a subpopulation
            % with index higher than the one that was just deleted
            % Nothing else needs to change for these.
            if ddat.currentSubpop{index} > selectedSubpop
                ddat.currentSubpop{index} = ddat.currentSubpop{index} - 1;
            end
            % Any viewers that were examining the delete subpopulation need
            % to be shifted down to the next available subpopulation
            if ddat.currentSubpop{index} == selectedSubpop
                if selectedSubpop > 1
                    ddat.currentSubpop{index} = ddat.currentSubpop{index} - 1;
                end
                lic(index)
            end
        end
                
        set_subpopulation_quantities;
        
    end

    function rename_subpopulation_from_listbox(src, event)
        index = get(findobj('tag', 'SubPopulationListbox'), 'Value');
        
        % Ask user for new sub-population name
        newName = inputdlg('Input Name For Sub-Population', 'Name Sub Population');

        if isempty(newName); return; end
        if isempty(strtrim(newName{1})); return; end
        
        newName = strtrim(newName{1});
        
        % Make sure name does not already exist
        indexMatch = strcmpi(ddat.subpopNames, newName);
        if ~isempty(find(indexMatch, 1))
            disp('Cannot change sub-population name. Requested sub-population name is already in use.');
            return
        end
        
        % If passed those three checks, can change the name
        ddat.subpopNames{index} = newName;
        
        set_subpopulation_quantities;
    end

    function subpop_listbox_selection(src, event)
        if isempty(src.Value); return; end
        ddat.subpopBeingEdited = src.Value;
        set_subpopulation_quantities;     
    end
    
    function verify_subpop_cell_edit(src, event)
        covEdited = event.Indices(1);
        newInput = event.EditData;
        
        newValue = Inf;
        
        % If continuous covariate - check valid number
        if ddat.covTypes(covEdited) == 0
            
            % Fix if invalid number
            if any(~ismember(newInput, '0123456789.-')) || isempty(newInput)
                newValue = event.PreviousData;
            end
            
            % Warn if out of range
            inputNum = str2num(newInput);
            if ~all( inputNum >= min(ddat.covariates{:, covEdited}) & ...
                    inputNum <= max(ddat.covariates{:, covEdited}))
                
                disp(['WARNING - input value for ' ddat.covariateNames{covEdited},...
                    ' is more extreme than any value in dataset.'])
                
            end
            
            newValue = inputNum;
            
        else
            % Check option valid     
            uniqueCovariates = unique(ddat.covariates{:, covEdited});
            indexMatch = strcmpi(uniqueCovariates, newInput);
            finalSelection = find(indexMatch);
            
            if isempty(finalSelection)
                disp(['WARNING - ' newInput ' is not a valid level.'])
                newValue = event.PreviousData;
            else
                newValue = uniqueCovariates{finalSelection};
            end
            
        end
        
        % Update the data structure
        ddat.subpopCovSettings{ddat.subpopBeingEdited}{covEdited} = newValue;
        
        % Update the model matrix
        [X, varNamesX] = generate_model_matrix(ddat.covTypes,...
            ddat.variableCodingInformation.varInModel,...
            ddat.subpopCovSettings{ddat.subpopBeingEdited}',...
            ddat.variableCodingInformation.effectsCodingsEncoders,...
            ddat.variableCodingInformation.unitScale,...
            ddat.variableCodingInformation.weighted,...
            ddat.variableCodingInformation.interactionsBase,...
            ddat.covariateNames,...
            ddat.variableCodingInformation.covariateMeans,...
            ddat.variableCodingInformation.covariateSDevs);
        
        % Create the full version of the model matrix (one row per visit)
        X = kron(eye(ddat.nVisit), X);
        basicBlock = [-1 * ones(1, ddat.nVisit-1) ; eye(ddat.nVisit - 1)];
        X = [ones(ddat.nVisit, 1) basicBlock X];
        
        ddat.subpopModelMats{ddat.subpopBeingEdited} = X;
        
        for index = 1:ddat.nViewer
            if strcmpi(ddat.currentViewerType{index}, 'Sub-Population')
                if ddat.currentSubpop{index} == ddat.subpopBeingEdited
                    lic(index)
                end
            end
        end
        
        % Update all
        set_subpopulation_quantities;
        
    end

    function set_subpop_dropdown_strings
        for index = 1:ddat.nViewer
            if ~isempty( ddat.subpopNames )
                set(findobj('tag', ['SubPopSelectDropdown_' num2str(index)]),...
                    'String', ddat.subpopNames);
            else
                set(findobj('tag', ['SubPopSelectDropdown_' num2str(index)]),...
                    'String', 'No sub-populations specified');
            end
        end
    end

    %% Functions related to contrast specification
    
    function set_contrast_quantities
        
        %% Part 0 - Keep track if user has resized
        ddat.currentUserContrastTableExtent = get(findobj('tag', 'ContrastSpecificationTable'), 'extent');
        
        %% Part 1 - Manage Listbox of Contrast
        
        currentContrasts = ddat.contrastNames;
        nContrast = length(currentContrasts);
        if isempty(currentContrasts)
            set(findobj('tag', 'ContrastDelete'), 'enable', 'off');
            set(findobj('tag', 'ContrastRename'), 'enable', 'off');
        else
            set(findobj('tag', 'ContrastDelete'), 'enable', 'on');
            set(findobj('tag', 'ContrastRename'), 'enable', 'on');
        end
                
        % First a safety check that the selected listbox element is not out
        % of bounds (could happen in case of deletion).
        if get(findobj('tag', 'ContrastListbox'), 'Value') > nContrast
            set(findobj('tag', 'ContrastListbox'), 'Value', 1);
        end
        % Now set the display listbox
        set(findobj('tag', 'ContrastListbox'), 'String', currentContrasts);
        
        %% Part 2 - The edit window for selected contrast
                        
        if ddat.contrastBeingEdited > length(ddat.contrastNames)
            newTitle = 'No combination selected';
            set(findobj('tag', 'ContrastSpecificationTable'), 'enable', 'off');
            set(findobj('tag', 'ContrastSpecificationTable'), 'data', {});
        else
            set(findobj('tag', 'ContrastSpecificationTable'), 'enable', 'on');
            newTitle = ['Edit Contrast: ' ddat.contrastNames{ddat.contrastBeingEdited}];
            newData = ddat.defaultContrastTableData;
            newData(:, 2) = num2cell(ddat.contrastCoefSettings{ddat.contrastBeingEdited});            
            set(findobj('tag', 'ContrastSpecificationTable'), 'data', newData);
            set(findobj('tag', 'ContrastSpecificationTable'), 'ColumnName', {'Parameter', 'Coefficient'});
        end
        set(findobj('tag', 'ContrastSpecificationSubpanel'), 'title', newTitle);
        
        % Now update any resizing so that it does not reset
        %set(findobj('tag', 'ContrastSpecificationTable'), 'extent', ddat.currentUserContrastTableExtent);
                
        %% Part 3 - Trigger update for any viewers
        set_contrast_dropdown_strings;
        
    end
    
    function add_new_contrast_to_listbox(src, event)
        currentContrasts = ddat.contrastNames;
        % Code below is to generate a temporary name for the contrast
        newContrastString = 'LC ';
        isUnique = 0;
        counter = 1;
        while isUnique == 0
            if all(strcmpi(currentContrasts, [newContrastString num2str(counter)]) == 0)
                isUnique = 1;
            else
                counter = counter + 1;
            end
        end
        
        index = length(ddat.contrastNames) + 1;
        ddat.contrastNames{index} = [newContrastString num2str(counter)];
        
        % initialize contrast covariates to default values (zeros)
        ddat.contrastCoefSettings{index} = zeros(length(ddat.contrastBetaLabels), 1);
        
        set_contrast_quantities;
    end

    function rename_contrast_from_listbox(src, event)
        index = get(findobj('tag', 'ContrastListbox'), 'Value');
        
        % Ask user for new sub-population name
        newName = inputdlg('Input Name For Linear Combination', 'Name Linear Combination');

        if isempty(newName); return; end
        if isempty(strtrim(newName{1})); return; end
        
        newName = strtrim(newName{1});
        
        % Make sure name does not already exist
        indexMatch = strcmpi(ddat.contrastNames, newName);
        if ~isempty(find(indexMatch, 1))
            disp('Cannot change name. Requested name is already in use.');
            return
        end
        
        % If passed those three checks, can change the name
        ddat.contrastNames{index} = newName;
        
        set_contrast_quantities;
    end

    function delete_contrast_from_listbox(src, event)
        
        currentContrasts = ddat.contrastNames;
        
        % Safeguard, but this should not trigger since button should be
        % disabled
        if isempty(currentContrasts); return; end
        
        selectedContrast = get(findobj('tag', 'ContrastListbox'), 'Value');
        
        ddat.contrastNames(selectedContrast) = [];
        ddat.contrastCoefSettings(selectedContrast) = [];
        
        if ddat.contrastBeingEdited == selectedContrast
            ddat.contrastBeingEdited = 1;
        end
        
        for index = 1:ddat.nViewer
            % Shift the indices for any viewers that were using a contrast
            % with index higher than the one that was just deleted
            % Nothing else needs to change for these.
            if ddat.currentContrast{index} > selectedContrast
                ddat.currentContrast{index} = ddat.currentContrast{index} - 1;
            end
            % Any viewers that were examining the deleted contrast need
            % to be shifted down to the next available contrast
            if ddat.currentContrast{index} == selectedContrast
                if selectedContrast > 1
                    ddat.currentContrast{index} = ddat.currentContrast{index} - 1;
                end
                if strcmp(ddat.currentViewerType{index}, 'Linear Combination')
                    lic(index)
                end
            end
        end
                
        set_contrast_quantities;
        
    end

    function contrast_listbox_selection(src, event)
        if isempty(src.Value); return; end
        ddat.contrastBeingEdited = src.Value;
        set_contrast_quantities;     
    end

    function verify_contrast_cell_edit(src, event)
        covEdited = event.Indices(1);
        newInput = event.EditData;
                
        % Fix if invalid number
        if any(~ismember(newInput, '0123456789.-')) || isempty(newInput)
            newValue = event.PreviousData;
            ddat.contrastCoefSettings{ddat.contrastBeingEdited}(covEdited) = newValue;
        else
            newValue = str2num(newInput);
            % Update the data structure
            ddat.contrastCoefSettings{ddat.contrastBeingEdited}(covEdited) = newValue;

            for index = 1:ddat.nViewer
                if strcmpi(ddat.currentViewerType{index}, 'Linear Combination')
                    if ddat.currentContrast{index} == ddat.contrastBeingEdited
                        lic(index)
                    end
                end
            end
        end
        
        % Update all
        set_contrast_quantities;
        
    end

    function set_contrast_dropdown_strings
        for index = 1:ddat.nViewer
            if ~isempty( ddat.contrastNames )
                set(findobj('tag', ['ContrastSelectDropdown_' num2str(index)]),...
                    'String', ddat.contrastNames);
            else
                set(findobj('tag', ['ContrastSelectDropdown_' num2str(index)]),...
                    'String', 'No contrasts specified');
            end
        end
    end


    %% Functions related to trajectory views
    function set_trajectory_views
        
        % No need to do this if not a longitudinal study
        if ddat.nVisit == 1; return; end
        
                
        % Reset the plots
        delete(findobj('tag', 'TrajAxesAvg').Children);
        delete(findobj('tag', 'TrajAxesCov').Children);
        delete(findobj('tag', 'TrajAxesSubpop').Children);
        delete(findobj('tag', 'TrajAxesSubj').Children);

        % Legends for each plot
        popAvgLegend    = cell(0);
        covLegend       = cell(0);
        subpopLegend    = cell(0);
        subjLegend    = cell(0);
        
        colorOptions = lines(ddat.nViewer);
        
        for index = 1:ddat.nViewer
            
            switch ddat.currentViewerType{index}
                case 'Sub-Population'
                    
                    % Make sure sub populations have been defined
                    if isempty( ddat.subpopNames )
                        continue;
                    end
                    
                    ind1 = sub2ind(ddat.voxSize, ddat.sagPos{index}, ddat.corPos{index}, ddat.axiPos{index});
                    % Corresponding element of "validVoxels"
                    vvInd = find(ddat.validVoxels == ind1);
                    modelMatrix = ddat.subpopModelMats{ddat.currentSubpop{index}};
                    est =  modelMatrix * ImageData.CoefEsts{ddat.currentIC{index}}(:, vvInd);
                    
                    if ~isempty(est)
                        line(findobj('tag', 'TrajAxesSubpop'),...
                            1:ddat.nVisit,...
                            est,...
                            'color', colorOptions(index, :))
                        
                        % Append to legend
                        subpopLegend = [subpopLegend, ['Brain View: ', num2str(index)]];
                    end
                    
                case 'Population'
                                                            
                    % Index of 3d brain
                    ind1 = sub2ind(ddat.voxSize, ddat.sagPos{index}, ddat.corPos{index}, ddat.axiPos{index});
                    % Corresponding element of "validVoxels"
                    vvInd = find(ddat.validVoxels == ind1);
                                        
                    est = ddat.LCPopAvgTime * ImageData.CoefEsts{ddat.currentIC{index}}(:, vvInd);

                    % Plot
                    if ~isempty(est)
                        line(findobj('tag', 'TrajAxesAvg'),...
                            1:ddat.nVisit,...
                            est,...
                            'color', colorOptions(index, :))
                        
                        % Append to legend
                        popAvgLegend = [popAvgLegend, ['Brain View: ', num2str(index)]];
                    end
                    
                case 'Covariate Effect'
                    
                    ind1 = sub2ind(ddat.voxSize, ddat.sagPos{index}, ddat.corPos{index}, ddat.axiPos{index});
                    % Corresponding element of "validVoxels"
                    vvInd = find(ddat.validVoxels == ind1);
                          
                    covariateIndices = ddat.nVisit + ddat.currentCov{index};
                    covariateIndices = covariateIndices:ddat.P:(ddat.nVisit*ddat.P+ddat.nVisit)
                    est = ImageData.CoefEsts{ddat.currentIC{index}}(covariateIndices, vvInd);
                    
                    % Plot
                    if ~isempty(est)
                        line(findobj('tag', 'TrajAxesCov'),...
                            1:ddat.nVisit,...
                            est,...
                            'color', colorOptions(index, :))
                        
                        % Append to legend
                        covLegend = [covLegend, ['Cov: ' ddat.varNamesX{ddat.currentCov{index}} ', Brain View: ', num2str(index)]];
                    end
                
                case 'Single Subject'
                    ind1 = sub2ind(ddat.voxSize, ddat.sagPos{index}, ddat.corPos{index}, ddat.axiPos{index});
                    % Corresponding element of "validVoxels"
                    vvInd = find(ddat.validVoxels == ind1);
                    
                    est = squeeze(ddat.currentSubjectMatData{index}(ddat.currentIC{index}, vvInd, :));
                    
                    if ~isempty(est)
                        line(findobj('tag', 'TrajAxesSubj'),...
                            1:ddat.nVisit,...
                            est,...
                            'color', colorOptions(index, :))
                        
                        % Append to legend
                        subjLegend = [subjLegend, ['Subj: ' num2str(ddat.currentSubject{index}) ', Brain View: ', num2str(index)]];
                    end
                    
                otherwise
            end
            
        end
        
        % Update all legends/titles etc
        legend(findobj('tag', 'TrajAxesAvg'), popAvgLegend);
        legend(findobj('tag', 'TrajAxesCov'), covLegend);
        legend(findobj('tag', 'TrajAxesSubpop'), subpopLegend);
        legend(findobj('tag', 'TrajAxesSubj'), subjLegend);
        
        title(findobj('tag', 'TrajAxesAvg'), 'Population Average');
        title(findobj('tag', 'TrajAxesCov'), 'Covariate Effects');
        title(findobj('tag', 'TrajAxesSubpop'), 'Subpopulations');
        title(findobj('tag', 'TrajAxesSubj'), 'Selected Subjects');
        
        xlabel(findobj('tag', 'TrajAxesAvg'), 'Visit');
        xlabel(findobj('tag', 'TrajAxesCov'), 'Visit');
        xlabel(findobj('tag', 'TrajAxesSubpop'), 'Visit');
        xlabel(findobj('tag', 'TrajAxesSubj'), 'Visit');
        
        xticks(findobj('tag', 'TrajAxesAvg'), 1:ddat.nVisit)
        xticks(findobj('tag', 'TrajAxesCov'), 1:ddat.nVisit)
        xticks(findobj('tag', 'TrajAxesSubpop'), 1:ddat.nVisit)
        xticks(findobj('tag', 'TrajAxesSubj'),   1:ddat.nVisit)
                
    end

    
    %% Functions related to effect information
    function select_effect_information_brain_view(src, event)
        ddat.currentEffectInfoView = src.Value;
        set_effect_information;
    end

    function select_effect_information_brain_view_type(src, event)
        ddat.currentEffectInfoViewType = src.String{src.Value};
        set_effect_information;
    end

    function select_effect_information_subpopulation(src, event)
        ddat.currentEffectCurrentSubpop = src.Value;
        set_effect_information;
    end

    function select_effect_information_covariate(src, event)
        ddat.currentEffectCurrentCovariate = src.Value;
        set_effect_information;
    end

    function populate_effect_information_brain_view_panel;
        newString = compose('Brain View %g', 1:ddat.nViewer);
        if ddat.currentEffectInfoView > ddat.nViewer
            ddat.currentEffectInfoView = 1;
        end
        set(findobj('tag', 'EffectInformationBrainViewSelect'), 'value', ddat.currentEffectInfoView);
        set(findobj('tag', 'EffectInformationBrainViewSelect'), 'String', newString);
    end

    function populate_effect_information_subpop_dropdown;
        if isempty(ddat.subpopNames)
            newString = {'Select sub-population'};
            ddat.currentEffectCurrentSubpop = 1;
        else
            newString = ddat.subpopNames;
            if ddat.currentEffectCurrentSubpop > length(newString)
                ddat.currentEffectCurrentSubpop = 1;
            end
        end
        set(findobj('tag', 'EffectInformationSubpopDropdown'), 'String', newString);
        set(findobj('tag', 'EffectInformationSubpopDropdown'), 'Value', ddat.currentEffectCurrentSubpop);
    end

    function toggle_effect_information_show_visit_averages(src, event)
        ddat.currentEffectDrawVisit = src.Value;
        set_effect_information;
    end
    
    function set_effect_information
        
        if ddat.isPreview == 1; return; end
        
        populate_effect_information_brain_view_panel;
        populate_effect_information_subpop_dropdown;
        
        % Remove current plot        
        delete(findobj('tag', 'EffectInformationAxes').Children);
        
        % Start with flat line at s0 value
        ind1 = sub2ind(ddat.voxSize, ddat.sagPos{ddat.currentEffectInfoView}, ddat.corPos{ddat.currentEffectInfoView}, ddat.axiPos{ddat.currentEffectInfoView});
        % Corresponding element of "validVoxels"
        vvInd = find(ddat.validVoxels == ind1);
        voxelEffects =  ImageData.CoefEsts{ddat.currentIC{ddat.currentEffectInfoView}}(:, vvInd);
        if isempty(voxelEffects)
            return
        end
        ax1 = findobj('tag', 'EffectInformationAxes');  
        s0 = voxelEffects(1);
        % Add horizontal line at s0
        hold all
        line(ax1,...
            0:ddat.nVisit+1,...
            s0 * ones(ddat.nVisit+2, 1))
      
        % Determine the total number of lines that will be drawn per visit. This is
        % used to decide on their widths and x-axis locations (so that all
        % are visible).
        totalLine = 0;
        if ddat.currentEffectDrawVisit == 1; totalLine = 1; end
        linePositions = zeros(ddat.nVisit, 1); % default
        
        % Turn off options (they get reenabled in the switch statement
        % below).
        set(findobj('tag', 'EffectInformationSubpopDropdown'), 'visible', 'off');
        set(findobj('tag', 'EffectInformationCovariateDropdown'), 'visible', 'off');
        
        % If population average - create each visit effect
        switch ddat.currentEffectInfoViewType
            case 'Population'
                % do nothing
            case 'Sub-population'
                set(findobj('tag', 'EffectInformationSubpopDropdown'), 'visible', 'on')
                totalLine = totalLine + 1;
                linePositions = linspace(-0.3, 0.3, totalLine+2);
                linePositions(1) = []; linePositions(end) = [];
                
                % Make sure subpopulation exists
                if isempty(ddat.subpopNames); return; end
                
                modelMatrix = ddat.subpopModelMats{ddat.currentEffectCurrentSubpop};
                est = modelMatrix * voxelEffects;
                for jj = 1:ddat.nVisit
                    L = line(ax1,...
                        [linePositions(end)+jj,linePositions(end)+jj],...
                        [s0, est(jj)],...
                        'color', 'red',...
                        'tag', ['evSubpop_' num2str(jj)],...
                        'LineWidth', 6);
                end
                
                
            case 'Covariate'
                set(findobj('tag', 'EffectInformationCovariateDropdown'), 'visible', 'on');
                
                % TODO determine interactions that include the covariate!!
                % Determine if covariate is continuous or categorical
                if ddat.covTypes(ddat.currentEffectCurrentCovariate) == 0
                    nLevel = 1;
                else
                    nLevel = length(ddat.variableCodingInformation.effectsCodingsEncoders{ddat.currentEffectCurrentCovariate}.encoder);
                end
                totalLine = totalLine + nLevel;
                linePositions = linspace(-0.3, 0.3, totalLine+2);
                linePositions(1) = []; linePositions(end) = [];
                
                % if continuous, plot the one-unit increase
                if ddat.covTypes(ddat.currentEffectCurrentCovariate) == 0
                    for jj = 1:ddat.nVisit
                        est = voxelEffects(ddat.nVisit + (jj-1)*ddat.P + ddat.currentEffectCurrentCovariate);
                        line(ax1,...
                            [linePositions(ddat.currentEffectDrawVisit+1)+jj, linePositions(ddat.currentEffectDrawVisit+1)+jj],...
                            [s0, s0 + est],...
                            'color', 'red',...
                            'LineWidth', 6)
                    end
                    
                    % if categorical, plot a separate line for each effect
                else
                    xxx=1;
                    %betas = 
                    encoder = ddat.variableCodingInformation.effectsCodingsEncoders{ddat.currentEffectCurrentCovariate};
                    nME = length(encoder.variableNames);
                    %encoder.encoder(encoder.referenceCategory)
                    
                    % Check if other covariate is categorical - if so
                    % construct both interaction pieces
                    %ddat.interactions ddat.covTypes
                    
                    relevantParams = ddat.paramIncludesVar(ddat.currentEffectCurrentCovariate, :)'...
                        .* voxelEffects(ddat.nVisit + 1:ddat.nVisit+ddat.P );
                    
                    % THIS IS TEMPORARY - SKIPPING INTERACTIONS
                    for jj = 1:ddat.nVisit
                        relevantParams = ddat.paramIncludesVar(ddat.currentEffectCurrentCovariate, :)'...
                            .* voxelEffects( (ddat.nVisit + 1:ddat.nVisit+ddat.P) + (jj-1) * ddat.P );
                        
                         rp = relevantParams(relevantParams ~= 0.0);
                    
                        est0 = sum(-1.0 * rp(1:nME));
                        line(ax1,...
                                [linePositions(ddat.currentEffectDrawVisit+1)+jj, linePositions(ddat.currentEffectDrawVisit+1)+jj],...
                                [s0, s0 + est0],...
                                'color', 'red',...
                                'LineWidth', 6)
                        if (s0 + est0) >= s0
                            text(ax1, [linePositions(ddat.currentEffectDrawVisit+1)+jj],[s0 + est0],  encoder.referenceCategory, 'rotation', 90);
                        else
                            text(ax1, [linePositions(ddat.currentEffectDrawVisit+1)+jj],...
                                [s0 + est0],  encoder.referenceCategory,...
                                'rotation', 90,...
                                 'HorizontalAlignment', 'right');

                        end
                            
                        for ecVar = 1:nME
                            est0 = rp(ecVar);
                             line(ax1,...
                            [linePositions(ddat.currentEffectDrawVisit+1 + ecVar)+jj, linePositions(ddat.currentEffectDrawVisit+1 + ecVar)+jj],...
                                [s0, s0 + est0],...
                                'color', 'red',...
                                'LineWidth', 6);
                            if (s0 + est0) >= s0
                                text(ax1, [linePositions(ddat.currentEffectDrawVisit+1 + ecVar)+jj],[s0 + est0], encoder.variableNames{ecVar}, 'rotation', 90);
                            else
                                text(ax1, [linePositions(ddat.currentEffectDrawVisit+1 + ecVar)+jj],...
                                    [s0 + est0], encoder.variableNames{ecVar},...
                                    'rotation', 90,...
                                     'HorizontalAlignment', 'right');
     
                            end
                        end
                    end
                    
                   
                    
                end
                
            otherwise
        end
        
        % Check if user has requested visit specific averages:
        if ddat.currentEffectDrawVisit == 1
            est = ddat.LCPopAvgTime * voxelEffects;
            for jj = 1:ddat.nVisit
                line(ax1,...
                    [linePositions(1)+jj, linePositions(1)+jj],...
                    [s0, est(jj)],...
                    'LineWidth', 6)
            end
        end
        
        
        ax1.Tag = 'EffectInformationAxes';

        
        
    end
    
    %% Image Creation/Storage

    % This gets called when a new brain display is created
    % TODO choose type based on other current views
    function initialize_image_storage(index)
          
        if ddat.isPreview
            imagePath = fullfile(ddat.outdir, '_iniIC_1.nii');
        else
            imagePath = fullfile(ddat.outdir, [ddat.outpre, '_S0_IC_1.nii']);
        end
        imageRaw = load_nii(imagePath);
        
        ddat.axiPos{index} = floor(size(imageRaw.img, 3) / 2);
        ddat.corPos{index} = floor(size(imageRaw.img, 2) / 2);
        ddat.sagPos{index} = floor(size(imageRaw.img, 1) / 2);
        
        
        ImageData.rawImages{index}         = imageRaw.img;
        ImageData.imageFilenames{index}    = imagePath;
        ImageData.imageScaleFactors{index} = std(imageRaw.img(ddat.validVoxels));
        ImageData.axiSlices{index} = imageRaw.img(:, :, ddat.axiPos{index});
        ImageData.corSlices{index} = squeeze(imageRaw.img(:,  ddat.corPos{index}, :));
        ImageData.sagSlices{index} = squeeze(imageRaw.img(ddat.sagPos{index}, :, :));
        
        ImageData.anatomicalAxiSlices{index} = ImageData.anatomical{1}(:, :, ddat.axiPos{index});
        ImageData.anatomicalCorSlices{index} = squeeze(ImageData.anatomical{1}(:, ddat.corPos{index}, :));
        ImageData.anatomicalSagSlices{index} = squeeze(ImageData.anatomical{1}(ddat.sagPos{index}, :, :));
        
        ImageData.maskingFile{index} = '';
        ImageData.maskingLayer{index} = ones(ddat.voxSize);
                
        %% Slider Setup
        xslider_step(1) = 1/(ddat.sagDim);
        xslider_step(2) = 1.00001/(ddat.sagDim);
        set(findobj('Tag', ['SagSlider_' num2str(index)]), 'Min', 1, 'Max',ddat.sagDim, ...
            'SliderStep',xslider_step,...
            'Value',ddat.sagPos{index}); %%Sagittal Y-Z, adjust x direction
        
        yslider_step(1) = 1/(ddat.corDim);
        yslider_step(2) = 1.00001/(ddat.corDim);
        set(findobj('Tag', ['CorSlider_'  num2str(index)]), 'Min', 1, 'Max',ddat.corDim, ...
            'SliderStep', yslider_step,...
            'Value',ddat.corPos{index}); %%Sagittal Y-Z, adjust x direction
        
        zslider_step(1) = 1/(ddat.axiDim);
        zslider_step(2) = 1.00001/(ddat.axiDim);
        set(findobj('Tag', ['AxiSlider_'  num2str(index)]), 'Min', 1, 'Max',ddat.axiDim, ...
            'SliderStep', zslider_step,...
            'Value',ddat.axiPos{index}); %%Sagittal Y-Z, adjust x direction
        
        
    end

    % If an anatomical file has been provided, then this loads it and sets
    % up the anatomical image. Otherwise the mask file details are used to
    % create an underlay
    function initialize_anatomical
        if isempty(ImageData.anatomicalFile)
            newImg = zeros(ddat.voxSize);
            newImg(ddat.validVoxels) = 1;
            ImageData.anatomical{1} = newImg;
        else
            anatRaw = load_nii(ImageData.anatomicalFile);
            ImageData.anatomical{1} = anatRaw.img;
        end
        
        % If first initialization (not loading) this might be case
        if ddat.nViewer == 0
            ImageData.anatomicalAxiSlices{1} = ImageData.anatomical{1}(:, :, ceil(ddat.axiDim/2));
            ImageData.anatomicalCorSlices{1} = squeeze(ImageData.anatomical{1}(:, ceil(ddat.corDim/2), :));
            ImageData.anatomicalSagSlices{1} = squeeze(ImageData.anatomical{1}(ceil(ddat.sagDim/2), :, :));
        end
        
        for index = 1:ddat.nViewer
            ImageData.anatomicalAxiSlices{index} = ImageData.anatomical{1}(:, :, ddat.axiPos{index});
            ImageData.anatomicalCorSlices{index} = squeeze(ImageData.anatomical{1}(:, ddat.corPos{index}, :));
            ImageData.anatomicalSagSlices{index} = squeeze(ImageData.anatomical{1}(ddat.sagPos{index}, :, :));
        end
        
    end

    function initial_display
        
        
        if ddat.isPreview
            imagePath = fullfile(ddat.outdir, ['_iniIC_1.nii']);
        else
            imagePath = fullfile(ddat.outdir, [ddat.outpre, '_S0_IC_1.nii']);
        end
        imageRaw = load_nii(imagePath);
        
        initialize_anatomical;

        add_default_brain_view;
        
         % get list of components
        setup_IC_select_dropdown(1);
        
        initialize_image_storage(1);
        
        set_subpopulation_quantities;
        
        set_contrast_quantities;
         
        lic(1);
        
    end

    function update_selected_voxel(src, event, index)
        
        axesHandle  = get(src, 'Parent');
        coordinates = get(axesHandle,'CurrentPoint'); 
        coordinates = coordinates(1,1:2);
        
        % Look at the name of the parent object to determine if Axial, Sag,
        % or Cor image was clicked on. This will give us the "fixed"
        % position of the [sag, cor, axi] position vector
        newPos = zeros(3, 1);
        if contains(axesHandle.Tag, 'Cor')
            newPos(1) = coordinates(1);
            newPos(2) = ddat.corPos{index};
            newPos(3) = axesHandle.YLim(2) - coordinates(2) + 1;
        elseif contains(axesHandle.Tag, 'Axi')
            newPos(1) = coordinates(2);
            newPos(2) = coordinates(1);
            newPos(3) = ddat.axiPos{index};
        else
            newPos(1) = ddat.sagPos{index};
            newPos(2) = coordinates(1);
            newPos(3) = axesHandle.YLim(2) - coordinates(2) + 1;
        end
        
        newPos = round(newPos);
               
        % Make sure new position is valid
        % note - these could potentially be replaced by ddat.sagDim etc
        newPos(newPos <= 0.0) = 1;
        if newPos(1) > size(ImageData.anatomicalCorSlices{1}, 1)
            newPos(1) = size(ImageData.anatomicalCorSlices{1}, 1);
        end
        if newPos(2) > size(ImageData.anatomicalSagSlices{1}, 1)
            newPos(2) = size(ImageData.anatomicalSagSlices{1}, 1);
        end
        if newPos(3) > size(ImageData.anatomicalSagSlices{1}, 2)
            newPos(3) = size(ImageData.anatomicalSagSlices{1}, 2);
        end
        
        % Set the stored values
                
        updateIndex = ddat.syncTo{index};
        
        ddat.sagPos{updateIndex} = newPos(1);
        ddat.corPos{updateIndex} = newPos(2);
        ddat.axiPos{updateIndex} = newPos(3);
        
        % Trigger a re-render
        frc(updateIndex)
        
    end

    function sagSliderMove(src, event)
        index = str2num(extractAfter(src.Tag, '_'));
        ddat.sagPos{index} = round(get(src, 'Value'));  
        frc(index);
    end

    function axiSliderMove(src, event)
        index = str2num(extractAfter(src.Tag, '_'));
        ddat.axiPos{index} = round(get(src, 'Value'));  
        frc(index);
    end

    function corSliderMove(src, event)
        index = str2num(extractAfter(src.Tag, '_'));
        ddat.corPos{index} = round(get(src, 'Value'));  
        frc(index);
    end

    %% Brain Manipulation
    function transform_selected_slice(index)
        % TODO make this index dependent
        if ddat.viewZScores{index} == 1
            ImageData.axiSlices{index} = ImageData.axiSlices{index} ./ sqrt(ImageData.imageScaleFactors{index}(:, :, ddat.axiPos{index}));
            ImageData.corSlices{index} = ImageData.corSlices{index} ./ ...
                sqrt(squeeze(ImageData.imageScaleFactors{index}(:, ddat.corPos{index}, :)));
            ImageData.sagSlices{index} = ImageData.sagSlices{index} ./ ...
                sqrt(squeeze(ImageData.imageScaleFactors{index}(ddat.sagPos{index}, :, :)));
        end
        
        ImageData.axiSlices{index} = ImageData.axiSlices{index} .* ImageData.maskingLayer{index}(:, :, ddat.axiPos{index});
        ImageData.corSlices{index} = ImageData.corSlices{index} .* ...
                sqrt(squeeze(ImageData.maskingLayer{index}(:, ddat.corPos{index}, :)));
        ImageData.sagSlices{index} = ImageData.sagSlices{index} .* ...
                sqrt(squeeze(ImageData.maskingLayer{index}(ddat.sagPos{index}, :, :)));
        
    end

    function set_selected_slice(index)
        
        ImageData.axiSlices{index} = ImageData.rawImages{index}(:, :, ddat.axiPos{index});
        ImageData.corSlices{index} = squeeze(ImageData.rawImages{index}(:, ddat.corPos{index}, :));
        ImageData.sagSlices{index} = squeeze(ImageData.rawImages{index}(ddat.sagPos{index}, :, :));
        
        ImageData.anatomicalAxiSlices{index} = ImageData.anatomical{1}(:, :, ddat.axiPos{index});
        ImageData.anatomicalCorSlices{index} = squeeze(ImageData.anatomical{1}(:, ddat.corPos{index}, :));
        ImageData.anatomicalSagSlices{index} = squeeze(ImageData.anatomical{1}(ddat.sagPos{index}, :, :));
        
    end

    function render_image_slice(index)
        
        % See: 
        % https://www.mathworks.com/matlabcentral/answers/710113-how-do-i-plot-2-images-each-with-a-different-colormap-and-clim-in-a-single-subplot
            
        ax1 = findobj('tag', ['AnatAxiAxes_' num2str(index)] );
        ax2 = findobj('tag', ['AxiAxes_' num2str(index)] );
        anatImg = imshow(ImageData.anatomicalAxiSlices{index},  'Parent', ax1);
        set(ax1, 'tag', ['AnatAxiAxes_' num2str(index)]);
        %if isempty(ax2.Children)
                delete(ax2.Children)

            funcImg = imshow(ImageData.axiSlices{index}, 'Parent', ax2);
%             set(funcImg, 'Tag', ['AnatAxiImage_' num2str(index)]);
%         else
%             set(findobj('tag', ['AnatAxiImage_' num2str(index)]), 'CData', ImageData.axiSlices{index});
%         end

        set(ax2, 'tag', ['AxiAxes_' num2str(index)]);
        set(funcImg,'ButtonDownFcn', {@update_selected_voxel, index} )
        %set(findobj('tag', ['AnatAxiImage_' num2str(index)]),'ButtonDownFcn', {@update_selected_voxel, index} )
        % threshold
        THR = ones(size(ImageData.axiSlices{index}));
        THR( abs(ImageData.axiSlices{index}) <= ddat.thresholdVal{index}) = 0.0;
        THR( isnan(ImageData.axiSlices{index}) ) = 0.0;
        set(funcImg, 'AlphaData', THR);
        %set(findobj('tag', ['AnatAxiImage_' num2str(index)]), 'AlphaData', THR);
        % set color map
        set(ax2, 'clim', ddat.clims{index});
        colormap(ax2, ddat.colorbarScheme{index})
        if ddat.drawCrosshair{index} == 1
            yline(ax2, ddat.sagPos{index},...
                'color', ddat.crosshairSettings{index}.color);
            xline(ax2, ddat.corPos{index},...
                'color', ddat.crosshairSettings{index}.color);
        end
        
        % Sag Axes
        ax1 = findobj('tag', ['AnatSagAxes_' num2str(index)] );
        ax2 = findobj('tag', ['SagAxes_' num2str(index)] );
        anatImg = imshow( rot90(ImageData.anatomicalSagSlices{index}),  'Parent', ax1);
        set(ax1, 'tag', ['AnatSagAxes_' num2str(index)]);
        funcSliceRotated = rot90(ImageData.sagSlices{index});
        % Clear child image
        delete(ax2.Children)
        %if isempty(ax2.Children)
        funcImg = imshow(funcSliceRotated, 'Parent', ax2);
        %    set(funcImg, 'Tag', ['AnatSagImage_' num2str(index)]);
        %else
        %    set(findobj('tag', ['AnatSagImage_' num2str(index)]), 'CData', funcSliceRotated);
        %end
        %funcImg = imshow( funcSliceRotated, 'Parent', ax2);
        set(ax2, 'tag', ['SagAxes_' num2str(index)]);
        %set(findobj('tag', ['AnatSagImage_' num2str(index)]),'ButtonDownFcn', {@update_selected_voxel, index})
        set(funcImg,'ButtonDownFcn', {@update_selected_voxel, index})
        % threshold
        THR = ones(size(funcSliceRotated));
        THR( abs(funcSliceRotated) <= ddat.thresholdVal{index}) = 0.0;
        THR( isnan(funcSliceRotated) ) = 0.0;
        set(funcImg, 'AlphaData', THR);
        %set(findobj('tag', ['AnatSagImage_' num2str(index)]), 'AlphaData', THR);
        % set color map
        set(ax2, 'clim', ddat.clims{index});
        colormap(ax2, ddat.colorbarScheme{index})
        if ddat.drawCrosshair{index} == 1
            yline(ax2, ddat.axiDim - ddat.axiPos{index} + 1,...
                'color', ddat.crosshairSettings{index}.color);
            xline(ax2, ddat.corPos{index},...
                'color', ddat.crosshairSettings{index}.color);
        end
        
        % Cor Axes
        ax1 = findobj('tag', ['AnatCorAxes_' num2str(index)] );
        ax2 = findobj('tag', ['CorAxes_' num2str(index)] );
        anatImg = imshow( rot90(ImageData.anatomicalCorSlices{index}),  'Parent', ax1);
        set(ax1, 'tag', ['AnatCorAxes_' num2str(index)]);
        funcSliceRotated = rot90(ImageData.corSlices{index});
        %funcImg = imshow(funcSliceRotated, 'Parent', ax2);
        %if isempty(ax2.Children)
                delete(ax2.Children)
            funcImg = imshow(funcSliceRotated, 'Parent', ax2);
        %    set(funcImg, 'Tag', ['AnatCorImage_' num2str(index)])
        %else
        %    set(findobj('tag', ['AnatCorImage_' num2str(index)]), 'CData', funcSliceRotated);
        %end
        set(ax2, 'tag', ['CorAxes_' num2str(index)]);
        %set(findobj('tag', ['AnatCorImage_' num2str(index)]),'ButtonDownFcn', {@update_selected_voxel, index})
        set(funcImg,'ButtonDownFcn', {@update_selected_voxel, index})
        % threshold
        THR = ones(size(funcSliceRotated));
        THR( abs(funcSliceRotated) <= ddat.thresholdVal{index}) = 0.0;
        THR( isnan(funcSliceRotated) ) = 0.0;
        %set(findobj('tag', ['AnatCorImage_' num2str(index)]), 'AlphaData', THR);
        set(funcImg, 'AlphaData', THR);
        % set color map
        set(ax2, 'clim', ddat.clims{index});
        colormap(ax2, ddat.colorbarScheme{index})
        
        if ddat.drawCrosshair{index} == 1
            yline(ax2, ddat.axiDim - ddat.axiPos{index} + 1,...
                'color', ddat.crosshairSettings{index}.color);
            xline(ax2, ddat.sagPos{index}, 'color',...
                ddat.crosshairSettings{index}.color);
        end
        
        
    end

    function set_colormap_info(index);
        
        ax = findobj('Tag', ['colorMap_' num2str(index)] );
        c = colorbar(ax);
        colormap(ax, ddat.colorbarScheme{index})
        ax.Visible = 'off';
        ax.CLim = ddat.clims{index};
        % Make fill the axes it is plotted to
        % Changing width also moves the plot side to side. Try centering first if
        % this does not work.
        ax.Position = [-4.6 0.2 5.0 0.7];
        %set(ax, 'tag', ['colorMap_' num2str(index)]);
        
        % Show correct map in dropdown menu
        colormapOptions = get(findobj('tag', ['colormapSelectDropdown_' num2str(index)]), 'String');
        value = find(contains(colormapOptions, ddat.colorbarScheme{index}));
        set(findobj('tag', ['colormapSelectDropdown_' num2str(index)]), 'Value', value);
        
        % Show correct color limits
        set(findobj('tag', ['colorbarRangeEdit_' num2str(index)] ), 'String', num2str(ddat.clims{index}(2)));
        
        
    end

    function edit_threshold_slider(src, event);
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.thresholdVal{index} = src.Value;
        frc(index);
    end

    function edit_threshold_box(src, event);
        index = str2double(extractAfter(src.Tag, '_'));
        newVal = str2double(src.String);
        if isempty(newVal) || isnan(newVal) || abs(newVal) == Inf
            src.String = num2str(ddat.thresholdVal{index});
        else
            ddat.thresholdVal{index} = abs(newVal);
            frc(index);
        end
    end

    function edit_colorbar_range_box(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        newVal = str2double(src.String);
        if isempty(newVal) || isnan(newVal) || newVal == 0 || abs(newVal) == Inf
            src.String = num2str(ddat.clims{index}(2));
        else
            ddat.clims{index} = [-abs(newVal), abs(newVal)];
            frc(index);
        end
    end

    function select_colormap(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.colorbarScheme{index} = src.String{src.Value};
        frc(index);
    end

    function update_draw_crosshair(src, event);
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.drawCrosshair{index} = src.Value;
        frc(index);
    end

    %% Image Selection Panel
    function select_IC(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.currentIC{index} = src.Value;
        lic(index);
    end

    function select_cov(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.currentCov{index} = src.Value;
        lic(index);
    end

    function select_visit(src, ~)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.currentVisit{index} = src.Value;
        lic(index);
    end

    function select_contrast(src, ~)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.currentContrast{index} = src.Value;
        lic(index);
    end

    function select_subpop(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.currentSubpop{index} = src.Value;
        lic(index);
    end

    function select_subject(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.currentSubject{index} = src.Value;
        lic(index);
    end

    function toggle_zscore_checkbox(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.viewZScores{index} = src.Value;
        frc(index);
    end

    %% Information for user
    function set_selected_voxel_information(index)
        set(findobj('tag', ['valAtVoxelBox_' num2str(index)]), 'String', ImageData.axiSlices{index}(ddat.sagPos{index}, ddat.corPos{index}));   
    end




    %% Brain Syncing
    
    function set_sync_properties(index)
        
        dropdownOptionsAll = compose('Brain View %g', 1:ddat.nViewer);
        dropdownOptions = dropdownOptionsAll;
        
        set(findobj('tag', ['BrainViewSyncDropdown_' num2str(index)]),...
                'string', dropdownOptions);
        
        if ddat.isSynced{index} == 0
            % Disable sync items
            set(findobj('tag', ['BrainViewSyncICCheckbox_' num2str(index)]), 'enable', 'off');
            set(findobj('tag',  ['BrainViewSyncThresholdingCheckbox_' num2str(index)]), 'enable', 'off');
            set(findobj('tag',  ['BrainViewSyncColormapCheckbox_' num2str(index)]), 'enable', 'off');
            set(findobj('tag',  ['BrainViewSyncDropdown_' num2str(index)]), 'enable', 'off');
            
            set(findobj('tag', ['BrainViewSyncICCheckbox_' num2str(index)]), 'value', 0);
            set(findobj('tag',  ['BrainViewSyncThresholdingCheckbox_' num2str(index)]), 'value', 0);
            set(findobj('tag',  ['BrainViewSyncColormapCheckbox_' num2str(index)]), 'value', 0);
            set(findobj('tag',  ['BrainViewSyncDropdown_' num2str(index)]), 'value', index);
            
            % Un-lock out some of the settings that might have been
            % disabled during the sync
            set(findobj('tag', ['ICSelectDropdown_' num2str(index)]), 'enable', 'on');
        else
            
            if ddat.syncTo{index} ~= index && ddat.syncICs{index} == 1
                set(findobj('tag', ['ICSelectDropdown_' num2str(index)]), 'enable', 'off');
            else
                set(findobj('tag', ['ICSelectDropdown_' num2str(index)]), 'enable', 'on');
            end
            
            set(findobj('tag', ['BrainViewSyncICCheckbox_' num2str(index)]), 'enable', 'on');
            set(findobj('tag',  ['BrainViewSyncThresholdingCheckbox_' num2str(index)]), 'enable', 'on');
            set(findobj('tag',  ['BrainViewSyncColormapCheckbox_' num2str(index)]), 'enable', 'on');
            set(findobj('tag',  ['BrainViewSyncDropdown_' num2str(index)]), 'enable', 'on');
            
            set(findobj('tag', ['BrainViewSyncICCheckbox_' num2str(index)]), 'value', ddat.syncICs{index});
            set(findobj('tag',  ['BrainViewSyncThresholdingCheckbox_' num2str(index)]), 'value', ddat.syncThresholding{index});
            set(findobj('tag',  ['BrainViewSyncColormapCheckbox_' num2str(index)]), 'value', ddat.syncColormaps{index});
            set(findobj('tag',  ['BrainViewSyncDropdown_' num2str(index)]), 'value', ddat.syncTo{index});
        end
        
    end
    
    function select_sync_IC(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.syncICs{index} = src.Value;
        updateIndex = ddat.syncTo{index};
        frc(updateIndex);
    end

    function select_sync_thresholding(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.syncThresholding{index} = src.Value;
        updateIndex = ddat.syncTo{index};
        frc(updateIndex);
    end

    function select_sync_colormap(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.syncColormaps{index} = src.Value;
        updateIndex = ddat.syncTo{index};
        frc(updateIndex);
    end

    % Called when user selects "free" syncing, will remove any quantities
    % related to syncing with old group
    function select_free_sync(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.syncICs{index} = 0;
        ddat.syncThresholding{index} = 0;
        ddat.syncColormaps{index} = 0;
        ddat.isSynced{index} = 0;
        ddat.syncTo{index}   = index;
        
        frc(index)
    end

    % Called when user selects syncing
    function select_sync(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.syncICs{index} = 0;
        ddat.syncThresholding{index} = 0;
        ddat.syncColormaps{index} = 0;
        ddat.isSynced{index} = 1;
        ddat.syncTo{index}   = index;
        
        frc(index)
    end

    function select_brain_view_sync_leader(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        ddat.syncTo{index}   = src.Value;
        frc(src.Value);
    end

    %% Listbox showing the various options for viewing

    function change_viewer_type(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
       	ddat.currentViewerType{index} = src.String{src.Value};
        lic(index);
    end

    % Workaround for initial view since src/event have not been created yet
    function add_default_brain_view;
        temp = struct();
        temp.Tag = 'xxx_0';
        add_brain_view(temp, 1);
    end

    function remove_brain_view(src, event)
        
        % Get index of box that requested deletion
        splitTag = strsplit(src.Tag, '_');
        callIndex = str2double(splitTag{2});
        
        if ddat.nViewer == 1 && callIndex == 1
            disp('Cannot remove only brain view')
            return
        end
        
        % Delete all objects corresponding to this view
        regexstring = ['_' num2str(callIndex) '(?![0-9])'];
        objList = findobj('-regexp', 'Tag', regexstring);
        for iObj = 1:length(objList)
            delete(objList(iObj));
        end
        
        shift_axes(callIndex, 'decr') 
        
        ddat.nViewer = ddat.nViewer - 1;
        
        % Delete the old positions from syncing
        ddat.syncTo(ddat.nViewer + 1) = [];
        
        % Re-render viewers
        for i = 1:ddat.nViewer
            frc(i);
        end
        
        
    end

    %% Masking
    
    % Reads in all masks from output directory
    function set_mask_dropdown_options
        
        
        % Load in from the output directory
        maskOptionsTemp = {dir(fullfile(ddat.outdir, [ddat.outpre '*_mask_*'])).name};
        
        % Remove the prefix and mask part (makes display in dropdown
        % easier to read)
        eraseString = [extractAfter(ddat.outpre, '/') '_mask_'];
        maskOptions = erase(maskOptionsTemp, eraseString);
        
        % Add the "no mask option"
        maskOptions = ['No Mask' maskOptions];
        
        % Now masks are in alphabetical order -- creating a new one can put it at
        % a different point in the list. Need to adjust the "value" for
        % each masking dropdown menu to accomodate this
        oldString = get(findobj('tag', ['ApplyMaskDropdown_' num2str(1)]), 'String');
        for index = 1:ddat.nViewer
            oldVal = get(findobj('tag', ['ApplyMaskDropdown_' num2str(index)]), 'Value');
            
            if iscell(oldString)
                oldSelection = oldString{oldVal};
            else
                oldSelection = oldString;
            end
            
            newSelectionIndex = find(strcmp(maskOptions, oldSelection));
            
            if isempty(newSelectionIndex)
                disp('Warning: Problem with matching masks.')
                return
            end
            
            % Check for case where user deleted old mask?
            
            % Temporary set value to 1 (always valid)
            set(findobj('tag', ['ApplyMaskDropdown_' num2str(index)]), 'Value', 1);
            
            % Set the new string
            set(findobj('tag', ['ApplyMaskDropdown_' num2str(index)]), 'String', maskOptions);
            % Set the new value
            set(findobj('tag', ['ApplyMaskDropdown_' num2str(index)]), 'Value', newSelectionIndex);
            
            % Set the stored ddat value
            if newSelectionIndex > 1
                ImageData.maskingFile{index} = fullfile(ddat.outdir, [ddat.outpre '_mask_' maskOptions{newSelectionIndex}]);
            else
                ImageData.maskingFile{index} = '';
            end
            
        end
        
        
    end
    
    function save_mask(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        
        % Ask the user to name the mask
        newName = inputdlg('Input Name For Mask', 'Name Mask');
        
        % Verify the user did not cancel input
        if isempty(newName); return; end
        
        % Create the full file name using the name the user provided
        maskFname = fullfile(ddat.outdir, [ddat.outpre '_mask_' newName{1} '.nii']);
        
        % Create binary mask
        maskedImage = create_mask_data(ImageData.rawImages{index},...
            ddat.thresholdVal{index},...
            ImageData.imageScaleFactors{index},...
            ddat.viewZScores{index},...
            ImageData.maskingLayer{index});
        
        % Save the mask
        newNii = make_nii(maskedImage);
        %newNii.hdr.hist.originator = data.maskOriginator;
        save_nii(newNii, maskFname);
        
        set_mask_dropdown_options;
        
    end

    function [fullImage] = create_full_volume(rawImage, thresholdLevel, scale, viewZ, mask) 
        if viewZ == 1
            newImage = rawImage ./ sqrt(scale);
        else
            newImage = rawImage;
        end
        fullImage = newImage .* mask .* (abs(newImage) > thresholdLevel);
    end

    function [thrImage] = create_mask_data(rawImage, thresholdLevel, scale, viewZ, mask)
        
        newImage = create_full_volume(rawImage, thresholdLevel, scale, viewZ, mask);
        thrImage = 1.0 .* (abs(newImage) > thresholdLevel);
        
    end

    function apply_mask(src, event)
        index = str2double(extractAfter(src.Tag, '_'));
        value = src.Value;
        maskName = src.String{value};
        
        if value > 1
            ImageData.maskingFile{index} = fullfile(ddat.outdir, [ddat.outpre '_mask_' maskName]);
        else
            ImageData.maskingFile{index} = '';
        end
        
        
        lic(index);
        
    end

    %% Controls for adding and removing brain views
    function add_brain_view(src, event)
                
        % Get index of box that requested new viewer
        splitTag = strsplit(src.Tag, '_');
        callIndex = str2double(splitTag{2});
        
        index = callIndex + 1;
        
        ddat.clims{index} = [-2, 2];
        ddat.thresholdVal{index} = 0.0;
        ddat.drawCrosshair{index} = 0;
        ddat.currentIC{index} = 1;
        if ddat.isPreview
            ddat.currentViewerType{index} = 'Preview';
        else
            ddat.currentViewerType{index} = 'Population';
        end
        ddat.currentVisit{index} = 1;
        
        ddat.currentSubpop{index} = 1;
        ddat.currentContrast{index} = 1;
        
        % Syncing
        ddat.isSynced{index} = 0;
        ddat.syncTo{index}   = index;
        ddat.syncICs{index} = 0;
        ddat.syncThresholding{index} = 0;
        ddat.syncColormaps{index} = 0;
        
        ddat.crosshairSettings{index} = struct();
        ddat.crosshairSettings{index}.color = 'red';
        
        ddat.currentCov{index} = 1;
        
        ddat.currentSubject{index} = 1;
        ddat.currentSubjectMatData{index} = [];
        
        ddat.viewZScores{index} = 0;
        
        create_new_brain_view_gui_components(index);

        ddat.nViewer = ddat.nViewer + 1;
        
        setup_IC_select_dropdown(index);
        
        setup_subject_select_dropdown(index);
        
        if index > 1
            ddat.colorbarScheme{index} = ddat.colorbarScheme{1};
        else
         	ddat.colorbarScheme{index} = 'jet';
        end
        
        populate_sync_dropdown_menus;
        
        initialize_image_storage(index);
        
        align_all_widgets;
        
        lic(index);
        %frc(index);
        
        
        
    end


    %% Fill out the Syncing dropdown menu
    function populate_sync_dropdown_menus
                        
        dropdownOptionsAll = compose('Brain View %g', 1:ddat.nViewer);
        
        for index = 1:ddat.nViewer
            set(findobj('tag', ['BrainViewSyncDropdown_' num2str(index)]),...
                'string', dropdownOptionsAll);
        end
        
    end


    %Increment the axes labels for all images following the input index
    function shift_axes(index, shiftType)
        
        % Handle resizing
        if strcmp(shiftType, 'incr')
            new_denom = 1.0 / (ddat.nViewer + 1);
            tot = 1;
            for i = 1:(ddat.nViewer + 1)
                tot = tot - new_denom;
                set(findobj('tag', ['BrainPanel_' num2str(i)]),...
                    'Position', [0.0, tot 1.0 new_denom]);
            end
        else
            new_denom = 1.0 / (ddat.nViewer - 1);
            tot = 1;
            for i = 1:(index)
                tot = tot - new_denom;
                set(findobj('tag', ['BrainPanel_' num2str(i)]),...
                    'Position', [0.0, tot 1.0 new_denom]);
            end
        end
        
        % Fixup any syncing for indicies that are not going to get checked
        % in the loop below
        if strcmp(shiftType, 'decr')
            for i = 1:index
                if (ddat.syncTo{i} == index)
                    ddat.syncTo{i} = i;
                    ddat.isSynced{i} = 0;
                end
            end
        end
        
        % Corner case
        if ddat.nViewer == 0
            return
        end
        
        % Default is increment (inserting a new view)
        counterRange = ddat.nViewer:-1:index;
        if strcmp(shiftType, 'decr')
            counterRange = (index+1):ddat.nViewer;
        end
        
        for altIndexi = 1:length(counterRange)
            altIndex = counterRange(altIndexi);
            
            if strcmp(shiftType, 'incr')
                newIndex = altIndex + 1;
            elseif strcmp(shiftType, 'decr')
                newIndex = altIndex - 1;
            else
                disp('Warning - invalid shift type')
            end
            
            regexstring = ['_' num2str(altIndex) '(?![0-9])'];
            objList = findobj('-regexp', 'Tag', regexstring);
            
            for iObj = 1:length(objList)
                originalTag = get(objList(iObj), 'tag');
                newTagTemp = strsplit(originalTag, '_');
                newTag = [newTagTemp{1} '_' num2str(newIndex)];
                set(objList(iObj), 'tag', newTag);
            end
            
            % Move the display to the appropriate location
            tot = 1 - newIndex * new_denom;
            set(findobj('tag', ['BrainPanel_' num2str(newIndex)]),...
                'Position', [0.0, tot 1.0 new_denom]);
            
            set(findobj('tag', ['BrainViewPanel_' num2str(newIndex)]),...
                'Title', ['Brain View: ' num2str(newIndex)]);
            
            % Shift the corresponding ddat quantities
            ddat.axiPos{newIndex} = ddat.axiPos{altIndex};
            ddat.corPos{newIndex} = ddat.corPos{altIndex};
            ddat.sagPos{newIndex} = ddat.sagPos{altIndex};

            ddat.clims{newIndex}          = ddat.clims{altIndex};
            ddat.thresholdVal{newIndex}   = ddat.thresholdVal{altIndex};
            ddat.colorbarScheme{newIndex} = ddat.colorbarScheme{altIndex};

            ddat.drawCrosshair{newIndex} = ddat.drawCrosshair{altIndex};
            ddat.crosshairSettings{newIndex} = ddat.crosshairSettings{altIndex};

            ddat.currentIC{newIndex} = ddat.currentIC{altIndex};
            ddat.currentViewerType{newIndex} = ddat.currentViewerType{altIndex};
            ddat.currentCov{newIndex}  = ddat.currentCov{altIndex};
            ddat.viewZScores{newIndex} = ddat.viewZScores{altIndex};
            ddat.currentVisit{newIndex}  = ddat.currentVisit{altIndex};
            ddat.currentSubpop{newIndex}  = ddat.currentSubpop{altIndex};
            ddat.currentContrast{newIndex}  = ddat.currentContrast{altIndex};
            ddat.currentSubject{newIndex}  = ddat.currentSubject{altIndex};
            ddat.currentSubjectMatData{newIndex} = ddat.currentSubjectMatData{altIndex};
            
            % Syncing
            ddat.isSynced{newIndex} = ddat.isSynced{altIndex};
            % Sync to needs to be adjusted IF old syncto >= the changed
            % index
            if index <= ddat.syncTo{altIndex}
                % If deleted old sync leader, then unsync
                if ddat.syncTo{altIndex} == index
                    ddat.isSynced{newIndex} = 0;
                    ddat.syncTo{newIndex}   = newIndex;
                % Else shift
                else
                    if strcmp(shiftType, 'decr')
                        ddat.syncTo{newIndex}   = ddat.syncTo{altIndex} - 1;
                    else
                        ddat.syncTo{newIndex}   = ddat.syncTo{altIndex} + 1;
                    end
                end
            else
                ddat.syncTo{newIndex} = ddat.syncTo{altIndex};
            end
            
            % Syncing
            ddat.syncICs{newIndex} = ddat.syncICs{altIndex};
            ddat.syncThresholding{newIndex} = ddat.syncThresholding{altIndex};
            ddat.syncColormaps{newIndex} = ddat.syncColormaps{altIndex};
            
            % Check if need to move effect information viewer
            if ddat.currentEffectInfoView == altIndex
                ddat.currentEffectInfoView = newIndex;
            end

            % Separate structure that contains image related data. This should not get
            % stored
            ImageData.rawImages{newIndex} = ImageData.rawImages{altIndex};
            ImageData.imageFilenames{newIndex} = ImageData.imageFilenames{altIndex};
            ImageData.imageScaleFactors{newIndex} = ImageData.imageScaleFactors{altIndex};
            ImageData.axiSlices{newIndex} = ImageData.axiSlices{altIndex};
            ImageData.corSlices{newIndex} = ImageData.corSlices{altIndex};
            ImageData.sagSlices{newIndex} = ImageData.sagSlices{altIndex};
            ImageData.maskingFile{newIndex}  = ImageData.maskingFile{altIndex};
            ImageData.maskingLayer{newIndex} = ImageData.maskingLayer{altIndex};
            
        end        
        
    end
        

    function create_new_brain_view_gui_components(index);
                
            ystart = 1.0 - index * (1.0 / (ddat.nViewer+1));
            
            % Relabel all brain views that follow this one
            shift_axes(index, 'incr');
            
            BrainPanel = uipanel('BackgroundColor',get(hs.fig,'color'),...
                'units', 'normalized',...
                'Parent', findobj('tag', 'ViewersPanel'),...
                'Tag', ['BrainPanel_'  num2str(index)],...
                'Position',[0, ystart 1.0 (1.0 /  (ddat.nViewer+1) )]);
            

            displayPanel = uipanel('BackgroundColor','black',...
                'units', 'normalized',...
                'Parent', BrainPanel,...
                'Tag', ['viewingPanel_'  num2str(index)],...
                'Position',[0.21, 0.0 0.69 1]);
            
            colorbarPanel = uipanel('units', 'normalized',...
                'Parent', BrainPanel,...
                'Tag', ['colorbarPanel_'   num2str(index)],...
                'Position',[0.90, 0.1 0.09 0.9], ...;
                'BackgroundColor',get(hs.fig,'color'));
            
            ControlPanel = uipanel('BackgroundColor','white',...
                'units', 'normalized',...
                'Parent', BrainPanel,...
                'Tag', 'ControlPanel',...
                'Position',[0.01, 0.0 0.19 1], ...;
                'BackgroundColor',get(hs.fig,'color'));

            AnatSagAxes = axes('Parent', displayPanel, ...
                'Position',[.59 .18 .27 .8],...
                'Tag', ['AnatSagAxes_'  num2str(index)],...
                'visible', 'off' );
            SagAxes = axes('Parent', displayPanel, ...
                'Units', 'Normalized', ...
                'Position',[0.01 0.18 0.27 .8],...
                'Tag', ['SagAxes_' num2str(index)],...
                'visible', 'off');
            AnatSagAxes.UserData = linkprop([SagAxes,AnatSagAxes],...
                {'Position','InnerPosition','DataAspectRatio','xtick','ytick', ...
                'ydir','xdir','xlim','ylim'});

            AnatCorAxes = axes('Parent', displayPanel, ...
                'Position',[.59 .18 .27 .8],...
                'Tag', ['AnatCorAxes_'  num2str(index)],...
                'visible', 'off' );
            CorAxes = axes('Parent', displayPanel, ...
                'Position',[.30 .18 .27 .8],...
                'Tag', ['CorAxes_'  num2str(index)],...
                'visible', 'off' );
            AnatCorAxes.UserData = linkprop([CorAxes,AnatCorAxes],...
                {'Position','InnerPosition','DataAspectRatio','xtick','ytick', ...
                'ydir','xdir','xlim','ylim'});

            AnatAxiAxes = axes('Parent', displayPanel, ...
                'Position',[.59 .18 .27 .8],...
                'Tag', ['AnatAxiAxes_'  num2str(index)],...
                'visible', 'off' );
            AxiAxes = axes('Parent', displayPanel, ...
                'Position',[.59 .18 .27 .8],...
                'Tag', ['AxiAxes_'  num2str(index)],...
                'visible', 'off' );
            AnatAxiAxes.UserData = linkprop([AxiAxes,AnatAxiAxes],...
                {'Position','InnerPosition','DataAspectRatio','xtick','ytick', ...
                'ydir','xdir','xlim','ylim'});  

            SagSlider = uicontrol('Parent', displayPanel, ...
                'Style', 'Slider', ...
                'Units', 'Normalized', ...
                'Position', [0.01, 0.01, 0.27, 0.05], ...
                'Tag', ['SagSlider_' num2str(index)], 'Callback', @sagSliderMove);
            CorSlider = uicontrol('Parent', displayPanel, ...
                'Style', 'Slider', ...
                'Units', 'Normalized', ...
                'Position', [0.30, 0.01, 0.27, 0.05], ...
                'Tag', ['CorSlider_' num2str(index)], 'Callback', @corSliderMove);
            AxiSlider = uicontrol('Parent', displayPanel, ...
                'Style', 'Slider', ...
                'Units', 'Normalized', ...
                'Position', [0.59, 0.01, 0.27, 0.05], ...
                'Tag', ['AxiSlider_' num2str(index)], 'Callback', @axiSliderMove);
            
            % Colormap
            colorMap = axes('Parent', colorbarPanel, ...
            'units', 'Normalized',...
            'Position', [0.05, 0.27, 0.4, 0.6], ...
            'Tag', ['colorMap_' num2str(index)]);
        
            % Color range text
%             colorbarRangeText = uicontrol('Parent', colorbarPanel, ...
%                 'Style', 'Text', ...
%                 'Units', 'Normalized', ...
%                 'String', 'Colorlimit:',...
%                 'backgroundcolor', 'white',...
%                 'Position', [0.01, 0.01, 0.48, 0.05], ...
%                 'Tag', ['colorbarRangeText_' num2str(index)]);
            colorbarRangeTextAxes = axes('Parent', colorbarPanel, ...
                'Units', 'Normalized', ...
                'Position', [0.01, 0.01, 0.48, 0.05], ...
                'Tag', ['colorbarRangeTextAxes_' num2str(index)]);
            colorbarRangeTextAxes.Visible = 'Off';
            t = text(colorbarRangeTextAxes, 0.5, 0.5, sprintf('Color\nRange:'),...
                'horizontalalignment', 'center');
            
            colorbarRangeEdit = uicontrol('Parent', colorbarPanel, ...
                'Style', 'edit', ...
                'Units', 'Normalized', ...
                'BackgroundColor','white',...
                'Position', [0.51, 0.01, 0.48, 0.05], ...
                'Tag', ['colorbarRangeEdit_' num2str(index)],...
                'TooltipString', 'Input a number. The colorbar range will be from - this number to + this number',...
                'callback', @edit_colorbar_range_box);

            colormapSelectDropdown = uicontrol('Parent', colorbarPanel,...
                'Style', 'popupmenu', ...
                'Units', 'Normalized', ...
                'Position', [0.01, 0.11, 0.98, 0.05], ...
                'Tag', ['colormapSelectDropdown_' num2str(index)],...
                'TooltipString', 'Select the colormap for the brain views.',...
                'Callback', @select_colormap, ...
                'String', {'parula', 'jet'}); %#ok<NASGU>
            
            %% Add and subtract
            AddAndRemovePanel = uipanel('units', 'normalized',...
                'Parent', BrainPanel,...
                'Tag', ['AddAndRemovePanel_'   num2str(index)],...
                'Position',[0.90, 0.01 0.09 0.09], ...;
                'BackgroundColor',get(hs.fig,'color'));
            
            AddBrainViewButton = uicontrol('Parent',AddAndRemovePanel,...
                'Tag', ['AddBrainViewButton_' num2str(index)],...
                'Style','pushbutton',...
                'String', '+',...
                'units', 'normalized',...
                'TooltipString', 'Click to add a brain view below.',...
                'Position', [0.54 0.3 0.4 0.4],...
                'Callback', @add_brain_view);
            
            
            RemoveBrainViewButton = uicontrol('Parent',AddAndRemovePanel,...
                'Tag', ['RemoveBrainViewButton_' num2str(index)],...
                'Style','pushbutton',...
                'String', '-',...
                'units', 'normalized',...
                'TooltipString', 'Click to remove this brain view.',...
                'Position', [0.066 0.3 0.4 0.4],...
                'Callback', @remove_brain_view);
            
             %% Thresholding controls
            ThresholdPanel =  uipanel('BackgroundColor',get(hs.fig,'color'),...
                'units', 'normalized',...
                'Parent', ControlPanel,...
                'Tag', ['ThresholdPanel_' num2str(index)]  ,...
                'Position',[0.01, 0.01 0.98 0.14], ...
                'Title', 'Thresholding');

            thresholdSlider = uicontrol('Parent', ThresholdPanel, ...
                'Style', 'Slider', ...
                'Units', 'Normalized', ...
                'max', 3.0,...
                'Position', [0.01, 0.01, 0.64, 0.5], ...
                'Tag', ['thresholdSlider_' num2str(index)],...
                'callback', @edit_threshold_slider);

            % Box showing the threshold value. Can be manually changed
            thresholdValueBox = uicontrol('Parent', ThresholdPanel, ...
                'Style', 'edit', ...
                'Units', 'Normalized', ...
                'BackgroundColor','white',...
                'Position', [0.66, 0.01, 0.33, 0.98], ...
                'TooltipString', 'Input a thresholding limit. Any elements of the brain map with absolute value less than this threshold will be hidden.',...
                'Tag', ['thresholdValueBox_' num2str(index)],...
                'callback', @edit_threshold_box);

 
            %% Image Selection Panel
            ImageSelectionPanel = uipanel('BackgroundColor',get(hs.fig,'color'),...
                'units', 'normalized',...
                'Parent', ControlPanel,...
                'Tag', ['ImageSelectionPanel_' num2str(index)]  ,...
                'Position',[0.01, 0.66 0.98 0.33], ...
                'Title', 'Image');
            
            % LHS - dropdown menus
            
            VisitSelectDropdown = uicontrol('Parent', ImageSelectionPanel,...
                'Style', 'popupmenu', ...
                'Units', 'Normalized', ...
                'Position', [0.05, 0.02, 0.50, 0.22], ...
                'Tag', ['VisitSelectDropdown_' num2str(index)],...
                'visible', 'off',...
                'String', compose('Visit %g', 1:ddat.nVisit),...
                'Callback', @select_visit);
            
            CovSelectDropdown = uicontrol('Parent', ImageSelectionPanel,...
                'Style', 'popupmenu', ...
                'Units', 'Normalized', ...
                'Position', [0.05, 0.26, 0.50, 0.22], ...
                'Tag', ['CovSelectDropdown_' num2str(index)],...
                'visible', 'off',...
                'String', ddat.varNamesX,...
                'Callback', @select_cov);
            
            ContrastSelectDropdown = uicontrol('Parent', ImageSelectionPanel,...
                'Style', 'popupmenu', ...
                'Units', 'Normalized', ...
                'Position', [0.05, 0.26, 0.50, 0.22], ...
                'Tag', ['ContrastSelectDropdown_' num2str(index)],...
                'visible', 'off',...
                'String', 'Select Contrast',...
                'Callback', @select_contrast);
            
            SubPopSelectDropdown = uicontrol('Parent', ImageSelectionPanel,...
                'Style', 'popupmenu', ...
                'Units', 'Normalized', ...
                'Position', [0.05, 0.26, 0.50, 0.22], ...
                'Tag', ['SubPopSelectDropdown_' num2str(index)],...
                'visible', 'off',...
                'String', 'Select Sub-population',...
                'Callback', @select_subpop);
            
            SubjectSelectDropdown = uicontrol('Parent', ImageSelectionPanel,...
                'Style', 'popupmenu', ...
                'Units', 'Normalized', ...
                'Position', [0.05, 0.26, 0.50, 0.22], ...
                'Tag', ['SubjectSelectDropdown_' num2str(index)],...
                'visible', 'off',...
                'String', 'Select Subject',...
                'Callback', @select_subject);
            
            ICSelectDropdown = uicontrol('Parent', ImageSelectionPanel,...
                'Style', 'popupmenu', ...
                'Units', 'Normalized', ...
                'Position', [0.05, 0.50, 0.50, 0.22], ...
                'Tag', ['ICSelectDropdown_' num2str(index)],...
                'Callback', @select_IC);
                %@(src, event)update_brain_data('setICMap', 1), ...
            
            viewerTypeDropdown = uicontrol('Parent', ImageSelectionPanel,...
                'Style', 'popupmenu', ...
                'Units', 'Normalized', ...
                'Position', [0.05, 0.74, 0.50, 0.22], ...
                'Tag', ['viewerTypeDropdown_' num2str(index)],...
                'String', {'Population', 'Sub-Population', 'Covariate Effect', 'Linear Combination', 'Single Subject'},...
                'Callback', @change_viewer_type);
            
            % Tweak for preview
            if ddat.isPreview == true
                viewerTypeDropdown.String = {'Preview'};
            end
            
            % RHS - checkboxes
            DrawCrosshair = uicontrol('Parent', ImageSelectionPanel,...
                'Style', 'checkbox', ...
                'Units', 'Normalized', ...
                'Position', [0.55, 0.2, 0.40, 0.2], ...
                'Tag', ['DrawCrosshair_' num2str(index)],...
                'String', 'Draw Crosshair', ...
                'TooltipString', 'Draw a crosshair on the selected voxel',...
                'Callback', @update_draw_crosshair,...
                'Value', ddat.drawCrosshair{index}); %#ok<NASGU>

            ViewZScoresCheckbox = uicontrol('Parent', ImageSelectionPanel,...
                'Style', 'checkbox', ...
                'Units', 'Normalized', ...
                'Position', [0.55, 0.6, 0.40, 0.2], ...
                'Tag', ['ViewZScoresCheckbox_' num2str(index)],...
                'String', 'View Z-Scores', ...
                'TooltipString', 'Convert the images to Z-scores',...
                'Callback', @toggle_zscore_checkbox); %#ok<NASGU>
            
            
            
            %% Masking Panel
            MaskingPanel = uipanel('BackgroundColor',get(hs.fig,'color'),...
                'units', 'normalized',...
                'Parent', ControlPanel,...
                'Tag', ['MaskingPanel_' num2str(index)]  ,...
                'Position',[0.01, 0.51 0.98 0.14], ...
                'Title', 'Masking');
                
            CreateMaskButton = uicontrol('Parent',MaskingPanel,...
                'Tag', ['CreateMaskButton_' num2str(index)],...
                'Style','pushbutton',...
                'String', 'Save Mask',...
                'units', 'normalized',...
                'Position', [0.01 0.01 0.48 0.98],...
                'Callback', @save_mask);
            
            ApplyMaskDropdown = uicontrol('Parent', MaskingPanel,...
                'Style', 'popupmenu', ...
                'Units', 'Normalized', ...
                'Position', [0.51, 0.01, 0.48, 0.01], ...
                'Tag', ['ApplyMaskDropdown_' num2str(index)],...
                'TooltipString', 'Apply a binary mask to the image. Any thresholding you request will be performed IN ADDITION to this masking.',...
                'String', {'No Mask'},...
                'Callback', @apply_mask);
            
            % Tweak for preview
            if ddat.isPreview == true
                CreateMaskButton.Enable = 'off';
                ApplyMaskDropdown.Enable = 'off';
            end
                
            %% Brainview Panel
            BrainViewPanel = uipanel('BackgroundColor',get(hs.fig,'color'),...
                'units', 'normalized',...
                'Parent', ControlPanel,...
                'Tag', ['BrainViewPanel_' num2str(index)]  ,...
                'Position',[0.01, 0.15 0.98 0.35], ...
                'Title', ['Brain View: ', num2str(index)]);
            
            % Control if free or synced
            BrainViewFreeOrSyncButtonGroup = uibuttongroup('Parent',BrainViewPanel,...
                'units', 'normalized',...
                'tag', ['BrainViewFreeOrSyncButtonGroup_' num2str(index)],...
                'visible', 'on',...
                'Position',[0.01 0.1 0.4 0.8]);

            BrainViewFree = uicontrol(BrainViewFreeOrSyncButtonGroup,...
                'string', 'Free Selection',...
                'tag', ['BrainViewFree_' num2str(index)],...
                'style', 'radiobutton',...
                'units', 'normalized',...
                'Callback', @select_free_sync,...
                'Position',[0.1 0.525 0.9 0.45]); %#ok<NASGU>
            
            BrainViewSync = uicontrol(BrainViewFreeOrSyncButtonGroup,...
                'style', 'radiobutton',...
                'string', 'Sync Selection',...
                'units', 'normalized',...
                'tag', ['BrainViewSync_' num2str(index)],...
                'Callback', @select_sync,...
                'Position',[0.1 0.025 0.9 0.45]); %#ok<NASGU>
            
             % Syncing Options
            BrainViewSyncDropdown = uicontrol('Parent', BrainViewPanel,...
                'Style', 'popupmenu', ...
                'Units', 'Normalized', ...
                'Position', [0.5 0.8 0.5 0.15], ...
                'String', 'Select Sync Group',...
                'callback', @select_brain_view_sync_leader,...
                'Tag', ['BrainViewSyncDropdown_' num2str(index)],...
                'enable', 'off');

            BrainViewSyncICCheckbox = uicontrol('Parent', BrainViewPanel,...
                'Style', 'checkbox', ...
                'Units', 'Normalized', ...
                'Position', [0.5, 0.5, 0.40, 0.15], ...
                'Tag', ['BrainViewSyncICCheckbox_' num2str(index)],...
                'String', 'Sync ICs', ...
                'Callback', @select_sync_IC,...
                'enable', 'off'); %#ok<NASGU>
            
            BrainViewSyncThresholdingCheckbox = uicontrol('Parent', BrainViewPanel,...
                'Style', 'checkbox', ...
                'Units', 'Normalized', ...
                'Position', [0.5, 0.25, 0.40, 0.15], ...
                'Tag', ['BrainViewSyncThresholdingCheckbox_' num2str(index)],...
                'String', 'Sync Thresholds', ...
                'Callback', @select_sync_thresholding,...
                'enable', 'off'); %#ok<NASGU>
            
            BrainViewSyncColormapCheckbox = uicontrol('Parent', BrainViewPanel,...
                'Style', 'checkbox', ...
                'Units', 'Normalized', ...
                'Position', [0.5, 0.0, 0.40, 0.15], ...
                'Tag', ['BrainViewSyncColormapCheckbox_' num2str(index)],...
                'String', 'Sync Colormaps', ...
                'Callback', @select_sync_colormap,...
                'enable', 'off'); %#ok<NASGU>
            
            % Tweak for preview
            if ddat.isPreview == true
                BrainViewFreeOrSyncButtonGroup.Visible = 'off';
            end
            

            %% Information Display
            valAtVoxelBox = uicontrol('Parent', displayPanel, ...
                'Style', 'Text', ...
                'Units', 'Normalized', ...
                'BackgroundColor','white',...
                'Position', [0.90, 0.45, 0.08, 0.1], ...
                'Tag', ['valAtVoxelBox_' num2str(index)]);
            
            
    end

    %% Alignment Functions
    % These are written to help align different widgets as the number of
    % views increases/decreases
    
    function align_all_widgets
        align_thresholding_widgets;
        align_masking_widgets;
        %align_colorbar_widgets;
    end
    
    function align_thresholding_widgets
        if ddat.nViewer > 2
            for index = 1:ddat.nViewer
                align([findobj('tag', ['thresholdSlider_' num2str(index)]),...
                    findobj('tag', ['thresholdValueBox_' num2str(index)])],...
                    'VerticalAlignment','Top');
            end
        else
            for index = 1:ddat.nViewer
                align([findobj('tag', ['thresholdSlider_' num2str(index)]),...
                    findobj('tag', ['thresholdValueBox_' num2str(index)])],...
                    'VerticalAlignment','Middle');
            end
        end
    end

    function align_masking_widgets
        if ddat.nViewer > 2
            for index = 1:ddat.nViewer
                align([findobj('tag', ['CreateMaskButton_' num2str(index)]),...
                    findobj('tag', ['ApplyMaskDropdown_' num2str(index)])],...
                    'VerticalAlignment','Top');
            end
        else
            for index = 1:ddat.nViewer
                align([findobj('tag', ['CreateMaskButton_' num2str(index)]),...
                    findobj('tag', ['ApplyMaskDropdown_' num2str(index)])],...
                    'VerticalAlignment','Middle');
            end
        end
    end

    function align_colorbar_widgets
        if ddat.nViewer > 2
            for index = 1:ddat.nViewer
                align([findobj('tag', ['colorbarRangeText_' num2str(index)]),...
                    findobj('tag', ['colorbarRangeEdit_' num2str(index)])],...
                    'VerticalAlignment','Top');
            end
        else
            for index = 1:ddat.nViewer
                align([findobj('tag', ['colorbarRangeText_' num2str(index)]),...
                    findobj('tag', ['colorbarRangeEdit_' num2str(index)])],...
                    'VerticalAlignment','Middle');
            end
        end
    end

end
