function varargout = displayResults(varargin)
% displayResults - Function to view the results of the EM algorithm.
% This function opens up a viewer window that allows the user to view the
% hc-ICA results at the group, single subject, sub-population, and beta
% map levels. The code is also used to view ICs for the initial guess. The
% user can create masks in the group window and apply them to images in the
% other windows (e.g. beta maps).
%
% Inputs: Inputs should be entered in the following order (all done within
% other functions)
%
%   q           - number of ICs
%   outpath     - path to the output folder
%   prefix      - prefix for the output
%   N           - number of subjects in analysis
%   Type        - display window requested (group, beta, etc.)
%   Covariates  - names of the covariates
%   X           - design matrix
%   covTypes       - vector of 1s and 0s indicating whether each covariate is
%                 categorical
%   nVisit      - number of visits in the analysis
%
%

delete( findobj('Tag', 'ICselect') );
delete( findobj('Tag', 'viewZScores') );

% Set up the data structure "ddat" with the input information. This
% structure will hold all the data as the user continues to use the viewer.
global ddat;
global data;
ddat = struct();
ddat.q = cell2mat(varargin(1)); ddat.outdir = varargin{2};
ddat.outpre = varargin{3}; ddat.nsub = cell2mat(varargin(4));
ddat.type = varargin{5};
ddat.varNamesX = varargin{6};
ddat.X = varargin{7};
ddat.covTypes = varargin{8};
ddat.betaVarEst = 0;
ddat.interactions = varargin{9};
ddat.nVisit = varargin{10};
ddat.color_map = parula;
[~, ddat.p] = size(ddat.X);
global keeplist;
if ~isempty(keeplist)
    ddat.qstar = sum(keeplist);
else
    ddat.qstar = ddat.q;
end
varargout = cell(1);

% Bool to keep track of whether a sub-population has been created by the
% user
ddat.subPopExists = 0;
% Keep track of whether or not a contrast has been created by the user
ddat.contrastExists = 0;
ddat.viewingContrast = 0;

% Keeping Track of the number of currently active maps (visits, sub pops,
%  contrasts, etc) in the viewer window.
ddat.nActiveMaps = 1;

% Keeping Track of open Augmenting Panels
ddat.prevDisplaySize = [];
ddat.trajectoryActive = 0;
ddat.trajPreviousTag = ''; % string value of previously added line. used to clear plot

% Keep track of what pops / visits are being viewed
ddat.viewTracker = zeros(1, ddat.nVisit);
ddat.viewTracker(1, 1) = 1;

% Keep track of user's previous settings for viewTracker (for switching
% back and forth between viewers)
ddat.saved_grp_viewTracker = zeros(1, ddat.nVisit);
ddat.saved_beta_viewTracker = zeros(ddat.p, ddat.nVisit);
ddat.saved_contrast_viewTracker = zeros(0, ddat.nVisit);
ddat.saved_subpop_viewTracker = zeros(0, ddat.nVisit);
ddat.saved_subj_viewTracker = zeros(0, ddat.nVisit);

% Keep track of what sub-populations/contrasts have been specified
% variable name is specified linear combinations
ddat.valid_LC_contrast = zeros(0);
ddat.LC_contrasts = zeros(0, ddat.p);
ddat.valid_LC_subpop = zeros(0);
ddat.LC_subpops = zeros(0, ddat.p);

% Keep tracker of the user's preferred settings
ddat.tileType = 'vertical';

% Check if an instance of displayResults already running
hs = findall(0,'tag','displayResults');
if (isempty(hs))
    hs = addcomponents;
    set(hs.fig,'Visible','on');
    initialDisp;
else
    figure(hs);
end

%% GUI Main Component Definition and KeyPress Functions
    function hs = addcomponents
        % Add components, save ddat in a struct
        hs.fig = figure('Units', 'normalized', ...,...
            'position', [0.3 0.3 0.5 0.5],...
            'MenuBar', 'none',...
            'Tag','displayResults',...
            'NumberTitle','off',...
            'Name','HINT Results Viewer',...
            'Resize','on',...
            'Visible','off',...
            'WindowKeyPressFcn', @KeyPress);
        fileMenu = uimenu('Label','File');
        %uimenu(fileMenu,'Label','Save','Callback','disp(''save'')');
        uimenu(fileMenu, 'Label', 'Save to JPG', 'Callback', @save_jpg);
        %uimenu(fileMenu,'Label','Quit','Callback','disp(''exit'')',...
        %    'Separator','on','Accelerator','Q');
        viewerMenu = uimenu('Label', 'View', 'Tag', 'viewerMenu');
        uimenu(viewerMenu, 'Label', 'Population', 'Separator', 'On', 'Callback', @stGrp);
        uimenu(viewerMenu, 'Label', 'Sub-Population', 'Callback', @stSubPop);
        uimenu(viewerMenu, 'Label', 'Single Subject', 'Callback', @stSubj);
        uimenu(viewerMenu, 'Label', 'Covariate Effect', 'Callback', @stBeta);
        BrainView = uimenu(viewerMenu, 'Label', 'Brain View', 'tag', 'BrainViewSubmenu');
        uimenu(BrainView, 'Label', 'Stacked', 'Callback', @brain_view_stacked);
        uimenu(BrainView, 'Label', 'Grouped', 'Callback', @brain_view_grouped);
        helpMenu = uimenu('Label','Help');
        textalign = 'left';
        licaMenu = uimenu('Label', 'Longitudinal Tools', 'Tag', 'licaMenu');
        uimenu(licaMenu, 'Label', 'View Voxel Trajectories', 'Callback', @shift_to_trajectory_view);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Brain Display Windows
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Default Panel - this panel contains the main display windows and options
        % other primary panels are placed on it, so that it can be
        % shrunk/expanded as needed
        
        % Primary Panels (layout)
        
        DefaultPanel = uipanel('BackgroundColor','white',...
            'Tag', 'DefaultPanel',...
            'units', 'normalized',...
            'Position',[0.0, 0.0 1.0 1.0], ...;
            'BackgroundColor',get(hs.fig,'color'));
        AugmentingPanel = uipanel('BackgroundColor','white',...
            'Tag', 'AugmentingPanel',...
            'units', 'normalized',...
            'Position',[0.0, 8.0 0.0 0.0], ...;
            'BackgroundColor',get(hs.fig,'color'));
        
        % Sub Panels (layout)
        colorbarPanel = uipanel('BackgroundColor','white',...
            'units', 'normalized',...
            'Parent', DefaultPanel,...
            'Tag', 'colorbarPanel',...
            'Position',[0.95, 0.5 0.05 0.5], ...;
            'BackgroundColor',get(hs.fig,'color'));
        
        displayPanel = uipanel('BackgroundColor','black',...
            'units', 'normalized',...
            'Parent', DefaultPanel,...
            'Tag', 'viewingPanelNormal',...
            'Position',[0, 0.5 0.949 0.5], ...;
            'BackgroundColor','black');
        %'BackgroundColor',get(hs.fig,'color'));
        
        ControlPanel = uipanel('BackgroundColor','white',...
            'units', 'normalized',...
            'Parent', DefaultPanel,...
            'Tag', 'ControlPanel',...
            'Position',[0, 0 1 0.5], ...;
            'BackgroundColor',get(hs.fig,'color'));
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Brain Viewers
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Windows
        
        for i = 1:ddat.nVisit
            SagAxes = axes('Parent', displayPanel, ...
                'Units', 'Normalized', ...
                'Position',[0.01 0.18 0.27 .8],...
                'Tag', ['SagittalAxes1_' num2str(i)],...
                'visible', 'off');
            CorAxes = axes('Parent', displayPanel, ...
                'Position',[.30 .18 .27 .8],...
                'Tag', ['CoronalAxes1_'  num2str(i)],...
                'visible', 'off' );
            AxiAxes = axes('Parent', displayPanel, ...
                'Position',[.59 .18 .27 .8],...
                'Tag', ['AxialAxes1_'  num2str(i)],...
                'visible', 'off' );
        end
        
        
        % Sliders
        SagSlider = uicontrol('Parent', displayPanel, ...
            'Style', 'Slider', ...
            'Units', 'Normalized', ...
            'Position', [0.01, -0.3, 0.27, 0.4], ...
            'Tag', 'SagSlider', 'Callback', @sagSliderMove);
        CorSlider = uicontrol('Parent', displayPanel, ...
            'Style', 'Slider', ...
            'Units', 'Normalized', ...
            'Position', [0.30, -0.3, 0.27, 0.4], ...
            'Tag', 'CorSlider', 'Callback', @corSliderMove);
        AxiSlider = uicontrol('Parent', displayPanel, ...
            'Style', 'Slider', ...
            'Units', 'Normalized', ...
            'Position', [0.59, -0.3, 0.27, 0.4], ...
            'Tag', 'AxiSlider', 'Callback', @axiSliderMove);
        % Colorbar
        colorMap = axes('Parent', colorbarPanel, ...
            'units', 'Normalized',...
            'Position', [0.05, 0.05, 0.4, 0.9], ...
            'Tag', 'colorMap');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Location and Crosshair Control
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        locPanel = uipanel('Title','Location and Crosshair Information',...
            'Parent', ControlPanel,...
            'FontSize',12,...
            'BackgroundColor','white',...
            'BackgroundColor',[224/256,224/256,224/256], ...
            'Tag', 'locPanel', ...
            'units', 'normalized',...
            'Position',[0.01, 0.01 .32 .98]); %#ok<NASGU>
        curInfo = uicontrol('Parent', locPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.74, 0.98, 0.25], ...
            'Tag', 'curInfo', 'BackgroundColor', 'Black');%#ok<NASGU>
        crosshairPosText = uicontrol('Parent', locPanel, ...
            'Style', 'Text', 'String', 'Crosshair Position: ', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.49, 0.49, 0.25]);%#ok<NASGU>
        crosshairPos = uicontrol('Parent', locPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.50, 0.49, 0.49, 0.25], ...
            'Tag', 'crosshairPos');%#ok<NASGU>
        crosshairValText = uicontrol('Parent', locPanel, ...
            'Style', 'Text', 'String', 'Crosshair Value: ', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.50, 0.49, 0.1],...
            'visible', 'off');%#ok<NASGU>
        crosshairVal = uicontrol('Parent', locPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.50, 0.50, 0.49, 0.1], ...
            'visible', 'off',...
            'Tag', 'crosshairVal1');%#ok<NASGU>
        originalPosText = uicontrol('Parent', locPanel, ...
            'Style', 'Text', 'String', '[X Y Z] Origin Position', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.25, 0.49, 0.23]);%#ok<NASGU>
        originalPos = uicontrol('Parent', locPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.50, 0.25, 0.49, 0.23], ...
            'Tag', 'originalPos');%#ok<NASGU>
        dimensionText = uicontrol('Parent', locPanel, ...
            'Style', 'Text', 'String', '[X Y Z] Dimension', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.01, 0.49, 0.23]);%#ok<NASGU>
        dimension = uicontrol('Parent', locPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.50, 0.01, 0.49, 0.23], ...
            'Tag', 'dimension');%#ok<NASGU>
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Component Selection & Masking
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        icPanel = uipanel('FontSize',12,...
            'Parent', ControlPanel,...
            'BackgroundColor','white',...
            'units', 'normalized',...
            'Position',[.35, 0.31 .32 .90], ...
            'Tag', 'icPanel', ...
            'BackgroundColor',[224/256,224/256,224/256]);
        ICselect = uicontrol('Parent', icPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.83, 0.48, 0.1], ...
            'Tag', 'ICselect', 'Callback',...
            @(src, event)load_functional_images, ...
            'String', 'Select IC'); %#ok<NASGU>
            %@(src, event)update_brain_data('setICMap', 1), ...
        viewZScores = uicontrol('Parent', icPanel,...
            'Style', 'checkbox', ...
            'Units', 'Normalized', ...
            'Position', [0.53, 0.46, 0.42, 0.15], ...
            'Tag', 'viewZScores', 'String', 'View Z-Scores', ...
            'Callback', @(src, event)update_brain_data() ); %#ok<NASGU>
        maskSelect = uicontrol('Parent', icPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.51, 0.83, 0.48, 0.1], ...
            'Tag', 'maskSelect', 'Callback', @(src, event)update_brain_maps('updateMasking', 1), ...
            'String', 'No Mask'); %#ok<NASGU>
        viewerInfo = uicontrol('Parent', icPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.02, 0.98, 0.3], ...
            'Tag', 'viewerInfo', 'BackgroundColor', 'Black', ...
            'ForegroundColor', 'white', ...
            'HorizontalAlignment', 'Left'); %#ok<NASGU>
        selectCovariate = uicontrol('Parent', icPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.51, 0.48, 0.1], ...
            'Tag', 'selectCovariate', 'Callback', @updateIC, ...
            'String', 'Select Covariate', 'Visible', 'Off'); %#ok<NASGU>
        
        EffectViewButtonGroup = uibuttongroup('Parent',icPanel,...
            'units', 'normalized',...
            'tag', 'EffectTypeButtonGroup',...
            'visible', 'off',...
            'Position',[0.01 0.38 0.5 0.35]);
        SelectEffectView = uicontrol(EffectViewButtonGroup,...
            'string', 'Effect View',...
            'style', 'radiobutton',...
            'units', 'normalized',...
            'Position',[0.1 0.6 0.9 0.3],...
            'callback', @beta_typeof_view_select); %#ok<NASGU>
        SelectContrastView = uicontrol(EffectViewButtonGroup,...
            'style', 'radiobutton',...
            'string', 'Contrast View',...
            'units', 'normalized',...
            'tag', 'SelectContrastView',...
            'callback', @beta_typeof_view_select,...
            'Position',[0.1 0.2 0.9 0.3]); %#ok<NASGU>
        
        selectSubject = uicontrol('Parent', icPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.51, 0.48, 0.1], ...
            'Tag', 'selectSubject', 'Callback', @updateIC, ...
            'String', 'Select Subject', 'Visible', 'Off'); %#ok<NASGU>
        keepIC = uicontrol('Parent', icPanel,...
            'Style', 'checkbox', ...
            'Units', 'Normalized', ...
            'visible', 'off', ...
            'Position', [0.01, 0.46, 0.42, 0.15], ...
            'Tag', 'keepIC', 'String', 'Use IC for hc-ICA', ...
            'Value', 1, 'Callback', @updateICSelMenu); %#ok<NASGU>
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Thresholding and Mask Creation
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        thresholdPanel = uipanel('FontSize',12,...
            'Parent', ControlPanel,...
            'BackgroundColor','white',...
            'Position',[.35, 0.01 .32 .29], ...
            'BackgroundColor',[224/256,224/256,224/256], ...
            'Tag', 'thresholdPanel', ...
            'Title', 'Thresholding');
        thresholdSlider = uicontrol('Parent', thresholdPanel,...
            'Style', 'Slider', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.85, 0.98, 0.1], ...
            'Tag', 'thresholdSlider', ...
            'min', 0, 'max', 4, 'sliderstep', [0.01, 0.1], ...
            'callback', @editThreshold); %#ok<NASGU>
        manualThreshold = uicontrol('Parent', thresholdPanel, ...
            'Style', 'Edit', ...
            'Units', 'Normalized', ...
            'Position', [0.24, 0.30, 0.49, 0.35], ...
            'Tag', 'manualThreshold', ...
            'BackgroundColor','white',...
            'callback', @manualThreshold); %#ok<NASGU>
 
        createMask = uicontrol('Parent', thresholdPanel, ...
            'Style', 'pushbutton', ...
            'String', 'Create Mask', ...
            'Units', 'Normalized', ...
            'Position', [0.24, 0.01, 0.49, 0.25], ...
            'Tag', 'createMask', 'callback', @create_mask, ...
            'Visible', 'Off'); %#ok<NASGU>
        useEmpiricalVar = uicontrol('Parent', thresholdPanel,...
            'Style', 'checkbox', ...
            'Units', 'Normalized', ...
            'visible', 'off', ...
            'Position', [0.11, 0.01, 0.79, 0.25], ...
            'Tag', 'useEmpiricalVar',...
            'String', 'Use empirical variance estimate', ...
            'Value', 1, 'Callback', @updateICSelMenu,...
            'Visible', 'Off'); %#ok<NASGU>
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Viewer Select Options
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % This is a new box that handles visit information
        % as well as sub-population information
        
        % Background Panel
        ViewSelectionPanel = uipanel('FontSize',12,...
            'Parent', ControlPanel,...
            'BackgroundColor','white',...
            'Title', 'Viewer Selection', ...
            'Tag', 'ViewSelectionPanel', ...
            'Visible', 'On', ...
            'BackgroundColor',[224/256,224/256,224/256], ...
            'Position',[.75, 0.01 .30 .98]);
        
        % Box containing subpopulations, contrasts, or visits
        ViewSelectTable = uitable('Parent', ViewSelectionPanel, ...
            'Units', 'Normalized', ...
            'Position', [0.1, 0.1, 0.8, 0.8], ...
            'Tag', 'ViewSelectTable', ...
            'CellSelectionCallback', @ViewSelectTable_cell_select); %#ok<NASGU>
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Subpopulation Information
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        subPopPanel = uipanel('FontSize',12,...
            'Parent', ControlPanel,...
            'BackgroundColor','white',...
            'Title', 'Subpopulation Control', ...
            'Tag', 'SubpopulationControl', ...
            'Visible', 'Off', ...
            'BackgroundColor',[224/256,224/256,224/256], ...
            'Position',[.69, 0.01 .30 .45]);
        % TODO delete
        subPopSelect = uicontrol('Parent', subPopPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.255, 0.85, 0.49, 0.1], ...
            'Tag', 'subPopSelect1', 'Callback', @updateSubPopulation, ...
            'String', 'No Sub-Population Created'); %#ok<NASGU>
        subPopDisplay = uitable('Parent', subPopPanel, ...
            'Units', 'Normalized', ...
            'Position', [0.1, 0.3, 0.8, 0.5], ...
            'Tag', 'subPopDisplay', ...
            'CellEditCallback', @update_linear_combination); %#ok<NASGU>
        newSubPop = uicontrol('Parent', subPopPanel, ...
            'Units', 'Normalized', ...
            'String', 'Add Sub-Population', ...
            'Position', [0.15, 0.15, 0.7, 0.15], ...
            'Tag', 'newSubPop', 'Callback', @addNewSubPop); %#ok<NASGU>
        comparesubPop = uicontrol('Parent', subPopPanel, ...
            'Units', 'Normalized', ...
            'String', 'Compare Sub-Populations', ...
            'Position', [0.15, 0.01, 0.7, 0.15], ...
            'Tag', 'compareSubPops', 'Callback', @compareSubPopulations); %#ok<NASGU>
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Beta Contrast Information
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        betaContrastPanel = uipanel('FontSize',12,...
            'Parent', ControlPanel,...
            'BackgroundColor','white',...
            'Title', 'Covariate Contrast', ...
            'Tag', 'covariateContrastControl', ...
            'Visible', 'Off', ...
            'BackgroundColor',[224/256,224/256,224/256], ...
            'Position',[.69, 0.01 .30 .45]);
        contrastSelect = uicontrol('Parent', betaContrastPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.255, 0.85, 0.49, 0.1], ...
            'Tag', 'contrastSelect1', 'Callback', @updateContrastDisp, ...
            'visible', 'off',...
            'String', 'No Contrast Created'); %#ok<NASGU>
        contrastDisplay = uitable('Parent', betaContrastPanel, ...
            'Units', 'Normalized', ...
            'Position', [0.1, 0.17, 0.8, 0.8], ...
            'Tag', 'contrastDisplay', ...
            'CellEditCallback', @update_linear_combination); %#ok<NASGU>
        newContrast = uicontrol('Parent', betaContrastPanel, ...
            'Units', 'Normalized', ...
            'String', 'Add New Contrast', ...
            'Position', [0.01, 0.01, 0.49, 0.15], ...
            'Tag', 'newContrast', 'Callback', @addNewContrast); %#ok<NASGU>
        removeContrastButton = uicontrol('Parent', betaContrastPanel, ...
            'Units', 'Normalized', ...
            'String', 'Remove A Contrast', ...
            'Position', [0.51, 0.01, 0.49, 0.15], ...
            'Tag', 'newContrast', 'Callback', @removeContrast); %#ok<NASGU>
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % IC Selection
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        icSelPanel = uipanel('FontSize',12,...
            'Parent', ControlPanel,...
            'BackgroundColor','white',...
            'Title', 'IC Selection', ...
            'Tag', 'icSelectionPanel', ...
            'Visible', 'Off', ...
            'Position',[.69, 0.01 .30 .45]);
        icSelRef = uitable('Parent', icSelPanel, ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.01, 0.9, 0.95], ...
            'Tag', 'icSelRef', 'RowName', ''); %#ok<NASGU>
        icSelCloseButton = uicontrol('style', 'pushbutton',...
            'units', 'normalized', ...
            'Position', [0.93, 0.01, 0.05, 0.05],...
            'String', 'Close', ...
            'tag', 'icSelectCloseButton', ...
            'visible', 'off', ...
            'Callback', @closeICSelect); %#ok<NASGU>
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %     Trajectory Plotting Panel
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Pieces:
        % 1. viewTrajPanel - background panel
        % 2. TrajAxes - figure plotted to
        % 3. TrajControlPanel - Panel containing voxel info
        
        ViewTrajPanel = uipanel('FontSize',12,...
            'Parent', AugmentingPanel,...
            'Title', 'Voxel Trajectory Information', ...
            'Tag', 'ViewTrajPanel', ...
            'Visible', 'Off', ...
            'units', 'normalized',...
            'Position',[0.0, 0.0 1.0 1.0]);
        TrajAxes = axes('Parent', ViewTrajPanel, ...
            'units', 'normalized',...
            'Position',[.1 .6 0.8 .35],...
            'Tag', 'TrajAxes' ); %#ok<NASGU>
        TrajControlPanel = uipanel('FontSize',12,...
            'Title', 'Voxel Controls', ...
            'Tag', 'TrajControlPanel', ...
            'Parent', ViewTrajPanel, ...
            'units', 'normalized',...
            'Position',[.05, 0.05 0.9 .4]);
        TrajTable = uitable('Parent', TrajControlPanel, ...
            'Units', 'Normalized', ...
            'Position', [0.05, 0.3, 0.9, 0.6], ...
            'Tag', 'TrajTable', 'RowName', '',...
            'ColumnWidth', {30,30,30},...
            'ColumnName', {'Sag','Cor','Axi'}, ...
            'CellSelectionCallback', @traj_box_cell_select); %#ok<NASGU>
        TrajAddCurrent = uicontrol('style', 'pushbutton',...
            'units', 'normalized', ...
            'Parent', TrajControlPanel,...
            'Position', [0.1, 0.1, 0.4, 0.1],...
            'String', 'Save current voxel', ...
            'tag', 'TrajAddCurrent', ...
            'visible', 'on', ...
            'Callback', @traj_add_voxel_to_list); %#ok<NASGU>
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %     Map Property Panel
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % This panel handles keeping track of what visits/contrasts/subpops
        %  are currently being viewed
        
        %         MapPropertyPanel = uipanel('FontSize',12,...
        %             'Parent', AugmentingPanel,...
        %             'Title', 'Brain Map Viewer Selection', ...
        %             'Tag', 'MapPropertyPanel', ...
        %             'Visible', 'Off', ...
        %             'units', 'normalized',...
        %             'Position',[0.0, 0.0 1.0 1.0]);
        
        
        movegui(hs.fig, 'center')
        
    end

    function KeyPress(varargin)
        keypress = varargin{2};
        %         %% Modifier commands
        if ~isempty(keypress.Modifier) && ~isempty(keypress.Character)
            
            if (keypress.Character == 't') && strcmp(keypress.Modifier{1}, 'command')
                shift_to_trajectory_view;
            end
            
            if (keypress.Character == 'v') && strcmp(keypress.Modifier{1}, 'command')
                if strcmp(ddat.tileType, 'vertical')
                    brain_view_grouped;
                else
                    brain_view_stacked;
                end
            end
            
        end
    end

