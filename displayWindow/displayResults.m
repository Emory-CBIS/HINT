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
%   validVoxels - indices of voxels contained in brain mask
%   voxSize     - (x, y, z) dimension of whole brain anatomical image
%
%

delete( findobj('Tag', 'ICselect') );
delete( findobj('Tag', 'viewZScores') );

% Set up the data structure "ddat" with the input information. This
% structure will hold all the data as the user continues to use the viewer.
global ddat;
global data;

% Go through the input
ddat = struct();
ddat.q = cell2mat(varargin(1)); ddat.outdir = varargin{2};
ddat.outpre = varargin{3}; ddat.nsub = cell2mat(varargin(4));
ddat.type = varargin{5};
ddat.varNamesX = varargin{6};
ddat.X = varargin{7};
ddat.covTypes = varargin{8};
ddat.interactions = varargin{9};
ddat.nVisit = varargin{10};
ddat.validVoxels = varargin{11};
ddat.voxSize = varargin{12};
ddat.user_specified_anatomical_file = '';

ddat.betaVarEst = 0;

ddat.nVisitBackup = ddat.nVisit;
ddat.nCrVContrast = 0; % used as nVisit only when viewing cross-visit contrasts


% Set the default colormap
ddat.color_map = 'parula';
ddat.highcolor = parula;
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
%ddat.viewTracker = zeros(1, ddat.nVisit);
%ddat.viewTracker(1, 1) = 1;
ddat.viewTracker = zeros(1, 1);
ddat.viewTracker(1, 1) = 1;

% Keep track of user's previous settings for viewTracker (for switching
% back and forth between viewers)
ddat.saved_grp_viewTracker = zeros(ddat.nVisit, 1);
ddat.saved_beta_viewTracker = zeros(ddat.nVisit, ddat.p);
ddat.saved_contrast_viewTracker = zeros(ddat.nVisit, 0);
ddat.saved_cross_visit_contrast_viewTracker = zeros(0, 1); % visits not meaningful for cross visit contrast
ddat.saved_subpop_viewTracker = zeros(ddat.nVisit, 0);
ddat.saved_subj_viewTracker = zeros(ddat.nVisit, 0);

