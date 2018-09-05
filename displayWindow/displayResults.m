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

% Check if an instance of displayResults already running
hs = findall(0,'tag','displayResults');
if (isempty(hs))
    hs = addcomponents;
    set(hs.fig,'Visible','on');
    initialDisp;
else
    figure(hs);
end

    function hs = addcomponents
        % Add components, save ddat in a struct
        hs.fig = figure('Units', 'normalized', ...,...
            'position', [0.3 0.3 0.5 0.5],...
            'MenuBar', 'none',...
            'Tag','displayResults',...
            'NumberTitle','off',...
            'Name','Result Viewer',...
            'Resize','on',...
            'Visible','off');
        fileMenu = uimenu('Label','File');
        uimenu(fileMenu,'Label','Save','Callback','disp(''save'')');
        uimenu(fileMenu,'Label','Quit','Callback','disp(''exit'')',...
            'Separator','on','Accelerator','Q');
        viewerMenu = uimenu('Label', 'View', 'Tag', 'viewerMenu');
        uimenu(viewerMenu, 'Label', 'Population', 'Separator', 'On', 'Callback', @stGrp);
        uimenu(viewerMenu, 'Label', 'Sub-Population', 'Callback', @stSubPop);
        uimenu(viewerMenu, 'Label', 'Single Subject', 'Callback', @stSubj);
        uimenu(viewerMenu, 'Label', 'Covariate Effect', 'Callback', @stBeta);
        helpMenu = uimenu('Label','Help');
        textalign = 'left';
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Brain Display Windows
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Panel
        displayPanel = uipanel('BackgroundColor','white',...
            'Tag', 'viewingPanelNormal',...
            'Position',[0, 0.5 1 0.5], ...;
            'BackgroundColor',get(hs.fig,'color'));
        % Windows
        SagAxes = axes('Parent', displayPanel, ...
            'Units', 'Normalized', ...
            'Position',[0.01 0.18 0.27 .8],...
            'Tag', 'SagittalAxes1' ); 
        CorAxes = axes('Parent', displayPanel, ...
            'Position',[.30 .18 .27 .8],...
            'Tag', 'CoronalAxes1' );
        AxiAxes = axes('Parent', displayPanel, ...
            'Position',[.59 .18 .27 .8],...
            'Tag', 'AxialAxes1' );
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
        colorMap = axes('Parent', displayPanel, ...
            'units', 'Normalized',...
            'Position', [0.90, 0.18, 0.05, 0.8], ...
            'Tag', 'colorMap');
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Location and Crosshair Control
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        locPanel = uipanel('Title','Location and Crosshair Information',...
             'FontSize',12,...
             'BackgroundColor','white',...
             'BackgroundColor',[224/256,224/256,224/256], ...
             'Tag', 'locPanel', ...
             'Position',[.01, 0.01 .32 .45]);
        curInfo = uicontrol('Parent', locPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.8, 0.98, 0.13], ...
            'Tag', 'curInfo', 'BackgroundColor', 'Black');
        crosshairPosText = uicontrol('Parent', locPanel, ...
            'Style', 'Text', 'String', 'Crosshair Position: ', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.65, 0.49, 0.1]);
        crosshairPos = uicontrol('Parent', locPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.50, 0.65, 0.49, 0.1], ...
            'Tag', 'crosshairPos');
        crosshairValText = uicontrol('Parent', locPanel, ...
            'Style', 'Text', 'String', 'Crosshair Value: ', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.50, 0.49, 0.1]);
        crosshairVal = uicontrol('Parent', locPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.50, 0.50, 0.49, 0.1], ...
            'Tag', 'crosshairVal1');
        originalPosText = uicontrol('Parent', locPanel, ...
            'Style', 'Text', 'String', '[X Y Z] Origin Position', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.35, 0.49, 0.1]);
        originalPos = uicontrol('Parent', locPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.50, 0.35, 0.49, 0.1], ...
            'Tag', 'originalPos');
        dimensionText = uicontrol('Parent', locPanel, ...
            'Style', 'Text', 'String', '[X Y Z] Dimension', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.20, 0.49, 0.1]);
        dimension = uicontrol('Parent', locPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.50, 0.20, 0.49, 0.1], ...
            'Tag', 'dimension');
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Component Selection & Masking
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        icPanel = uipanel('FontSize',12,...
             'BackgroundColor','white',...
             'Position',[.35, 0.21 .32 .25], ...
             'Tag', 'icPanel', ...
             'BackgroundColor',[224/256,224/256,224/256]);
        ICselect = uicontrol('Parent', icPanel,... 
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.83, 0.48, 0.1], ...
            'Tag', 'ICselect', 'Callback', @updateIC, ...
            'String', 'Select IC');
        viewZScores = uicontrol('Parent', icPanel,... 
            'Style', 'checkbox', ...
            'Units', 'Normalized', ...
            'Position', [0.53, 0.46, 0.42, 0.15], ...
            'Tag', 'viewZScores', 'String', 'View Z-Scores', ...
            'Callback', @updateZImg);
        maskSelect = uicontrol('Parent', icPanel,... 
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.51, 0.83, 0.48, 0.1], ...
            'Tag', 'maskSelect', 'Callback', @applyMask, ...
            'String', 'No Mask');
        viewerInfo = uicontrol('Parent', icPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.02, 0.98, 0.3], ...
            'Tag', 'viewerInfo', 'BackgroundColor', 'Black', ...
            'ForegroundColor', 'white', ...
            'HorizontalAlignment', 'Left');
        selectCovariate = uicontrol('Parent', icPanel,... 
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.51, 0.48, 0.1], ...
            'Tag', 'selectCovariate', 'Callback', @updateIC, ...
            'String', 'Select Covariate', 'Visible', 'Off');
        selectSubject = uicontrol('Parent', icPanel,... 
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.51, 0.48, 0.1], ...
            'Tag', 'selectSubject', 'Callback', @updateIC, ...
            'String', 'Select Subject', 'Visible', 'Off');
        keepIC = uicontrol('Parent', icPanel,... 
            'Style', 'checkbox', ...
            'Units', 'Normalized', ...
            'visible', 'off', ...
            'Position', [0.01, 0.46, 0.42, 0.15], ...
            'Tag', 'keepIC', 'String', 'Use IC for hc-ICA', ...
            'Value', 1, 'Callback', @updateICSelMenu);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Thresholding and Mask Creation
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        thresholdPanel = uipanel('FontSize',12,...
             'BackgroundColor','white',...
             'Position',[.35, 0.01 .32 .19], ...
             'BackgroundColor',[224/256,224/256,224/256], ...
             'Tag', 'thresholdPanel', ...
             'Title', 'Z Thresholding');
        thresholdSlider = uicontrol('Parent', thresholdPanel,... 
            'Style', 'Slider', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.85, 0.98, 0.1], ...
            'Tag', 'thresholdSlider', ...
            'min', 0, 'max', 4, 'sliderstep', [0.01, 0.1], ...
            'callback', @editThreshold);
        manualThreshold = uicontrol('Parent', thresholdPanel, ...
            'Style', 'Edit', ...
            'Units', 'Normalized', ...
            'Position', [0.24, 0.30, 0.49, 0.35], ...
            'Tag', 'manualThreshold', ...
            'callback', @manualThreshold);
        createMask = uicontrol('Parent', thresholdPanel, ...
            'Style', 'pushbutton', ...
            'String', 'Create Mask', ...
            'Units', 'Normalized', ...
            'Position', [0.24, 0.01, 0.49, 0.25], ...
            'Tag', 'createMask', 'callback', @saveMask, ...
            'Visible', 'Off');
        useEmpiricalVar = uicontrol('Parent', thresholdPanel,... 
            'Style', 'checkbox', ...
            'Units', 'Normalized', ...
            'visible', 'off', ...
            'Position', [0.11, 0.01, 0.79, 0.25], ...
            'Tag', 'useEmpiricalVar',...
            'String', 'Use empirical variance estimate', ...
            'Value', 1, 'Callback', @updateICSelMenu,...
            'Visible', 'Off');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Subpopulation Information
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        subPopPanel = uipanel('FontSize',12,...
            'BackgroundColor','white',...
            'Title', 'Subpopulation Control', ...
            'Tag', 'SubpopulationControl', ...
            'Visible', 'Off', ...
            'BackgroundColor',[224/256,224/256,224/256], ...
            'Position',[.69, 0.01 .30 .45]);
        subPopSelect = uicontrol('Parent', subPopPanel,... 
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.255, 0.85, 0.49, 0.1], ...
            'Tag', 'subPopSelect1', 'Callback', @updateSubPopulation, ...
            'String', 'No Sub-Population Created');
        subPopDisplay = uitable('Parent', subPopPanel, ...
            'Units', 'Normalized', ...
            'Position', [0.1, 0.3, 0.8, 0.5], ...
            'Tag', 'subPopDisplay', ...
            'CellEditCallback', @newPopCellEdit);
        newSubPop = uicontrol('Parent', subPopPanel, ...
            'Units', 'Normalized', ...
            'String', 'Add New Sub-Population', ...
            'Position', [0.15, 0.15, 0.7, 0.15], ...
            'Tag', 'newSubPop', 'Callback', @addNewSubPop);
        comparesubPop = uicontrol('Parent', subPopPanel, ...
            'Units', 'Normalized', ...
            'String', 'Compare Sub-Populations', ...
            'Position', [0.15, 0.01, 0.7, 0.15], ...
            'Tag', 'compareSubPops', 'Callback', @compareSubPopulations);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Beta Contrast Information
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        betaContrastPanel = uipanel('FontSize',12,...
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
            'String', 'No Contrast Created');
        contrastDisplay = uitable('Parent', betaContrastPanel, ...
            'Units', 'Normalized', ...
            'Position', [0.1, 0.3, 0.8, 0.5], ...
            'Tag', 'contrastDisplay', ...
            'CellEditCallback', @newPopCellEdit);
        newContrast = uicontrol('Parent', betaContrastPanel, ...
            'Units', 'Normalized', ...
            'String', 'Add New Contrast', ...
            'Position', [0.15, 0.15, 0.7, 0.15], ...
            'Tag', 'newContrast', 'Callback', @addNewContrast);
        removeContrastButton = uicontrol('Parent', betaContrastPanel, ...
            'Units', 'Normalized', ...
            'String', 'Remove A Contrast', ...
            'Position', [0.15, 0.01, 0.7, 0.15], ...
            'Tag', 'newContrast', 'Callback', @removeContrast);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% IC Selection
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
        icSelPanel = uipanel('FontSize',12,...
            'BackgroundColor','white',...
            'Title', 'IC Selection', ...
            'Tag', 'icSelectionPanel', ...
            'Visible', 'Off', ...
            'Position',[.69, 0.01 .30 .45]);
        icSelRef = uitable('Parent', icSelPanel, ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.01, 0.9, 0.95], ...
            'Tag', 'icSelRef', 'RowName', '');
        icSelCloseButton = uicontrol('style', 'pushbutton',...
            'units', 'normalized', ...
            'Position', [0.93, 0.01, 0.05, 0.05],...
            'String', 'Close', ...
            'tag', 'icSelectCloseButton', ...
            'visible', 'off', ...
            'Callback', @closeICSelect);
        
        movegui(hs.fig, 'center')
        
    end

    % This function is called when the user decides to compare two
    % subpopulations. It heavily changes the display window.
    function createPanel(selectedPops)
        
        % Setup cell arrays for all sub population info.
        ddat.type = 'subPopCompare';
        ddat.axial_image = cell(ddat.nCompare, 1);
        ddat.sagittal_image = cell(ddat.nCompare, 1);
        ddat.coronal_image = cell(ddat.nCompare, 1);
        ddat.axial_xline = cell(ddat.nCompare, 1);
        ddat.axial_yline = cell(ddat.nCompare, 1);
        ddat.coronal_xline = cell(ddat.nCompare, 1);
        ddat.coronal_yline = cell(ddat.nCompare, 1);
        ddat.sagittal_xline = cell(ddat.nCompare, 1);
        ddat.sagittal_yline = cell(ddat.nCompare, 1);
        
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
                'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],'xtick',[],'ytick',[],'Tag',['AxialAxes' num2str(subPop)])
            daspect(gca,aspect([1 3 2]));
            set(ddat.axial_image{subPop},'ButtonDownFcn','get_pos_dispexp(''axi'');');
            pos_axi = [ddat.sag, ddat.cor];
            crosshair = plot_crosshair(pos_axi, [], gca);
            ddat.axial_xline{subPop} = crosshair.lx;
            ddat.axial_yline{subPop} = crosshair.ly;

            % Setup Coronal Image
            axes(findobj('Tag', ['CoronalAxes' num2str(subPop)] ));
            ddat.coronal_image{subPop} = image(Scor);
            set(gca,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],'xtick',[],'ytick',[],'Tag',['CoronalAxes' num2str(subPop)])
            daspect(gca,aspect([1 3 2]));
            set(ddat.coronal_image{subPop},'ButtonDownFcn','get_pos_dispexp(''cor'');');
            pos_cor = [ddat.sag, ddat.axi];
            crosshair = plot_crosshair(pos_cor, [], gca);
            ddat.coronal_xline{subPop} = crosshair.lx;
            ddat.coronal_yline{subPop} = crosshair.ly;

            % Setup Sagital image
            %test = findobj('Tag', ['SagittalAxes' num2str(subPop)] );
            axes(findobj('Tag', ['SagittalAxes' num2str(subPop)] ));
            ddat.sagittal_image{subPop} = image(Ssag);
            set(gca,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],'xtick',[],'ytick',[],'Tag',['SagittalAxes' num2str(subPop)])
            daspect(gca,aspect([2 3 1]));
            set(ddat.sagittal_image{subPop},'ButtonDownFcn','get_pos_dispexp(''sag'');');
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
    
    % initialDisp - sets up the initial state of the display window based
    % on the user selection (aggregate viewer, covariate effect viewer, etc)
    function initialDisp(hObject,callbackdata)
        set(findobj('Tag', 'thresholdSlider'), 'Value', 0);
        set(findobj('Tag', 'manualThreshold'), 'String', '0');
        % Number of comparisons is fixed to 1, but this can be modified
        % without issue
        ddat.nCompare = 1;
        % Stretch containers storing the images to have the correct number
        % of objects (1)
        ddat.axial_image = cell(ddat.nCompare, 1);
        ddat.sagittal_image = cell(ddat.nCompare, 1);
        ddat.coronal_image = cell(ddat.nCompare, 1);
        ddat.axial_xline = cell(ddat.nCompare, 1);
        ddat.axial_yline = cell(ddat.nCompare, 1);
        ddat.coronal_xline = cell(ddat.nCompare, 1);
        ddat.coronal_yline = cell(ddat.nCompare, 1);
        ddat.sagittal_xline = cell(ddat.nCompare, 1);
        ddat.sagittal_yline = cell(ddat.nCompare, 1);
        ddat.img = cell(ddat.nCompare, 1); ddat.oimg = cell(ddat.nCompare,1);
        
        % Change what display panels are seen based on what viewer is open.
        if strcmp(ddat.type, 'grp')
            set(findobj('Tag', 'useEmpiricalVar'), 'Visible', 'Off');
            set(findobj('Tag', 'selectSubject'), 'Visible', 'Off');
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'Off');
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'Off');
            set(findobj('Tag', 'covariateContrastControl'), 'Visible', 'Off');
            set( findobj('Tag', 'createMask'), 'Visible', 'On' );
            % move the info panels to the middle of the screen
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.56, 0.01 .32 .19]);
            set( findobj('Tag', 'icPanel'), 'Position',[.56, 0.21 .32 .25]);
            set( findobj('Tag', 'locPanel'), 'Position',[.12, 0.01 .32 .45]);
            % load the data
            ndata = load_nii([ddat.outdir '/' ddat.outpre '_aggregate' 'IC_1.nii']);
            ddat.img{1} = ndata.img; ddat.oimg{1} = ndata.img;
        elseif strcmp(ddat.type, 'subpop')
            set(findobj('Tag', 'useEmpiricalVar'), 'Visible', 'Off');
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'Off');
            set( findobj('Tag', 'createMask'), 'Visible', 'Off' );
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'On');
            set(findobj('Tag', 'covariateContrastControl'), 'Visible', 'Off');
            % Place the boxes in the correct locations
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.35, 0.01 .32 .19]);
            set( findobj('Tag', 'icPanel'), 'Position',[.35, 0.21 .32 .25]);
            set( findobj('Tag', 'locPanel'), 'Position',[.01, 0.01 .32 .45]);
            set( findobj('Tag', 'selectSubject'), 'Visible', 'Off');
            % Set up the sub-population box
            if ddat.subPopExists == 0
                newColnames = ddat.varNamesX;
                set(findobj('Tag', 'subPopDisplay'), 'Data', cell(0, ddat.p));
                set(findobj('Tag', 'subPopDisplay'), 'ColumnName', newColnames);
                set(findobj('Tag', 'subPopDisplay'), 'ColumnEditable', true);
                ddat.subPopExists = 1;
            end
            % No data to display at first
            tempImg = load_nii([ddat.outdir '/' ddat.outpre '_S0_' 'IC_1.nii']);
            ddat.img{1} = zeros(size(tempImg.img)); ddat.oimg{1} = zeros(size(tempImg.img));
        elseif strcmp(ddat.type, 'beta')
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
            % load the data
            ndata = load_nii([ddat.outdir '/' ddat.outpre '_beta_cov1_IC1.nii']);
            ddat.img{1} = ndata.img; ddat.oimg{1} = ndata.img; 
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'On');
            setupCovMenu;
        elseif strcmp(ddat.type, 'subj')
            set(findobj('Tag', 'useEmpiricalVar'), 'Visible', 'Off');
            set(findobj('Tag', 'selectCovariate'), 'Visible', 'Off');
            set( findobj('Tag', 'createMask'), 'Visible', 'Off' );
            set(findobj('Tag', 'SubpopulationControl'), 'Visible', 'Off');
            set(findobj('Tag', 'covariateContrastControl'), 'Visible', 'Off');
            % move the info panels to the middle of the screen
            set( findobj('Tag', 'thresholdPanel'), 'Position',[.56, 0.01 .32 .19]);
            set( findobj('Tag', 'icPanel'), 'Position',[.56, 0.21 .32 .25]);
            set( findobj('Tag', 'locPanel'), 'Position',[.12, 0.01 .32 .45]);
            % Load a top level aggregate map just to have the dimensions
            ndata = load_nii([ddat.outdir '/' ddat.outpre '_' 'S0_IC_1.nii']);
            ddat.img{1} = ndata.img; ddat.oimg{1} = ndata.img;
            % load the data
            ddat.subjectLevelData = load([ddat.outdir '/' ddat.outpre '_subject_IC_estimates.mat']);
            ddat.subjectLevelData = ddat.subjectLevelData.subICmean
            generateSingleSubjMap;
            set(findobj('Tag', 'selectSubject'), 'Visible', 'On');
            setupSubMenu;
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
            createPanel();
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

        % Look for an appropriately sized mask file.
        maskSearch;
        
        % Get the size of each dimension.
        dim = size(ddat.img{1});
        ddat.xdim = dim(1); ddat.ydim = dim(2); ddat.zdim = dim(3);
        
        if strcmp(ddat.type, 'beta')
        %%% Create the beta variance estimate map
        ddat.betaVarEst = zeros(ddat.p, ddat.p, ddat.xdim, ddat.ydim, ddat.zdim);
        % Fill out the beta map for the current IC
        currentIC = get(findobj('Tag', 'ICselect'), 'val');
        newMap = load(fullfile(ddat.outdir,...
            [ddat.outpre '_BetaVarEst_IC_' num2str(currentIC) '.mat']));
        ddat.betaVarEst = newMap.betaVarEst;
        end
        
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
        
        % Set up the anatomical image.
        setupAnatomical;

        % Set up the initial colorbar.
        jet2=jet(64); jet2(38:end, :)=[];
        hot2=hot(64); hot2(end-5:end, :)=[]; hot2(1:4, :)=[];
        hot2(1:2:38, :)=[]; hot2(2:2:16, :)=[]; hot2=flipud(hot2);
        hot3=[jet2; hot2]; ddat.hot3 = hot3;
        ddat.highcolor = hot3;
        ddat.basecolor = gray(191);
        ddat.colorlevel = 256;
        
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
        
        % create the combined images
        createCombinedImage;
        
        % Loop over sub-populations filling out the images.
        for subPop=1:ddat.nCompare
            
            % Fill out the images data.
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
                'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],'xtick',[],'ytick',[],'Tag',['AxialAxes' num2str(subPop)])
            daspect(gca,aspect([1 3 2]));
            set(ddat.axial_image{subPop},'ButtonDownFcn','get_pos_dispexp(''axi'');');
            pos_axi = [ddat.sag, ddat.cor];
            crosshair = plot_crosshair(pos_axi, [], gca);
            ddat.axial_xline{subPop} = crosshair.lx;
            ddat.axial_yline{subPop} = crosshair.ly;

            % Setup Coronal Image
            axes(findobj('Tag', ['CoronalAxes' num2str(subPop)] ));
            ddat.coronal_image{subPop} = image(Scor);
            set(gca,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],'xtick',[],'ytick',[],'Tag',['CoronalAxes' num2str(subPop)])
            daspect(gca,aspect([1 3 2]));
            set(ddat.coronal_image{subPop},'ButtonDownFcn','get_pos_dispexp(''cor'');');
            pos_cor = [ddat.sag, ddat.axi];
            crosshair = plot_crosshair(pos_cor, [], gca);
            ddat.coronal_xline{subPop} = crosshair.lx;
            ddat.coronal_yline{subPop} = crosshair.ly;

            % Setup Sagital image
            axes(findobj('Tag', ['SagittalAxes' num2str(subPop)] ));
            ddat.sagittal_image{subPop} = image(Ssag);
            set(gca,'YDir','normal','XLimMode','manual','YLimMode','manual',...
                'ClimMode','manual','YColor',[0 0 0],'XColor',[0 0 0],'xtick',[],'ytick',[],'Tag',['SagittalAxes' num2str(subPop)])
            daspect(gca,aspect([2 3 1]));
            set(ddat.sagittal_image{subPop},'ButtonDownFcn','get_pos_dispexp(''sag'');');
            pos_sag = [ddat.cor, ddat.axi];
            crosshair = plot_crosshair(pos_sag, [], gca);
            ddat.sagittal_xline{subPop} = crosshair.lx;
            ddat.sagittal_yline{subPop} = crosshair.ly;
        
        end % end of sub population loop

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
        set(findobj('Tag', 'originalPos'),'String',sprintf('%7.0d %7.0d %7.0d',origin(1),origin(2),origin(3)));
        set(findobj('Tag', 'crosshairPos'),'String',sprintf('%7.0d %7.0d %7.0d',ddat.sag,ddat.cor, ddat.axi));
        set(findobj('Tag', 'dimension'),'String',sprintf('%7.0d %7.0d %7.0d',ddat.xdim,ddat.ydim,ddat.zdim));
        
        updateZImg;
        maskSearch;
        
        if ~strcmp(ddat.type, 'subpop')
            editThreshold;
        end
        
        updateCrosshairValue;
        redisplay;
        updateInfoText;
    end

    % Function to generate the single subject maps. This is preferable to
    % storing all of the maps in case there are many subjects
    function generateSingleSubjMap(hObject, callbackdata)

        disp('Generating map for requested subject.')
        % Get the requested subject number
        subnum = get( findobj('Tag', 'selectSubject'), 'Value' );
        % Get the requested IC
        newIC = get(findobj('Tag', 'ICselect'), 'val');
        
        % Get the correct elements of the subjicmean vector
        vectData = squeeze(ddat.subjectLevelData(newIC, subnum, :));
        % Place in the correct dimensions
        vxl = size(ddat.oimg{1});
        locs = ~isnan(ddat.oimg{1});
        nmat = nan(vxl);
        nmat(locs) = vectData;
        ddat.img{1} = nmat; ddat.oimg{1} = nmat;
    end

    % Function to setup anatomical image.
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

    % Function to combine the anatomical image and the functional image.
    % Taken from bs-mac viewer.
    function createCombinedImage(hObject,callbackdata)
        ddat.scaledFunc = cell(ddat.nCompare, 1);
        ddat.combinedImg = cell(ddat.nCompare, 1);
        
        % Find the min and max value of each image.
        minVal1 = min(min(min(cat(1,ddat.img{:}))));
        maxVal1 = max(max(max(cat(1,ddat.img{:}))));
        
        % Loop over each sub-population to compare and create the combined
        % image.
        for iPop = 1:ddat.nCompare
            % Scale the functional image
            tempImage = ddat.img{iPop};
            tempImage(isnan(ddat.img{iPop})) = minVal1 - 1;
            minVal2 = minVal1 - 1;
            ddat.scaledFunc{iPop} = scale_in(tempImage, minVal2, maxVal1, 63);
            newColormap = [(gray(191));zeros(1, 3); ddat.highcolor];%%index 192 is not used, just for seperate the base and top colormap;
            ddat.color_map = newColormap;
            ddat.combinedImg{iPop} = overlay_w_transparency(uint16(ddat.scaledImg),...
                uint16(ddat.scaledFunc{iPop}),1, 0.6, newColormap, ddat.highcolor);
        end
    end

    % Function to replace the brain images on the viewer.
    function redisplay(hObject,callbackdata)
        % Loop over the number of subgroups currently being viewed.
        for iInd = 1:ddat.nCompare
            % Grab the data for the selected slices and update axes obj.
            for cl = 1:3
                Saxi(:, :, cl) = squeeze(ddat.combinedImg{iInd}(cl).combound(:, :, ddat.axi))';
                Scor(:, :, cl) = squeeze(ddat.combinedImg{iInd}(cl).combound(:,ddat.cor,:))';
                Ssag(:, :, cl) = squeeze(ddat.combinedImg{iInd}(cl).combound(ddat.sag,:,:))';
            end
            ddat.cor_mm = (ddat.cor-ddat.origin(2))*ddat.pixdim(2);
            axesC = (findobj('Tag', ['CoronalAxes' num2str(iInd)] ));
            set(ddat.coronal_image{iInd},'CData',Scor);
            axesC = (findobj('Tag', ['AxialAxes' num2str(iInd)] ));
            set(ddat.axial_image{iInd},'CData',Saxi);
            axesC = (findobj('Tag', ['SagittalAxes' num2str(iInd)] ));
            set(ddat.sagittal_image{iInd},'CData',Ssag);           
        end
        
        % Update the colormap (here as a safety precaution).
        axesC = findobj('Tag', 'colorMap');
        updateColorbar;
    end
    
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

    % Function to look for a mask object created by the user for this IC
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

    % Function to update the colorbar
    function updateColorbar(hObject, callbackdata)
        %Get the 0.95 quantile to use as the min and max of the colorbar
        max_functmap_value = max(max(prctile(cat(ddat.nCompare,ddat.img{:}),95 ))); 
        min_functmap_value = min(min(prctile(cat(ddat.nCompare,ddat.img{:}),95 )));
        maxval = max(max_functmap_value, abs(min_functmap_value));
        max_functmap_value = maxval; min_functmap_value = -maxval;
        incr_val=max_functmap_value/5;
        int_part=floor(incr_val); frac_part=incr_val-int_part;
        incr = int_part + round(frac_part*10)/10;
        % handle case where incr is 0 because the values are too small;
        if incr == 0
            incr = 0.05;
        end
        % Update the labels for the colorbar
        ddat.colorbar_labels = (min_functmap_value-0.05):incr:max_functmap_value+0.05;
        ddat.colorbar_labels = round(ddat.colorbar_labels,2);
        ddat.scaled_pp_labels = scale_in(ddat.colorbar_labels, min_functmap_value, max_functmap_value, 63);
        % Update the colorbar
        axes(findobj('Tag', 'colorMap'));  
        set(gca,'NextPlot','add')
        colorbar_plot( findobj('Tag', 'colorMap'), ddat.colorbar_labels, ddat.scaled_pp_labels);
    end

    % Function to load a new IC - called when the user changes ICs.
    function updateIC(hObject, callbackdata)
        % Turn off contrast
        ddat.viewingContrast = 0;
        % IC to load
        newIC = get(findobj('Tag', 'ICselect'), 'val');
        % file based on current viewer
        if strcmp(ddat.type, 'grp')
            newFile = [ddat.outdir '/' ddat.outpre '_aggregateIC_' num2str(newIC) '.nii'];
            newData = load_nii(newFile);
            ddat.img{1} = newData.img; ddat.oimg{1} = newData.img;
        elseif strcmp(ddat.type, 'subpop')
            newFile = [ddat.outdir '/' ddat.outpre '_S0_IC_' num2str(newIC) '.nii'];
            updateSubPopulation;
        elseif strcmp(ddat.type, 'beta')
                covnum = get(findobj('Tag', 'selectCovariate'), 'Value');
                ndata = load_nii([ddat.outdir '/' ddat.outpre...
                    '_beta_cov' num2str(covnum) '_IC' num2str(newIC) '.nii']);
                ddat.img{1} = ndata.img; ddat.oimg{1} = ndata.img;
                        % Fill out the beta map for the current IC
                newIC = get(findobj('Tag', 'ICselect'), 'val');
                newMap = load(fullfile(ddat.outdir,...
                    [ddat.outpre '_BetaVarEst_IC_' num2str(newIC) '.mat']));
                ddat.betaVarEst = newMap.betaVarEst;
        elseif strcmp(ddat.type, 'subj')
            generateSingleSubjMap;
        elseif strcmp(ddat.type, 'icsel')
            ndata = load_nii([ddat.outdir '/' ddat.outpre '_iniIC_' num2str(newIC) '.nii']);
            % need to turn the 0's into NaN values
            zeroImg = ndata.img; zeroImg(find(ndata.img == 0)) = nan;
            ddat.img{1} = zeroImg; ddat.oimg{1} = zeroImg;
            % get if the checkbox should be selected
            isSelected = get(findobj('Tag', 'icSelRef'), 'Data');
            if strcmp(isSelected{newIC,2}, 'x')
                set(findobj('Tag', 'keepIC'), 'Value', 1);
            else
                set(findobj('Tag', 'keepIC'), 'Value', 0);
            end
        elseif strcmp(ddat.type, 'reEst')
            ndata = load_nii([ddat.outdir '/' ddat.outpre '_iniguess/' ddat.outpre '_reducedIniGuess_GroupMap_IC_' num2str(newIC) '.nii']);
            % need to turn the 0's into NaN values
            zeroImg = ndata.img; zeroImg(find(ndata.img == 0)) = nan;
            ddat.img{1} = zeroImg; ddat.oimg{1} = zeroImg;
        elseif strcmp(ddat.type, 'subPopCompare')
            % Read in the data for the sub population in this panel
            covariateSettings = get(findobj('Tag', 'subPopDisplay'),'Data');
            newFile = strcat(ddat.outdir,'/',ddat.outpre,'_S0_IC_',num2str(newIC),'.nii');
            newDat = load_nii(newFile);
            for subPop = 1:ddat.nCompare
                newFunc = newDat.img;
                for xi = 1:ddat.p
                    beta = load_nii([ddat.outdir '/' ddat.outpre '_beta_cov' num2str(xi) '_IC' num2str(newIC) '.nii']);
                    xb = beta.img * str2double(covariateSettings( subPop , xi));
                    newFunc = newFunc + xb;
                end
                ddat.img{subPop} = newFunc; ddat.oimg{subPop} = newFunc;                
            end
        end
        
        % Convert the image to a z-score if that option is selected
        updateZImg;
        maskSearch;
        editThreshold;
        
        % If viewing a single subject and a mask is currently selected,
        % then apply that mask to the new subect's data;
        if strcmp(ddat.type, 'subj')
            applyMask;
        end
    end

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

    % Function to apply a user created mask to the data.
    function applyMask(hObject, callbackdata)
        % Find what mask has been selected
        maskOptions = findobj('Tag', 'maskSelect');
        if maskOptions.Value > 1
            mask = load_nii([ddat.outdir '/' maskOptions.String{maskOptions.Value}]);
            for iPop = 1:ddat.nCompare
                maskedFunc = ddat.scaledFunc{iPop} .* mask.img;
                maskedFunc(maskedFunc == 0) = 1;
                ddat.combinedImg{iPop} = overlay_w_transparency(uint16(ddat.scaledImg),...
                    uint16(maskedFunc),1, 0.6, ddat.color_map, ddat.hot3);
            end
            set(findobj('Tag', 'thresholdSlider'), 'Value', 0);
            set(findobj('Tag', 'manualThreshold'), 'String', '0');
        else
            for iPop = 1:ddat.nCompare
                ddat.combinedImg{iPop} = overlay_w_transparency(uint16(ddat.scaledImg),...
                    uint16(ddat.scaledFunc{iPop}),1, 0.6, ddat.color_map, ddat.hot3);
            end
            set(findobj('Tag', 'thresholdSlider'), 'Value', 0);
            set(findobj('Tag', 'manualThreshold'), 'String', '0');
        end
        redisplay;
    end

    % Check if user has selected Z-scores or not and update corresponding
    % GUI elements.
    function updateZImg(hObject, callbackdata)
        
        % Find out if should be looking at Z-scores
        current_Z = get(findobj('Tag', 'viewZScores'), 'Value');
        
        for subPop = 1:ddat.nCompare
            if current_Z == 1
                if strcmp('beta', ddat.type)
                    % get the current beta map
                    cBeta = get(findobj('Tag', 'selectCovariate'), 'Value');
                    % get the current IC map
                    cIC = get(findobj('Tag', 'ICselect'), 'Value');
                    % get the index of the se matrix needed
                    %seIndex = (ddat.q)*cBeta + cIC;
                    if (ddat.viewingContrast == 0)
                        % Scale using the theoretical variance estimate
                        % theoretical estimate is q(p+1) * q(p+1)
                        ddat.img{subPop} = ddat.oimg{subPop} ./...
                            sqrt(squeeze(ddat.betaVarEst( cBeta, cBeta, :,:,: )));
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
                else
                    ddat.img{subPop} = ddat.oimg{subPop} /...
                        std(ddat.oimg{subPop}(:), 'omitnan');
                    set(findobj('Tag', 'manualThreshold'), 'max',...
                        max(max(max(cat(ddat.nCompare,ddat.img{:})))));
                    editThreshold;
                end
            else
                ddat.img{subPop} = ddat.oimg{subPop};
                set(findobj('Tag', 'thresholdSlider'), 'Value', 0);
                set(findobj('Tag', 'manualThreshold'), 'String', '');
                set(findobj('Tag', 'manualThreshold'), 'Value', 0);
            end
        end
        
        % Redisplay the new image
        createCombinedImage;
        redisplay;
        updateCrosshairValue;
        updateInfoText;
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
            endText = ['Sub-Population ' get(findobj('Tag', 'subPopSelect'), 'Value')];
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

    % Update sagittal slider.
    function sagSliderMove(hObject, callbackdata)
        for iPop = 1:ddat.nCompare
            axes(findobj('Tag', ['SagittalAxes' num2str(iPop)]));
            ddat.sag = round(get(hObject, 'Value'));
            for cl = 1:3
                Ssag(:, :, cl) = squeeze(ddat.combinedImg{iPop}(cl).combound(ddat.sag, :, :))';
            end
            set(ddat.sagittal_image{iPop},'CData',Ssag);
            set(ddat.axial_yline{iPop},'Xdata',[ddat.sag ddat.sag]);
            set(ddat.coronal_yline{iPop},'Xdata',[ddat.sag ddat.sag]);
            set(findobj('Tag','crosshairPos'),'String',...
                sprintf('%7.0d %7.0d %7.0d',ddat.sag,ddat.cor, ddat.axi));
        end
    end

    % Update coronal slider.
    function corSliderMove(hObject, callbackdata)
        for iPop = 1:ddat.nCompare
            axes(findobj('Tag', ['CoronalAxes' num2str(iPop)]));
            ddat.cor = round(get(hObject, 'Value'));
            for cl = 1:3
                Scor(:, :, cl) = squeeze(ddat.combinedImg{iPop}(cl).combound(:,ddat.cor,:))';
            end
            set(ddat.coronal_image{iPop},'CData',Scor);
            set(ddat.axial_xline{iPop},'Ydata',[ddat.cor ddat.cor]);
            set(ddat.sagittal_yline{iPop},'Xdata',[ddat.cor ddat.cor]);
            set(findobj('Tag','crosshairPos'),'String',...
                sprintf('%7.0d %7.0d %7.0d',ddat.sag,ddat.cor, ddat.axi));
        end
    end

    % Update axial slider.
    function axiSliderMove(hObject, callbackdata)
        for iPop = 1:ddat.nCompare
            axes(findobj('Tag', ['AxialAxes' num2str(iPop)]));
            ddat.axi = round(get(hObject, 'Value'));
            for cl = 1:3
                Saxi(:, :, cl) = squeeze(ddat.combinedImg{iPop}(cl).combound(:, :, ddat.axi))';
            end
            set(ddat.axial_image{iPop},'CData',Saxi);
            set(ddat.coronal_xline{iPop},'Ydata',[ddat.axi ddat.axi]);
            set(ddat.sagittal_xline{iPop},'Ydata',[ddat.axi ddat.axi]);
            set(findobj('Tag','crosshairPos'),'String',...
                sprintf('%7.0d %7.0d %7.0d',ddat.sag,ddat.cor, ddat.axi));    
        end
    end
   
    % Function to edit the z-threshold required to view on brain image.
    function editThreshold(hObject, callbackdata)
        
        % Get user selected cutoff
        cutoff = get( findobj('Tag', 'thresholdSlider'), 'value');
        set( findobj('Tag', 'manualThreshold'), 'string', num2str(cutoff) );
        
        % Force the checkbox to be 1
        current_Z = get(findobj('Tag', 'viewZScores'), 'Value');
        if current_Z == 0
            set( findobj('Tag', 'viewZScores'), 'Value', 1 );
            updateZImg;
        end
        
        % Loop over sub populations and update Z threshold.
        for subPop = 1:ddat.nCompare
            threshImg = ddat.scaledFunc{subPop} .* (abs(ddat.img{subPop}) >= cutoff);
            threshImg(threshImg == 0) = 1;
            ddat.combinedImg{subPop} = overlay_w_transparency(uint16(ddat.scaledImg),...
                uint16(threshImg),1, 0.6, ddat.color_map, ddat.highcolor);
        end
        
        redisplay;
        updateInfoText;
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

    % Function to save a thresholded mask for future use. Should only be
    % available from the group level IC window.
    function saveMask(hObject, callbackdata)
        newfile = strcat(ddat.outdir, '/' , ddat.outpre, '_maskIC_',...
            num2str(get(findobj('Tag', 'ICselect'), 'Value')), '_zthresh_',...
            get(findobj('Tag', 'manualThreshold'), 'string'), '.nii');
        newMask = (abs(ddat.img{1}) >= str2double(get(findobj('Tag', 'manualThreshold'), 'string')));
        save_nii(make_nii(double(newMask)), newfile);
        maskSearch;
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
        ceditable(1:length(ddat.covTypes)) = 1;
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

    % Function to allow the user to specifiy covariates for a new
    % sub-population.
    function newPopCellEdit(hObject, callbackdata)
        % When the user edits a cell, need to make sure that it is a valid level
        coledit = callbackdata.Indices(2);
        % Make sure input value is a number and not a string
        if all(ismember(callbackdata.NewData, '0123456789+-.eEdD')) & ~isempty(callbackdata.NewData)
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
            newTable(callbackdata.Indices(1), coledit) = {''};
            set(findobj('Tag', 'subPopDisplay'), 'Data', newTable);
        end
        [nsubpop ign] = size( get(findobj('Tag', 'subPopSelect'),'String'));
        
        % Check if all main effects are now filled out. If so, update the
        % interactions, otherwise set them to zero
        factorValues = callbackdata.Source.Data{1:length(ddat.covTypes)};
        allFilledOut = 1;
        rowIndex = callbackdata.Indices(1);
        for iCov=1:length(ddat.covTypes)
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
        
        if (nsubpop == 1)
            for iPop = 1:ddat.nCompare
                updateSubPopulation(findobj('Tag', ['subPopSelect' num2str(iPop)]));
            end
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
        createPanel(selectedSubPops);
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
    end

    % Function to switch to the group level viewer.
    function stGrp(hObject, callbackdata)
        if strcmp(ddat.type, 'subPopCompare')
            revertToDisp;
        end
        ddat.type = 'grp';
        initialDisp;
    end

    % Function to switch to the subject level viewer.
    function stSubj(~, ~)
        if strcmp(ddat.type, 'subPopCompare')
            revertToDisp;
        end
        ddat.type = 'subj';
        initialDisp;
    end

    % Function to switch to the beta map viewer.
    function stBeta(~, ~)
        if strcmp(ddat.type, 'subPopCompare')
            revertToDisp;
        end
        ddat.type = 'beta';
        initialDisp;
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

    function removeContrast(hObject, callbackdata)
        % Check that a contrast exists
        if ddat.contrastExists == 1
            % Keep track of if a contrast should be removed (vs user enter
            % cancel)
            removeContrast = 0;
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

                        % change the drop down menu
                        newString = cell(olddim(1)-1, 1);
                        oldstring = get(findobj('Tag', 'contrastSelect1'), 'String');
                        for i=1:olddim(1)-1
                            if (olddim(1) > 1)
                                newString(i) = {oldstring{i}};
                            else
                                newString(i) = {oldstring(:)'};
                            end
                        end
                        %newString(olddim(1) + 1) = {['C' num2str(olddim(1)+1)]};
                        
                        % Finally, update what is being viewed.
                        % Only have to do this if currently viewing a
                        % contrast
                        if ddat.viewingContrast
                            currentSelection = get(findobj('Tag', ['contrastSelect' num2str(1)]),'Value');
                            % If removed something above the current
                            % selection, do nothing.
                            % If removed current selection, switch to
                            % regular cov viewer and tell user
                            if currentSelection == removeIndex
                                % turn off viewing contrast
                                ddat.viewingContrast = 0;
                                % switch the the selected covariate instead
                                updateIC;
                                set(findobj('Tag', ['contrastSelect' num2str(1)]),'Value', 1);
                            end
                            % If removed above current selection, just
                            % switch the dropdown menu to reflect this
                            if currentSelection > removeIndex
                                set(findobj('Tag', ['contrastSelect' num2str(1)]),'Value', currentSelection - 1);
                                updateContrastDisp;
                            end
                        end
                        
                        if olddim(1) - 1 == 0
                            newString = 'No Contrast Created';
                            ddat.contrastExists = 0;
                            ddat.viewingContrast = 0;
                            set(findobj('Tag', 'contrastDisplay'), 'RowName', {});
                        end
                        
                        % Update all sub population selection viewers
                        for iPop = 1:ddat.nCompare
                            set(findobj('Tag', ['contrastSelect' num2str(iPop)]),'String', newString);  
                        end
                        
                        
                    end
                end 
            end
        % update "viewing contrast" as well
        % check that whatever is on screen is valid BE CAREFUL HERE!!
        else
            warnbox = warndlg('No contrasts have been specified')
        end
    end

end