% Menu functions
    function brain_view_stacked(varargin)
        ddat.tileType = 'vertical';
        set_viewing_properties;
    end
    function brain_view_grouped(varargin)
        ddat.tileType = 'grouped';
        set_viewing_properties;
    end

% Function to calculate the required amount of the screen used up by
% each panel in the viewer window.
% Should be used anytime the number of maps being viewed changes or when
% the user changes the viewer type

%TODO see if checking if property different is faster than just forcing a
%resize.

    function set_viewing_properties(varargin)
        
        % No longer going to manually set screen space. This way if user
        % changes size of screen they no longer have to repeat every time
        % they change something
        
        
        % Second, determine what control panels should be in view based on
        % the type of viewer currently being used
        if strcmp(ddat.type, 'grp')
            % Set visible/invisible
            set(findobj('Tag', 'useEmpiricalVar'), 'Visible', 'Off');
            set(findobj('Tag', 'selectSubject'), 'Visible', 'Off');
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'Off');
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'Off');
            set(findobj('Tag', 'covariateContrastControl'), 'Visible', 'Off');
            set( findobj('Tag', 'createMask'), 'Visible', 'On' );
            % Resize the info panels
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.34, 0.01 .31 .39]);
            set( findobj('Tag', 'icPanel'), 'Position',[.34, 0.42 .31 .57]);
            set( findobj('Tag', 'locPanel'), 'Position',[.01, 0.01 .31 .98]);
            set( findobj('Tag', 'ViewSelectionPanel'), 'Position',[.67, 0.01 .31 .98]);
        end
        
        if strcmp(ddat.type, 'subj')
            % Set visible/invisible
            set(findobj('Tag', 'useEmpiricalVar'), 'Visible', 'Off');
            set(findobj('Tag', 'selectSubject'), 'Visible', 'On');
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'Off');
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'Off');
            set(findobj('Tag', 'covariateContrastControl'), 'Visible', 'Off');
            set( findobj('Tag', 'createMask'), 'Visible', 'Off' );
            % Resize the info panels
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.34, 0.01 .31 .39]);
            set( findobj('Tag', 'icPanel'), 'Position',[.34, 0.42 .31 .57]);
            set( findobj('Tag', 'locPanel'), 'Position',[.01, 0.01 .31 .98]);
            set( findobj('Tag', 'ViewSelectionPanel'), 'Position',[.67, 0.01 .31 .98]);
        end
        
        if strcmp(ddat.type, 'beta')
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.34, 0.01 .31 .39]);
            set( findobj('Tag', 'icPanel'), 'Position',[.34, 0.42 .31 .57]);
            set( findobj('Tag', 'locPanel'), 'Position',[.01, 0.01 .31 .98]);
            set( findobj('Tag', 'ViewSelectionPanel'), 'Position',[.67, 0.51 .31 .48]);
            set( findobj('Tag', 'covariateContrastControl'), 'Position',[.67, 0.01 .31 .48]);
            set( findobj('tag', 'EffectTypeButtonGroup'), 'visible', 'on' );
        end
        
        if strcmp(ddat.type, 'subpop')
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.34, 0.01 .31 .39]);
            set( findobj('Tag', 'icPanel'), 'Position',[.34, 0.42 .31 .57]);
            set( findobj('Tag', 'locPanel'), 'Position',[.01, 0.01 .31 .98]);
            set( findobj('Tag', 'ViewSelectionPanel'), 'Position',[.67, 0.51 .31 .48]);
            set( findobj('Tag', 'SubpopulationControl'), 'Position',[.67, 0.01 .31 .48]);
            set( findobj('tag', 'EffectTypeButtonGroup'), 'visible', 'off' );
            set( findobj('tag', 'subPopSelect1'), 'visible', 'off');
        end
        
        % Third, based on the number of brain maps being viewed, determine
        % the relative amount to real estate to give the brain maps over
        % the controls panel.
        % Cases: 1  maps - 50/50
        %        2  maps - 60/40
        %        3+ maps - 70/30
        nMapsViewed = sum(ddat.viewTracker(:) > 0);
        switch nMapsViewed
            case 0
                y_use = 0.5;
            case 1
                y_use = 0.5;
            case 2
                y_use = 0.6;
            case 3
                y_use = 0.7;
            otherwise
                y_use = 0.7;
        end
        % Get the current sizes
        curr_setting_viewer = get(findobj('tag', 'viewingPanelNormal'), 'position');
        curr_setting_ctrl   = get(findobj('tag', 'ControlPanel'), 'position');
        % Edit the height the two boxes get
        curr_setting_viewer(2) = 1.0 - y_use + 0.01;
        curr_setting_viewer(4) = y_use;
        curr_setting_ctrl(4)   = 1.0 - y_use;
        % Set to the new proportion
        set(findobj('tag', 'viewingPanelNormal'), 'position', curr_setting_viewer);
        set(findobj('tag', 'ControlPanel')      , 'position', curr_setting_ctrl);
        
        
        % Fourth, scale the brain maps to fit in the space allocated to
        % them
        y_avail = y_use / nMapsViewed;
        
        [apos, cpos, spos, axesInfoPanelPos] = generate_axes_positioning( ddat.viewTracker, ddat.tileType);
        
        % transpose and reorder is so that the ordering comes out one pop
        % at a time
        [visit_numbers, selected_pops] = find(ddat.viewTracker' > 0);
        for i = 1:nMapsViewed
            
            % Figure out which map to plot
            selected_pop = selected_pops(i);
            visit_number = visit_numbers(i);
            
            % Calculate the map position
            %             spos = [0.01 (.18 + 0.82*(nMapsViewed-i)/nMapsViewed) .27 0.82/nMapsViewed];
            %             cpos = [0.30 (.18 + 0.82*(nMapsViewed-i)/nMapsViewed) .27 0.82/nMapsViewed];
            %             apos = [0.59 (.18 + 0.82*(nMapsViewed-i)/nMapsViewed) .27 0.82/nMapsViewed];
            
            % Move the maps to their positions
            set(findobj('Tag', ['CoronalAxes'  num2str(selected_pop) '_'...
                num2str(visit_number)] ) , 'position', cpos{selected_pop, visit_number});
            set(findobj('Tag', ['AxialAxes'    num2str(selected_pop) '_'...
                num2str(visit_number)] ) , 'position', apos{selected_pop, visit_number});
            set(findobj('Tag', ['SagittalAxes' num2str(selected_pop) '_'...
                num2str(visit_number)] ) , 'position', spos{selected_pop, visit_number});
            
            % Move the info panel to its position
            %             axesInfoPanelPos = [0.87 (.18 + 0.82*(nMapsViewed-i)/nMapsViewed) .13 0.82/nMapsViewed];
            set(findobj('Tag', ['axesPanel' num2str(selected_pop), '_' num2str(visit_number)]),...
                'position', axesInfoPanelPos{selected_pop, visit_number});
            
        end
        
        
        
    end

%% GUI - Dropdown Menu Functions

% Function to setup the covariate menu when viewing sub-populations.
    function setupCovMenu(hObject, callbackdata)
        newstring = cell(ddat.p, 1);
        for covariate=1:ddat.p
            newstring{covariate} = strcat(ddat.varNamesX{covariate});
        end
        set(findobj('Tag', 'selectCovariate'), 'String', newstring);
    end

% Function to setup the subject menu when viewing individual subjects.
    function setupSubMenu(hObject, callbackdata)
        newstring = cell(ddat.nsub, 1);
        for subject=1:ddat.nsub
            newstring{subject} = ['Subject ' num2str(subject)];
        end
        set(findobj('Tag', 'selectSubject'), 'String', newstring);
    end

% Function to setup the IC menu.
    function setupICMenu(hObject, callbackdata)
        newstring = cell(ddat.q, 2);
        for ic = 1:ddat.q
            newstring{ic, 1} = ['IC ' num2str(ic)];
            newstring{ic, 2} = 'x';
        end
        set(findobj('Tag', 'icSelRef'), 'Data', newstring);
    end

% Function to fill out the visits in the visit menu
    function setupVisitMenu(hObject, callbackdata)
        newstring = cell(ddat.nVisit, 1);
        for iVisit=1:ddat.nVisit
            newstring{iVisit} = ['Visit ' num2str(subject)];
        end
        set(findobj('Tag', 'selectVisit'), 'String', newstring);
    end

%% ViewTable Functions

% Function to set the properties of the ViewSelectTable box

    function setup_ViewSelectTable(varargin)
        
        % Determine whether the ViewSelectTable should appear in the
        % first place (Cross-Sectional hc-ICA aggregate - should not appear)
        
        % Determine whether the table should be editable
        if strcmp(ddat.type, 'grp') || strcmp(ddat.type, 'subj') || strcmp(ddat.type, 'beta')
            set(findobj('tag', 'ViewSelectTable'), 'ColumnEditable', false);
        else
            set(findobj('tag', 'ViewSelectTable'), 'ColumnEditable', true);
        end
        
        % If aggregate maps and longitudinal, then items in the box are
        % fixed. Will just be a list of visits and whether or not they
        % are being viewed.
        
        if strcmp(ddat.type, 'grp') || strcmp(ddat.type, 'subj')
            for k=1:ddat.nVisit; table_data{k} = 'no'; end
            table_data{1} = 'yes';
            set(findobj('tag', 'ViewSelectTable'), 'Data', table_data');
            % Set the visit names
            for k=1:ddat.nVisit; visit_names{k} = ['Visit ' num2str(k)]; end
            set(findobj('tag', 'ViewSelectTable'), 'RowName', visit_names');
            set(findobj('tag', 'ViewSelectTable'), 'ColumnName', {'Viewing'});
        end
        
        if strcmp(ddat.type, 'subpop')
            
            subpops = ddat.LC_subpops;
            subpop_names = get(findobj('tag', 'subPopDisplay'), 'RowName');
            n_subpop = size(subpops, 1);

            disp('create LC_subpop_names and load from it!')

            % Load saved viewTracker information
            ddat.viewTracker = ddat.saved_subpop_viewTracker;

            % Default to showing contrast 1, visit 1
            if all(ddat.viewTracker(:) == 0)
                %ddat.viewTracker(1, 1) = 1;
            end

            % Fill out the selection table
            table_data = cell(ddat.nVisit, 0);
            for k=1:ddat.nVisit
                for p=1:n_subpop
                    if ddat.viewTracker(p, k) > 0
                        table_data{k, p} = 'yes';
                    else
                        table_data{k, p} = 'no';
                    end
                end
            end
            set(findobj('tag', 'ViewSelectTable'), 'Data', table_data);
            set(findobj('tag', 'ViewSelectTable'), 'ColumnName', {});


            % Set the visit names (rows)
            for k=1:ddat.nVisit; visit_names{k} = ['Visit ' num2str(k)]; end
            set(findobj('tag', 'ViewSelectTable'), 'RowName', visit_names');

            if prod(size(subpop_names, 1)) == 1
                subpop_names = {subpop_names};
            end

            % set the column names (contrasts)
            if n_subpop > 0
                set(findobj('tag', 'ViewSelectTable'), 'ColumnName', subpop_names');
            end
            
        end
        
        % If Effect maps, then box is nVisit x P (or P+1)
        if strcmp(ddat.type, 'beta')
            
            % Have to choose between table for effect view and table for
            % contrast view
            
            % Setup for Effect view
            if strcmp(get(get(findobj('tag', 'EffectTypeButtonGroup'),...
                    'SelectedObject'), 'String'), 'Effect View')
                
                ddat.viewTracker = ddat.saved_beta_viewTracker;
                % Default to showing contrast 1, visit 1
                if all(ddat.viewTracker(:) == 0)
                    ddat.viewTracker(1, 1) = 1;
                end
                
                for k=1:ddat.nVisit
                    for p=1:ddat.p
                        if ddat.viewTracker(p, k) > 0
                            table_data{k, p} = 'yes';
                        else
                            table_data{k, p} = 'no';
                        end
                    end
                end
                
                set(findobj('tag', 'ViewSelectTable'), 'Data', table_data);
                
                % Set the visit names (rows)
                for k=1:ddat.nVisit; visit_names{k} = ['Visit ' num2str(k)]; end
                set(findobj('tag', 'ViewSelectTable'), 'RowName', visit_names');
                
                % set the column names (covariates)
                for p=1:ddat.p; column_names{p} = ddat.varNamesX{p}; end;
                set(findobj('tag', 'ViewSelectTable'), 'ColumnName', column_names');
                
                
                % Contrast View Table Setup
            else
                
                % Check the contrast table to find how many contrasts have
                % been created. This will be the number of columns
                contrasts = ddat.LC_contrasts;
                contrast_names = get(findobj('tag', 'contrastDisplay'), 'RowName');
                n_contrast = size(contrasts, 1);
                
                disp('create LC_contrast_names and load from it!')
                
                % Load saved viewTracker information
                ddat.viewTracker = ddat.saved_contrast_viewTracker;
                
                % Default to showing contrast 1, visit 1
                if all(ddat.viewTracker(:) == 0)
                    %ddat.viewTracker(1, 1) = 1;
                end
                
                % Fill out the selection table
                table_data = cell(ddat.nVisit, 0);
                for k=1:ddat.nVisit
                    for p=1:n_contrast
                        if ddat.viewTracker(p, k) > 0
                            table_data{k, p} = 'yes';
                        else
                            table_data{k, p} = 'no';
                        end
                    end
                end
                set(findobj('tag', 'ViewSelectTable'), 'Data', table_data);
                set(findobj('tag', 'ViewSelectTable'), 'ColumnName', {});
               
                
                % Set the visit names (rows)
                for k=1:ddat.nVisit; visit_names{k} = ['Visit ' num2str(k)]; end
                set(findobj('tag', 'ViewSelectTable'), 'RowName', visit_names');
                
                if prod(size(contrast_names, 1)) == 1
                    contrast_names = {contrast_names};
                end
                
                % set the column names (contrasts)
                if n_contrast > 0
                    set(findobj('tag', 'ViewSelectTable'), 'ColumnName', contrast_names');
                end
                
%                 disp('currently this resets the view tracker...')
%                 ddat.viewTracker = zeros(n_contrast, ddat.nVisit);
%                 
%                 disp('add contrast management tracking what was being viewed')
%                 ddat.viewTracker(1, 1) = 1;
                
            end
            
        end
        
    end

% Function to add/remove a visit/subpop/contrast from the view window

    function ViewSelectTable_cell_select(hObject, eventdata, handles)
        
        % Verify input is valid
        if ~isempty(eventdata.Indices)
            
            % Get the selected row
            selected_row = eventdata.Indices(1);
            
            % Get the corresponding population
            selected_pop = eventdata.Indices(2);
            
            % Find the visit this corresponds to, this will be the column
            % of the img object we load in
            visit_number = str2double(eventdata.Source.RowName{selected_row}(end-1:end));
            
            
            % If not viewed, add to viewer, else remove
            if strcmp(eventdata.Source.Data{selected_row, selected_pop}, 'no')
                
                % Set to yes
                eventdata.Source.Data{selected_row, selected_pop} = 'yes';
                
                % Add to tracker
                ddat.viewTracker(selected_pop, visit_number) = 1;
                ddat.viewTracker( ddat.viewTracker > 0 ) = cumsum( ddat.viewTracker(ddat.viewTracker > 0)); % renumber
                
                
                % Update axes visibility
                %                 set(findobj('Tag', ['CoronalAxes'  num2str(selected_pop) '_'...
                %                     num2str(visit_number)] ) , 'visible', 'on');
                %                 set(findobj('Tag', ['AxialAxes'    num2str(selected_pop) '_'...
                %                     num2str(visit_number)] ) , 'visible', 'on');
                %                 set(findobj('Tag', ['SagittalAxes' num2str(selected_pop) '_'...
                %                     num2str(visit_number)] ) , 'visible', 'on');
                
                % Update axes existence
                set_number_of_brain_axes(0);
                
                % Refresh the display window with the new row
                
                % TODO remove below two lines; they are from old system
                %editThreshold;
                update_brain_maps('updateCombinedImage', [selected_pop, visit_number]);
                
                % Stack the update chain at step 1
                %update_brain_data;
                
            else
                
                % Set to no
                eventdata.Source.Data{selected_row, selected_pop} = 'no';
                
                % Remove from tracker
                ddat.viewTracker(selected_pop, visit_number) = 0;
                ddat.viewTracker( ddat.viewTracker > 0 ) = cumsum( ddat.viewTracker(ddat.viewTracker > 0)); % renumber
                
                % Update axes visibility
                set(findobj('Tag', ['CoronalAxes'  num2str(selected_pop) '_'...
                    num2str(visit_number)] ) , 'visible', 'off');
                set(findobj('Tag', ['AxialAxes'    num2str(selected_pop) '_'...
                    num2str(visit_number)] ) , 'visible', 'off');
                set(findobj('Tag', ['SagittalAxes' num2str(selected_pop) '_'...
                    num2str(visit_number)] ) , 'visible', 'off');
                
                % Update axes existence
                set_number_of_brain_axes(0);
                
                % Check to make sure something is being viewed before
                % updating the view tracker
                if sum(ddat.viewTracker > 0)
                    update_brain_data;
                end
                
            end
            
            % Update stored view tracker
            switch ddat.type
                case 'grp'
                    ddat.saved_grp_viewTracker = ddat.viewTracker;
                case 'beta'
                    
                    contrast_selected = strcmp(get(get(findobj('tag',...
                        'EffectTypeButtonGroup'), 'SelectedObject'),...
                        'String'), 'Contrast View');
                    if contrast_selected
                        ddat.saved_contrast_viewTracker = ddat.viewTracker;
                    else
                        ddat.saved_beta_viewTracker = ddat.viewTracker;
                    end

                case 'subject'
                    ddat.saved_subject_viewTracker = ddat.viewTracker;
                case 'subpop'
                    ddat.saved_subpop_viewTracker = ddat.viewTracker;
                otherwise
                    disp('Error updating view table, check strings')
            end
            
            
        end
        
        
        
    end

%% Axes Control

% Function to setup the correct number of Axes for the viewer window.
% This is based on nActiveMaps. The function handles create of new
% settings and deletion of old settings. Note that this function is not the
% one that handles figuring out which order the brain maps are input.
    function set_number_of_brain_axes(redoAllMaps)
        
        
        % TODO might be able to simplify the tracking and figuing out what
        % should be deleted XXX
        
        % Figure out the number of axes. It is possible that this
        % number is different than view tracker, since a contrast/subpop could
        % have been deleted. Should never be more than 1 more

        % Get current number of displayed axes
        current_n_maps = 0;
        for iPop = 1:size(ddat.viewTracker, 1)
            for iVisit = 1:size(ddat.viewTracker, 2)
                % Check if axes exists
                if ~isempty(findobj('tag', ['CoronalAxes' num2str(iPop) '_' num2str(iVisit)]))
                    current_n_maps = current_n_maps + 1;
                end
            end
        end
        
        %%% Delete axes
        % thsi uses viewTrackers size because this is axes
        % creation/deletion NOT placement of maps
        
        
        % Find the maximum number of axes that exists. This is done in case
        % we switch from one viewer to another, might miss somethnig in
        % cleanup stage
        maxAxes = size(ddat.viewTracker, 1);
        for i = maxAxes:(maxAxes+10)
            for iVisit = 1:size(ddat.viewTracker, 2)
                if ~isempty(findobj('tag', ['CoronalAxes' num2str(i) '_' num2str(iVisit)]))
                    maxAxes = i;
                end
            end
        end
        
        % Loop through possibilities and remove things that shouldnt be
        % there        
        for iPop = 1:maxAxes
            for iVisit = 1:size(ddat.viewTracker, 2)
                
                % Check removal criteria
                if redoAllMaps == 1 || ddat.viewTracker(iPop, iVisit) == 0
                    
                    if ~isempty(findobj('tag', ['CoronalAxes' num2str(iPop) '_' num2str(iVisit)]))
                        
                        delete(findobj('tag', ['CoronalAxes' num2str(iPop) '_' num2str(iVisit)]));
                        delete(findobj('tag', ['SagittalAxes' num2str(iPop) '_' num2str(iVisit)]));
                        delete(findobj('tag', ['AxialAxes' num2str(iPop) '_' num2str(iVisit)]));
                        delete(findobj('tag', ['axesPanel' num2str(iPop), '_' num2str(iVisit)]));
                        
                    end % end of check and delete
                    
                end
                
            end
        end
        
        if ddat.type == "subj"
            subj_index = get(findobj('tag', 'selectSubject'), 'value');
            [map_fields, visit_fields] = generate_info_box_fields(ddat.type, ddat.viewTracker, subj_index);
        else
            [map_fields, visit_fields] = generate_info_box_fields(ddat.type, ddat.viewTracker);
        end
        
        %%% Add axes
        aspect = 1./ddat.daspect;
        for iPop = 1:size(ddat.viewTracker, 1)
            for iVisit = 1:size(ddat.viewTracker, 2)
                % Check if axes exists, if not, create it
                if isempty(findobj('tag', ['CoronalAxes' num2str(iPop) '_' num2str(iVisit)])) && ddat.viewTracker(iPop, iVisit) > 0
                    
                    % Coronal Image
                    CorAxes = axes('Parent', hs.fig.Children(3).Children(2), ...
                        'Units', 'Normalized',...
                        'Tag', ['CoronalAxes' num2str(iPop) '_' num2str(iVisit)],...
                        'visible', 'off' );
                    set(CorAxes,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                        'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],...
                        'xtick',[],'ytick',[],...
                        'Tag',['CoronalAxes' num2str(iPop) '_' num2str(iVisit)])
                    daspect(CorAxes, aspect([1 3 2]));
                    
                    % Axial Image
                    AxiAxes = axes('Parent', hs.fig.Children(3).Children(2), ...
                        'Units', 'Normalized', ...
                        'Tag', ['AxialAxes' num2str(iPop) '_' num2str(iVisit)],...
                        'visible', 'off');
                    set(AxiAxes,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                        'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],...
                        'xtick',[],'ytick',[],'Tag',['AxialAxes' num2str(iPop) '_' num2str(iVisit)])
                    daspect(AxiAxes,aspect([1 3 2]));
                    %                     set(ddat.axial_image{iPop, iVisit},'ButtonDownFcn',...
                    %                         {@image_button_press, 'axi'});
                    %                     pos_axi = [ddat.sag, ddat.cor];
                    %                     crosshair = plot_crosshair(pos_axi, [], AxiAxes);
                    %                     ddat.axial_xline{iPop, iVisit} = crosshair.lx;
                    %                     ddat.axial_yline{iPop, iVisit} = crosshair.ly;
                    
                    % Sagittal Image
                    SagAxes = axes('Parent', hs.fig.Children(3).Children(2), ...
                        'Units', 'Normalized', ...
                        'Tag', ['SagittalAxes' num2str(iPop) '_' num2str(iVisit)],...
                        'visible', 'off' );
                    set(SagAxes,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                        'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],...
                        'xtick',[],'ytick',[],'Tag',['SagittalAxes' num2str(iPop) '_' num2str(iVisit)])
                    daspect(SagAxes,aspect([2 3 1]));
                    
                    %% Information Panel
                    InfoPanel = uipanel('FontSize',12,...
                        'Title', '', ...
                        'Tag', ['axesPanel' num2str(iPop), '_' num2str(iVisit)], ...
                        'Parent', hs.fig.Children(3).Children(2), ...
                        'units', 'normalized', 'visible', 'on');
                    
                    % The actual labels
                    MapValue = uicontrol('Parent', InfoPanel, ...
                        'Style', 'Text', 'String', map_fields{iPop, iVisit}, ...
                        'tag', ['axesPanel' num2str(iPop), '_' num2str(iVisit), '_MAP'],...
                        'Units', 'Normalized', ...
                        'Position', [0.01, 0.66, 0.98, 0.33]);
                    VisitValue = uicontrol('Parent', InfoPanel, ...
                        'Style', 'Text', 'String', visit_fields{iPop, iVisit}, ...
                        'tag', ['axesPanel' num2str(iPop), '_' num2str(iVisit), '_VISIT'],...
                        'Units', 'Normalized', ...
                        'Position', [0.01, 0.35, 0.98, 0.30]);
                    VoxelValue = uicontrol('Parent', InfoPanel, ...
                        'Style', 'Text', 'String', '', ...
                        'Units', 'Normalized', ...
                        'tag', ['VoxelValueBox' num2str(iPop) '_' num2str(iVisit)],...
                        'Position', [0.01, 0.01, 0.98, 0.4]);
                    % Fill out the panel name
                    %iPop iVisit
                    %obtain
                    
                    % The else statement handles the case where the axes
                    % already exists. In this case, we might still need to
                    % update the desciptor text
                else
                    set(findobj('tag', ['axesPanel' num2str(iPop), '_' num2str(iVisit), '_MAP']),...
                        'String', map_fields{iPop, iVisit});
                    set(findobj('tag', ['axesPanel' num2str(iPop), '_' num2str(iVisit), '_VISIT']),...
                        'String', visit_fields{iPop, iVisit});
                    set(findobj('tag', ['VoxelValueBox' num2str(iPop) '_' num2str(iVisit)]),...
                        'String', '');
                end % end of check for existance of axes
            end
        end
        
        set_viewing_properties;
        
    end



%% Augmenting Windows - Trajectory Control
% Function to shift view structure to include the trajectory viewer on the right
    function shift_to_trajectory_view(varargin)
        
        % Turn on Trajectory View
        
        if (ddat.trajectoryActive == 0)
            
            % Increase the size of the viewer window
            currentPosition = hs.fig.Position;
            ddat.prevDisplaySize = currentPosition;
            hs.fig.Position = [currentPosition(1)*.6 currentPosition(2) 0.8 0.6];
            
            % Resize the Default View panel
            set(findobj('Tag', 'DefaultPanel'), 'Position', [0.0, 0.0, 0.75, 1.0]);
            
            % Give the new space to the augmenting panel
            set(findobj('Tag', 'AugmentingPanel'), 'Position', [0.75, 0.0, 0.25, 1.0]);
            
            % Enable the trajectory view
            set(findobj('Tag', 'ViewTrajPanel'), 'Visible', 'On');
            
            % Set the tracker in the ddat structure
            ddat.trajectoryActive = 1;
            
            % Make sure the visit labels on the x-axis are correct
            trajAxesHandle = findobj('Tag', 'TrajAxes');
            set(trajAxesHandle,'XLim', [1, ddat.nVisit], 'XTick', 1:ddat.nVisit);
            drawnow;
            
            % Add the currently selected voxel to the trajectory plot
            plot_voxel_trajectory([ddat.sag, ddat.cor, ddat.axi])
            
            % Turn off trajectory view
        else
            
            % Remove any red lines
            trajAxesHandle = findobj('Tag', 'TrajAxes');
            nLine = length(trajAxesHandle.Children);
            if nLine > 0
                for iline = 1:nLine
                    if all(trajAxesHandle.Children(iline).Color == [1 0 0])
                        delete(trajAxesHandle.Children(iline));
                        break
                    end
                end
            end
            
            % Reset the size of the figure
            hs.fig.Position = ddat.prevDisplaySize;
            
            % Take away the space from the augmenting panel
            set(findobj('Tag', 'AugmentingPanel'), 'Position', [0.0, 0.0, 0.0, 0.0]);
            
            % Resize the Default View panel
            set(findobj('Tag', 'DefaultPanel'), 'Position', [0, 0, 1.0, 1.0]);
            
            % Disable the trajectory view
            set(findobj('Tag', 'ViewTrajPanel'), 'Visible', 'Off');
            
            % Set the tracker in the ddat structure
            ddat.trajectoryActive = 0;
        end
        
    end

% Function to add the currently selected voxel to the stored list
    function traj_add_voxel_to_list(varargin)
        
        newCoordinates = [ddat.sag, ddat.cor, ddat.axi];
        
        % Verify that the voxel is not already in the list
        storedCoordinates = get( findobj('Tag', 'TrajTable'), 'Data' );
        nStored = size(storedCoordinates, 1);
        duplicate = 0;
        for iStored = 1:nStored
            if all(newCoordinates == [storedCoordinates{iStored, :}])
                duplicate = 1;
                break
            end
        end
        
        % If not a duplicate, add it to the list
        if duplicate == 0
            % Add to the list
            storedCoordinates{nStored+1, 1} = ddat.sag;
            storedCoordinates{nStored+1, 2} = ddat.cor;
            storedCoordinates{nStored+1, 3} = ddat.axi;
            set( findobj('Tag', 'TrajTable'), 'Data', storedCoordinates );
            % Plot the new voxel
            plot_voxel_trajectory(newCoordinates)
        end
        
    end

% Function to plot the trajectory of the currently selected voxel
    function plot_voxel_trajectory(voxelIndex)
        
        % verify that trajectories are being plotted
        if ddat.trajectoryActive == 1
            
            % Get the axes to plot to
            trajAxesHandle = findobj('Tag', 'TrajAxes');
            
            % check if this is a new voxel, if so, delete previous red line
            if ~strcmp(num2str(voxelIndex), ddat.trajPreviousTag)
                % Delete the previously selected red line
                for iline = 1:length(trajAxesHandle.Children)
                    if strcmp(trajAxesHandle.Children(iline).Tag, ddat.trajPreviousTag)
                        % check if red line
                        if all(trajAxesHandle.Children(iline).Color == [1 0 0])
                            delete(trajAxesHandle.Children(iline));
                            break
                        end
                    end
                end
            end
            
            % Get the trajectory for the currently selected voxel
            traj = zeros(ddat.nVisit, 1);
            for iVisit = 1:ddat.nVisit
                traj(iVisit) = ddat.oimg{1, iVisit}(voxelIndex(1), voxelIndex(2), voxelIndex(3));
            end
            
            
            % Make sure the yaxis of the plot matches
            if any(~isnan(traj))
                minY = min(traj);
                maxY = max(traj);
                range = maxY - minY;
                if trajAxesHandle.YLim(1) > (minY - (0.05*range))
                    trajAxesHandle.YLim(1) = (minY - (0.05*range));
                end
                if trajAxesHandle.YLim(2) < (maxY + (0.05*range))
                    trajAxesHandle.YLim(2) = (maxY + (0.05*range));
                end
            end
            
            % Give the new line a name based on its coordinates
            lineName = num2str(voxelIndex);
            
            % check if the line name is already in use, if so, the new line
            % should be blue instead of red (stored)
            if (length(trajAxesHandle.Children) > 0) && strcmp(lineName, trajAxesHandle.Children(1).Tag)
                % Plot the line to be stored
                line(trajAxesHandle, 1:ddat.nVisit, traj, 'Tag', lineName, 'Color', 'Blue');
                drawnow;
            else
                % Plot a new line
                line(trajAxesHandle, 1:ddat.nVisit, traj, 'Tag', lineName, 'Color', 'Red');
                drawnow;
            end
            
            
            % Store this to know what to delete when moving to a new
            % position
            ddat.trajPreviousTag = lineName;
            
        end
        
    end

% Function to update the trajectory information when a new subject/IC/subpop has been
% selected. Main idea is that we need to force an update of all saved
% lines, as well as the red line. Can also be used in future we we "save" a
% state of the viewer window to re-loaded saved voxels.
%
% Last Edited - 12/5/19
%
% Steps Involved
% 0. Remove all lines from the plot
% 1. Get a list of all saved voxels
% 2. Re-plot the blue lines for each of these
% 3. Obtain currently selected voxel
% 4. Plot red line for this one
%
% Potential Changes
% 1. Right now starts with a check that the trajectories are active. I
% might want to remove this, since I think I want to call it any time that
% a large number of things change. On the other hand, I could make it run
% any time that the trajectory box is enabled/disabled (might be less error
% prone).
    function update_all_traj_fields()
        
        % verify that trajectories are being plotted
        if ddat.trajectoryActive == 1
            
            % Get the axes to plot to
            trajAxesHandle = findobj('Tag', 'TrajAxes');
            
            % Step 0 - Remove all old lines
            for iline = 1:length(trajAxesHandle.Children)
                delete(trajAxesHandle.Children(1));
            end
            
            % Step 1 - Obtain list of all saved voxels
            storedCoordinates = get( findobj('Tag', 'TrajTable'), 'Data' );
            nStored = size(storedCoordinates, 1);
            %storedCoordinates{iStored, :}
            
            % Step 2 - Plot a blue line for each voxel in the list
            % TODO in future might need to loop over pops/contrasts here
            traj = zeros(ddat.nVisit, 1);
            for iline = 1:nStored
                
                % Extract the voxel indices
                voxelIndex = [storedCoordinates{iline, :}];
                
                % Get the value at this voxel for each visit
                for iVisit = 1:ddat.nVisit
                    traj(iVisit) = ddat.oimg{1, iVisit}(voxelIndex(1), voxelIndex(2), voxelIndex(3));
                end
                
                % Plot the corresponding blue line
                lineName = num2str(voxelIndex);
                line(trajAxesHandle, 1:ddat.nVisit, traj, 'Tag', lineName, 'Color', 'Blue');
                
            end
            
            % Step 3 - Grab the currently selected voxel coordinates/values
            % TODO in future might need to loop over pops/contrasts here
            for iVisit = 1:ddat.nVisit
                traj(iVisit) = ddat.oimg{1, iVisit}(ddat.sag, ddat.cor, ddat.axi);
            end
            
            % Step 4 - Plot the red line
            % TODO in future might need to loop over pops/contrasts here
            lineName = num2str([ddat.sag, ddat.cor, ddat.axi]);
            line(trajAxesHandle, 1:ddat.nVisit, traj, 'Tag', lineName, 'Color', 'Red');
            ddat.trajPreviousTag = lineName;
            
        end % end of verification that traj being plotted
        
    end

% Function to move the viewer window to a selected voxel
    function traj_box_cell_select(hObject, eventdata, handles)
        
        % Verify input is valid
        if ~isempty(eventdata.Indices)%&&~isempty(data)
            
            % Get the selected row
            selected_row = eventdata.Indices(1);
            
            % Get the corresponding coordinates
            ddat.sag = eventdata.Source.Data{selected_row, 1};
            ddat.cor = eventdata.Source.Data{selected_row, 2};
            ddat.axi = eventdata.Source.Data{selected_row, 3};
            
            % Move the display window to this position
            redisplay;
            % Force set axis info
            
            % New loop over population/visit
            [rowInd, colInd] = find(ddat.viewTracker > 0);
            if size([rowInd, colInd], 2) ~= 2
                rowInd = rowInd(:); colInd = colInd(:);
            end
            indices = [rowInd, colInd];
            nUpdate = size(indices, 1);
            
            for iUpdate = 1:nUpdate
                
                iRow = indices(iUpdate, 1); iCol = indices(iUpdate, 2);
                axes_suffix = [num2str(iRow) '_' num2str(iCol)];
                
                % Move all images to the correct slices
                moveptr( get(findobj('tag', ['SagittalAxes' axes_suffix])), ddat.cor, ddat.axi )
                moveptr( get(findobj('tag', ['CoronalAxes' axes_suffix])), ddat.sag, ddat.axi )
                moveptr( get(findobj('tag', ['AxialAxes' axes_suffix])), ddat.cor, ddat.sag )
                
                % Saggital Axis
                cld = get(findobj('tag', ['SagittalAxes' axes_suffix]), 'Children');
                newevent.Button = 1;
                %newevent.IntersectionPoint = [ddat.cor ddat.axi ddat.sag];
                newevent.IntersectionPoint = [ddat.cor ddat.axi 0];
                newevent.Source = cld(3);
                newevent.EventName = 'Hit';
                set(gcf,'CurrentAxes', findobj('tag', ['SagittalAxes' axes_suffix]))
                cp = [ddat.cor, ddat.axi, 20.0; ddat.cor, ddat.axi, 0.0];
                %set(findobj('tag', 'SagittalAxes1'), 'CurrentPoint', cp);
                image_button_press( cld(3), newevent, 'sag', cp)
                
                %             %% Coronal Axis
                cld = get(findobj('tag', ['CoronalAxes' axes_suffix]), 'Children');
                newevent.Button = 1;
                newevent.IntersectionPoint = [ddat.sag ddat.axi ddat.cor ];
                newevent.Source = cld(3);
                newevent.EventName = 'Hit';
                set(gcf,'CurrentAxes', findobj('tag', ['CoronalAxes' axes_suffix]))
                cp = [ddat.sag, ddat.axi, 20.0; ddat.sag, ddat.axi, 0.0];
                image_button_press( cld(3), newevent, 'cor', cp)
                %
                %             %% Axi Axis
                %             cld = get(findobj('tag', 'AxialAxes1'), 'Children');
                %             newevent.Button = 1;
                %             %newevent.IntersectionPoint = [ddat.cor ddat.axi ddat.sag];
                %             newevent.IntersectionPoint = [ddat.cor ddat.axi 0];
                %             newevent.Source = cld(3);
                %             newevent.EventName = 'Hit';
                %             image_button_press( cld(3), newevent, 'axi')
            end
            
        end
        
        % Remove the last red line from the trajectory plot
        trajAxesHandle = findobj('Tag', 'TrajAxes');
        % check if this is a new voxel, if so, delete previous red line
        % Delete the previously selected red line
        for iline = 1:length(trajAxesHandle.Children)
            if strcmp(trajAxesHandle.Children(iline).Tag, ddat.trajPreviousTag)
                % check if red line
                if all(trajAxesHandle.Children(iline).Color == [1 0 0])
                    delete(trajAxesHandle.Children(iline));
                    break
                end
            end
        end
        
    end

%% Shared button press function
    function image_button_press(src, event, type, varargin)
        if ~isempty(varargin)
            position_information_update(type, varargin{1});
        else
            position_information_update(type);
        end
        plot_voxel_trajectory([ddat.sag, ddat.cor, ddat.axi]);
    end

%% Initial Display

%%% initialDisp - sets up the initial state of the display window based
% on the user selection (aggregate viewer, covariate effect viewer, etc)

    function initialDisp(hObject,callbackdata)
        set(findobj('Tag', 'thresholdSlider'), 'Value', 0);
        set(findobj('Tag', 'manualThreshold'), 'String', '0');
        setup_ViewSelectTable;
        % Number of comparisons is fixed to 1, but this can be modified
        % without issue
        ddat.nCompare = 1;
        % Stretch containers storing the images to have the correct number
        % of objects (1)
        ddat.axial_image    = cell(ddat.nCompare, ddat.nVisit);
        ddat.sagittal_image = cell(ddat.nCompare, ddat.nVisit);
        ddat.coronal_image  = cell(ddat.nCompare, ddat.nVisit);
        ddat.axial_xline    = cell(ddat.nCompare, ddat.nVisit);
        ddat.axial_yline    = cell(ddat.nCompare, ddat.nVisit);
        ddat.coronal_xline  = cell(ddat.nCompare, ddat.nVisit);
        ddat.coronal_yline  = cell(ddat.nCompare, ddat.nVisit);
        ddat.sagittal_xline = cell(ddat.nCompare, ddat.nVisit);
        ddat.sagittal_yline = cell(ddat.nCompare, ddat.nVisit);
        ddat.img = cell(ddat.nCompare, ddat.nVisit); ddat.oimg = cell(ddat.nCompare, ddat.nVisit);
        % New 8/29/19, used to keep track of which voxels to show
        ddat.maskingStatus = cell(ddat.nCompare, ddat.nVisit);
        
        % Change what display panels are seen based on what viewer is open.
        if strcmp(ddat.type, 'grp')
            
            ddat.viewTracker = zeros(1, ddat.nVisit);
            ddat.viewTracker(1, 1) = 1;
            
            set(findobj('Tag', 'useEmpiricalVar'), 'Visible', 'Off');
            set(findobj('Tag', 'selectSubject'), 'Visible', 'Off');
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'Off');
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'Off');
            set(findobj('Tag', 'covariateContrastControl'), 'Visible', 'Off');
            set( findobj('Tag', 'createMask'), 'Visible', 'On' );
            % move the info panels to the middle of the screen
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.56, 0.01 .32 .19]);
            set( findobj('Tag', 'icPanel'), 'Position',[.56, 0.21 .32 .50]);
            set( findobj('Tag', 'locPanel'), 'Position',[.12, 0.01 .32 .98]);
            
            % load the aggregate map for each visit
%             for iVisit = 1:ddat.nVisit
%                 ndata = load_nii([ddat.outdir '/' ddat.outpre '_aggregate' 'IC_1_visit' num2str(iVisit) '.nii']);
%                 ddat.img{1, iVisit} = ndata.img; ddat.oimg{1, iVisit} = ndata.img;
%                 ddat.maskingStatus{1, iVisit} = ~isnan(ddat.img{1, iVisit});
%             end
            
        elseif strcmp(ddat.type, 'subpop')
            set(findobj('Tag', 'useEmpiricalVar'), 'Visible', 'Off');
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'Off');
            set( findobj('Tag', 'createMask'), 'Visible', 'Off' );
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'On');
            set(findobj('Tag', 'covariateContrastControl'), 'Visible', 'Off');
            % Place the boxes in the correct locations
            %set( findobj('Tag', 'thresholdPanel'), 'Position',[.35, 0.01 .32 .19]);
            %5set( findobj('Tag', 'icPanel'), 'Position',[.35, 0.21 .32 .25]);
            %set( findobj('Tag', 'locPanel'), 'Position',[.01, 0.01 .32 .45]);
            set( findobj('Tag', 'selectSubject'), 'Visible', 'Off');
            % Set up the sub-population box
            if ddat.subPopExists == 0
                newColnames = ddat.varNamesX;
                set(findobj('Tag', 'subPopDisplay'), 'Data', cell(0, ddat.p));
                set(findobj('Tag', 'subPopDisplay'), 'ColumnName', newColnames);
                set(findobj('Tag', 'subPopDisplay'), 'ColumnEditable', true);
                %ddat.subPopExists = 1;
            end
            % Place the boxes in the correct locations
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.35, 0.01 .32 .19]);
            set( findobj('Tag', 'icPanel'), 'Position',[.35, 0.21 .32 .25]);
            set( findobj('Tag', 'locPanel'), 'Position',[.01, 0.01 .32 .45]);
            % No data to display at first
            %tempImg = load_nii([ddat.outdir '/' ddat.outpre '_S0_' 'IC_1.nii']);
            %ddat.img{1} = zeros(size(tempImg.img)); ddat.oimg{1} = zeros(size(tempImg.img));
            
        elseif strcmp(ddat.type, 'beta')
            
            ddat.viewTracker = zeros(ddat.p, ddat.nVisit);
            ddat.viewTracker(1, 1) = 1;
            
            ddat.viewingContrast = 0;
            set(findobj('Tag', 'useEmpiricalVar'), 'Visible', 'Off');
            set(findobj('Tag', 'covariateContrastControl'), 'Visible', 'On');
            set(findobj('Tag', 'selectSubject'), 'Visible', 'Off');
            set( findobj('Tag', 'createMask'), 'Visible', 'Off' );
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'Off');
            % Place the boxes in the correct locations
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.35, 0.01 .32 .19]);
            set( findobj('Tag', 'icPanel'), 'Position',[.35, 0.21 .32 .25]);
            set( findobj('Tag', 'locPanel'), 'Position',[.01, 0.01 .32 .45]);
            % Set up the contrast box
            if ddat.contrastExists == 0
                newColnames = ddat.varNamesX;
                set(findobj('Tag', 'contrastDisplay'), 'Data', cell(0, ddat.p));
                set(findobj('Tag', 'contrastDisplay'), 'ColumnName', newColnames);
                set(findobj('Tag', 'contrastDisplay'), 'ColumnEditable', true);
                ddat.contrastExists = 0;
            end
            
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'On');
            setupCovMenu;
            
        elseif strcmp(ddat.type, 'subj')
            
            ddat.viewTracker = zeros(1, ddat.nVisit);
            ddat.viewTracker(1, 1) = 1;
            
            set(findobj('Tag', 'useEmpiricalVar'), 'Visible', 'Off');
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'Off');
            set( findobj('Tag', 'createMask'), 'Visible', 'Off' );
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'Off');
            set(findobj('Tag', 'covariateContrastControl'), 'Visible', 'Off');
            % move the info panels to the middle of the screen
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.56, 0.01 .32 .19]);
            set( findobj('Tag', 'icPanel'), 'Position',[.56, 0.21 .32 .50]);
            set( findobj('Tag', 'locPanel'), 'Position',[.12, 0.01 .32 .98]);
            
            % Load a top level aggregate map just to have the dimensions
            ndata = load_nii([ddat.outdir '/' ddat.outpre '_aggregate' 'IC_1_visit' num2str(1) '.nii']);
            ddat.img{1} = ndata.img; ddat.oimg{1} = ndata.img;
            % load the data
            ddat.subjectLevelData = load([ddat.outdir '/' ddat.outpre '_subject_IC_estimates.mat']);
            ddat.subjectLevelData = ddat.subjectLevelData.subICmean;
            generate_single_subject_map;
            set(findobj('Tag', 'selectSubject'), 'Visible', 'On');
            setupSubMenu;
            ddat.maskingStatus{1, 1} = ~isnan(ddat.img{1, 1});
            
        elseif strcmp(ddat.type, 'icsel')
            ndata = load_nii([ddat.outdir '/_iniIC_1.nii']);
            % need to turn the 0's into NaN values
            zeroImg = ndata.img; zeroImg(find(ndata.img == 0)) = nan;
            ddat.img{1} = zeroImg; ddat.oimg{1} = zeroImg;
            set(findobj('Tag', 'icSelectionPanel'), 'Visible', 'On');
            set(findobj('Tag', 'keepIC'), 'Visible', 'On');
            set(findobj('Tag', 'viewerMenu'), 'Visible', 'Off');
            set(findobj('Tag', 'icSelectCloseButton'), 'Visible', 'On');
            setupICMenu;
            
            % setup display window for the reduced dimension estimates
        elseif strcmp(ddat.type, 'reEst')
            ndata = load_nii([ddat.outdir '/' ddat.outpre '_iniguess/' ddat.outpre '_reducedIniGuess_GroupMap_IC_1.nii']);
            % need to turn the 0's into NaN values
            zeroImg = ndata.img; zeroImg(find(ndata.img == 0)) = nan;
            ddat.img{1} = zeroImg; ddat.oimg{1} = zeroImg;
            set(findobj('Tag', 'selectSubject'), 'Visible', 'Off');
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'Off');
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'Off');
            set( findobj('Tag', 'createMask'), 'Visible', 'On' );
            % move the info panels to the middle of the screen
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.56, 0.01 .32 .19]);
            set( findobj('Tag', 'icPanel'), 'Position',[.56, 0.21 .32 .25]);
            set( findobj('Tag', 'locPanel'), 'Position',[.12, 0.01 .32 .45]);
            setupICMenu;
            % This should only be called from subpopulation display
            
        elseif strcmp(ddat.type, 'subPopCompare')
            ddat.nCompare = 2;
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'On');
            set(findobj('Tag', 'SubpopulationControl'), 'Position', [0.72, 0.70, 0.27, 0.29]);
            set(findobj('Tag', 'subPopDisplay'), 'ColumnEditable', false);
            set(findobj('Tag', 'newSubPop'), 'Visible', 'Off');
            set(findobj('Tag', 'subPopSelect'), 'Visible', 'Off');
            expandSubPopulationPanel();
        end
        
        % Fill out all ICs if doing IC selection.
        if strcmp(ddat.type, 'icsel')
            newstring = cell(ddat.q, 1);
            for ic=1:ddat.q
                newstring{ic} = strcat(['IC ' num2str(ic)]);
            end
            % Fill out only the keeplist ICs if doing any other type of viewer.
        else
            newstring = cell(ddat.qstar, 1);
            for ic=1:ddat.qstar
                newstring{ic} = strcat(['IC ' num2str(ic)]);
            end
        end
        set(findobj('Tag', 'ICselect'), 'String', newstring);
        set(findobj('Tag', 'ICselect'), 'Value', 1);
        
        % Set the Z-score selection box to be off.
        set(findobj('Tag', 'viewZScores'), 'Value', 0);
        ddat.isZ = 0;
        
        % Set up the initial colorbar.
        jet2=jet(64); jet2(38:end, :)=[];
        hot2=hot(64); hot2(end-5:end, :)=[]; hot2(1:4, :)=[];
        hot2(1:2:38, :)=[]; hot2(2:2:16, :)=[]; hot2=flipud(hot2);
        hot3=[jet2; hot2];
        ddat.hot3 = jet(64);
        ddat.highcolor = jet(64);
        ddat.basecolor = gray(191);
        ddat.colorlevel = 256;
        
        % Look for an appropriately sized mask file.
        maskSearch;
        
        