%% Keep track of what sub-populations/contrasts have been specified
% variable name is specified linear combinations
% Standard contrast
ddat.valid_LC_contrast = zeros(0);
ddat.LC_contrasts = zeros(0, ddat.p);
ddat.LC_contrast_names = {};
% Cross-visit contrast
ddat.valid_LC_cross_visit_contrast = zeros(0);
ddat.LC_cross_visit_contrasts = zeros(0, ddat.nVisit * ddat.p);
ddat.LC_cross_visit_contrast_names = {};
ddat.LC_cross_visit_contrast_strings = repmat({''}, 0, 1);
% Subpopulation specification
ddat.valid_LC_subpop = zeros(0);
ddat.LC_subpop_names = {};
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
            'position', [0.2 0.2 0.6 0.6],...
            'MenuBar', 'none',...
            'Tag','displayResults',...
            'NumberTitle','off',...
            'Name','HINT Results Viewer',...
            'Resize','on',...
            'Visible','off',...
            'WindowKeyPressFcn', @KeyPress);
        fileMenu = uimenu('Label','File');
        %uimenu(fileMenu,'Label','Save','Callback','disp(''save'')');
        uimenu(fileMenu, 'Label', 'Load anatomical image', 'Callback', @anatomical_spec_window);
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
        % View -> Colorbar
        ColorbarView = uimenu(viewerMenu, 'Label', 'Colormap', 'tag', 'ColorbarViewSubmenu');
        uimenu(ColorbarView, 'Label', 'Autumn', 'Callback', @set_typeof_colorbar, 'tag', 'cbautumn');
        uimenu(ColorbarView, 'Label', 'Jet', 'Callback', @set_typeof_colorbar, 'tag', 'cbjet');
        uimenu(ColorbarView, 'Label', 'Parula', 'Checked','on', 'Callback', @set_typeof_colorbar, 'tag', 'cbparula');
        uimenu(ColorbarView, 'Label', 'Spring', 'Callback', @set_typeof_colorbar, 'tag', 'cbspring');
        uimenu(ColorbarView, 'Label', 'Summer', 'Callback', @set_typeof_colorbar, 'tag', 'cbsummer');
        uimenu(ColorbarView, 'Label', 'Winter', 'Callback', @set_typeof_colorbar, 'tag', 'cbwinter');
        % Help
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
            'Position',[0.90, 0.5 0.09 0.5], ...;
            'BackgroundColor',get(hs.fig,'color'));
        
        displayPanel = uipanel('BackgroundColor','black',...
            'units', 'normalized',...
            'Parent', DefaultPanel,...
            'Tag', 'viewingPanelNormal',...
            'Position',[0, 0.5 0.89 0.5], ...;
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
            'Position', [0.01, 0.02, 0.98, 0.2], ...
            'Tag', 'viewerInfo', 'BackgroundColor', 'Black', ...
            'ForegroundColor', 'white', ...
            'HorizontalAlignment', 'Left'); %#ok<NASGU>
        selectCovariate = uicontrol('Parent', icPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.51, 0.48, 0.1], ...
            'Tag', 'selectCovariate', 'Callback', @updateIC, ...
            'String', 'Select Covariate', 'Visible', 'Off'); %#ok<NASGU>
        
        % Contrast vs Effect selection button group
        EffectViewButtonGroup = uibuttongroup('Parent',icPanel,...
            'units', 'normalized',...
            'tag', 'EffectTypeButtonGroup',...
            'visible', 'off',...
            'Position',[0.01 0.28 0.5 0.45]);
        SelectEffectView = uicontrol(EffectViewButtonGroup,...
            'string', 'Effect View',...
            'style', 'radiobutton',...
            'units', 'normalized',...
            'Position',[0.1 0.61 0.9 0.3],...
            'callback', @beta_typeof_view_select); %#ok<NASGU>
        % Contrasts within a visit (eg. trt vs ctrl group at baseline
        % visit)
        SelectContrastView = uicontrol(EffectViewButtonGroup,...
            'style', 'radiobutton',...
            'string', 'Contrast View',...
            'units', 'normalized',...
            'tag', 'SelectContrastView',...
            'callback', @beta_typeof_view_select,...
            'Position',[0.1 0.31 0.9 0.3]); %#ok<NASGU>
        % Contrasts that work across visit (eg. group eff at visit 1 vs 2)
        SelectCrVContrastView = uicontrol(EffectViewButtonGroup,...
            'style', 'radiobutton',...
            'string', 'Cross-Visit Contrast View',...
            'units', 'normalized',...
            'tag', 'SelectCrVContrastView',...
            'callback', @beta_typeof_view_select,...
            'Position',[0.1 0.01 0.9 0.3]); %#ok<NASGU>
        
        selectSubject = uicontrol('Parent', icPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.51, 0.48, 0.1], ...
            'Tag', 'selectSubject', 'Callback', @(src, event)load_functional_images, ...
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
        deleteSubPopButton = uicontrol('Parent', subPopPanel, ...
            'Units', 'Normalized', ...
            'String', 'Delete Sub-Population', ...
            'Position', [0.15, 0.01, 0.7, 0.15], ...
            'Tag', 'compareSubPops', 'Callback', @removeSubPop); %#ok<NASGU>
        
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
        crossVisitContrastDisplay = uitable('Parent', betaContrastPanel, ...
            'Units', 'Normalized', ...
            'Position', [0.1, 0.17, 0.8, 0.8], ...
            'Tag', 'crossVisitContrastDisplay'); %#ok<NASGU>
        editCrossVisitContrasts = uicontrol('Parent', betaContrastPanel, ...
            'Units', 'Normalized', ...
            'String', 'Edit Cross-Visit Contrasts', ...
            'Position', [0.26, 0.01, 0.49, 0.15], ...
            'Tag', 'editCrossVisitContrasts',...
            'Callback', @openCrossVisitContrastSpecificationWindow); %#ok<NASGU>
        removeContrastButton = uicontrol('Parent', betaContrastPanel, ...
            'Units', 'Normalized', ...
            'String', 'Remove A Contrast', ...
            'Position', [0.51, 0.01, 0.49, 0.15], ...
            'Tag', 'removeContrast', 'Callback', @removeContrast); %#ok<NASGU>
        
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

    % Allow the user to decide which colorbar they want to use. Default is
    % parula
    function set_typeof_colorbar(varargin)
        % Remove the checkmark from the old selected colormap
        set(findobj('tag', ['cb' ddat.color_map]), 'checked', 'off');
        % Get the new map
        ddat.color_map = lower(varargin{1}.Label);
        ddat.highcolor = eval(ddat.color_map);
        % Place a check mark next to the currently selected colormap
        set(findobj('tag', ['cb' ddat.color_map]), 'checked', 'on');
        % Update the viewer
        update_brain_data;
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
        
        if ddat.nVisit > 1
            set(findobj('tag', 'licaMenu'), 'Visible', 'on');
        else
            set(findobj('tag', 'licaMenu'), 'Visible', 'off');
        end
        
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
            
            % Determine if should show standard contrast information or
            % cross-visit contrast information
            if strcmp( get(findobj('tag', 'EffectTypeButtonGroup'),...
                    'SelectedObject').String, 'Cross-Visit Contrast View')
                set( findobj('tag', 'editCrossVisitContrasts'), 'visible', 'on' );
                set( findobj('tag', 'crossVisitContrastDisplay'), 'visible', 'on' );
                set( findobj('tag', 'newContrast'), 'visible', 'off' );
                set( findobj('tag', 'removeContrast'), 'visible', 'off' );
                set( findobj('tag', 'contrastDisplay'), 'visible', 'off' );
            else
                set( findobj('tag', 'editCrossVisitContrasts'), 'visible', 'off' );
                set( findobj('tag', 'crossVisitContrastDisplay'), 'visible', 'off' );
                set( findobj('tag', 'newContrast'), 'visible', 'on' );
                set( findobj('tag', 'removeContrast'), 'visible', 'on' );
                set( findobj('tag', 'contrastDisplay'), 'visible', 'on' );
            end
            
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
        
        if strcmp(ddat.type, 'icsel')
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.34, 0.01 .31 .39]);
            set( findobj('Tag', 'icPanel'), 'Position',[.34, 0.42 .31 .57]);
            set( findobj('Tag', 'locPanel'), 'Position',[.01, 0.01 .31 .98]);
            %set( findobj('Tag', 'ViewSelectionPanel'), 'Position',[.67, 0.51 .31 .48]);
            %set( findobj('Tag', 'SubpopulationControl'), 'Position',[.67, 0.01 .31 .48]);
            set( findobj('tag', 'EffectTypeButtonGroup'), 'visible', 'off' );
            set( findobj('tag', 'subPopSelect1'), 'visible', 'off');
            set(findobj('Tag', 'icSelectionPanel'), 'Visible', 'On');
            set(findobj('Tag', 'icSelectionPanel'), 'Position', [0.67 0.11 0.31 0.88]);
            % Close Button
            set(findobj('Tag', 'icSelectCloseButton'), 'Visible', 'On');
            set(findobj('Tag', 'icSelectCloseButton'), 'Position', [0.67 0.01 0.31 0.05]);
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
            ddat.viewTracker = zeros(ddat.nVisit, 1);
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
            n_subpop = sum(ddat.valid_LC_subpop);

            disp('create LC_subpop_names and load from it!')

            % Load saved viewTracker information
            ddat.viewTracker = ddat.saved_subpop_viewTracker;

            % Fill out the selection table
            table_data = cell(ddat.nVisit, 0);
            for k=1:ddat.nVisit
                for p=1:length(ddat.valid_LC_subpop)
                    if ddat.valid_LC_subpop(p) == 1
                        % enable clicking on this cell and set yes/no
                        if ddat.viewTracker(k, p) > 0
                            table_data{k, p} = 'yes';
                        else
                            table_data{k, p} = 'no';
                        end
                    else
                        % disable clicking on this cell
                        
                    end
                end
            end
            set(findobj('tag', 'ViewSelectTable'), 'Data', table_data);
            set(findobj('tag', 'ViewSelectTable'), 'ColumnName', {});

            if prod(size(subpop_names, 1)) == 1
                subpop_names = {subpop_names};
            end
            
            % Set the visit names (rows)
            for k=1:ddat.nVisit; visit_names{k} = ['Visit ' num2str(k)]; end
            set(findobj('tag', 'ViewSelectTable'), 'RowName', visit_names');

            % set the column names (subpopulations)
            for p=1:n_subpop; column_names{p} = ddat.LC_subpop_names{p}; end;
            if n_subpop > 0
                set(findobj('tag', 'ViewSelectTable'), 'ColumnName', column_names');
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
                        if ddat.viewTracker(k, p) > 0
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
            elseif strcmp(get(get(findobj('tag', 'EffectTypeButtonGroup'),...
                    'SelectedObject'), 'String'), 'Contrast View')
                
                % Check the contrast table to find how many contrasts have
                % been created. This will be the number of columns
                contrasts = ddat.LC_contrasts;
                contrast_names = get(findobj('tag', 'contrastDisplay'), 'RowName');
                n_contrast = sum(ddat.valid_LC_contrast);
                
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
                    for p=1:length(ddat.valid_LC_contrast)
                        if ddat.valid_LC_contrast(p) == 1
                            if ddat.viewTracker(k, p) > 0
                                table_data{k, p} = 'yes';
                            else
                                table_data{k, p} = 'no';
                            end
                        end
                    end
                end
                set(findobj('tag', 'ViewSelectTable'), 'Data', table_data);
                set(findobj('tag', 'ViewSelectTable'), 'ColumnName', {});
                
                % Set the visit names (rows)
                for k=1:ddat.nVisit; visit_names{k} = ['Visit ' num2str(k)]; end
                set(findobj('tag', 'ViewSelectTable'), 'RowName', visit_names');
                
                % set the column names (contrasts)
                if n_contrast > 0
                    set(findobj('tag', 'ViewSelectTable'), 'ColumnName', contrast_names');
                end
                
            elseif strcmp(get(get(findobj('tag', 'EffectTypeButtonGroup'),...
                    'SelectedObject'), 'String'), 'Cross-Visit Contrast View')
                
                ddat.viewTracker = ddat.saved_cross_visit_contrast_viewTracker;
                
                nCVC = length(ddat.LC_cross_visit_contrast_strings);
                table_data = cell(nCVC, 1);
                for k=1:nCVC
                    if ddat.viewTracker(k, 1) > 0
                        table_data{k, 1} = 'yes';
                    else
                        table_data{k, 1} = 'no';
                    end
                end
                
                set(findobj('tag', 'ViewSelectTable'), 'Data', table_data);
                
                % Row names are the cross-visit-contrast names
                set(findobj('tag', 'ViewSelectTable'), 'RowName', ddat.LC_cross_visit_contrast_names);
                
                % set the column names (covariates)
                set(findobj('tag', 'ViewSelectTable'), 'ColumnName', {'Viewing Contrast'});
                
            else
                
                disp('ERROR - unrecognized view type')
                
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
            selected_col = eventdata.Indices(2);
  
            % If doing cross-visit contrast, have to fix this up
%             cvc_selected = strcmp(get(get(findobj('tag',...
%                 'EffectTypeButtonGroup'), 'SelectedObject'),...
%                 'String'), 'Cross-Visit Contrast View');
%             if cvc_selected == 1
%                 visit_number = 1;
%                 selected_pop = selected_row;
%             else
%                 % Find the visit this corresponds to, this will be the column
%                 % of the img object we load in
%                 visit_number = str2double(eventdata.Source.RowName{selected_row}(end-1:end));
%             end
            
            % Make sure that this column is valid. It will always be valid
            % for group, subpop, or regular beta. However, it might not be
            % filled out yet for a contrast or a sub-population
            isValidColumn = 1;
            contrast_selected = strcmp(get(get(findobj('tag',...
                'EffectTypeButtonGroup'), 'SelectedObject'),...
                'String'), 'Contrast View');
            if strcmp(ddat.type, 'beta') & contrast_selected
                isValidColumn = ddat.valid_LC_contrast(selected_col);
            elseif strcmp(ddat.type, 'subpop')
                isValidColumn = ddat.valid_LC_subpop(selected_col);
            end
            
            if isValidColumn == 1
            
            % If not viewed, add to viewer, else remove
            
%             if cvc_selected == 1
%                 isNo = strcmp(eventdata.Source.Data{selected_pop, 1}, 'no');
%             else
%                 isNo = strcmp(eventdata.Source.Data{selected_row, selected_pop}, 'no');
%             end
            isNo = strcmp(eventdata.Source.Data{selected_row, selected_col}, 'no');
            
            if isNo
                
                % Set to yes
                eventdata.Source.Data{selected_row, selected_col} = 'yes';
                
                % Add to tracker
                ddat.viewTracker(selected_row, selected_col) = 1;
                ddat.viewTracker( ddat.viewTracker > 0 ) = cumsum( ddat.viewTracker(ddat.viewTracker > 0)); % renumber
                
                % Update axes existence
                set_number_of_brain_axes(0);
                                
                % TODO remove below two lines; they are from old system
%                 if cvc_selected == 1
%                     update_brain_maps('updateCombinedImage', [selected_pop, visit_number]);
%                 else
%                     update_brain_maps('updateCombinedImage', [selected_pop, visit_number]);
%                 end
                update_brain_maps('updateCombinedImage', [selected_row, selected_col]);
                
                % Stack the update chain at step 1
                %update_brain_data;
                
            else
                
                % Set to no
                eventdata.Source.Data{selected_row, selected_col} = 'no';
                
                % Remove from tracker
                ddat.viewTracker(selected_row, selected_col) = 0;
                ddat.viewTracker( ddat.viewTracker > 0 ) = cumsum( ddat.viewTracker(ddat.viewTracker > 0)); % renumber
                
                % Update axes visibility
                set(findobj('Tag', ['CoronalAxes'  num2str(selected_row) '_'...
                    num2str(selected_col)] ) , 'visible', 'off');
                set(findobj('Tag', ['AxialAxes'    num2str(selected_row) '_'...
                    num2str(selected_col)] ) , 'visible', 'off');
                set(findobj('Tag', ['SagittalAxes' num2str(selected_row) '_'...
                    num2str(selected_col)] ) , 'visible', 'off');
                
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
                    
                    effect_view_selected = strcmp(get(get(findobj('tag',...
                        'EffectTypeButtonGroup'), 'SelectedObject'),...
                        'String'), 'Effect View');
                    
                    if effect_view_selected
                        ddat.saved_beta_viewTracker = ddat.viewTracker;
                    else
                        if strcmp(get(get(findobj('tag',...
                        'EffectTypeButtonGroup'), 'SelectedObject'),...
                        'String'), 'Contrast View');
                            ddat.saved_contrast_viewTracker = ddat.viewTracker;
                        else
                            ddat.saved_cross_visit_contrast_viewTracker = ddat.viewTracker;
                        end
                    end

                case 'subj'
                    ddat.saved_subject_viewTracker = ddat.viewTracker;
                case 'subpop'
                    ddat.saved_subpop_viewTracker = ddat.viewTracker;
                otherwise
                    disp('Error updating view table, check strings')
            end
            
            
            end % end of check for a valid column being selected
            
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
        
        % First make sure that trajectory viewer is valid (longitudinal data only)        
        if ddat.nVisit > 1
        
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
                %plot_voxel_trajectory([ddat.sag, ddat.cor, ddat.axi])
                update_all_traj_fields([ddat.sag, ddat.cor, ddat.axi])

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
        end % end of check that we are using longitudinal viewer
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
            %plot_voxel_trajectory(newCoordinates)
            update_all_traj_fields(newCoordinates);
        end
        
    end

%% New function -> completely draws all plots based on saved voxels and on
% the currently select voxel. Intended as a replacement for the combination
% of plot_voxel_trajectory and update_all_traj_fields(old version)

% voxelIndex is the currently selected voxel -> dont think is needed
    function update_all_traj_fields(voxelIndex)
        
        currentlySelectedVoxel = num2str([ddat.sag, ddat.cor, ddat.axi]);
        
         % TODO - pre-create this somewhere -> enumeration of line type
        % by marker type
        marker_style = {'none'; 'o'; '+'};
        line_style = {'-'; '--'};
        traj_style_settings = cell( length(marker_style)*length(line_style), 2);
        style_ind = 0;
        for imarkerstyle = 1:length(marker_style)
            for ilinetype = 1:length(line_style)
                style_ind = style_ind + 1;
                traj_style_settings{style_ind, 1} = marker_style{imarkerstyle};
                traj_style_settings{style_ind, 2} = line_style{ilinetype};
            end
        end
        
        % verify that trajectories are being plotted
        if ddat.trajectoryActive == 1
            
            % Get the axes to plot to
            trajAxesHandle = findobj('Tag', 'TrajAxes');
            
            % Step 0: Remove all lines
            for iline = length(trajAxesHandle.Children):-1:1
                 delete(trajAxesHandle.Children(iline));
            end
            
            % Make sure there is something to plot
            if ~isempty(ddat.oimg)
            
                % Determine required size of Yaxis
                trajAxesHandle.YLim(1) = min(min(min(cell2mat(ddat.oimg)))) ;
                trajAxesHandle.YLim(2) = max(max(max(cell2mat(ddat.oimg)))) ;

                % Step 1: Plot (in blue) all voxels from the saved table
                nTypePlot = size(ddat.oimg, 1); % 1 for agg, nbeta for beta, ncontr for ctr etc
                set(trajAxesHandle.Legend, 'visible', 'off');
                savedVoxels = get( findobj('Tag', 'TrajTable'), 'Data');
                for iSavedVoxel = 1:size(savedVoxels, 1)
                    lineName = num2str([savedVoxels{iSavedVoxel, :}]);
                    for iTypePlot = 1:nTypePlot
                        % Get the trajectory
                        traj = zeros(size(ddat.oimg, 2), 1);
                        for iVisit = 1:size(ddat.oimg, 2)
                            traj(iVisit) = ddat.oimg{iTypePlot, iVisit}(savedVoxels{iSavedVoxel, 1},...
                                savedVoxels{iSavedVoxel, 2},...
                                savedVoxels{iSavedVoxel, 3});
                        end
                        line(trajAxesHandle, 1:ddat.nVisit,...
                            traj,...
                            'Tag', lineName,...
                            'Color', 'Blue',...
                            'LineStyle', traj_style_settings{iTypePlot, 2},...
                            'Marker', traj_style_settings{iTypePlot, 1});
                        drawnow;
                    end
                end

                % Step 2: Plot the currently selected voxel in red
                for iTypePlot = 1:nTypePlot
                    % Get the trajectory
                    traj = zeros(size(ddat.oimg, 2), 1);
                    for iVisit = 1:size(ddat.oimg, 2)
                        traj(iVisit) = ddat.oimg{iTypePlot, iVisit}(ddat.sag, ddat.cor, ddat.axi);
                    end
                    % plot it
                    lineName = num2str([ddat.sag, ddat.cor, ddat.axi]);
                    line(trajAxesHandle, 1:ddat.nVisit,...
                        traj,...
                        'Tag', lineName,...
                        'Color', 'Red',...
                        'LineStyle', traj_style_settings{iTypePlot, 2},...
                        'Marker', traj_style_settings{iTypePlot, 1});
                    drawnow;
                end

                % Step 3: Determine legend labels
                switch ddat.type
                    case 'beta'
                        switch get(findobj('tag', 'EffectTypeButtonGroup'), 'SelectedObject').String
                            case 'Effect View'
                                legendLabels = ddat.varNamesX;
                            case 'Contrast View'
                                legendLabels = ddat.LC_contrast_names;
                            case 'Cross-Visit Contrast View'
                                legendLabels = ddat.LC_contrast_names;
                                disp('NEED TO SET SUB POP NAMES')
                            otherwise
                                disp('Error, unrecognized setting for beta view type')
                        end
                    case 'subpop'
                        legendLabels = ddat.LC_subpop_names;
                    case 'grp'
                        legendLabels = 'Aggregate';
                    case 'subj'
                        legendLabels = findobj('tag', 'selectSubject').String{findobj('tag', 'selectSubject').Value};
                    otherwise
                end
                legend(trajAxesHandle,...
                        legendLabels ,'Location','NorthEastOutside');
            
            end % end of check that there is data to plot. 
            
        end
        
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
        %plot_voxel_trajectory([ddat.sag, ddat.cor, ddat.axi]);
        update_all_traj_fields([ddat.sag, ddat.cor, ddat.axi]);
    end

%% Initial Display

%%% initialDisp - sets up the initial state of the display window based
% on the user selection (aggregate viewer, covariate effect viewer, etc)

    function initialDisp(hObject,callbackdata)
        set(findobj('Tag', 'thresholdSlider'), 'Value', 0);
        set(findobj('Tag', 'manualThreshold'), 'String', '0');
        setup_ViewSelectTable;
        
%         ddat.nCompare = 1;
%         % Stretch containers storing the images to have the correct number
%         % of objects (1)
%         ddat.axial_image    = cell(ddat.nCompare, ddat.nVisit);
%         ddat.sagittal_image = cell(ddat.nCompare, ddat.nVisit);
%         ddat.coronal_image  = cell(ddat.nCompare, ddat.nVisit);
%         ddat.axial_xline    = cell(ddat.nCompare, ddat.nVisit);
%         ddat.axial_yline    = cell(ddat.nCompare, ddat.nVisit);
%         ddat.coronal_xline  = cell(ddat.nCompare, ddat.nVisit);
%         ddat.coronal_yline  = cell(ddat.nCompare, ddat.nVisit);
%         ddat.sagittal_xline = cell(ddat.nCompare, ddat.nVisit);
%         ddat.sagittal_yline = cell(ddat.nCompare, ddat.nVisit);
%         ddat.img = cell(ddat.nCompare, ddat.nVisit); ddat.oimg = cell(ddat.nCompare, ddat.nVisit);
%         % New 8/29/19, used to keep track of which voxels to show
%         ddat.maskingStatus = cell(ddat.nCompare, ddat.nVisit);
        
        % Change what display panels are seen based on what viewer is open.
        if strcmp(ddat.type, 'grp')
            
            ddat.viewTracker = zeros(ddat.nVisit, 1);
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
            
        elseif strcmp(ddat.type, 'subpop')
            set(findobj('Tag', 'useEmpiricalVar'), 'Visible', 'Off');
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'Off');
            set( findobj('Tag', 'createMask'), 'Visible', 'Off' );
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'On');
            set(findobj('Tag', 'covariateContrastControl'), 'Visible', 'Off');
            set( findobj('Tag', 'selectSubject'), 'Visible', 'Off');
            % Set up the sub-population box
            if ddat.subPopExists == 0
                newColnames = ddat.varNamesX;
                set(findobj('Tag', 'subPopDisplay'), 'Data', cell(0, ddat.p));
                set(findobj('Tag', 'subPopDisplay'), 'ColumnName', newColnames);
                set(findobj('Tag', 'subPopDisplay'), 'ColumnEditable', true);
            end
            % Place the boxes in the correct locations
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.35, 0.01 .32 .19]);
            set( findobj('Tag', 'icPanel'), 'Position',[.35, 0.21 .32 .25]);
            set( findobj('Tag', 'locPanel'), 'Position',[.01, 0.01 .32 .45]);

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
            
            ddat.viewTracker = zeros(ddat.nVisit, 1);
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
            setupSubMenu;
            
        elseif strcmp(ddat.type, 'icsel')
            % TODO check 4 lines below for removal
            set(findobj('Tag', 'icSelectionPanel'), 'Visible', 'On');
            set(findobj('Tag', 'keepIC'), 'Visible', 'On');
            set(findobj('Tag', 'viewerMenu'), 'Visible', 'Off');
            set(findobj('Tag', 'icSelectCloseButton'), 'Visible', 'On');
            % Place the boxes in the correct locations
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.35, 0.01 .32 .19]);
            set( findobj('Tag', 'icPanel'), 'Position',[.35, 0.21 .32 .25]);
            set( findobj('Tag', 'locPanel'), 'Position',[.01, 0.01 .32 .45]);
            set( findobj('Tag', 'ViewSelectionPanel'), 'Visible', 'off');
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
        
        % TODO move to its own function that the user can pick from
        % Set up the initial colorbar.