%         % Load the Variance Estimates for the regression coefficients
%         if strcmp(ddat.type, 'beta')
%             
%             % Create the beta variance estimate map
%             ddat.betaVarEst = zeros(ddat.p, ddat.p, ddat.xdim, ddat.ydim, ddat.zdim);
%             
%             % Fill out the beta map for the current IC
%             currentIC = get(findobj('Tag', 'ICselect'), 'val');
%             
%             % TODO check the selected visit here just in case
%             iVisit = 1;
%             
%             % Load the map
%             newMap = load(fullfile(ddat.outdir,...
%                 [ddat.outpre '_BetaVarEst_IC' num2str(currentIC)...
%                 '_visit' num2str(iVisit) '.mat']));
%             ddat.betaVarEst = newMap.betaVarEst;
%             
%         end
        
        load_functional_images;
        
        % Set up the anatomical image.
        %setupAnatomical;
        
        % Load the functional images and display
        
        % Get the size of each dimension.
        %dim = size(ddat.img{1, 1});
        %ddat.xdim = dim(1); ddat.ydim = dim(2); ddat.zdim = dim(3);
       
        
        % create the combined images
        %createCombinedImage;
       
        
        %% Using the new function in INITIAL DISP
        %set_number_of_brain_axes(1)
        %update_brain_maps('updateCombinedImage', [1, 1], 'updateMasking', 1)
        
        updateColorbar;
        
        %set_number_of_brain_axes(1)
        
        
        %%%%% Set up each of the sliders %%%%%
        % Sagittal Slider
        xslider_step(1) = 1/(ddat.xdim);
        xslider_step(2) = 1.00001/(ddat.xdim);
        set(findobj('Tag', 'SagSlider'), 'Min', 1, 'Max',ddat.xdim, ...
            'SliderStep',xslider_step,'Value',ddat.sag); %%Sagittal Y-Z, adjust x direction
        % Coronal Slider
        yslider_step(1) = 1/(ddat.ydim);
        yslider_step(2) = 1.00001/(ddat.ydim);
        set(findobj('Tag', 'CorSlider'), 'Min', 1, 'Max',ddat.ydim, ...
            'SliderStep',yslider_step,'Value',ddat.cor); %%Coronal X-Z, adjust y direction
        % Axial Slider
        zslider_step(1) = 1/(ddat.zdim);
        zslider_step(2) = 1.00001/(ddat.zdim);
        set(findobj('Tag', 'AxiSlider'), 'Min', 1, 'Max',ddat.zdim, ...
            'SliderStep',zslider_step,'Value',ddat.axi);
        
        % Info for the text box.
        set(findobj('Tag', 'originalPos'),'String',...
            sprintf('%7.0d %7.0d %7.0d',ddat.origin(1),ddat.origin(2),ddat.origin(3)));
        set(findobj('Tag', 'crosshairPos'),'String',...
            sprintf('%7.0d %7.0d %7.0d',ddat.sag,ddat.cor, ddat.axi));
        set(findobj('Tag', 'dimension'),'String',...
            sprintf('%7.0d %7.0d %7.0d',ddat.xdim,ddat.ydim,ddat.zdim));
        
        %updateZImg;
        %maskSearch;
        
        if ~strcmp(ddat.type, 'subpop')
            %editThreshold;
        end
        
        %updateCrosshairValue;
        %redisplay;
        updateInfoText;
    end

%% Single Subject Viewer Specific Functions

% Function to generate the single subject maps. This is preferable to
% storing all of the maps in case there are many subjects
    function generate_single_subject_map(hObject, callbackdata)
        
        disp('Generating map for requested subject and component.')
        
        % Get the requested subject number
        subnum = get( findobj('Tag', 'selectSubject'), 'Value' );
        
        % Get the requested IC
        newIC = get(findobj('Tag', 'ICselect'), 'val');
        
        % Get the correct elements of the subjicmean vector
        for iVisit = 1:ddat.nVisit
            vectData = squeeze(ddat.subjectLevelData(iVisit, newIC, subnum, :));
            % Place in the correct dimensions
            vxl = size(ddat.oimg{1});
            locs = ~isnan(ddat.oimg{1, 1});
            nmat = nan(vxl);
            nmat(locs) = vectData;
            ddat.img{1, iVisit} = nmat; ddat.oimg{1, iVisit} = nmat;
        end
        
    end

%% Anatomical Image and Mask Functions
    function setupAnatomical(hObject, callbackdata)
        
        % 2mm voxel case
        if ddat.xdim == 182 && ddat.ydim == 218 && ddat.zdim == 182
            ddat.mri_struct = load_nii('templates/MNI152_T1_1mm.nii');
        elseif ddat.xdim == 91 && ddat.ydim == 109 && ddat.zdim == 91
            ddat.mri_struct = load_nii('templates/MNI152_T1_2mm.nii');
        elseif ddat.xdim == 61 && ddat.ydim == 73 && ddat.zdim == 61
            ddat.mri_struct = load_nii('templates/MNI152_T1_3mm.nii');
        elseif ddat.xdim == 45 && ddat.ydim == 54 && ddat.zdim == 45
            ddat.mri_struct = load_nii('templates/MNI152_T1_4mm.nii');
            % Handle case where no mask was found.
        else
            mriHolder = ones(ddat.xdim, ddat.ydim, ddat.zdim);
            ddat.mri_struct = make_nii(mriHolder);
        end
        minVal = min(ddat.mri_struct.img(:));
        maxVal = max(ddat.mri_struct.img(:));
        ddat.scaledImg = scale_in(ddat.mri_struct.img, minVal, maxVal, 190);
        
    end

    function maskSearch(hObject,  callbackdata)
        % Get the the current IC
        currentIC = get(findobj('Tag', 'ICselect'), 'val');
        % Check: does a mask file exist?
        fls = dir([ddat.outdir '/' ddat.outpre '*maskIC_' num2str(currentIC) '_' '*.nii']);
        nfile = size(fls); nfile = nfile(1);
        if nfile > 0
            handles.maskExist = 1;
            newstring = cell(nfile+1, 1);
            newstring{1} = 'No Mask';
            for m = 2:(nfile+1)
                newstring{m} = fls(m-1).name;
            end
            set( findobj('Tag', 'maskSelect'), 'String', newstring);
            % handle the case where no masks were found
        else
            ddat.maskExist = 0;
            set( findobj('Tag', 'maskSelect'), 'Value', 1);
            set( findobj('Tag', 'maskSelect'), 'String', 'No Mask');
        end
    end


% update_viewed_component - function to load a new IC, should only be called by
% update_brain_data

%     function update_viewed_component(hObject, callbackdata)
%         
%         % IC to load
%         newIC = get(findobj('Tag', 'ICselect'), 'val');
%         
%         if strcmp(ddat.type, 'grp')
%             
%             % Load each visit
%             for iVisit = 1:ddat.nVisit
%                 newFile = [ddat.outdir '/' ddat.outpre '_aggregateIC_'...
%                     num2str(newIC) '_visit' num2str(iVisit) '.nii'];
%                 newData = load_nii(newFile);
%                 ddat.img{1, iVisit} = newData.img;
%                 ddat.oimg{1, iVisit} = newData.img;
%             end
%             
%         elseif strcmp(ddat.type, 'subpop')
%             newFile = [ddat.outdir '/' ddat.outpre '_S0_IC_' num2str(newIC) '.nii'];
%             updateSubPopulation;
%             
%         elseif strcmp(ddat.type, 'beta')
%             
%             for p = 1:ddat.p
%                 for iVisit = 1:ddat.nVisit
%                     % File name
%                     ndata = load_nii([ddat.outdir '/' ddat.outpre...
%                         '_beta_cov' num2str(p) '_IC' num2str(newIC) '_visit'...
%                         num2str(iVisit) '.nii']);
%                     
%                     ddat.img{p, iVisit} = ndata.img; ddat.oimg{p, iVisit} = ndata.img;
%                     ddat.maskingStatus{p, iVisit} = ~isnan(ddat.img{p, iVisit});
%                 end
%             end
%             
%         elseif strcmp(ddat.type, 'subj')
%             
%             generate_single_subject_map;
%             set_number_of_brain_axes(0);
%             
%         elseif strcmp(ddat.type, 'icsel')
%             ndata = load_nii([ddat.outdir '/' ddat.outpre '_iniIC_' num2str(newIC) '.nii']);
%             % need to turn the 0's into NaN values
%             zeroImg = ndata.img; zeroImg(find(ndata.img == 0)) = nan;
%             ddat.img{1} = zeroImg; ddat.oimg{1} = zeroImg;
%             % get if the checkbox should be selected
%             isSelected = get(findobj('Tag', 'icSelRef'), 'Data');
%             if strcmp(isSelected{newIC,2}, 'x')
%                 set(findobj('Tag', 'keepIC'), 'Value', 1);
%             else
%                 set(findobj('Tag', 'keepIC'), 'Value', 0);
%             end
%         elseif strcmp(ddat.type, 'reEst')
%             ndata = load_nii([ddat.outdir '/' ddat.outpre '_iniguess/' ddat.outpre '_reducedIniGuess_GroupMap_IC_' num2str(newIC) '.nii']);
%             % need to turn the 0's into NaN values
%             zeroImg = ndata.img; zeroImg(find(ndata.img == 0)) = nan;
%             ddat.img{1} = zeroImg; ddat.oimg{1} = zeroImg;
%         elseif strcmp(ddat.type, 'subPopCompare')
%             % Read in the data for the sub population in this panel
%             covariateSettings = get(findobj('Tag', 'subPopDisplay'),'Data');
%             newFile = strcat(ddat.outdir,'/',ddat.outpre,'_S0_IC_',num2str(newIC),'.nii');
%             newDat = load_nii(newFile);
%             for subPop = 1:ddat.nCompare
%                 newFunc = newDat.img;
%                 for xi = 1:ddat.p
%                     beta = load_nii([ddat.outdir '/' ddat.outpre '_beta_cov' num2str(xi) '_IC' num2str(newIC) '.nii']);
%                     xb = beta.img * str2double(covariateSettings( subPop , xi));
%                     newFunc = newFunc + xb;
%                 end
%                 ddat.img{subPop} = newFunc; ddat.oimg{subPop} = newFunc;
%             end
%         end
%         
%         
%     end