%         jet2=jet(64); jet2(38:end, :)=[];
%         hot2=hot(64); hot2(end-5:end, :)=[]; hot2(1:4, :)=[];
%         hot2(1:2:38, :)=[]; hot2(2:2:16, :)=[]; hot2=flipud(hot2);
%         hot3=[jet2; hot2];
%         ddat.hot3 = jet(64);
        %ddat.highcolor = ddat.color_map;
        ddat.basecolor = gray(191);
        ddat.colorlevel = 256;
        
        % Look for an appropriately sized mask file.
        % TODO check if can remove - looks like it
        %maskSearch;

        load_functional_images;
        
        % TODO check if can remove - yes, can
        %updateColorbar;

        % Setup each of the view sliders
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
        
        % Origin Information for the text box.
        set(findobj('Tag', 'originalPos'),'String',...
            sprintf('%7.0d %7.0d %7.0d',ddat.origin(1),ddat.origin(2),ddat.origin(3)));
        set(findobj('Tag', 'dimension'),'String',...
            sprintf('%7.0d %7.0d %7.0d',ddat.xdim,ddat.ydim,ddat.zdim));
       
    end


%% Anatomical Image and Mask Functions
    function setupAnatomical(hObject, callbackdata)
        
        
        %% Check if user has specified an anatomical image if not, check
        % if there is a matching anatomical in provided list
        if ~strcmp(ddat.user_specified_anatomical_file, '')
            ddat.mri_struct = load_nii(ddat.user_specified_anatomical_file);
        % 2mm voxel case
        elseif ddat.xdim == 182 && ddat.ydim == 218 && ddat.zdim == 182
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
%
% Verified in use 3/12/20

    function update_brain_maps(varargin)
        
        % Log for what steps are required (defaults here)
        updateCombinedImage = 0; updateCombinedImageElements = 0; %updateScaling=0;
        updateColorbarFlag = 1;
        updateMasking = 0;
        %updateMasking = get(findobj('tag', 'maskSelect'), 'value') > 1;
        
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
                [rc, cc] = find(cellfun(@isempty, ddat.oimg) == 0);
                if ~isempty(rc) > 0
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
% Verified in use 3.12/20

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
                    ddat.oimg{iVisit, 1} = newData.img;
                    ddat.maskingStatus{iVisit, 1} = ~isnan(ddat.oimg{iVisit, 1});
                end
                
            % IC Selection Window
            case 'icsel'       
                newData = load_nii([ddat.outdir '/_iniIC_' num2str(sel_IC) '.nii']);
                ddat.oimg{1, 1} = newData.img;
                ddat.maskingStatus{1, 1} = ~isnan(ddat.oimg{1, 1});
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
                contrast_selected = ~strcmp(get(get(findobj('tag',...
                    'EffectTypeButtonGroup'), 'SelectedObject'),...
                    'String'), 'Effect View');
            
                % This is just here for dimension purposes later
                % TODO check if can delete now
                refimg = zeros(size(beta_raw{1, 1}));
                    
                if contrast_selected
                    
                    % Check which type of contrast viewer is selected
                    selected_contrast_type = get(get(findobj('tag',...
                        'EffectTypeButtonGroup'), 'SelectedObject'),...
                        'String');
                    
                    % Standard Contrasts
                    if strcmp(selected_contrast_type, 'Contrast View')
                        % Check to make sure a contrast has been specified
                        if size(ddat.LC_contrasts, 1) > 0
                            % Fill out each linear combination based on indices
                            nUpdate = size(indices, 1); 
                            for iUpdate = 1:nUpdate
                                disp('add random intercept')
                                disp('check for interactions')

                                % Cell to update - for contrast view
                                % rows are visits and columns are contrasts
                                iRow = indices(iUpdate, 1); iCol = indices(iUpdate, 2);

                                % The column of the contrast is the linear
                                % combination currently viewing
                                ddat.oimg{iRow, iCol} = zeros(size(beta_raw{1, 1}));
                                ddat.maskingStatus{iRow, iCol} = ~isnan(beta_raw{1, 1});
                                % Main Effects
                                % NOTE - beta raw is covariate x visit
                                for xi = 1:ddat.p
                                    ddat.oimg{iRow, iCol} = ddat.oimg{iRow, iCol} + ...
                                        str2double(ddat.LC_contrasts{iCol, xi}) .* beta_raw{xi, iRow};
                                end
                            end
                        end % end of check that contrasts have been specified (standard view)
                    else
                        % Check to make sure a contrast has been specified
                        if size(ddat.LC_cross_visit_contrasts, 1) > 0
                            % Fill out each linear combination based on indices
                            nUpdate = size(indices, 1); 
                            for iUpdate = 1:nUpdate
                                % Cell to update
                                iRow = indices(iUpdate, 1); iCol = indices(iUpdate, 2);
                                % The column of the contrast is the linear
                                % combination currently viewing
                                ddat.oimg{iRow, iCol} = zeros(size(beta_raw{1, 1}));
                                ddat.maskingStatus{iRow, iCol} = ~isnan(beta_raw{1, 1});
                                % Main Effects
                                % TODO change this to nVisit * P ?
                                ind = 0;
                                for j = 1:ddat.nVisit
                                    for xi = 1:ddat.p
                                        ind = ind + 1;
                                        ddat.oimg{iRow, iCol} = ddat.oimg{iRow, iCol} + ...
                                            (ddat.LC_cross_visit_contrasts(iRow, ind)) .* beta_raw{xi, j};
                                    end
                                end
                                
                            end 
                        end % end of check that contrasts have been specified (cross-visit view)
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
                visit_effect = {};
                for p = 1:ddat.p
                    for iVisit = 1:ddat.nVisit
                        % File name
                        ndata = load_nii([ddat.outdir '/' ddat.outpre...
                            '_beta_cov' num2str(p) '_IC' num2str(sel_IC) '_visit'...
                            num2str(iVisit) '.nii']);

                        beta_raw{iVisit, p} = ndata.img;                     
                    end
                end
                
                % load the visit effects
                if ddat.nVisit > 1
                    for iVisit = 1:ddat.nVisit
                        visit_effect_fname = [ddat.outdir '/' ddat.outpre '_visit_effect' '_IC'...
                            num2str(sel_IC) '_visit' num2str(iVisit) '.nii'];
                        ndata = load_nii(visit_effect_fname);
                        visit_effect{iVisit} = ndata.img;
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
                    disp('check for interactions')

                    % Cell to update
                    iRow = indices(iUpdate, 1); iCol = indices(iUpdate, 2);

                    % The column of the contrast is the linear
                    % combination currently viewing
                    if ddat.nVisit > 1
                        ddat.oimg{iRow, iCol} = S0_maps + visit_effect{iRow};
                    else
                        ddat.oimg{iRow, iCol} = S0_maps;
                    end
                    
                    ddat.maskingStatus{iRow, iCol} = ~isnan(S0_maps);
                    
                    % Main Effects - rows are visits, columns are subpops
                    for xi = 1:ddat.p
                        ddat.oimg{iRow, iCol} = ddat.oimg{iRow, iCol} + ...
                            str2double(ddat.LC_subpops{iCol, xi}) .* beta_raw{iRow, xi};
                    end
                end
                end
                
            case 'subj'
                
                disp('verify that order is correct. Should be same from saving function from EM alg')
                
                %disp('todo: move "loading a subject" into its own function, call it here')
                