%% Brain Map Plotting

% update_brain_maps - primary function that updates the brain maps
%   being viewed
%
% Arguments:
%   'viewTrackerStatus' - Pass a new npop x nvisit matrix containing which
%                         population maps are being viewed.
%   'updateCombinedImage' - Pass a matrix with 2 colums, each row is the
%                           indices of the map that needs to regenerate the
%                           combined image

    function update_brain_maps(varargin)
        
        % Log for what steps are required (defaults here)
        updateCombinedImage = 0; updateCombinedImageElements = 0; %updateScaling=0;
        updateColorbarFlag = 1; updateMasking=0;
        
        % Determine which steps are required based on user input
        narg = length(varargin)/2;
        for iarg = 1:narg
            
            index = 2*(iarg-1) + 1;
            
            switch varargin{index}
                case 'viewTrackerStatus'
                    editTrackerRows = 1;
                    ViewTrackerNew  = varargin{index+1};
                case 'updateCombinedImage'
                    updateCombinedImage = 1;
                    updateCombinedImageElements = varargin{index+1};
                case 'updateColorbar'
                    updateColorbarFlag = varargin{index+1};
                case 'updateMasking'
                    updateMasking = varargin{index+1};
                otherwise
                    disp(['Invalid Argument: ', varargin{index}])
            end
            
        end
        
        % Load a new mask if selected
        if updateMasking == 1
            selected_mask = get(findobj('tag', 'maskSelect'), 'string');
            selected_str = get(findobj('tag', 'maskSelect'), 'value');
            if selected_str ~= 1
                fname = fullfile(ddat.outdir, fileparts(ddat.outpre), selected_mask{selected_str});
                mask_temp = load_nii(fname);
                ddat.mask = (mask_temp.img > 0);
            else
                % check that something is being viewed
                [rc, cc] = find(cellfun(@isempty, ddat.oimg) == 0)
                if length(rc) > 0
                    ddat.mask = ones(size(ddat.oimg{rc(1),cc(1)}));
                end
            end
            
            % Force image update since new mask has been loaded
            updateCombinedImage = 1;
            [rowInd, colInd] = find(ddat.viewTracker > 0);
            if size([rowInd, colInd], 2) ~= 2
                rowInd = rowInd(:); colInd = colInd(:);
            end
            updateCombinedImageElements = [rowInd, colInd];
        end
        
        
        %%% Re-create the combined images
        if updateCombinedImage == 1
            create_combined_image(updateCombinedImageElements);
        end
        
        %%% Update the images on the axes
        % TODO argument for specific axes? not sure if this case arises
        update_axes_image;
        
        % Update the colorbar
        if updateColorbarFlag == 1
            updateColorbar;
        end
        
    end

% Function to load functional data. This is the oimg attribute stored in
% ddat. Generally this function will only be called on when:
%    1. Opening the viewer 
%    2. Loading a new IC
%    3. Changing the specified sub-populations or contrasts
%
%Arguments:
%    indices - elements of viewTable that are to be loaded.
%

    function load_functional_images(indices)
        
        % This is a check in case we forgot to provide the indices argument
        % needed for some cases where this is called from a button press
        if ~exist('indices', 'var')
            [rowInd, colInd] = find(ddat.viewTracker > -999);
            if size([rowInd, colInd], 2) ~= 2
                rowInd = rowInd(:); colInd = colInd(:);
            end
            indices = [rowInd, colInd];
        end
        
        % Determine the currently selected component
        sel_IC = get(findobj('tag', 'ICselect'), 'value');
        
        % Clear out the images
        ddat.oimg = {};
        ddat.img = {};
        
        switch ddat.type
            
            % Load the group aggregate map
            case 'grp'
                
                % Load each visit
                for iVisit = 1:ddat.nVisit
                    
                    newFile = [ddat.outdir '/' ddat.outpre '_aggregateIC_'...
                        num2str(sel_IC) '_visit' num2str(iVisit) '.nii'];
                    newData = load_nii(newFile);
                    %ddat.img{1, iVisit} = newData.img;
                    ddat.oimg{1, iVisit} = newData.img;
                    ddat.maskingStatus{1, iVisit} = ~isnan(ddat.oimg{1, iVisit});
                    
                end
               
            case 'beta'
                                
                % Load each of the betas
                beta_raw = {};
                for p = 1:ddat.p
                    for iVisit = 1:ddat.nVisit
                        
                        % File name
                        ndata = load_nii([ddat.outdir '/' ddat.outpre...
                            '_beta_cov' num2str(p) '_IC' num2str(sel_IC) '_visit'...
                            num2str(iVisit) '.nii']);

                        beta_raw{p, iVisit} = ndata.img;
                        
                    end
                end
                
                % Check if currently using the contrast view
                contrast_selected = strcmp(get(get(findobj('tag',...
                'EffectTypeButtonGroup'), 'SelectedObject'),...
                'String'), 'Contrast View');
                
                if contrast_selected
                    
                    % Check to make sure a contrast has been specified
                    if size(ddat.LC_contrasts, 1) > 0
                    
                    % Fill out each linear combination based on indices
                    nUpdate = size(indices, 1); 
                    
                    for iUpdate = 1:nUpdate
                        disp('add random intercept')
                        disp('check for interactions')
            
                        % Cell to update
                        iRow = indices(iUpdate, 1); iCol = indices(iUpdate, 2);
                        
                        % The column of the contrast is the linear
                        % combination currently viewing
                        ddat.oimg{iRow, iCol} = zeros(size(beta_raw{1, 1}));
                        ddat.maskingStatus{iRow, iCol} = ~isnan(beta_raw{1, 1});
                        % Main Effects
                        for xi = 1:ddat.p
                            ddat.oimg{iRow, iCol} = ddat.oimg{iRow, iCol} + ...
                                str2double(ddat.LC_contrasts{iRow, xi}) .* beta_raw{xi, iCol};
                        end
                    end
                    end
                    
                else
                    
                    % If currently viewing the raw beta values, then assign all
                    % of them
                    for p = 1:ddat.p
                        for iVisit = 1:ddat.nVisit
                            ddat.oimg{p, iVisit} = beta_raw{p, iVisit};
                            ddat.maskingStatus{p, iVisit} = ~isnan(ddat.oimg{p, iVisit});
                        end
                    end
                    
                end             
                
            case 'subpop'
                
                % Load each of the betas and the S_0 maps
                beta_raw = {};
                for p = 1:ddat.p
                    for iVisit = 1:ddat.nVisit
                        
                        % File name
                        ndata = load_nii([ddat.outdir '/' ddat.outpre...
                            '_beta_cov' num2str(p) '_IC' num2str(sel_IC) '_visit'...
                            num2str(iVisit) '.nii']);

                        beta_raw{p, iVisit} = ndata.img;                     
                    end
                end
                
                % File name for S0 Map
                newFile = [ddat.outdir '/' ddat.outpre '_S0_IC_'...
                    num2str(sel_IC) '.nii'];
                newData = load_nii(newFile);
                S0_maps = newData.img;
                
                % Check to make sure a subpopulation has been specified
                if size(ddat.LC_subpops, 1) > 0

                % Fill out each linear combination based on indices
                nUpdate = size(indices, 1); 

                for iUpdate = 1:nUpdate
                    disp('add random intercept')
                    disp('check for interactions')

                    % Cell to update
                    iRow = indices(iUpdate, 1); iCol = indices(iUpdate, 2);

                    % The column of the contrast is the linear
                    % combination currently viewing
                    ddat.oimg{iRow, iCol} = S0_maps;
                    ddat.maskingStatus{iRow, iCol} = ~isnan(S0_maps);
                    
                    % Main Effects
                    for xi = 1:ddat.p
                        ddat.oimg{iRow, iCol} = ddat.oimg{iRow, iCol} + ...
                            str2double(ddat.LC_subpops{iRow, xi}) .* beta_raw{xi, iCol};
                    end
                end
                end
                
            case 'subject'
                updateMasking = varargin{index+1};
            case 'iniguess'
                updateMasking = varargin{index+1};    
            otherwise
                disp('CHECK VIEWTYPE SPECIFICATION')
                
        end
        
        % TODO Find a better way to do this. In most cases oimg will be filled
        % out here. Exception is opening subpop viewer. Then we need
        % something for the function to cehck for dimensions -> use s0 map
        if strcmp(ddat.type, 'subpop')
            refimg = S0_maps;
        else
            refimg = ddat.oimg{1, 1};
        end
        
        % Check if all of the anatomical image/dimension bookkeeping needs
        % to be performed. This should only need to happen upon first
        % opening the view window.

              
        % Get the size of each dimension.
        if ~isfield(ddat, 'xdim')
            dim = size(refimg);
            ddat.xdim = dim(1); ddat.ydim = dim(2); ddat.zdim = dim(3);
            ddat.betaVarEst = zeros(ddat.p, ddat.p, ddat.xdim, ddat.ydim, ddat.zdim);

            % Make sure the anatomial image matches
            setupAnatomical;

            % Update the crosshair information
                    % Get the crosshair origin information.
            ddat.pixdim = double(ddat.mri_struct.hdr.dime.pixdim(2:4));
            if any(ddat.pixdim <= 0)
                ddat.pixdim(find(ddat.pixdim <= 0)) = 1;
            end
            origin = abs(ddat.mri_struct.hdr.hist.originator(1:3));
            if isempty(origin) || all(origin == 0)		% according to SPM
                origin = (dim+1)/2;
            end
            origin = round(origin);
            if any(origin > dim)				% simulate fMRI
                origin(find(origin > dim)) = dim(find(origin > dim));
            end
            if any(origin <= 0)
                origin(find(origin <= 0)) = 1;
            end
            ddat.daspect = ddat.pixdim ./ min(ddat.pixdim);
            ddat.origin = origin; ddat.sag = origin(1); ddat.cor = origin(2);
            ddat.axi = origin(3);
            ddat.roi_voxel = 0.1;

            % Load the brain region information
            brodmannMap = load('templates/BrodmannRegionMap.mat');
            RegionMap = load_nii('templates/brodmann_RPI_MNI_2mm.nii');
            % Load the correct Region Map if not in 2mm space
            if ddat.xdim == 182 && ddat.ydim == 218 && ddat.zdim == 182
                RegionMap = load_nii('templates/brodmann_RPI_MNI_1mm.nii');
            elseif ddat.xdim == 61 && ddat.ydim == 73 && ddat.zdim == 61
                RegionMap = load_nii('templates/brodmann_RPI_MNI_3mm.nii');
            elseif ddat.xdim == 45 && ddat.ydim == 54 && ddat.zdim == 45
                RegionMap = load_nii('templates/brodmann_RPI_MNI_4mm.nii');
            end
            RegionName = brodmannMap.brodmann(:, 1:2);
            ddat.total_region_name = RegionName;
            ddat.region_struct = RegionMap;
        end
        
        % Set correct number of axes
        set_number_of_brain_axes(1)
        
        % Check mask status
        maskSearch;
        
        % Now that oimg has been updated, need to carry out the rest of the
        % steps:
        disp('figure out args here')
        update_brain_data('updateMasking', 1);
        
    end





% New version of the create combined image function
% issue is with what to scale by... XXXXX
    function create_combined_image(indices)
        
        nUpdate = size(indices, 1);
        
        % Find the min and max value of each image.
        minVal1 = min(min(min(cat(1,ddat.img{:}))));
        maxVal1 = max(max(max(cat(1,ddat.img{:}))));
        
        % Get user selected cutoff
        cutoff = get( findobj('Tag', 'thresholdSlider'), 'value');
        set( findobj('Tag', 'manualThreshold'), 'string', num2str(cutoff) );
        
        for iUpdate = 1:nUpdate
            
            % Cell to update
            iRow = indices(iUpdate, 1); iCol = indices(iUpdate, 2);
            
            % Scale the functional image
            tempImage = ddat.img{iRow, iCol};
            tempImage(ddat.maskingStatus{iRow, iCol} == 0 ) = nan;
            tempImage(isnan(tempImage)) = minVal1 - 1;
            minVal2 = minVal1 - 1;
            ddat.scaledFunc{iRow, iCol} = scale_in(tempImage, minVal2, maxVal1, 63);
            
        
            % Loop over sub populations and update threshold.
            ddat.maskingStatus{iRow, iCol} = (abs(ddat.img{iRow, iCol}) >= cutoff);
    
            
            % Apply the Mask and then the slider based threshold
            %TODO for maskingStatus, Irow and icol might be flipped!
            maskedFunc = ddat.scaledFunc{iRow, iCol} .* ddat.mask .* ddat.maskingStatus{iRow, iCol};
            maskedFunc(maskedFunc == 0) = 1;
            
            newColormap = [(gray(191));zeros(1, 3); ddat.highcolor];%%index 192 is not used, just for seperate the base and top colormap;
            
            ddat.combinedImg{iRow, iCol} = overlay_w_transparency(uint16(ddat.scaledImg),...
                uint16( maskedFunc ),...
                1, 0.6, newColormap, ddat.highcolor);
            
        end
        
    end

% New version to replot on axes (former redisplay) - this needs to account
% for which axes corresponds to which element of cell array!, use
% ViewTracker for this! - gives which axes each belongs to
    function update_axes_image(varargin)
        
        [nRow, nCol] = size(ddat.oimg);
        
        aspect = 1./ddat.daspect;
        
        for iRow = 1:nRow
            for iCol = 1:nCol
                
                % Check that this is in view before redisplaying
                if ddat.viewTracker(iRow, iCol) > 0
                    
                    % Get the corresponding axes. This SHOULD be in
                    % numerical order, but we include extra step here just
                    % to be safe
                    axes_index = ddat.viewTracker(iRow, iCol);
                    
                    % Grab the data for the selected slices and update axes obj.
                    for cl = 1:3
                        Saxi(:, :, cl) = squeeze(ddat.combinedImg{iRow, iCol}(cl).combound(:, :, ddat.axi))';
                        Scor(:, :, cl) = squeeze(ddat.combinedImg{iRow, iCol}(cl).combound(:,ddat.cor,:))';
                        Ssag(:, :, cl) = squeeze(ddat.combinedImg{iRow, iCol}(cl).combound(ddat.sag,:,:))';
                    end
                    ddat.cor_mm = (ddat.cor-ddat.origin(2))*ddat.pixdim(2);
                    
                    axesC = (findobj('Tag', ['CoronalAxes' num2str(iRow) '_' num2str(iCol)] ));
                    %daspect(axesC, aspect([1 3 2]));
                    ddat.coronal_image{iRow, iCol} = image(axesC, Scor); % TODO can I do this step somewhere else?
                    % re-add the tag b/c matlab deletes it for some reason
                    set(axesC, 'tag', ['CoronalAxes' num2str(iRow) '_' num2str(iCol)]);
                    set(ddat.coronal_image{iRow, iCol},'CData', Scor);
                    %ddat.axial_image{subPop, currentVisitIndex} = image(Scor);
                    % stuff below this can all be done when the item is
                    % created!!!!
                    set(axesC,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                        'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],...
                        'xtick',[],'ytick',[],...
                        'Tag',['CoronalAxes' num2str(iRow) '_' num2str(iCol)])
                    daspect(axesC,aspect([1 3 2]));
                    
                    set(ddat.coronal_image{iRow, iCol},'ButtonDownFcn',...
                        {@image_button_press, 'cor'});
                    pos_cor = [ddat.sag, ddat.axi];
                    crosshair = plot_crosshair(pos_cor, [], axesC);
                    ddat.coronal_xline{iRow, iCol} = crosshair.lx;
                    ddat.coronal_yline{iRow, iCol} = crosshair.ly;
                    
                   
                    
                    
                    axesC = (findobj('Tag', ['AxialAxes' num2str(iRow) '_' num2str(iCol)] ));
                    ddat.axial_image{iRow, iCol} = image(axesC, Saxi);
                    % re-add the tag b/c matlab deletes it for some reason
                    set(axesC, 'tag', ['AxialAxes' num2str(iRow) '_' num2str(iCol)]);
                    set(ddat.axial_image{iRow, iCol},'CData',Saxi);
                    set(axesC,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                        'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],...
                        'xtick',[],'ytick',[],...
                        'Tag',['AxialAxes' num2str(iRow) '_' num2str(iCol)])
                    daspect(axesC,aspect([1 3 2]));
                    set(ddat.axial_image{iRow, iCol},'ButtonDownFcn',...
                        {@image_button_press, 'axi'});
                    pos_axi = [ddat.sag, ddat.cor];
                    crosshair = plot_crosshair(pos_axi, [], axesC);
                    ddat.axial_xline{iRow, iCol} = crosshair.lx;
                    ddat.axial_yline{iRow, iCol} = crosshair.ly;
                    
                    
                    axesC = (findobj('Tag', ['SagittalAxes' num2str(iRow) '_' num2str(iCol)] ));
                    ddat.sagittal_image{iRow, iCol} = image(axesC, Ssag);
                    % re-add the tag b/c matlab deletes it for some reason
                    set(axesC, 'tag', ['SagittalAxes' num2str(iRow) '_' num2str(iCol)]);
                    set(ddat.sagittal_image{iRow, iCol},'CData',Ssag);
                    set(axesC,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                        'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],...
                        'xtick',[],'ytick',[],...
                        'Tag',['SagittalAxes' num2str(iRow) '_' num2str(iCol)])
                    daspect(axesC,aspect([2 3 1]));
                    set(ddat.sagittal_image{iRow, iCol},'ButtonDownFcn',...
                        {@image_button_press, 'sag'});
                    pos_sag = [ddat.cor, ddat.axi];
                    crosshair = plot_crosshair(pos_sag, [], axesC);
                    %crosshair = plot_crosshair(pos_sag);
                    ddat.sagittal_xline{iRow, iCol} = crosshair.lx;
                    ddat.sagittal_yline{iRow, iCol} = crosshair.ly;
                    
                  
                end
                
            end
        end
        
        % Update the position information text
        [validRow, validCol] = find(ddat.viewTracker > 0);       
        if ~isempty(validRow)
            position_information_update((findobj('Tag', ['SagittalAxes' num2str(validRow(1)) '_' num2str(validCol(1))] )))
            
            % Update the crosshair information text
            set(findobj('Tag', 'crosshairPos'),'String',...
            sprintf('%7.0d %7.0d %7.0d',ddat.sag,ddat.cor, ddat.axi));
        end
        
    end

%% Functions related to the underlying brain data

% update_brain_data
% Arguments
% setZStatus '0' for raw values '1' for zscores
% updateMasking tells this function to tell THE NEXT function to reload the
% mask. This is required if we are switching images back and forth
    function update_brain_data(varargin)
        
        % Default values
        setICMap = -1;
        updateImg = -1;
        indices = [];
        updateMasking = 0;
        
        % Determine which steps are required based on user input
        narg = length(varargin)/2;
        
        disp('get rid of setICmap argument..., now handled earlier in chain')
        
        % Make sure an actual argument was provided
        if narg > 0
        for iarg = 1:narg
            index = 2*(iarg-1) + 1;
            switch varargin{index}
                case 'setICMap'
                    setICMap  = varargin{index+1};
                case 'updateMasking'
                    updateMasking = varargin{index+1};
                otherwise
                    disp(['Invalid Argument: ', varargin{index}])
            end
        end
        end
        
        % Load a new IC Map, if requested
        if setICMap > -1
            update_viewed_component;
        end
        

        % Update the Z-score status, always done if this function triggers
        update_Z_maps;       
        
        % Move chain on to UPDATE_BRAIN_MAPS
        [rowInd, colInd] = find(ddat.viewTracker > 0);
        
        if size([rowInd, colInd], 2) ~= 2
            rowInd = rowInd(:); colInd = colInd(:);
        end
        
        if ~isempty(rowInd)
            update_brain_maps('updateCombinedImage', [rowInd, colInd],...
                'updateMasking', updateMasking);
        else
            update_brain_maps('updateMasking', updateMasking);
        end
        
    end


%% Slider Movement

% Update sagittal slider.
    function sagSliderMove(hObject, callbackdata)
        
        [nRow, nCol] = size(ddat.img);
        
        ddat.sag = round(get(hObject, 'Value'));
        disp('sag slider moved')
  
        update_axes_image;
    end

% Update coronal slider.
    function corSliderMove(hObject, callbackdata)
        ddat.cor = round(get(hObject, 'Value'));
        
        [nRow, nCol] = size(ddat.img);
        
        % This is to update the axes info text.
        %set_number_of_brain_axes(0);
        update_axes_image;
    end

% Update axial slider.
    function axiSliderMove(hObject, callbackdata)
        
        [nRow, nCol] = size(ddat.img);
        
        ddat.axi = round(get(hObject, 'Value'));

        update_axes_image;
        
    end



  function create_mask(hObject, callbackdata)        
        
        % Open the mask creation window and get:
        %   1. The type of mask to be created (single, union, intersect, cancel)
        %   2. The contributing nifti files
        visit_list = get(findobj('tag', 'ViewSelectTable'), 'RowName');
        [mask_gui_output, selected_visits] = MaskSelectionWindow(visit_list);
        
        % Only create a mask if the gui did not return cancel
        if ~strcmp(mask_gui_output, 'cancel')
            
            mask_fname = '';
            
            threshold = str2double(get(findobj('Tag', 'manualThreshold'), 'string'));
            
            % Create the mask based on the user's selection
            switch mask_gui_output
                
                case 'Single-Visit Mask'
                    disp('Creating single visit mask')
                    mask_fname = strcat(ddat.outdir, '/' , ddat.outpre, '_SingleVisit_maskIC_',...
                        num2str(get(findobj('Tag', 'ICselect'), 'Value')), '_zthresh_',...
                        get(findobj('Tag', 'manualThreshold'), 'string'),...
                        '_Visit_', sprintf('%.0f_' , selected_visits), '.nii');
                    
                    % Create the mask
                    new_mask = (abs(ddat.img{selected_visits}) >= threshold);
                    
                case 'Union Mask'
                    disp('Creating union mask')
                    mask_fname = strcat(ddat.outdir, '/' , ddat.outpre, '_Union_maskIC_',...
                        num2str(get(findobj('Tag', 'ICselect'), 'Value')), '_zthresh_',...
                        get(findobj('Tag', 'manualThreshold'), 'string'),...
                        '_Visits_', sprintf('%.0f_' , selected_visits), '.nii');
                    
                    % Create the mask
                    new_mask = zeros(size(ddat.img{1}));
                    for ivisit = 1:length(selected_visits)
                        new_mask = new_mask + (abs(ddat.img{selected_visits(ivisit)}) >= threshold);
                    end
                    % union mask can end up with larger values (counts),
                    % this line is to make them all 1s or 0s
                    new_mask = (new_mask > 0);
                    
                case 'Intersection Mask'
                    
                    disp('Creating intersection mask')
                    mask_fname = strcat(ddat.outdir, '/' , ddat.outpre, '_Intersect_maskIC_',...
                        num2str(get(findobj('Tag', 'ICselect'), 'Value')), '_zthresh_',...
                        get(findobj('Tag', 'manualThreshold'), 'string'),...
                        '_Visits_', sprintf('%.0f_' , selected_visits), '.nii');
                    
                    % Create the mask
                    new_mask = ones(size(ddat.img{1}));
                    for ivisit = 1:length(selected_visits)
                        new_mask = new_mask .* (abs(ddat.img{selected_visits(ivisit)}) >= threshold);
                    end
                    
            end
            
            disp(['Saving ' mask_fname])
            
            save_nii(make_nii(double(new_mask)), mask_fname);
            
            maskSearch;
        end % end of check that user did not cancel in mask window
    end


%% Old Viewing Functions


% Function called when the user selected a button from the
% EffectViewButtonGroup

% TODO check if this is what is already being viewed?
    function beta_typeof_view_select(hObject, callbackdata)
        
        %disp('REMOVE THE LOADING HERE, IT SHOULD BE HAPPENING ON FN CALL')
        
        % Effect view was selected -> load corresponding betas
        if strcmp(callbackdata.Source.String, 'Effect View')
            
            % Edit the view selection table
            setup_ViewSelectTable;
            
%             % load each beta map for each visit
%             for p = 1:ddat.p
%                 for iVisit = 1:ddat.nVisit
%                     
%                     disp('this needs to call load_functional_image!!!')
%                     % File name
%                     ndata = load_nii([ddat.outdir '/' ddat.outpre...
%                         '_beta_cov' num2str(p) '_IC1_visit'...
%                         num2str(iVisit) '.nii']);
%                     
%                     ddat.img{p, iVisit} = ndata.img; ddat.oimg{p, iVisit} = ndata.img;
%                     ddat.maskingStatus{p, iVisit} = ~isnan(ddat.img{p, iVisit});
%                     
%                 end
%             end
            
            % Contrast View
        else
            
            setup_ViewSelectTable;
            disp('set this!')
            
            % If an archived view table is present, then load it, otherwise
            % setup a default view table based on the number of contrasts.
            %ddat.viewTable
            
            % Create each specified contrast
            %generate_img_linear_combination();
            
        end
        
        % Update the brain display to reflect the new images
        disp('is this really the right indexing to use, I think "yes" for contrasts??')
        [rowInd, colInd] = find( ones(size(ddat.viewTracker)) > 0);
        
        if size([rowInd, colInd], 2) ~= 2
            rowInd = rowInd(:); colInd = colInd(:);
        end
        
        load_functional_images( [rowInd, colInd] );
        
    end