%                 % Load the .mat file containing the subject maps
%                 subj_results = load([ddat.outdir '/' ddat.outpre '_subject_IC_estimates.mat']);
%                 
%                 % Load the masking information
%                 runinfo = load([ddat.outdir '/' ddat.outpre '_runinfo.mat']);
%                 valid_voxels = runinfo.validVoxels;
                
                % Get the selected subject
                iSubj = get(findobj('tag', 'selectSubject'), 'value'); 
                
                create_subject_image(iSubj, sel_IC)
                
                
            %case 'iniguess'
            %    updateMasking = varargin{index+1};    
            otherwise
                disp('CHECK VIEWTYPE SPECIFICATION')
                
        end
        
       
        
        % Check if all of the anatomical image/dimension bookkeeping needs
        % to be performed. This should only need to happen upon first
        % opening the view window.

              
        % Get the size of each dimension.
        if ~isfield(ddat, 'xdim')
            dim = ddat.voxSize;
            ddat.xdim = ddat.voxSize(1); ddat.ydim = ddat.voxSize(2); ddat.zdim = ddat.voxSize(3);
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
        
        % Make sure that all augmenting windows are updated to reflect new
        % map
        update_all_traj_fields;
        
    end


% Function to load the requested IC for a single subject, all visits
% verified in use 3/12/20
    function create_subject_image(iSubj, iIC)
        
        % Load the .mat file containing the subject maps
        subj_results = load([ddat.outdir '/' ddat.outpre '_subject_IC_estimates.mat']);

        % Load the masking information
        runinfo = load([ddat.outdir '/' ddat.outpre '_runinfo.mat']);
        valid_voxels = runinfo.validVoxels;

         % Load each visit
        for iVisit = 1:ddat.nVisit

            %j = iVisit - 1;
            %ij = j+1+(iSubj-1)*(ddat.nVisit);
            allicsubj = subj_results.subICmean(:, :, iSubj, iVisit);
            new_image = zeros(runinfo.voxSize);
            new_image(valid_voxels) = allicsubj(iIC, :);
            ddat.oimg{iVisit, 1} = new_image;
            ddat.maskingStatus{iVisit, 1} = ~isnan(ddat.oimg{iVisit, 1});

        end
        
    end



% New version of the create combined image function
% issue is with what to scale by... XXXXX
% verified in use 3/12/20
    function create_combined_image(indices)
        
        nUpdate = size(indices, 1);
        
        % Find the min and max value of each image.
        minVal1 = min(min(min(cat(1,ddat.img{:}))));
        maxVal1 = max(max(max(cat(1,ddat.img{:}))));
        
        % Get user selected cutoff
        cutoff = get( findobj('Tag', 'thresholdSlider'), 'value');
        set( findobj('Tag', 'manualThreshold'), 'string', num2str(cutoff) );
        
        
        cvc_selected = strcmp(get(get(findobj('tag',...
                'EffectTypeButtonGroup'), 'SelectedObject'),...
                'String'), 'Cross-Visit Contrast View');
        
        for iUpdate = 1:nUpdate
            
            % Cell to update
            iRow = indices(iUpdate, 1); iCol = indices(iUpdate, 2);
            
            % Have to reverse the order for cross-visit contrast (need
            % better solution to this long term)
%             if cvc_selected == 1
%                 iRow = indices(iUpdate, 2);
%                 iCol = indices(iUpdate, 1);
%             end
            
            % Scale the functional image
            tempImage = ddat.img{iRow, iCol};
            %tempImage(ddat.maskingStatus{iRow, iCol} == 0 ) = nan;
            tempImage(isnan(tempImage)) = minVal1 - 1;
            minVal2 = minVal1 - 1;
            %ddat.scaledFunc{iRow, iCol} = scale_in(tempImage, minVal2, maxVal1, 63);            
            ddat.scaledFunc{iRow, iCol} = scale_in(tempImage, minVal2, maxVal1, size(ddat.highcolor, 1) - 1);
            
        
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
% verified in use 3.12.20
    function update_axes_image(varargin)
        
        [nRow, nCol] = size(ddat.oimg);
        
        aspect = 1./ddat.daspect;
        