% Function to allow the user to specifiy covariates for a new
% sub-population.
% Updated for new display viewer (1/7/19)
    function newPopCellEdit(hObject, callbackdata)
        
        % When the user edits a cell, need to make sure that it is a valid level
        coledit = callbackdata.Indices(2);
        % Make sure input value is a number and not a string
        %if all(ismember(callbackdata.NewData, '0123456789+-.eEdD')) & ~isempty(callbackdata.NewData)
        if all(ismember(callbackdata.NewData, '0123456789.-')) & ~isempty(callbackdata.NewData)
            % check if the edited cell is categorical, should be binary
            if length(unique(ddat.X(:, coledit))) == 2
                if ~(str2num(callbackdata.NewData) == 1 || str2num(callbackdata.NewData) == 0)
                    warndlg('Categorical covariates should be set to either 0 or 1', 'Data input error');
                    newTable = get(findobj('Tag', 'subPopDisplay'), 'Data');
                    newTable(callbackdata.Indices(1), coledit) = {''};
                    set(findobj('Tag', 'subPopDisplay'), 'Data', newTable);
                end
            else
                % make sure it is in the range of values recorded before
                minval = min(ddat.X(:,coledit));
                maxval = max(ddat.X(:,coledit));
                if (str2num(callbackdata.NewData) < minval || str2num(callbackdata.NewData) > maxval)
                    warndlg('The value input is more extreme than any value for this covariate in the data set', 'Warning');
                end
            end
        else
            warndlg('Please input a number, see covariate table for examples', 'Warning');
            newTable = get(findobj('Tag', 'subPopDisplay'), 'Data');
            newTable(callbackdata.Indices(1), coledit) = {[]};
            set(findobj('Tag', 'subPopDisplay'), 'Data', newTable);
        end
        [nsubpop ign] = size( get(findobj('Tag', 'subPopSelect'),'String'));
        
        % Check if all main effects are now filled out. If so, update the
        % interactions, otherwise set them to zero
        factorValues = callbackdata.Source.Data{1:length(ddat.covTypes)};
        allFilledOut = 1;
        rowIndex = callbackdata.Indices(1);
        for iCov=1:length(ddat.varNamesX)
            if isempty(callbackdata.Source.Data{rowIndex, iCov})
                allFilledOut = 0;
            end
        end
        
        % If all factors are filled out, then update the interactions
        if allFilledOut == 1
            nInt = size(ddat.interactions, 1);
            nCov = size(ddat.interactions, 2);
            for iInt = 1:nInt
                interactionValue = 1;
                for iCov = 1:nCov
                    if ddat.interactions(iInt, iCov) == 1
                        interactionValue = interactionValue *...
                            str2double(callbackdata.Source.Data{callbackdata.Indices(1), iCov});
                    end
                end
                callbackdata.Source.Data{callbackdata.Indices(1), nCov+iInt} = num2str(interactionValue);
            end
        end
        
        % TODO this is where I am with editing this function
        
        % TODO this + below should be replaced by a check if the currently edited sub
        % population is also being viewed. I think the "updateSubPopulation"
        % call can be removed entirely.
        if (nsubpop == 1)
            for iPop = 1:ddat.nCompare
                updateSubPopulation(findobj('Tag', ['subPopSelect' num2str(iPop)]));
            end
        end
        ddat.subPopExists = 1;
        
        % If the data are all filled out AND the current selection is the
        % one that was edited, update the display image
        updatedViewing = 0;
        updatedRow = callbackdata.Indices(1);
        if updatedRow == get(findobj('tag',  ['subPopSelect' num2str(1)]), 'value')
            updatedViewing = 1;
        end
        if updatedViewing && allFilledOut
            if strcmp(ddat.type, 'beta')
                if ddat.viewingContrast == 1
                    updateContrastDisp;
                end
            else
                updateSubPopulation;
            end
        end
        
        
        
        
    end

   % Function updating user-specific linear combinations (contrasts or sub
   % populations. Replaces newPopCellEdit from previous version of the
   % toolbox.
   function update_linear_combination(hObject, callbackdata)
        
        % When the user edits a cell, need to make sure that it is a valid level
        valid = check_valid_covariate_value(callbackdata);
        
        disp('add valid check before proceeding.')
        
        [nsubpop ign] = size( get(findobj('Tag', 'subPopSelect'),'String'));
        
        % Check if all main effects are now filled out. If so, update the
        % interactions, otherwise set them to zero
        rowIndex = callbackdata.Indices(1);
        allFilledOut = ~any(cellfun(@isempty,...
            callbackdata.Source.Data(rowIndex, :)));
        
        % If all factors are filled out, then update the interactions
        if allFilledOut == 1
            [nInt, nCov] = size(ddat.interactions);
            for iInt = 1:nInt
                interactionValue = 1;
                for iCov = 1:nCov
                    if ddat.interactions(iInt, iCov) == 1
                        interactionValue = interactionValue *...
                            str2double(callbackdata.Source.Data{callbackdata.Indices(1), iCov});
                    end
                end
                callbackdata.Source.Data{callbackdata.Indices(1), nCov+iInt} = num2str(interactionValue);
            end
            
            % Update appropriate LC list, note this is different from
            % viewtable, which only gets updated to match this if currently
            % viewing that type. These variables are stored in the
            % background, even if we switch viewer types
            %LC = cellfun(@str2num, callbackdata.Source.Data(callbackdata.Indices(1), :));
            if strcmp(ddat.type, 'beta')
                ddat.LC_contrasts = callbackdata.Source.Data; 
                ddat.valid_LC_contrast(callbackdata.Indices(1)) = 1; 
                
                % Update the size of saved viewTracker
                if size(callbackdata.Source.Data, 1) > size(ddat.saved_contrast_viewTracker, 1)
                    ddat.saved_contrast_viewTracker = [ddat.saved_contrast_viewTracker; zeros(1, ddat.nVisit)];
                end
                
            else
                ddat.LC_subpops = callbackdata.Source.Data;
                ddat.valid_LC_subpop(callbackdata.Indices(1)) = 1; 
                
                % Update the size of saved viewTracker
                if size(callbackdata.Source.Data, 1) > size(ddat.saved_subpop_viewTracker, 1)
                    ddat.saved_subpop_viewTracker = [ddat.saved_subpop_viewTracker; zeros(1, ddat.nVisit)];
                end
                
            end
            
            contrast_selected = strcmp(get(get(findobj('tag',...
                'EffectTypeButtonGroup'), 'SelectedObject'),...
                'String'), 'Contrast View');
            
            % Update the size of viewtable
            if (strcmp(ddat.type, 'beta') && contrast_selected )...
                    || strcmp(ddat.type, 'subpop')
                
                % Update the view table appropriately
                setup_ViewSelectTable;
                
                [rowInd, colInd] = find( ones(size(ddat.viewTracker)) > 0);
                
                if size([rowInd, colInd], 2) ~= 2
                    rowInd = rowInd(:); colInd = colInd(:);
                end
                
                load_functional_images( [rowInd, colInd] );                
            end
            
        % If the entire row is not filled out, be sure to disable contrast    
        else
            
            if strcmp(ddat.type, 'beta')
                ddat.valid_LC_contrast(callbackdata.Indices(1)) = 0; 
            else
                ddat.valid_LC_subpop(callbackdata.Indices(1)) = 0; 
            end
            
            % TODO remove from view table
        
        end
        
        % TODO check whether need to update view table, if a LC is now
        % invalid, corresponding row of view table needs to be turned off
        
   end

    % Function to test that a user-specified covariate value is valid.
    % Called by update_linear_combination after the user updates a cell.
    function [valid] = check_valid_covariate_value(callbackdata)
        
        coledit = callbackdata.Indices(2);
        
        valid = true;
        
        % Make sure input value is a number and not a string
        %if all(ismember(callbackdata.NewData, '0123456789+-.eEdD')) & ~isempty(callbackdata.NewData)
        if all(ismember(callbackdata.NewData, '0123456789.-')) & ~isempty(callbackdata.NewData)
            % check if the edited cell is categorical, should be binary
            if length(unique(ddat.X(:, coledit))) == 2
                if ~(str2num(callbackdata.NewData) == 1 || str2num(callbackdata.NewData) == 0)
                    warndlg('Categorical covariates should be set to either 0 or 1', 'Data input error');
                    newTable = get(findobj('Tag', 'subPopDisplay'), 'Data');
                    newTable(callbackdata.Indices(1), coledit) = {''};
                    set(findobj('Tag', 'subPopDisplay'), 'Data', newTable);
                    valid = false;
                end
            else
                % make sure it is in the range of values recorded before
                minval = min(ddat.X(:,coledit));
                maxval = max(ddat.X(:,coledit));
                if (str2num(callbackdata.NewData) < minval || str2num(callbackdata.NewData) > maxval)
                    warndlg('The value input is more extreme than any value for this covariate in the data set', 'Warning');
                end
            end
        else
            warndlg('Please input a number, see covariate table for examples', 'Warning');
            newTable = get(findobj('Tag', 'subPopDisplay'), 'Data');
            newTable(callbackdata.Indices(1), coledit) = {[]};
            set(findobj('Tag', 'subPopDisplay'), 'Data', newTable);
            valid = false;
        end
        
    end






% This is the function that handles editing the img object for different
% contrasts and sub-populations.
%
% Difference between the contrast and sub-pop is that the sub-pop starts
% with the S0 map

% LC_index is the index of the linear combination (sub pop or contrast)
% that we are currently interested in.
    function generate_img_linear_combination(LC_index)
        
        
        % If current viewer type is beta window -> setup a contrast
        if strcmp(ddat.type, "beta")
            
            % Pick off the user-specfied coefficients for the linear combination
            all_LC = get(findobj('tag', 'XXX'), 'data');
            sel_LC = all_LC(:, LC_index);
            
            % This is the old way of loading the contrast.
            % Load the first regression coefficient
            beta = load_nii([ddat.outdir '/' ddat.outpre '_beta_cov' num2str(1) '_IC' num2str(newIC) '.nii']);
            newFunc = beta.img .* str2double(contrastSettings( get(findobj('Tag',...
                ['contrastSelect' num2str(viewer)]), 'Value') , 1));
            
            % Load the remaining pieces
            for xi = 2:ddat.p
                
                beta = load_nii([ddat.outdir '/' ddat.outpre '_beta_cov' num2str(xi) '_IC' num2str(newIC) '.nii']);
                max(max(max(beta.img)))
                
                xb = beta.img .* str2double(contrastSettings( get(findobj('Tag',...
                    ['contrastSelect' num2str(viewer)]), 'Value') , xi));
                newFunc = newFunc + xb;
            end
            
            % This will be the new way of loading the contrast
            for p = 1:ddat.p
                for iVisit = 1:ddat.nVisit
                    
                    % Load the File
                    ndata = load_nii([ddat.outdir '/' ddat.outpre...
                        '_beta_cov' num2str(p) '_IC1_visit'...
                        num2str(iVisit) '.nii']);
                    
                    % Apply the contrast funciton
                    
                    
                    ddat.img{p, iVisit} = ndata.img;
                    ddat.oimg{p, iVisit} = ndata.img;
                    ddat.maskingStatus{p, iVisit} = ~isnan(ddat.img{p, iVisit});
                    
                end
            end
            
            % If current viewer type is sub-population window
        else
            disp('Generate linear combination not yet defined for this type of viewer.')
        end
        
    end









%% Currently Here



%% Function to update the colorbar
    function updateColorbar(hObject, callbackdata)
        
        maxval1 = -Inf; minval1 = Inf;
        
        if sum(ddat.viewTracker(:) > 0) > 0
            
            minval1 = min(min(min(cat(1,ddat.img{:}))));
            maxval1 = max(max(max(cat(1,ddat.img{:}))));
            
        % Handle case where no maps are being viewed
        else
            minval1 = 0; maxval1 = 0;
        end
        
        max_functmap_value = maxval1; min_functmap_value = minval1;
        incr_val=max_functmap_value/5;
        int_part=floor(incr_val); frac_part=incr_val-int_part;
        incr = int_part + round(frac_part*10)/10;
        % handle case where incr is 0 because the values are too small;
        if incr == 0
            incr = 0.05;
        end
        % Update the labels for the colorbar
        ddat.colorbar_labels = (min_functmap_value):incr:max_functmap_value;
        %ddat.colorbar_labels = round(ddat.colorbar_labels,2);
        ddat.colorbar_labels = fix(ddat.colorbar_labels*100)/100;
        ddat.scaled_pp_labels = scale_in(ddat.colorbar_labels, min_functmap_value, max_functmap_value, 63);
        % Update the colorbar
        axes(findobj('Tag', 'colorMap'));
        set(gca,'NextPlot','add')
        colorbar_plot( findobj('Tag', 'colorMap'), ddat.colorbar_labels, ddat.scaled_pp_labels);
        
    end

%% Data Loading Functions

%% Crosshair and Information

% Function to update the value at crosshair when user clicks on a slice
    function updateCrosshairValue(hObject, callbackdata)
        % Handle case where only one image is being viewed
        if ddat.nCompare == 1
            if get(findobj('Tag', 'viewZScores'), 'Value') == 0
                set(findobj('Tag', 'crosshairVal1'),'String',...
                    sprintf('Value at Voxel: %4.2f', ddat.img{1}(ddat.sag, ddat.cor, ddat.axi)));
            elseif get(findobj('Tag', 'viewZScores'), 'Value') == 1
                set(findobj('Tag', 'crosshairVal1'),'String',...
                    sprintf('Z = %4.2f', ddat.img{1}(ddat.sag, ddat.cor, ddat.axi)));
            end
            % Handle case where images are being compared
        else
            if get(findobj('Tag', 'viewZScores'), 'Value') == 0
                for iPop = 1:ddat.nCompare
                    set(findobj('Tag', ['crosshairVal' num2str(iPop)]),'String',...
                        sprintf('Value at Voxel: %4.2f',...
                        ddat.img{iPop}(ddat.sag, ddat.cor, ddat.axi)));
                end
            else
                for iPop = 1:ddat.nCompare
                    set(findobj('Tag', ['crosshairVal' num2str(iPop)]),'String',...
                        sprintf('Z = %4.2f',...
                        ddat.img{iPop}(ddat.sag, ddat.cor, ddat.axi)));
                end
            end
        end
    end


% Function to check the status of the Z-score button and update .img
% attribute of ddat accordingly. Replaces the old updateZImg function

    function update_Z_maps(~)
        
        % Check if Z-scroes are enabled or disabled
        Z_enabled = get(findobj('Tag', 'viewZScores'), 'Value');
        
        % Number of currently selected independent component
        current_IC = get(findobj('Tag', 'ICselect'), 'val');
        
        % If looking at effect/contrast maps, go ahead and load all of the
        % variances for the currently selected IC and visits, this way we do not keep
        % reloading them during the loop
        current_vars = {};
        if strcmp('beta', ddat.type) && (Z_enabled == 1)
            for iVisit = 1:size(ddat.viewTracker, 2)
                newMap = load(fullfile(ddat.outdir, [ddat.outpre '_BetaVarEst_IC'...
                    num2str(current_IC) '_visit' num2str(iVisit) '.mat']));
                current_vars{iVisit} = newMap.betaVarEst;
            end
        end
        
        for iPop = 1:size(ddat.viewTracker, 1)
            for iVisit = 1:size(ddat.viewTracker, 2)
                %if ddat.viewTracker(iPop, iVisit) > 0
                    
                    % Turn on Z-scores
                    if Z_enabled == 1
                        
                        if strcmp('beta', ddat.type)
                            
                            if (ddat.viewingContrast == 0)
                                
                                % TODO preallcoate and stop re-doing this
                                % using above current vars
                                current_var_est = current_vars{iVisit};
                                
                                % Scale using the theoretical variance estimate
                                % theoretical estimate is q(p+1) * q(p+1)
                                ddat.img{iPop, iVisit} = ddat.oimg{iPop, iVisit} ./...
                                    sqrt(squeeze( current_var_est( iPop, iPop, :,:,: )));
                                
                                
                            end
                            
                            if (ddat.viewingContrast == 1)
                                contrastSettings = get(findobj('Tag', 'contrastDisplay'), 'Data');
                                % Load the contrast
                                c = zeros(ddat.p,1);
                                for xi = 1:ddat.p
                                    c(xi) = str2double(contrastSettings( get(findobj('Tag',...
                                        ['contrastSelect' num2str(1)]), 'Value') , xi));
                                end
                                % Get the variance estimate; loop over each voxel
                                seContrast = sqrt(squeeze(mtimesx(mtimesx(c', ddat.betaVarEst), c)));
                                ddat.img{subPop} = ddat.oimg{subPop} ./...
                                    squeeze(seContrast);
                            end
                        
                        % Update for sub-population level
                        %elseif
                            
                        
                        % Z-update for population or subject level
                        else
                            ddat.img{iPop, iVisit} = ddat.oimg{iPop, iVisit} /...
                                std(ddat.oimg{iPop, iVisit}(:), 'omitnan');
                            set(findobj('Tag', 'manualThreshold'), 'max',1);
                            %editThreshold;
                        end
                        
                    % Turn off Z-scores (Revert to oimg)
                    else
                        ddat.img{iPop, iVisit} = ddat.oimg{iPop, iVisit};
                        set(findobj('Tag', 'thresholdSlider'), 'Value', 0);
                        set(findobj('Tag', 'manualThreshold'), 'String', '');
                        set(findobj('Tag', 'manualThreshold'), 'Value', 0);
                    end
                    
                %end
            end
        end
        
    end

% Function to let the user know where in the brain they have clicked.
    function updateInfoText(hObject, callbackdata)
        cIC = get(findobj('Tag', 'ICselect'), 'Value');
        if get(findobj('Tag', 'viewZScores'), 'Value')
            vOrZ = 'Z-Scores';
        else
            vOrZ = 'Voxel Values';
        end
        if strcmp(ddat.type, 'grp')
            endText = 'Group Level ';
        elseif strcmp(ddat.type, 'subpop')
            if ddat.subPopExists
                endText = ['Sub-Population ' num2str(get(findobj('Tag',...
                    ['subPopSelect' num2str(1)]), 'Value')) ', '];
            else
                endText = 'Nothing ';
            end
        elseif strcmp(ddat.type, 'beta')
            betaInd = get(findobj('Tag', 'selectCovariate'), 'Value');
            covView = get(findobj('Tag', 'selectCovariate'), 'String');
            endText = ['covariate effect of ' char(covView(betaInd)) ', '];
            if ddat.viewingContrast == 1
                %%% contrast
                cIC = get(findobj('Tag', 'ICselect'), 'Value');
                if get(findobj('Tag', 'viewZScores'), 'Value')
                    vOrZ = 'Z-Scores';
                else
                    vOrZ = 'Voxel Values';
                end
                viewObj = get(findobj('Tag',...
                    ['contrastSelect' num2str(1)]))
                contrastInd = num2str(viewObj.Value);
                endText = ['contrast C' contrastInd ', '];
                newString = ['Viewing ' endText vOrZ ' for IC ' num2str(cIC)];
                set(findobj('Tag', 'viewerInfo'), 'String', newString);
            end
        elseif strcmp(ddat.type, 'subj')
            subInd = get(findobj('Tag', 'selectSubject'), 'Value');
            endText = ['Effect for subject ' num2str(subInd) ', '];
        elseif strcmp(ddat.type, 'icsel')
            endText = '';
        elseif strcmp(ddat.type, 'reEst')
            endText = '';
        elseif strcmp(ddat.type, 'subPopCompare')
            endText = '';
        end
        newString = ['Viewing ' endText vOrZ ' for IC ' num2str(cIC)];
        set(findobj('Tag', 'viewerInfo'), 'String', newString);
    end


%% Thresholding

% last updated to work with lICA version on 8/28/19x
% Function to edit the z-threshold required to view on brain image.
    function editThreshold(hObject, callbackdata)
        
%         % Get user selected cutoff
%         cutoff = get( findobj('Tag', 'thresholdSlider'), 'value');
%         set( findobj('Tag', 'manualThreshold'), 'string', num2str(cutoff) );
%         
%         % Loop over sub populations and update threshold.
%         for iPop = 1:size(ddat.viewTracker, 1)
%             for iVisit = 1:size(ddat.viewTracker, 2)
%                 if ddat.viewTracker(iPop, iVisit) > 0
%                     ddat.maskingStatus{iPop, iVisit} = (abs(ddat.img{iPop, iVisit}) >= cutoff);
%                 end
%             end
%         end
        
        [rowInd, colInd] = find(ddat.viewTracker > 0);
        if size([rowInd, colInd], 2) ~= 2
            rowInd = rowInd(:); colInd = colInd(:);
        end
        update_brain_maps('updateCombinedImage', [rowInd, colInd], 'updateColorbar', 0);
        
    end

% Function to handle Z-thresholding if the user manually enters a
% value.
    function manualThreshold(hObject, callbackdata)
        newCutoff = get( findobj('Tag', 'manualThreshold'), 'string');
        if all(ismember(newCutoff, '0123456789+-.eEdD')) & ~isempty(newCutoff)
            maxval = get( findobj('Tag', 'thresholdSlider'), 'Max');
            if str2double(newCutoff) < 0 || str2double(newCutoff) > maxval
                warndlg(['Please input a number in range 0-' num2str(maxval)], 'Input Error');
                set( findobj('Tag', 'manualThreshold'), 'string', ...
                    get( findobj('Tag', 'thresholdSlider'), 'value'));
            else
                set( findobj('Tag', 'thresholdSlider'), 'value', str2double(newCutoff));
                editThreshold;
            end
        else
            warndlg('Please input a valid number', 'Input Error');
            set( findobj('Tag', 'manualThreshold'), 'string', ...
                get( findobj('Tag', 'thresholdSlider'), 'value'));
        end
    end



% Function to allow user to select sub populations to compare. Opens a
% new window.
    function compareSubPopulations(hObject, callbackdata)
        newfig = figure('Units', 'normalized', ...,...
            'position', [0.3 0.3 0.3 0.3],...
            'MenuBar', 'none',...
            'Tag','pickSubPops',...
            'NumberTitle','off',...
            'Name','Sub-Population Selection',...
            'Resize','on',...
            'Visible','on');%,...
        subPopSelectDisplay = uitable('Parent', newfig, ...
            'Units', 'Normalized', ...
            'Position', [0.55, 0.3, 0.35, 0.5], ...
            'Tag', 'subPopSelectDisplay'); %#ok<NASGU>
        set(findobj('Tag', 'subPopSelectDisplay'), 'Data', get(findobj('Tag', 'subPopDisplay'), 'Data'));
        set(findobj('Tag', 'subPopSelectDisplay'), 'RowName', get(findobj('Tag', 'subPopDisplay'), 'RowName'));
        set(findobj('Tag', 'subPopSelectDisplay'), 'ColumnName', get(findobj('Tag', 'subPopDisplay'), 'ColumnName'));
        subPopListBox = uicontrol('Style', 'listbox',...
            'Parent', newfig, ...
            'Units', 'Normalized', ...
            'Position', [0.1, 0.3, 0.35, 0.5],...
            'Tag', 'subPopListBox', 'Callback', @subPopSelectCall); %#ok<NASGU>
        % set the list box to have the correct number of sub populations
        set(findobj('Tag', 'subPopListBox'), 'String', get(findobj('Tag', 'subPopDisplay'), 'RowName') );
        set(findobj('Tag', 'subPopListBox'), 'Max', 3);
        numSelectedText = uicontrol('Parent', newfig, ...
            'Style', 'Text', 'String', 'Number of selected sub-populations: ', ...
            'Units', 'Normalized', ...
            'Position', [0.10, 0.18, 0.4, 0.1]); %#ok<NASGU>
        numSelected = uicontrol('Parent', newfig, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.50, 0.225, 0.05, 0.05], ...
            'Tag', 'numSelected', 'BackgroundColor', 'white'); %#ok<NASGU>
        runSubjCompare = uicontrol('Parent', newfig, ...
            'Units', 'Normalized', ...
            'String', 'Compare Selected Sub-Populations', ...
            'Position', [0.3, 0.01, 0.4, 0.13], ...
            'Tag', 'newSubPop', 'Callback', @launchCompareWindow); %#ok<NASGU>
        movegui(newfig, 'center')
    end

% Function to launch a comparison window
    function launchCompareWindow(hObject, callbackdata)
        selectedSubPops = get(findobj('Tag', 'subPopListBox'), 'Value');
        %close;
        set(0,'CurrentFigure',hs.fig);
        [~, ddat.nCompare] = size(selectedSubPops);
        set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'On');
        set(findobj('Tag', 'SubpopulationControl'), 'BackgroundColor', 'White');
        set(findobj('Tag', 'SubpopulationControl'), 'Position', [0.72, 0.70, 0.27, 0.29]);
        set(findobj('Tag', 'subPopDisplay'), 'ColumnEditable', false);
        set(findobj('Tag', 'newSubPop'), 'Visible', 'Off');
        set(findobj('Tag', 'subPopSelect1'), 'Visible', 'Off');
        set(findobj('Tag', 'compareSubPops'), 'Visible', 'Off');
        expandSubPopulationPanel(selectedSubPops);
        delete(hObject.Parent);
    end

% Counts the number of sub-populations selected.
    function subPopSelectCall(hObject, callbackdata)
        selectedPops = hObject.Value;
        [nothing, numPop] = size(selectedPops);
        set(findobj('Tag', 'numSelected'), 'String', num2str(numPop));
    end

% Function for the IC selection process. Creates the menu with all of
% the ICs and whether or not they have been selected for the EM
% algorithm.
    function updateICSelMenu(hObject, callbackdata)
        %global keeplist;
        isSelected = callbackdata.Source.Value;
        currentTable = get(findobj('Tag', 'icSelRef'), 'Data');
        if isSelected
            currentTable{get(findobj('Tag', 'ICselect'), 'Value'),2} = 'x';
            keeplist(get(findobj('Tag', 'ICselect'), 'Value')) = 1;
        else
            currentTable{get(findobj('Tag', 'ICselect'), 'Value'),2} = '';
            keeplist(get(findobj('Tag', 'ICselect'), 'Value')) = 0;
        end
        set(findobj('Tag', 'icSelRef'), 'Data', currentTable);
    end

% Functions from the task bar for display viewer switching
% Function to switch to the sub population viewer.
    function stSubPop(hObject, callbackdata)
        if strcmp(ddat.type, 'subPopCompare')
            revertToDisp;
        end
        ddat.type = 'subpop';
        initialDisp;
        update_all_traj_fields;
    end

% Function to switch to the group level viewer.
    function stGrp(hObject, callbackdata)
        if strcmp(ddat.type, 'subPopCompare')
            revertToDisp;
        end
        ddat.type = 'grp';
        initialDisp;
        update_all_traj_fields;
    end

% Function to switch to the subject level viewer.
    function stSubj(~, ~)
        if strcmp(ddat.type, 'subPopCompare')
            revertToDisp;
        end
        ddat.type = 'subj';
        initialDisp;
        update_all_traj_fields;
    end

% Function to switch to the beta map viewer.
    function stBeta(~, ~)
        if strcmp(ddat.type, 'subPopCompare')
            revertToDisp;
        end
        ddat.type = 'beta';
        initialDisp;
        update_all_traj_fields;
    end

% Function to undo the changes made by the sub population compare
% window
    function revertToDisp(~, ~)
        
        set(findobj('Tag', 'closePanel'), 'Visible', 'Off')
        
        % Resize the viewer window to the correct size
        hs.fig.Position = [0.3 0.3 0.5 0.5];
        % Delete figure children added by the sub population display window
        for iChild = 1:numel(hs.fig.Children)
            if (isprop(hs.fig.Children(iChild),'Tag'))
                if strcmp(hs.fig.Children(iChild).Tag, 'subPopDisplayPanel')
                    delete(hs.fig.Children(iChild));
                end
            end
        end
        
        displayPanel = uipanel('BackgroundColor','white',...
            'Tag', 'viewingPanelNormal',...
            'Position',[0, 0.5 1 0.5], ...;
            'BackgroundColor',get(hs.fig,'color'));
        % Windows
        SagAxes = axes('Parent', displayPanel, ...
            'Units', 'Normalized', ...
            'Position',[0.01 0.18 0.27 .8],...
            'Tag', 'SagittalAxes1' ); %#ok<NASGU>
        CorAxes = axes('Parent', displayPanel, ...
            'Position',[.30 .18 .27 .8],...
            'Tag', 'CoronalAxes1' ); %#ok<NASGU>
        AxiAxes = axes('Parent', displayPanel, ...
            'Position',[.59 .18 .27 .8],...
            'Tag', 'AxialAxes1' ); %#ok<NASGU>
        % Sliders
        SagSlider = uicontrol('Parent', displayPanel, ...
            'Style', 'Slider', ...
            'Units', 'Normalized', ...
            'Position', [0.01, -0.3, 0.27, 0.4], ...
            'Tag', 'SagSlider', 'Callback', @sagSliderMove); %#ok<NASGU>
        CorSlider = uicontrol('Parent', displayPanel, ...
            'Style', 'Slider', ...
            'Units', 'Normalized', ...
            'Position', [0.30, -0.3, 0.27, 0.4], ...
            'Tag', 'CorSlider', 'Callback', @corSliderMove); %#ok<NASGU>
        AxiSlider = uicontrol('Parent', displayPanel, ...
            'Style', 'Slider', ...
            'Units', 'Normalized', ...
            'Position', [0.59, -0.3, 0.27, 0.4], ...
            'Tag', 'AxiSlider', 'Callback', @axiSliderMove); %#ok<NASGU>
        % Colorbar
        colorMap = axes('Parent', displayPanel, ...
            'units', 'Normalized',...
            'Position', [0.90, 0.18, 0.05, 0.8], ...
            'Tag', 'colorMap'); %#ok<NASGU>
        
        % Recolor the sub population display and put it in the correct
        % place
        set(findobj('Tag', 'SubpopulationControl'), 'Position', [.69, 0.01 .30 .45]);
        set(findobj('Tag', 'SubpopulationControl'), 'BackgroundColor', [224/256,224/256,224/256]);
        set(findobj('Tag', 'locPanel'), 'BackgroundColor', [224/256,224/256,224/256]);
        set(findobj('Tag', 'icPanel'), 'BackgroundColor', [224/256,224/256,224/256]);
        set(findobj('Tag', 'thresholdPanel'), 'BackgroundColor', [224/256,224/256,224/256]);
        set(findobj('Tag', 'compareSubPops'), 'Visible', 'On');
        set(findobj('Tag', 'newSubPop'), 'Visible', 'On');
        set(findobj('Tag', 'subPopSelect1'), 'Visible', 'On');
        set(findobj('Tag', 'subPopDisplay'), 'ColumnEditable', true);
        
    end

% Close button for the IC selection window.
    function closeICSelect(hObject, ~)
        delete(hObject.Parent);
    end

%% Old Contrast Stuff

% Beta Panel Functions
% Function to allow the user to add another contrast to the list
    function addNewContrast(hObject, callbackdata)
        olddata = findobj('Tag', 'contrastDisplay'); olddim = size(olddata.Data);
        oldrownames = olddata.RowName;
        newTable = cell(olddim(1) + 1, ddat.p);
        % Fill in all the old information
        for column=1:olddim(2)
            for row=1:olddim(1)
                newTable(row, column) = olddata.Data(row,column);
            end
        end
        % reassign the row names for the table
        if olddim(1) == 0
            newRowNames = ['C' num2str(olddim(1)+1)];
        else
            newRowNames = [oldrownames; ['C' num2str(olddim(1)+1)]];
            newRowNames = cellstr(newRowNames);
        end
        
        set(findobj('Tag', 'contrastDisplay'), 'Data', newTable);
        set(findobj('Tag', 'contrastDisplay'), 'RowName', newRowNames);
        % Make it so that only the main effects can be edited
        ceditable = false(1, ddat.p);
        ceditable(1:size(ddat.interactions,2)) = 1;
        set(findobj('Tag', 'contrastDisplay'), 'ColumnEditable', ceditable);
        
        % change the drop down menu
        newString = cell(olddim(1)+1,1);
        oldstring = get(findobj('Tag', 'contrastSelect1'), 'String');
        for i=1:olddim(1)
            if (olddim(1) > 0)
                newString(i) = {oldstring{i}};
            else
                newString(i) = {oldstring(:)'};
            end
        end
        newString(olddim(1) + 1) = {['C' num2str(olddim(1)+1)]};
        % Update all sub population selection viewers
        for iPop = 1:ddat.nCompare
            set(findobj('Tag', ['contrastSelect' num2str(iPop)]),'String', newString);
        end
        ddat.contrastExists = 1;
    end

    %removeContrast
    %
    % This function removes a specified contrast. If that contrast was also
    % a "valid" contrast (fully filled out) then it is also removed from
    % ddat.LC_contrasts and ddat.valid_LC_contrast
    function removeContrast(hObject, callbackdata)
         
        % Check that a contrast exists
        if ddat.contrastExists == 1
            
            % Keep track of if a contrast should be removed (vs user enter
            % cancel)
            %removeContrast = 0;
            
            % open a window asking which contrast to remove
            waitingForResponse = 1;
            while waitingForResponse
                answer = inputdlg('Please enter contrast name to remove (C1, C2,...)')
                if isempty(answer)
                    waitingForResponse = 0;
                    % if user input something, check that it is valid
                else
                    validContrasts = get(findobj('Tag', 'contrastDisplay'), 'RowName');
                    matchedIndex = strfind(validContrasts, answer);
                    % Reduce to just first match to guard against C1 and
                    % C11
                    removeIndex = 0;
                    for iContrast = 1:length(validContrasts)
                        % handle more than one contrast
                        if iscell(validContrasts)
                            if matchedIndex{iContrast} == 1
                                removeIndex = iContrast;
                                break; % break out of the loop
                            end
                            % handle only one contrast
                        else
                            if matchedIndex == 1
                                removeIndex = iContrast;
                                break; % break out of the loop
                            end
                        end
                    end
                    % If a valid contrast was entered, then proceed
                    if removeIndex > 0
                        waitingForResponse = 0;
                        
                        % Remove this contrast from the viewTable and from
                        % the viewTracker
                        if ddat.valid_LC_contrast(removeIndex) == 1
                            
                            % Clear out variables
                            ddat.LC_contrasts(removeIndex, :) = []; 
                            ddat.valid_LC_contrast(removeIndex) = [];
                            ddat.saved_contrast_viewTracker(removeIndex, :) = [];
                            disp('remove from contrast names') %TODO
                            
                        end
                        
                        olddata = findobj('Tag', 'contrastDisplay'); olddim = size(olddata.Data);
                        oldrownames = olddata.RowName;
                        newTable = cell(olddim(1) - 1, ddat.p);
                        % Fill in all the old information
                        for column=1:olddim(2)
                            incRow = 0;
                            for row=1:olddim(1)
                                if row ~= removeIndex
                                    incRow = incRow + 1;
                                    newTable(incRow, column) = olddata.Data(row,column);
                                end
                            end
                        end
                                                
                        % reassign the row names for the table
                        if olddim(1) == 2
                            newRowNames = ['C' num2str(1)];
                        else
                            newRowNames = oldrownames(1:olddim(1) - 1);
                            newRowNames = cellstr(newRowNames);
                        end
                        
                        set(findobj('Tag', 'contrastDisplay'), 'Data', newTable);
                        set(findobj('Tag', 'contrastDisplay'), 'RowName', newRowNames);
                        % Make it so that only the main effects can be edited
                        ceditable = false(1, ddat.p);
                        ceditable(1:size(ddat.interactions,2)) = 1;
                        set(findobj('Tag', 'contrastDisplay'), 'ColumnEditable', ceditable);
                        
                        % Handle additional required changes if
                        % contrasts were what was currently being
                        % viewed
                        if strcmp(get(get(findobj('tag', 'EffectTypeButtonGroup'),...
                            'SelectedObject'), 'String'), 'Contrast View')
                        
                            % First need this intermediate step to delete
                            % any axes corresponding to deleted axes
                            ddat.viewTracker(removeIndex, :) = zeros(1, ddat.nVisit);
                            set_number_of_brain_axes(0);
                        
                            % Now update viewTracker
                            ddat.viewTracker = ddat.saved_contrast_viewTracker;

                            setup_ViewSelectTable;

                            [rowInd, colInd] = find( ones(size(ddat.viewTracker)) > 0);

                            if size([rowInd, colInd], 2) ~= 2
                                rowInd = rowInd(:); colInd = colInd(:);
                            end

                            load_functional_images( [rowInd, colInd] );
                        end
                        
%                         % change the drop down menu
%                         newString = cell(olddim(1)-1, 1);
%                         oldstring = get(findobj('Tag', 'contrastSelect1'), 'String');
%                         for i=1:olddim(1)-1
%                             if (olddim(1) > 1)
%                                 newString(i) = {oldstring{i}};
%                             else
%                                 newString(i) = {oldstring(:)'};
%                             end
%                         end
                        %newString(olddim(1) + 1) = {['C' num2str(olddim(1)+1)]};
                        
                        % Finally, update what is being viewed.
                        % Only have to do this if currently viewing a
                        % contrast
%                         if ddat.viewingContrast
%                             currentSelection = get(findobj('Tag', ['contrastSelect' num2str(1)]),'Value');
%                             % If removed something above the current
%                             % selection, do nothing.
%                             % If removed current selection, switch to
%                             % regular cov viewer and tell user
%                             if currentSelection == removeIndex
%                                 % turn off viewing contrast
%                                 ddat.viewingContrast = 0;
%                                 % switch the the selected covariate instead
%                                 updateIC;
%                                 set(findobj('Tag', ['contrastSelect' num2str(1)]),'Value', 1);
%                             end
%                             % If removed above current selection, just
%                             % switch the dropdown menu to reflect this
%                             if currentSelection > removeIndex
%                                 set(findobj('Tag', ['contrastSelect' num2str(1)]),'Value', currentSelection - 1);
%                                 updateContrastDisp;
%                             end
%                         end
                        
%                         if olddim(1) - 1 == 0
%                             newString = 'No Contrast Created';
%                             ddat.contrastExists = 0;
%                             ddat.viewingContrast = 0;
%                             set(findobj('Tag', 'contrastDisplay'), 'RowName', {});
%                         end
                        
%                         % Update all sub population selection viewers
%                         for iPop = 1:ddat.nCompare
%                             set(findobj('Tag', ['contrastSelect' num2str(iPop)]),'String', newString);
%                         end
                        
                        
                    end
                end
            end
            % update "viewing contrast" as well
            % check that whatever is on screen is valid BE CAREFUL HERE!!
        else
            warnbox = warndlg('No contrasts have been specified')
        end
    end


    function save_jpg(hObject, callbackdata)
        
        %saveas()
        startString = fullfile(ddat.outdir, [ddat.outpre, '_myfigure.jpg']);
        definput = {startString};
        answer = inputdlg('Please enter the filename for the image.',...
            'Input filename',...
            [1, 70], definput);
        
        %picfig = figure('pos',[10 10 900 300]);
        picfig = figure('units', 'normalized', 'pos', [0.2, 0.2, 0.6, 0.3]);
        copyobj(findobj('tag', 'viewingPanelNormal'), picfig)
        picfig.Children(1).Position = [0 0 1 1];
        picfig.Children(1).Children(1).Visible = 'off';
        picfig.Children(1).Children(2).Visible = 'off';
        picfig.Children(1).Children(3).Visible = 'off';
        
        saveas(picfig, answer{1})
        delete(picfig)
    end



%% Functions to be removed
% This function is called when the user decides to compare two
% subpopulations. It heavily changes the display window.
    function expandSubPopulationPanel(selectedPops)
        
        % Setup cell arrays for all sub population info.
        ddat.type = 'subPopCompare';
        ddat.axial_image = cell(ddat.nCompare, ddat.nVisit);
        ddat.sagittal_image = cell(ddat.nCompare, ddat.nVisit);
        ddat.coronal_image = cell(ddat.nCompare, ddat.nVisit);
        ddat.axial_xline = cell(ddat.nCompare, ddat.nVisit);
        ddat.axial_yline = cell(ddat.nCompare, ddat.nVisit);
        ddat.coronal_xline = cell(ddat.nCompare, ddat.nVisit);
        ddat.coronal_yline = cell(ddat.nCompare, ddat.nVisit);
        ddat.sagittal_xline = cell(ddat.nCompare, ddat.nVisit);
        ddat.sagittal_yline = cell(ddat.nCompare, ddat.nVisit);
        
        % Loop through and edit the properties of the original viewer
        % (change sizes, delete items, etc)
        % Expand the size of the viewer
        hs.fig.Position = [0.1 0.1 0.8 0.8];
        for iChild = 1:numel(hs.fig.Children)
            if (isprop(hs.fig.Children(iChild),'Tag'))
                if strcmp(hs.fig.Children(iChild).Tag, 'thresholdPanel')
                    hs.fig.Children(iChild).Position = [0.72 0.53 0.27 0.15];
                    hs.fig.Children(iChild).BackgroundColor = 'white';
                end
                if strcmp(hs.fig.Children(iChild).Tag, 'icPanel')
                    hs.fig.Children(iChild).Position = [0.72 0.34 0.27 0.15];
                    hs.fig.Children(iChild).BackgroundColor = 'white';
                end
                % Move the location panel
                if strcmp(hs.fig.Children(iChild).Tag, 'locPanel')
                    hs.fig.Children(iChild).Position = [0.72 0.08 0.27 0.25];
                    hs.fig.Children(iChild).BackgroundColor = 'white';
                end
                if strcmp(hs.fig.Children(iChild).Tag, 'viewingPanelNormal')
                    indToDelete = iChild;
                end
            end
        end
        % Do this outside because we dont want numel in hs to change during
        % the loop
        delete(hs.fig.Children(indToDelete));
        
        % Create a new viewing panel
        displayPanel = uipanel('BackgroundColor','white',...
            'tag', 'subPopDisplayPanel',...
            'units', 'Normalized',...
            'Position',[0.01, 0.01 0.7 0.98], ...
            'BackgroundColor','black');
        colorMap = axes('Parent', displayPanel, ...
            'units', 'Normalized',...
            'Position', [0.01, 0.1, 0.04, 0.8], ...
            'Tag', 'colorMap');
        
        % Calculate figure widths by number of sub populations.
        % the GUI restricts this to two, but the code allows for
        % more
        xint = 0.9 / ddat.nCompare;
        % load data to get dimension
        newFile = strcat(ddat.outdir,'/',ddat.outpre,'_S0_IC_',num2str(1),'.nii');
        newDat = load_nii(newFile); newFunc = newDat.img;
        
        % load the covariate information
        covariateSettings = get(findobj('Tag', 'subPopDisplay'),'Data');
        
        %% THIS IS WHERE I DO AXES CREATION
        for subGroup = 1:ddat.nCompare
            % Create all the axis information to go with the panel
            SagAxes = axes('Parent', displayPanel, ...
                'Units', 'Normalized', ...
                'Position',[0.05+xint * (subGroup-1) 0.65 xint 0.25],...
                'Tag', ['SagittalAxes' num2str(subGroup)] );
            CorAxes = axes('Parent', displayPanel, ...
                'Units', 'Normalized',...
                'Position',[0.05+xint * (subGroup-1) .35 xint 0.25],...
                'Tag', ['CoronalAxes' num2str(subGroup)] );
            AxiAxes = axes('Parent', displayPanel, ...
                'Units', 'Normalized', ...
                'Position',[0.05+xint * (subGroup-1) 0.05 xint .25],...
                'Tag', ['AxialAxes' num2str(subGroup)] );
            % Add in information about voxel value, this is assigned to
            %   a new panel
            infoPanel = uipanel('Parent', displayPanel,...
                'Position',[0.05+ xint/4 + xint * (subGroup-1), 0.93, xint/2, 0.06]);
            crosshairVal = uicontrol('Parent', infoPanel, ...
                'Style', 'Text', ...
                'Units', 'Normalized', ...
                'Position', [0.01, 0.01, 0.98, 0.48], ...
                'Tag', ['crosshairVal' num2str(subGroup)]);
            subPopSelect = uicontrol('Parent', infoPanel,...
                'Style', 'popupmenu', ...
                'Units', 'Normalized', ...
                'Position', [0.01, 0.52, 0.98, 0.48], ...
                'Tag', ['subPopSelect' num2str(subGroup)],...
                'Callback', @updateSubPopulation, ...
                'String', 'No Sub-Population Created', ...
                'Visible', 'Off');
            subPopListing = uicontrol('Parent', infoPanel,...
                'Style', 'Text', ...
                'Units', 'Normalized', ...
                'Position', [0.01, 0.52, 0.98, 0.48], ...
                'String', ['SubPop' num2str(subGroup)]);
            newDisplay = displayPanel;
            
            % data for the sub population in this panel
            newFunc = load_nii([ddat.outdir '/' ddat.outpre '_' 'S0_' 'IC_1.nii']);
            newFunc = newFunc.img;
            for xi = 1:ddat.p
                beta = load_nii([ddat.outdir '/' ddat.outpre '_beta_cov' num2str(xi) '_IC' num2str(1) '.nii']);
                xb = beta.img * str2double(covariateSettings( selectedPops(subGroup) , xi));
                newFunc = newFunc + xb;
            end
            ddat.img{subGroup} = newFunc; ddat.oimg{subGroup} = newFunc;
            
        end
        
        % Add a panel to the new display for the sliders
        sliderPanel = uipanel('Parent', displayPanel,...
            'Position',[0.95, 0.01 0.025 0.98],...
            'Tag', 'sliderPanel',...
            'BackgroundColor', 'black');
        SagSlider = uicontrol('Parent', sliderPanel, ...
            'Style', 'Slider', ...
            'Units', 'Normalized', ...
            'Position', [0.5, 0.65, 0.8, 0.25], ...
            'Tag', 'SagSlider', 'Callback', @sagSliderMove);
        CorSlider = uicontrol('Parent', sliderPanel, ...
            'Style', 'Slider', ...
            'Units', 'Normalized', ...
            'Position', [0.5, 0.35, 0.8, 0.25], ...
            'Tag', 'CorSlider', 'Callback', @corSliderMove);
        AxiSlider = uicontrol('Parent', sliderPanel, ...
            'Style', 'Slider', ...
            'Units', 'Normalized', ...
            'Position', [0.5, 0.05, 0.8, 0.25], ...
            'Tag', 'AxiSlider', 'Callback', @axiSliderMove);
        
        % add a close button to the bottom right for compare window
        closePanel = uipanel('FontSize',12,...
            'Units', 'Normalized',...
            'Visible', 'On', ...
            'Tag', 'closePanel', ...
            'BackgroundColor','white',...
            'Position', [0.79, 0.01, 0.135, 0.05])
        closeCompare = uicontrol('Parent', closePanel,...
            'Units', 'Normalized', ...
            'String', 'Close Window', ...
            'Position', [0.0, 0.0, 1, 1], ...
            'Tag', 'closeCompare', 'Callback', @stSubPop);
        
        hs.fig.Children = [hs.fig.Children(:,1); (newDisplay')];
        
        createCombinedImage;
        
        % Loop through and update all sub populations
        for subPop=1:ddat.nCompare
            
            for cl = 1:3
                Saxial(:, :, cl) = squeeze(ddat.combinedImg{subPop}(cl).combound(:, :, ddat.axi))';
                Scor(:, :, cl) = squeeze(ddat.combinedImg{subPop}(cl).combound(:,ddat.cor,:))';
                Ssag(:, :, cl) = squeeze(ddat.combinedImg{subPop}(cl).combound(ddat.sag,:,:))';
            end
            
            aspect = 1./ddat.daspect;
            % Setup Axial Image
            axes(findobj('Tag', ['AxialAxes' num2str(subPop)]));
            ddat.axial_image{subPop} = image(Saxial);
            set(gca,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                'color', 'black',...
                'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],'xtick',[],'ytick',[],'Tag',['AxialAxes' num2str(subPop)])
            daspect(gca,aspect([1 3 2]));
            %set(ddat.axial_image{subPop},'ButtonDownFcn','get_pos_dispexp(''axi''); plot_voxel_trajectory([''ddat.sag'', ''ddat.cor'', ''ddat.axi'']);');
            set(ddat.axial_image{subPop},'ButtonDownFcn',{@image_button_press, 'axi'});
            pos_axi = [ddat.sag, ddat.cor];
            crosshair = plot_crosshair(pos_axi, [], gca);
            ddat.axial_xline{subPop} = crosshair.lx;
            ddat.axial_yline{subPop} = crosshair.ly;
            
            % Setup Coronal Image
            axes(findobj('Tag', ['CoronalAxes' num2str(subPop)] ));
            ddat.coronal_image{subPop} = image(Scor);
            set(gca,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                'color', 'black',...
                'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],'xtick',[],'ytick',[],'Tag',['CoronalAxes' num2str(subPop)])
            daspect(gca,aspect([1 3 2]));
            set(ddat.coronal_image{subPop},'ButtonDownFcn',{@image_button_press, 'cor'});
            pos_cor = [ddat.sag, ddat.axi];
            crosshair = plot_crosshair(pos_cor, [], gca);
            ddat.coronal_xline{subPop} = crosshair.lx;
            ddat.coronal_yline{subPop} = crosshair.ly;
            
            % Setup Sagital image
            %test = findobj('Tag', ['SagittalAxes' num2str(subPop)] );
            axes(findobj('Tag', ['SagittalAxes' num2str(subPop)] ));
            ddat.sagittal_image{subPop} = image(Ssag);
            set(gca,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                'color', 'black',...
                'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],'xtick',[],'ytick',[],'Tag',['SagittalAxes' num2str(subPop)])
            daspect(gca,aspect([2 3 1]));
            set(ddat.sagittal_image{subPop},'ButtonDownFcn',{@image_button_press, 'sag'});
            pos_sag = [ddat.cor, ddat.axi];
            crosshair = plot_crosshair(pos_sag, [], gca);
            ddat.sagittal_xline{subPop} = crosshair.lx;
            ddat.sagittal_yline{subPop} = crosshair.ly;
            
        end % end of sub population loop
        
        %%%%% Setup the Sliders %%%%
        % Sagittal Slider
        xslider_step(1) = 1/(ddat.xdim);
        xslider_step(2) = 1.00001/(ddat.xdim);
        set(findobj('Tag', 'SagSlider'), 'Min', 1, 'Max',ddat.xdim, ...
            'SliderStep',xslider_step,'Value',ddat.sag); %%Sagittal Y-Z, adjust x direction
        % Coronal Slider
        yslider_step(1) = 1/(ddat.ydim);
        yslider_step(2) = 1.00001/(ddat.ydim);
        set(findobj('Tag', 'CorSlider'), 'Min', 1, 'Max',ddat.ydim, ...
            'SliderStep',yslider_step,'Value',ddat.cor); %%Coronal X-Z, adjust y direction
        % Axial Slider
        zslider_step(1) = 1/(ddat.zdim);
        zslider_step(2) = 1.00001/(ddat.zdim);
        set(findobj('Tag', 'AxiSlider'), 'Min', 1, 'Max',ddat.zdim, ...
            'SliderStep',zslider_step,'Value',ddat.axi);
        
        updateCrosshairValue;
        redisplay;
        updateInfoText;
    end


% SubPopulation Panel Functions
% Function to allow the user to add another sub population to the list
    function addNewSubPop(hObject, callbackdata)
        olddata = findobj('Tag', 'subPopDisplay'); olddim = size(olddata.Data);
        oldrownames = olddata.RowName;
        newTable = cell(olddim(1) + 1, ddat.p);
        % Fill in all the old information
        for column=1:olddim(2)
            for row=1:olddim(1)
                newTable(row, column) = olddata.Data(row,column);
            end
        end
        % reassign the row names for the table
        if olddim(1) == 0
            newRowNames = ['SubPop' num2str(olddim(1)+1)];
        else
            newRowNames = [oldrownames; ['SubPop' num2str(olddim(1)+1)]];
            newRowNames = cellstr(newRowNames);
        end
        
        set(findobj('Tag', 'subPopDisplay'), 'Data', newTable);
        set(findobj('Tag', 'subPopDisplay'), 'RowName', newRowNames);
        % Make it so that only the main effects can be edited
        ceditable = false(1, ddat.p);
        ceditable(1:length(ddat.varNamesX)) = 1;
        set(findobj('Tag', 'subPopDisplay'), 'ColumnEditable', ceditable);
        
        % change the drop down menu
        newString = cell(olddim(1)+1,1);
        oldstring = get(findobj('Tag', 'subPopSelect1'), 'String');
        for i=1:olddim(1)
            if (olddim(1) > 0)
                newString(i) = {oldstring{i}};
            else
                newString(i) = {oldstring(:)'};
            end
        end
        newString(olddim(1) + 1) = {['SubPop' num2str(olddim(1)+1)]};
        % Update all sub population selection viewers
        for iPop = 1:ddat.nCompare
            set(findobj('Tag', ['subPopSelect' num2str(iPop)]),'String', newString);
        end
    end


% Function to allow a user to select what sub-population is being
% viewed.
    function updateSubPopulation(hObject, callbackdata)
        % find the viewer that needs to be updated
        if exist('hObject.Tag')
            viewer = str2num(hObject.Tag(13:end));
        else
            viewer = 1;
        end
        % Load the IC
        newIC = get( findobj('Tag', 'ICselect'), 'value');
        newFile = strcat(ddat.outdir,'/',ddat.outpre,'_S0_IC_',num2str(newIC),'.nii');
        newDat = load_nii(newFile); newFunc = newDat.img;
        
        covariateSettings = get(findobj('Tag', 'subPopDisplay'), 'Data');
        for xi = 1:ddat.p
            beta = load_nii([ddat.outdir '/' ddat.outpre '_beta_cov' num2str(xi) '_IC' num2str(newIC) '.nii']);
            max(max(max(beta.img)))
            xb = beta.img .* str2double(covariateSettings( get(findobj('Tag',...
                ['subPopSelect' num2str(viewer)]), 'Value') , xi));
            newFunc = newFunc + xb;
        end
        
        ddat.img{viewer} = newFunc; ddat.oimg{viewer} = newFunc;
        createCombinedImage;
        redisplay;
        updateInfoText;
    end

% Function to update the displayed contrast from the covariate viewer
    function updateContrastDisp(hObject, callbackdata)
        % find the viewer that needs to be updated
        if exist('hObject.Tag')
            viewer = str2num(hObject.Tag(13:end));
        else
            viewer = 1;
        end
        % Load the IC
        newIC = get( findobj('Tag', 'ICselect'), 'value');
        
        contrastSettings = get(findobj('Tag', 'contrastDisplay'), 'Data');
        
        % Verify that the selected contrast is filled out and not all zero
        performContrastUpdate = 1;
        % check that something is filled out
        if isempty(contrastSettings)
            performContrastUpdate = 0;
            f = warndlg('Please specify a contrast before viewing.')
            % check nothing empty
        else
            tempsettings = contrastSettings( get(findobj('Tag',['contrastSelect' num2str(viewer)]), 'Value') , :);
            all0 = 0;
            if length(tempsettings) == 1
                all0 = strcmp(tempsettings, '0');
            else
                all0 = sum(strcmp(tempsettings, '0')) == length(tempsettings);
            end
            if any( cellfun(@isempty, tempsettings) )
                performContrastUpdate = 0;
                f = warndlg('Please fill out all covariate values before viewing.')
                % check that not all zero
            elseif all0 == 1
                performContrastUpdate = 0;
                f = warndlg('Contrast must have at least one non-zero value.')
            end
        end
        
        
        
        if performContrastUpdate
            % Update the status, we are now viewing a contrast
            ddat.viewingContrast = 1;
            % Load the first piece
            beta = load_nii([ddat.outdir '/' ddat.outpre '_beta_cov' num2str(1) '_IC' num2str(newIC) '.nii']);
            newFunc = beta.img .* str2double(contrastSettings( get(findobj('Tag',...
                ['contrastSelect' num2str(viewer)]), 'Value') , 1));
            % Load the remaining pieces
            for xi = 2:ddat.p
                beta = load_nii([ddat.outdir '/' ddat.outpre '_beta_cov' num2str(xi) '_IC' num2str(newIC) '.nii']);
                max(max(max(beta.img)))
                xb = beta.img .* str2double(contrastSettings( get(findobj('Tag',...
                    ['contrastSelect' num2str(viewer)]), 'Value') , xi));
                newFunc = newFunc + xb;
            end
            
            ddat.img{viewer} = newFunc; ddat.oimg{viewer} = newFunc;
            updateZImg;
            createCombinedImage;
            redisplay;
            updateInfoText;
            
            %%% Set the text to let the user know they are viewing a
            %%% contrast
            cIC = get(findobj('Tag', 'ICselect'), 'Value');
            if get(findobj('Tag', 'viewZScores'), 'Value')
                vOrZ = 'Z-Scores';
            else
                vOrZ = 'Voxel Values';
            end
            viewObj = get(findobj('Tag',...
                ['contrastSelect' num2str(viewer)]))
            contrastInd = num2str(viewObj.Value);
            endText = ['contrast C' contrastInd ', '];
            newString = ['Viewing ' endText vOrZ ' for IC ' num2str(cIC)];
            set(findobj('Tag', 'viewerInfo'), 'String', newString);
            
        end
    end


end