%         % Testing a fix for reverse viewTracker in cross visit contrast
%         % case
%         if strcmp(get(get(findobj('tag',...
%                 'EffectTypeButtonGroup'), 'SelectedObject'),...
%                 'String'), 'Cross-Visit Contrast View');
%             [nCol, nRow] = size(ddat.oimg);
%         end

        isCVC = strcmp(get(get(findobj('tag',...
                 'EffectTypeButtonGroup'), 'SelectedObject'),...
                 'String'), 'Cross-Visit Contrast View');

        for iRow = 1:nRow
            for iCol = 1:nCol
                
                % Check that this is in view before redisplaying
                isViewed = ddat.viewTracker(iRow, iCol) > 0;
                % Get the corresponding axes. This SHOULD be in
                % numerical order, but we include extra step here just
                % to be safe
                axes_index = ddat.viewTracker(iRow, iCol);
                if isCVC
                    %isViewed = ddat.viewTracker(iCol, iRow) > 0;
                    %axes_index = ddat.viewTracker(iCol, iRow);
                end
                
                if isViewed
                    
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
% verified 3/12/20
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


%% Slider Movement - all three in use 3/12/20

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

%% Masking

    % Verified in use 3/12/20
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


% Function called when the user selected a button from the
% EffectViewButtonGroup
% Verified in use 3/12/20
% TODO check if this is what is already being viewed?
    function beta_typeof_view_select(hObject, callbackdata)
        
        %disp('REMOVE THE LOADING HERE, IT SHOULD BE HAPPENING ON FN CALL')
        
        % Effect view was selected -> load corresponding betas
        if strcmp(callbackdata.Source.String, 'Effect View')
            
            % Edit the view selection table
            setup_ViewSelectTable;
            ddat.viewingContrast = 0;
          
            % Contrast View
        else
            
            setup_ViewSelectTable;
            disp('set this!')
            ddat.viewingContrast = 1;
            
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



   % Function updating user-specific linear combinations (contrasts or sub
   % populations. Replaces newPopCellEdit from previous version of the
   % toolbox.
   % verified in use 3/12
   function update_linear_combination(hObject, callbackdata)
        
        % When the user edits a cell, need to make sure that it is a valid level
        valid = check_valid_covariate_value(callbackdata);
        
        disp('add valid check before proceeding.')
        
        [nsubpop ign] = size( get(findobj('Tag', 'subPopSelect'),'String'));
        
        %% Determine if need to autofill the interaction term:
        % IF sub population - yes
        % IF contrast - no
        rowIndex = callbackdata.Indices(1);
        nMainEffects = length(ddat.covTypes);
        if strcmp(ddat.type, 'beta')
            allFilledOut = ~any(cellfun(@isempty,...
                callbackdata.Source.Data(rowIndex, 1:end)));
        else
            allFilledOut = ~any(cellfun(@isempty,...
                callbackdata.Source.Data(rowIndex, 1:nMainEffects)));
        end
        
        
        % If all factors are filled out, then update the interactions
        if allFilledOut == 1
            [nInt, nCov] = size(ddat.interactions);
            
            %% If sub-population viewer then covariates determine interactions
            % so we can auto fill them:
            if strcmp(ddat.type, 'subpop')
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
            
            % Update appropriate LC list, note this is different from
            % viewtable, which only gets updated to match this if currently
            % viewing that type. These variables are stored in the
            % background, even if we switch viewer types
            %LC = cellfun(@str2num, callbackdata.Source.Data(callbackdata.Indices(1), :));
            if strcmp(ddat.type, 'beta')
                ddat.LC_contrasts = callbackdata.Source.Data; 
                ddat.valid_LC_contrast(callbackdata.Indices(1)) = 1; 
                
                % Update the size of saved viewTracker
                size_diff = size(callbackdata.Source.Data, 1) - size(ddat.saved_contrast_viewTracker, 2);
                if size_diff > 0
                    ddat.saved_contrast_viewTracker = [ddat.saved_contrast_viewTracker zeros(ddat.nVisit, size_diff)];
                end
                
            else
                ddat.LC_subpops = callbackdata.Source.Data;
                ddat.valid_LC_subpop(callbackdata.Indices(1)) = 1; 
                
                % Update the size of saved viewTracker
                size_diff = size(callbackdata.Source.Data, 1) - size(ddat.saved_subpop_viewTracker, 2);
                if size_diff > 0
                    ddat.saved_subpop_viewTracker = [ddat.saved_subpop_viewTracker zeros(ddat.nVisit, size_diff)];
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
    % verified in use 3/12
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
% Verified in use 3/12
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



%% Function to update the colorbar
% verified in use 3/12/20
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
        % size(ddat.highcolor, 1)
        %%ddat.scaled_pp_labels = scale_in(ddat.colorbar_labels, min_functmap_value, max_functmap_value, 63);
        ddat.scaled_pp_labels = scale_in(ddat.colorbar_labels, min_functmap_value, max_functmap_value, size(ddat.highcolor, 1) - 1);
        % Update the colorbar
        axes(findobj('Tag', 'colorMap'));
        set(gca,'NextPlot','add')
        colorbar_plot( findobj('Tag', 'colorMap'), ddat.colorbar_labels,...
            ddat.scaled_pp_labels, ddat.highcolor);
        
    end


% Function to check the status of the Z-score button and update .img
% attribute of ddat accordingly. Replaces the old updateZImg function
% verified used 3/12
    function update_Z_maps(~)
        
        % Check if Z-scroes are enabled or disabled
        Z_enabled = get(findobj('Tag', 'viewZScores'), 'Value');
        
        % Number of currently selected independent component
        current_IC = get(findobj('Tag', 'ICselect'), 'val');
        
        % If looking at effect/contrast maps, go ahead and load all of the
        % variances for the currently selected IC and visits, this way we do not keep
        % reloading them during the loop
        if strcmp('beta', ddat.type) && (Z_enabled == 1)

              current_vars = load( fullfile(ddat.outdir, [ddat.outpre '_BetaVarEst_IC' num2str(current_IC)...
                            '.mat']) ).betaVarEst;
        end
        
        % Determine if cross-visit contrast
        cvc_selected = strcmp(get(get(findobj('tag',...
            'EffectTypeButtonGroup'), 'SelectedObject'),...
            'String'), 'Cross-Visit Contrast View');
        
        for iPop = 1:size(ddat.viewTracker, 2)
            for iVisit = 1:size(ddat.viewTracker, 1)
                %if ddat.viewTracker(iPop, iVisit) > 0
                    
                    % Turn on Z-scores
                    if Z_enabled == 1
                        
                        if strcmp('beta', ddat.type)

                            if (ddat.viewingContrast == 0)
                                
                                % create the appropriate vector multiplier
                                % to pick out the current covariate at the
                                % current visit
                                csel = zeros( size(ddat.viewTracker, 2) + 1 , 1) ;
                                csel(iPop + 1) = 1;
                                ctr = createContrast( csel, iVisit, ddat.nVisit);
                                
                                % get the corresponding variance term
                                
                                % TODO preallcoate and stop re-doing this
                                % using above current vars
                                %current_var_est = current_vars{iVisit};
                                
                                current_var_est = squeeze(mtimesx(mtimesx(ctr', current_vars(:, :, :, :, :) ), ctr));
                                
                                % Scale using the variance estimate
                                % theoretical estimate is q(p+1) * q(p+1)
                                ddat.img{iVisit, iPop} = ddat.oimg{iVisit, iPop} ./...
                                    sqrt(current_var_est);
                                
                                
                            end
                            
                            if (ddat.viewingContrast == 1)
                                
                   
                                
                                if cvc_selected == 0
                                    contrastSettings = get(findobj('Tag', 'contrastDisplay'), 'Data');
                                    
                                    disp('MAKE SURE THIS IS USING CORRECT POP ROW')

                                    % create the appropriate vector multiplier
                                    % to pick out the current covariate at the
                                    % current visit
                                    %% THIS MIGHT NEED TO BE P, not size of viewTracker, now that changed it
                                    csel = zeros( size(ddat.viewTracker, 2) + 1 , 1) ;
                                    for xi = 1:ddat.p
                                        csel(xi + 1) = str2double(contrastSettings( get(findobj('Tag',...
                                            ['contrastSelect' num2str(1)]), 'Value') , xi));
                                    end
                                    ctr = createContrast( csel, iVisit, ddat.nVisit);         

                                    % Get the variance estimate; loop over each voxel
                                    current_var_est = squeeze(mtimesx(mtimesx(ctr', current_vars(:, :, :, :, :) ), ctr));
                                    ddat.img{iVisit, iPop} = ddat.oimg{iVisit, iPop} ./...
                                        sqrt(current_var_est);
                                else
                                    
                                    % this will be of length nVisit *
                                    % nCovariateEffect, BUT we will also
                                    % need to include the random intercept
                                    % in any contrasts we write (with a 0
                                    % coefficient, just there to make sure
                                    % multiplies correctly with variance
                                    % estimate)
                                    

                                    if iVisit == 1
                                    
                                        contrastSettings = ddat.LC_cross_visit_contrasts(iPop, :);


                                        ctr_length = numel(contrastSettings) + ddat.nVisit - 1;
                                        ctr = zeros(ctr_length, 1);
                                        ind_ctr = 0;
                                        ind_noalpha = 0;
                                        for iVisit = 1:ddat.nVisit
                                            for icov = 1:ddat.p
                                             ind_ctr = ind_ctr + 1;
                                             ind_noalpha = ind_noalpha + 1;
                                             ctr(ind_ctr, :) = contrastSettings(1, ind_noalpha);
                                            end
                                            % skip an element for alpha..
                                            ind_ctr = ind_ctr + 1;
                                        end

                                        % Get the variance estimate; loop over each voxel
                                        current_var_est = squeeze(mtimesx(mtimesx(ctr', current_vars(:, :, :, :, :) ), ctr));
                                        ddat.img{1, iPop} = ddat.oimg{1, iPop} ./...
                                            sqrt(current_var_est);
                                    end
                                end
                            end
     
                        % Z-update for population or subject level
                        else
                            % Get the image restricted to the actual voxels
                            tempImg = ddat.oimg{iVisit, iPop};
                            FinalImg = nan(size(tempImg));
                            % Calculate the Z-scores
                            FinalImg(ddat.validVoxels) = (tempImg(ddat.validVoxels) - mean(tempImg(ddat.validVoxels))) /...
                                std(tempImg(ddat.validVoxels), 'omitnan');
                            ddat.img{iVisit, iPop} = FinalImg;
                            set(findobj('Tag', 'manualThreshold'), 'max',1);
                            %editThreshold;
                        end
                        
                    % Turn off Z-scores (Revert to oimg)
                    else
                        ddat.img{iVisit, iPop} = ddat.oimg{iVisit, iPop};
                        %set(findobj('Tag', 'thresholdSlider'), 'Value', 0);
                        set(findobj('Tag', 'manualThreshold'), 'String', '');
                        %set(findobj('Tag', 'manualThreshold'), 'Value', 0);
                    end
                    
                %end
            end
        end
        
    end

% Function to let the user know where in the brain they have clicked.
% verified used 3/12
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
% verified used 3/12
    function editThreshold(hObject, callbackdata)
        
        [rowInd, colInd] = find(ddat.viewTracker > 0);
        if size([rowInd, colInd], 2) ~= 2
            rowInd = rowInd(:); colInd = colInd(:);
        end
        update_brain_maps('updateCombinedImage', [rowInd, colInd], 'updateColorbar', 0);
        
    end

% TODO, make sure this plays nice with no contrast/subpop selected
% Function to handle Z-thresholding if the user manually enters a
% value.
% Verified used 3/12
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



%% TODO move IC selection to its own aug window?
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

%% The Functions below concern switching between viewer types (e.g. grp to subject)

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

% Close button for the IC selection window.
    function closeICSelect(hObject, ~)
        delete(hObject.Parent);
    end


% Beta Panel Functions
% Function to allow the user to add another contrast to the list
    function addNewContrast(hObject, callbackdata)
        
        olddata = findobj('Tag', 'contrastDisplay'); olddim = size(olddata.Data);
        %oldrownames = olddata.RowName;
        newTable = cell(olddim(1) + 1, ddat.p);
        
        % Fill in all the old information
        for column=1:olddim(2)
            for row=1:olddim(1)
                newTable(row, column) = olddata.Data(row,column);
            end
        end
        
        % reassign the row names for the table
%         if olddim(1) == 0
%             newRowNames = ['C' num2str(olddim(1)+1)];
%         else
%             newRowNames = [oldrownames; ['C' num2str(olddim(1)+1)]];
%             newRowNames = cellstr(newRowNames);
%         end

        % Update the contrast names to include the new contrast
        ddat.LC_contrast_names{olddim(1) + 1} = ['C' num2str(olddim(1)+1)];
        

        set(findobj('Tag', 'contrastDisplay'), 'Data', newTable);
        set(findobj('Tag', 'contrastDisplay'), 'RowName', ddat.LC_contrast_names);
        
        % Make it so that only the main effects can be edited if this is a
        % subpopulation, otherwise all can be edited
        if strcmp(ddat.type, 'beta')
            ceditable = true(1, ddat.p);
        else
            ceditable = false(1, ddat.p);
            ceditable(1:size(ddat.interactions,2)) = 1;
        end
        set(findobj('Tag', 'contrastDisplay'), 'ColumnEditable', ceditable);
        
        ddat.contrastExists = 1;
    end

    %removeContrast
    %
    % This function removes a specified contrast. If that contrast was also
    % a "valid" contrast (fully filled out) then it is also removed from
    % ddat.LC_contrasts and ddat.valid_LC_contrast
    % Verified used 3/12/20
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
                        %if ddat.valid_LC_contrast(removeIndex) == 1
                            
                            % Clear out variables
                            ddat.LC_contrasts(removeIndex, :) = []; 
                            ddat.valid_LC_contrast(removeIndex) = [];
                            ddat.saved_contrast_viewTracker(removeIndex, :) = [];
                            disp('remove from contrast names') %TODO
                            
                        %end
                        
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
                            newRowNames = cellstr(['C' num2str(1)]);
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
                        
                    end
                end
            end
            % update "viewing contrast" as well
            % check that whatever is on screen is valid BE CAREFUL HERE!!
        else
            warnbox = warndlg('No contrasts have been specified');
        end
    end


    function openCrossVisitContrastSpecificationWindow(hObject, callbackdata)
       
        % Store the old information. This will be used to
        % control what is shown after adding or deleting cross-visit
        % contrasts
        oldViewTracker = ddat.saved_cross_visit_contrast_viewTracker;
        oldCVCNames    = ddat.LC_cross_visit_contrast_names;
        
        % Open up the cross visit contrast specification window and
        % update ddat structure with new contrasts and their names
        [ddat.LC_cross_visit_contrasts,...
            ddat.LC_cross_visit_contrast_names,...
            ddat.LC_cross_visit_contrast_strings] =...
            CrossVisitContrastSpecificationWindow(ddat.varNamesX,...
                ddat.LC_cross_visit_contrasts,...
                ddat.LC_cross_visit_contrast_names,...
                ddat.nVisit);
        
        % Now update the cross visit contrast display box (lower RHS of window)
        % with the new strings describing the contrasts
        findobj('tag', 'crossVisitContrastDisplay')
        set(findobj('tag', 'crossVisitContrastDisplay'), 'RowName', ddat.LC_cross_visit_contrast_names);
        set(findobj('tag', 'crossVisitContrastDisplay'), 'ColumnName', []);
        
        set(findobj('tag', 'crossVisitContrastDisplay'), 'Data', ddat.LC_cross_visit_contrast_strings);
        
                
        % To set the width of the column, get the width of the longest
        % string
        [~, cell_sizes] = cellfun(@size, ddat.LC_cross_visit_contrast_strings);
        maxCellLength = 8 * max(cell_sizes);
        set(findobj('tag', 'crossVisitContrastDisplay'), 'ColumnWidth', {maxCellLength} );
        
        % Update the stored CVC view information
        nCVC = length(ddat.LC_cross_visit_contrast_strings);
        ddat.saved_cross_visit_contrast_viewTracker = zeros(nCVC, 1);
        for j = 1:nCVC
            % See if this contrast was previously defined
            comparison = strcmp(oldCVCNames, ddat.LC_cross_visit_contrast_names{j});
            if any(comparison)
                matchInd = find(comparison);
                % See if this contrast was previously being viewed
                if oldViewTracker(matchInd, 1) == 1
                    ddat.saved_cross_visit_contrast_viewTracker(j, 1) = 1;
                end
            end
        end
        
        % Update the view table appropriately
        setup_ViewSelectTable;

        [rowInd, colInd] = find( ones(size(ddat.viewTracker)) > 0);

        if size([rowInd, colInd], 2) ~= 2
            rowInd = rowInd(:); colInd = colInd(:);
        end

        load_functional_images( [rowInd, colInd] );                
        
        
    end

    %
    % This function removes a specified sub-population. If that subpopualtion was also
    % a "valid" sub-population (fully filled out) then it is also removed from
    % ddat.LC_subpops and ddat.valid_LC_subpop
    % Verified used 3/12/20
    function removeSubPop(hObject, callbackdata)
                 
        % Check that a subpopulation exists
        if numel(get(findobj('Tag', 'subPopDisplay'), 'Data')) > 0
            
            % Keep track of if a contrast should be removed (vs user enter
            % cancel)
            %removeContrast = 0;
            
            % open a window asking which contrast to remove
            waitingForResponse = 1;
            while waitingForResponse
                answer = inputdlg('Please enter sub-population name to remove (SubPop1, SubPop2,...)')
                if isempty(answer)
                    waitingForResponse = 0;
                    % if user input something, check that it is valid
                else
                    validSubpops = get(findobj('Tag', 'subPopDisplay'), 'RowName');
                    matchedIndex = strfind(validSubpops, answer);
                    % Reduce to just first match to guard against SubPop1 and
                    % SubPop11
                    removeIndex = 0;
                    for iSubPop = 1:length(validSubpops)
                        % handle more than one contrast
                        if iscell(validSubpops)
                            if matchedIndex{iSubPop} == 1
                                removeIndex = iSubPop;
                                break; % break out of the loop
                            end
                            % handle only one contrast
                        else
                            if matchedIndex == 1
                                removeIndex = iSubPop;
                                break; % break out of the loop
                            end
                        end
                    end
                    % If a valid subpopulation was entered, then proceed
                    if removeIndex > 0
                        waitingForResponse = 0;
                        
                        % Remove this contrast from the viewTable and from
                        % the viewTracker
                        if ddat.valid_LC_subpop(removeIndex) == 1
                            
                            % Clear out variables
                            ddat.LC_subpops(removeIndex, :) = []; 
                            ddat.valid_LC_subpop(removeIndex) = [];
                            ddat.saved_subpop_viewTracker(:, removeIndex) = [];
                            disp('remove from subpop names') %TODO
                            
                        end
                        
                        olddata = findobj('Tag', 'subPopDisplay'); olddim = size(olddata.Data);
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
                        disp('make this based on user specified names')
                        if olddim(1) == 2
                            newRowNames = cellstr(['SubPop' num2str(1)]);
                        else
                            newRowNames = oldrownames(1:olddim(1) - 1);
                            newRowNames = cellstr(newRowNames);
                        end
                        
                        set(findobj('Tag', 'subPopDisplay'), 'Data', newTable);
                        set(findobj('Tag', 'subPopDisplay'), 'RowName', newRowNames);
                        ddat.LC_subpop_names = newRowNames;
                        % Make it so that only the main effects can be edited
                        ceditable = false(1, ddat.p);
                        ceditable(1:size(ddat.interactions,2)) = 1;
                        set(findobj('Tag', 'subPopDisplay'), 'ColumnEditable', ceditable);
                        
                        % Handle additional required changes if
                        % subpop removed was currently being
                        % viewed
                        
                        
                        % First need this intermediate step to delete
                        % any axes corresponding to deleted axes
                        ddat.viewTracker(:, removeIndex) = zeros(ddat.nVisit, 1);
                        set_number_of_brain_axes(0);

                        % Now update viewTracker
                        ddat.viewTracker = ddat.saved_subpop_viewTracker;

                        setup_ViewSelectTable;

                        [rowInd, colInd] = find( ones(size(ddat.viewTracker)) > 0);

                        if size([rowInd, colInd], 2) ~= 2
                            rowInd = rowInd(:); colInd = colInd(:);
                        end

                        load_functional_images( [rowInd, colInd] );
                        
                    end
                end
            end
            % update "viewing contrast" as well
            % check that whatever is on screen is valid BE CAREFUL HERE!!
        else
            warnbox = warndlg('No Sub-Populations have been specified');
        end
    end


    %% Function to open a dialogue box allowing the user to input an anatomical image
    function anatomical_spec_window(hObject, callbackdata)
        [anatfile, anatpath] = uigetfile('*.nii');
        if isequal(anatfile,0)
           ddat.user_specified_anatomical_file = '';
        else
           ddat.user_specified_anatomical_file = fullfile(anatpath, anatfile);
        end
        % Re-load the underlying anatomical image and redisplay
        setupAnatomical;
        load_functional_images;
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





% SubPopulation Panel Functions
% Function to allow the user to add another sub population to the list
% Verified that this is used 3/12/20
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
        
        %if length(newRowNames)
        if iscell(newRowNames)
            ddat.LC_subpop_names = newRowNames;
        else
            ddat.LC_subpop_names = {newRowNames};
        end
        
        % Make it so that only the main effects can be edited
        ceditable = false(1, ddat.p);
        ceditable(1:length(ddat.varNamesX)) = 1;
        set(findobj('Tag', 'subPopDisplay'), 'ColumnEditable', ceditable);
        
        % change the drop down menu TODO THINK I CAN REMOVE THIS DUE TO
        % VIEWTABLE SWITCH
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
        set(findobj('Tag', 'subPopSelect1'), 'String', newString)
        
    end


end