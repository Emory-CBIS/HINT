function [variableNames, varInModel,...
    covTypes, effectsCodingsEncoders, covariates, interactionsBase,...
    weighted, unitScale, X, varNamesX] = model_specification_window(variableNames, varInModel,...
    covTypes, effectsCodingsEncoders, covariates, interactionsBase,...
    weighted, unitScale, X, varNamesX, varargin)

%% Parse input
parser = inputParser;
addRequired(parser, 'variableNames');
addRequired(parser, 'varInModel');
addRequired(parser, 'covTypes');
addRequired(parser, 'effectsCodingsEncoders');
addRequired(parser, 'covariates');
addRequired(parser, 'interactionsBase');
addRequired(parser, 'weighted');
addRequired(parser, 'unitScale');
addRequired(parser, 'X');
addRequired(parser, 'varNamesX');
parse(parser, variableNames, varInModel, covTypes, effectsCodingsEncoders,...
    covariates, interactionsBase, weighted, unitScale, X, varNamesX, varargin{:});

ModelSpecData = struct();
ModelSpecData.varInModel = parser.Results.varInModel;
ModelSpecData.variableNames = parser.Results.variableNames;
ModelSpecData.covTypes = parser.Results.covTypes;
ModelSpecData.effectsCodingsEncoders = parser.Results.effectsCodingsEncoders;
ModelSpecData.covariates = parser.Results.covariates;
ModelSpecData.interactionsBase = parser.Results.interactionsBase;
ModelSpecData.weighted = parser.Results.weighted;
ModelSpecData.unitScale = parser.Results.unitScale;
ModelSpecData.X = parser.Results.X;
ModelSpecData.varNamesX = parser.Results.varNamesX;

ModelSpecData.weighted = 0;

ModelSpecData.covariateMeans = zeros(0,1);
ModelSpecData.covariateSDevs = zeros(0,1);

hs = findall(0,'tag','modelSpecWindow');
if (isempty(hs))
    hs = add_model_specification_window_components;
    set(hs.fig,'Visible','on');
    set_display;
else
    figure(hs);
end

uiwait(hs.fig);
% Set output
if isvalid(hs.fig)
    outputdata = guidata(hs.fig).output;
    variableNames = outputdata.variableNames;
    varInModel = outputdata.varInModel;
    covTypes = outputdata.covTypes;
    effectsCodingsEncoders = outputdata.effectsCodingsEncoders;
    covariates = outputdata.covariates;
    interactionsBase = outputdata.interactionsBase;
    weighted = outputdata.weighted;
    unitScale = outputdata.unitScale;
    X = outputdata.X;
    varNamesX = outputdata.varNamesX;
else
    variableNames = parser.Results.variableNames;
    varInModel = parser.Results.varInModel;
    covTypes = parser.Results.covTypes;
    effectsCodingsEncoders = parser.Results.effectsCodingsEncoders;
    covariates = parser.Results.covariates;
    interactionsBase = parser.Results.interactionsBase;
    weighted = parser.Results.weighted;
    unitScale = parser.Results.unitScale;
    X = parser.Results.X;
    varNamesX = parser.Results.varNamesX;
end
delete(hs.fig);


    function hs = add_model_specification_window_components
        
        % Add components, save handles in a struct
        hs.fig = figure('Tag','modelSpecWindow',...
            'units', 'normalized', 'position', [0.2 0.2 0.6 0.6],...
            'MenuBar', 'none',...
            'NumberTitle','off',...
            'Name','Model Specification',...
            'Resize','on',...
            'Visible','off',...
            'Color', get(0,'defaultUicontrolBackgroundColor'));
        %,...
            %'WindowStyle', 'modal');
        
        %% Panel showing the model matrix
        modelMatrixPanel = uipanel('BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
            'Tag', 'modelMatrixPanel',...
            'Title', 'Model Matrix for hc-ICA Analysis',...
            'units', 'normalized',...
            'Position',[0.015, 0.50 0.97 0.48]); 
        
        % Listbox displaying the current model matrix
        modelMatrixTable = uitable('Parent', modelMatrixPanel,...
            'Tag', 'modelMatrixTable',...
            'units', 'normalized',...
            'Position',[0.05, 0.05 0.90 0.90]);
                
        %% Sub-panel for selecting covariates for the hc-ICA model
        varSelectPanel = uipanel('BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
            'Tag', 'varSelectPanel',...
            'Title', 'Model Specification',...
            'units', 'normalized',...
            'Position',[0.015, 0.05 0.31 0.43]); 
        
        varSelectAvailText = uicontrol('Parent', varSelectPanel,...
            'style', 'text',...
            'string', 'Covariates Available', ...
            'Tag', 'varSelectAvailText',...
            'units', 'normalized',...
            'Position',[0.05, 0.95 0.44 0.05]);
        
        varSelectAvailBox = uicontrol('Parent', varSelectPanel,...
            'style', 'listbox',...
            'Tag', 'varSelectAvailBox',...
            'units', 'normalized',...
            'Position',[0.05, 0.3 0.44 0.65]);
        
        varInModelBoxText = uicontrol('Parent', varSelectPanel,...
            'style', 'text',...
            'string', 'Covariates In Model', ...
            'Tag', 'varSelectAvailText',...
            'units', 'normalized',...
            'Position',[0.51, 0.95 0.44 0.05]);
        
        varInModelBox = uicontrol('Parent', varSelectPanel,...
            'style', 'listbox',...
            'Tag', 'varInModelBox',...
            'units', 'normalized',...
            'Position',[0.51, 0.3 0.44 0.65]);
        
        addVarModelButton = uicontrol('Style', 'pushbutton', ...
            'Parent', varSelectPanel,...
            'String', 'Add', ...
            'Units', 'Normalized', ...
            'Position', [0.1, 0.16, 0.3, 0.1], ...
            'Tag', 'addVarModelButton',...
            'callback', @add_covariate_button_callback); %#ok<NASGU>
        
        addAllVarModelButton = uicontrol('Style', 'pushbutton', ...
            'Parent', varSelectPanel,...
            'String', 'Add All', ...
            'Units', 'Normalized', ...
            'Position', [0.1, 0.05, 0.3, 0.1], ...
            'Tag', 'addAllVarModelButton',...
            'callback', @add_all_covariates_button_callback); %#ok<NASGU>
        
        removeVarModelButton = uicontrol('Style', 'pushbutton', ...
            'Parent', varSelectPanel,...
            'String', 'Remove', ...
            'Units', 'Normalized', ...
            'Position', [0.6, 0.16, 0.3, 0.1], ...
            'Tag', 'removeVarModelButton',...
            'Callback', @remove_covariate_button_callback); %#ok<NASGU>
        
        removeAllVarModelButton = uicontrol('Style', 'pushbutton', ...
            'Parent', varSelectPanel,...
            'String', 'Remove All', ...
            'Units', 'Normalized', ...
            'Position', [0.6, 0.05, 0.3, 0.1], ...
            'Tag', 'removeAllVarModelButton',...
            'callback', @remove_all_covariates_button_callback); %#ok<NASGU>
        
        %% Sub-panel for specifying the type (continuous, categorical) of
        % covariates
        covTypePanel = uipanel('BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
            'Tag', 'covTypePanel',...
            'Title', 'Specify Covariate Types',...
            'units', 'normalized',...
            'Position',[0.345, 0.26 0.31 0.22]); 
        
        catCovText = uicontrol('Parent', covTypePanel,...
            'style', 'text',...
            'string', 'Categorical', ...
            'Tag', 'catCovText',...
            'units', 'normalized',...
            'Position',[0.05, 0.85 0.44 0.15]);
        
        catCovBox = uicontrol('Parent', covTypePanel,...
            'style', 'listbox',...
            'Tag', 'catCovBox',...
            'units', 'normalized',...
            'Position',[0.05, 0.2 0.44 0.65]);
        
        contCovText = uicontrol('Parent', covTypePanel,...
            'style', 'text',...
            'string', 'Continuous', ...
            'Tag', 'contCovText',...
            'units', 'normalized',...
            'Position',[0.51, 0.85 0.44 0.15]);
        
        contCovBox = uicontrol('Parent', covTypePanel,...
            'style', 'listbox',...
            'Tag', 'contCovBox',...
            'units', 'normalized',...
            'Position',[0.51, 0.2 0.44 0.65]);
        
        makeContinuousButton = uicontrol('Style', 'pushbutton', ...
            'Parent', covTypePanel,...
            'String', 'Make Continuous', ...
            'Units', 'Normalized', ...
            'Position', [0.05, 0.025, 0.44, 0.15], ...
            'Tag', 'makeContinuousButton',...
            'callback', @switch_covariate_to_continuous); %#ok<NASGU>
        
        makeCategoricalButton = uicontrol('Style', 'pushbutton', ...
            'Parent', covTypePanel,...
            'String', 'Make Categorical', ...
            'Units', 'Normalized', ...
            'Position', [0.51, 0.025, 0.44, 0.15], ...
            'Tag', 'makeCategoricalButton',...
            'callback', @switch_covariate_to_categorical); %#ok<NASGU>
        
        
        %% Sub-panel for specifying the reference category for effects
        % coding
        refCatPanel = uipanel('BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
            'Tag', 'refCatPanel',...
            'Title', 'Specify Reference Category',...
            'units', 'normalized',...
            'Position',[0.345, 0.05 0.31 0.20]); 
        
        refCovText = uicontrol('Parent', refCatPanel,...
            'style', 'text',...
            'string', 'Covariate', ...
            'Tag', 'refCovText',...
            'units', 'normalized',...
            'Position',[0.05, 0.8 0.44 0.15]);
        
        refSelectCovBox = uicontrol('Parent', refCatPanel,...
            'style', 'listbox',...
            'Tag', 'refSelectCovBox',...
            'units', 'normalized',...
            'Position',[0.05, 0.05 0.44 0.75],...
            'callback', @reference_listbox_selection_callback);
        
        refCovSelectText = uicontrol('Parent', refCatPanel,...
            'style', 'text',...
            'string', 'Ref. Category', ...
            'Tag', 'refCovSelectText',...
            'units', 'normalized',...
            'Position',[0.51, 0.8 0.44 0.15]);
        
        refSelectBox = uicontrol('Parent', refCatPanel,...
            'style', 'listbox',...
            'Tag', 'refSelectBox',...
            'units', 'normalized',...
            'Position',[0.51, 0.05 0.44 0.75],...
            'callback', @change_reference_level_callback);
        
        
        
        
        %% Sub-panel for specifying interaction terms
        intSpecPanel = uipanel('BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
            'Tag', 'intSpecPanel',...
            'Title', 'Specify Interactions',...
            'units', 'normalized',...
            'Position',[0.675, 0.36 0.31 0.12]);
        
        intVar1Select = uicontrol('Parent', intSpecPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.5, 0.48, 0.35], ...
            'Tag', 'intVar1Select',...
            'String', 'Covariate 1'); %#ok<NASGU>
        
        intVar2Select = uicontrol('Parent', intSpecPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.51, 0.5, 0.48, 0.35], ...
            'Tag', 'intVar2Select',...
            'String', 'Covariate 2'); %#ok<NASGU>
        
        intAddButton = uicontrol('Style', 'pushbutton', ...
            'Parent', intSpecPanel,...
            'String', 'Add Interaction', ...
            'Units', 'Normalized', ...
            'Position', [0.02, 0.05, 0.46, 0.3], ...
            'Tag', 'intAddButton',...
            'callback', @add_interaction_callback); %#ok<NASGU>
        
        intRemoveButton = uicontrol('Style', 'pushbutton', ...
            'Parent', intSpecPanel,...
            'String', 'Remove Interaction', ...
            'Units', 'Normalized', ...
            'Position', [0.52, 0.05, 0.46, 0.3], ...
            'Tag', 'intRemoveButton',...
            'callback', @remove_interaction_callback); %#ok<NASGU>
        
        %% Sub-panel for viewing interaction terms
        intListPanel = uipanel('BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
            'Tag', 'intListPanel',...
            'Title', 'Interaction List',...
            'units', 'normalized',...
            'Position',[0.675, 0.15 0.31 0.2]);
        
        intListBox = uicontrol('Parent', intListPanel,...
            'style', 'listbox',...
            'Tag', 'intListBox',...
            'units', 'normalized',...
            'Position',[0.05, 0.05 0.9 0.9]);
        
         %% Sub-panel for weighted effects coding
        codingSchemePanel = uipanel('BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
            'Tag', 'codingSchemePanel',...
            'Title', 'Effects Coding',...
            'units', 'normalized',...
            'Position',[0.675, 0.05 0.31 0.1]);
        
        weightedEffectsCheckbox = uicontrol('Parent', codingSchemePanel,...
            'style', 'checkbox',...
            'Tag', 'weightedEffectsCheckbox',...
            'string', 'Use weighted effects coding',...
            'units', 'normalized',...
            'value', 0,...
            'visible', 'off',...
            'callback', @set_effects_coding_type,...
            'Position',[0.05, 0.5 0.7 0.45]);
                    %'value', ModelSpecData.weighted,...

        
        scaleContinuousCovsCheckbox = uicontrol('Parent', codingSchemePanel,...
            'style', 'checkbox',...
            'Tag', 'scaleContinuousCovsCheckbox',...
            'string', 'Scale continuous covariates to unit variance',...
            'units', 'normalized',...
            'value', ModelSpecData.unitScale,...
            'callback', @set_unit_scaling_yesno,...
            'Position',[0.05, 0.05 0.7 0.45]);
        
        % Save and continue button
        % OK and Cancel Buttons
        OKButton = uicontrol('Style', 'pushbutton', ...
            'String', 'OK', ...
            'Units', 'Normalized', ...
            'Position', [0.20, 0.01, 0.2, 0.03], ...
            'Tag', 'OKButton',...
            'Callback', @OK_buttonpress); %#ok<NASGU>
        CancelButton = uicontrol('Style', 'pushbutton', ...
            'String', 'Cancel', ...
            'Units', 'Normalized', ...
            'Position', [0.60, 0.01, 0.2, 0.03], ...
            'Tag', 'CancelButton',...
            'callback', @cancel_buttonpress); %#ok<NASGU>
        
        
    end

    function set_display;
        determine_listboxes_covariates_in_model;
        remove_invalid_interactions;
        determine_listboxes_covariate_types;
        determine_listboxes_reference_panel;
        determine_listboxes_reference_level_selection;
        determine_interation_dropdown_menus;
        determine_interation_listbox;
        display_current_model_matrix;
    end



    %% Model Specification Panel Functions

    function determine_listboxes_covariates_in_model(~, ~)
        
        % Find the covariates that are already in the model
        inModel    = ModelSpecData.variableNames(ModelSpecData.varInModel == 1);
        outOfModel = ModelSpecData.variableNames(ModelSpecData.varInModel == 0);
        
        set(findobj('tag', 'varInModelBox'), 'Value', 1);
        set(findobj('tag', 'varSelectAvailBox'), 'Value', 1);
        
        set(findobj('tag', 'varInModelBox'), 'String', inModel);
        set(findobj('tag', 'varSelectAvailBox'), 'String', outOfModel);
        
        % Check if buttons should be enabled or disabled
        
        % Disable "add" buttons if nothing left to add, otherwise enable
        if isempty(outOfModel)
            set(findobj('tag', 'addAllVarModelButton'), 'enable', 'off')
            set(findobj('tag', 'addVarModelButton'), 'enable', 'off')
        else
            set(findobj('tag', 'addAllVarModelButton'), 'enable', 'on')
            set(findobj('tag', 'addVarModelButton'), 'enable', 'on')
        end
        
        % Disable "remove" buttons if nothing left to remove, otherwise enable
        if isempty(inModel)
            set(findobj('tag', 'removeAllVarModelButton'), 'enable', 'off')
            set(findobj('tag', 'removeVarModelButton'), 'enable', 'off')
        else
            set(findobj('tag', 'removeAllVarModelButton'), 'enable', 'on')
            set(findobj('tag', 'removeVarModelButton'), 'enable', 'on')
        end
        
    end

    function add_covariate_button_callback(src, event)
        optionalVarsToAdd = get(findobj('tag', 'varSelectAvailBox'), 'String');
        
        if isempty(optionalVarsToAdd); return; end
        
        selectedString = get(findobj('tag', 'varSelectAvailBox'), 'Value');
        selectedCov = optionalVarsToAdd{selectedString};
        
        % Set the corresponding varInModel term to 0s
        ModelSpecData.varInModel(strcmp(ModelSpecData.variableNames, selectedCov)) = 1;
        set_display;
    end

    function add_all_covariates_button_callback(src, event)
        optionalVarsToAdd = get(findobj('tag', 'varSelectAvailBox'), 'String');
        
        if isempty(optionalVarsToAdd); return; end
        
        % Set the corresponding varInModel term to 0s
        ModelSpecData.varInModel(:) = 1;
        set_display;
    end

    function remove_all_covariates_button_callback(src, event)
        optionalVarsToRemove = get(findobj('tag', 'varInModelBox'), 'String');
        
        if isempty(optionalVarsToRemove); return; end
        
        % Set the corresponding varInModel term to 0s
        ModelSpecData.varInModel(:) = 0;
        set_display;
    end

    function remove_covariate_button_callback(src, event)
        optionalVarsToRemove = get(findobj('tag', 'varInModelBox'), 'String');
        
        if isempty(optionalVarsToRemove); return; end
        
        selectedString = get(findobj('tag', 'varInModelBox'), 'Value');
        selectedCov = optionalVarsToRemove{selectedString};
        
        % Set the corresponding varInModel term to 0s
        ModelSpecData.varInModel(strcmp(ModelSpecData.variableNames, selectedCov)) = 0;
        set_display;
        
    end

    %% Functions for the continuous/categorical switching panel
    function determine_listboxes_covariate_types;
        
        % List of categorical and continuous covariates included in the
        % model
        contCov    = ModelSpecData.variableNames(ModelSpecData.covTypes == 0 & ModelSpecData.varInModel == 1);
        catCov     = ModelSpecData.variableNames(ModelSpecData.covTypes == 1 & ModelSpecData.varInModel == 1);
        
        % Reset selection
        set(findobj('tag', 'contCovBox'), 'Value', 1);
        set(findobj('tag', 'catCovBox'), 'Value', 1);
        
        % Set the corresponding list boxes
        set(findobj('tag', 'contCovBox'), 'String', contCov);
        set(findobj('tag', 'catCovBox'), 'String', catCov);
        
        % Check if buttons should be enabled or disabled
        
        % Disable "continuous" button if all are already continuous
        if isempty(catCov)
            set(findobj('tag', 'makeContinuousButton'), 'enable', 'off')
        else
            set(findobj('tag', 'makeContinuousButton'), 'enable', 'on')
        end
        
        % Disable "make categorical" if all already categorical
        if isempty(contCov)
            set(findobj('tag', 'makeCategoricalButton'), 'enable', 'off')
        else
            set(findobj('tag', 'makeCategoricalButton'), 'enable', 'on')
        end
    end
    
    function switch_covariate_to_continuous(src, event);
        
        % Get the selected covariate
        optionalVarsToSTCont = get(findobj('tag', 'catCovBox'), 'String');
        
        if isempty(optionalVarsToSTCont); return; end
        
        % Determine selection by covariate name
        selectedString = get(findobj('tag', 'catCovBox'), 'Value');
        selectedCov = optionalVarsToSTCont{selectedString};
        
        % Make sure that this covariate contains numeric data
        dataCol = ModelSpecData.covariates{:, strcmp(ModelSpecData.variableNames, selectedCov)};
        if iscell(dataCol)
            dblConverted = cellfun(@str2double, dataCol);
            if any(isnan(dblConverted))
                disp(['Cannot convert ' selectedCov ' to numeric. Ignoring request.'])
                return
            end
        end
        
        % Set the corresponding covTypes term to 0s
        ModelSpecData.covTypes(strcmp(ModelSpecData.variableNames, selectedCov)) = 0;
        set_display;
        
    end

    function switch_covariate_to_categorical(src, event);
        
        % Get the selected covariate
        optionalVarsToSTCat = get(findobj('tag', 'contCovBox'), 'String');
        
        if isempty(optionalVarsToSTCat); return; end
        
        % Determine selection by covariate name
        selectedString = get(findobj('tag', 'contCovBox'), 'Value');
        selectedCov = optionalVarsToSTCat{selectedString};
        
        % Set the corresponding covTypes term to 0s
        ModelSpecData.covTypes(strcmp(ModelSpecData.variableNames, selectedCov)) = 1;
        set_display;
        
    end




    %% Reference Category Sub-Panel
    
    function determine_listboxes_reference_panel;
        activeCatIndices = ModelSpecData.covTypes == 1 & ModelSpecData.varInModel == 1;
        catCov     = ModelSpecData.variableNames(activeCatIndices);
        if get(findobj('tag', 'refSelectCovBox'), 'Value') > length(catCov)
            set(findobj('tag', 'refSelectCovBox'), 'Value', 1);
        end
        set(findobj('tag', 'refSelectCovBox'), 'String', catCov); 
    end

    function determine_listboxes_reference_level_selection

        % Get the name of the currently selected variable
        refListboxString = get(findobj('tag', 'refSelectCovBox'), 'String');
        
        if isempty(refListboxString)
            set(findobj('tag', 'refSelectBox'), 'Value', 1);
            set(findobj('tag', 'refSelectBox'), 'String', {});
            return
        end
        
        % If listbox was empty, make sure not invalid value
        if isempty(get(findobj('tag', 'refSelectCovBox'), 'Value'))
            set(findobj('tag', 'refSelectCovBox'), 'Value', 1)
        end
        
        
        selectedCovValue = get(findobj('tag', 'refSelectCovBox'), 'Value');
        selectedCov = refListboxString{selectedCovValue};
        
        % Find the corresponding covariate index
        covIndex = strcmp(ModelSpecData.variableNames, selectedCov);
        
        % Get a list of all categories
        ECE = ModelSpecData.effectsCodingsEncoders{covIndex};
        nonRefCats = ECE.variableNames;
        refCat = ECE.referenceCategory;
        % Combine into a new string
        listboxOptions = {refCat, nonRefCats{:}};
        
        % Set as listbox display
        set(findobj('tag', 'refSelectBox'), 'String', listboxOptions);
        set(findobj('tag', 'refSelectBox'), 'Value', 1);
    end

    function reference_listbox_selection_callback(~, ~)
                
        determine_listboxes_reference_level_selection;
        
    end

    function change_reference_level_callback(src, event)
        % Changing the reference level triggers a regeneration of the
        % effects coding encoder, followed by a regen of the model matrix
        
        % Get the name of the currently selected variable
        refListboxString = get(findobj('tag', 'refSelectCovBox'), 'String');
        
        if isempty(refListboxString); return; end
        
        selectedCovValue = get(findobj('tag', 'refSelectCovBox'), 'Value');
        selectedCov = refListboxString{selectedCovValue};
        
        % Find the corresponding covariate index
        covIndex = find(strcmp(ModelSpecData.variableNames, selectedCov));
        
        % Get the selected reference level for this covariate
        newRefGroup = src.String{src.Value};
        
        ModelSpecData.effectsCodingsEncoders{covIndex} = ...
            generate_effects_coding(ModelSpecData.covariates{:, covIndex},...
            'ref', newRefGroup);
        
        set_display;
    end
    
    %% Interaction Dropdown Panel
    function determine_interation_dropdown_menus;
        
        % Get a list of all covariates included in the model
        varList = ModelSpecData.variableNames(ModelSpecData.varInModel == 1);
        
        if isempty(varList)
            varList = "No Covariates";
        end
        
        % Add them to the dropdown menus
        currentValue = get(findobj('tag', 'intVar1Select'), 'value');
        if currentValue > length(varList)
            newSetting = length(varList);
            set(findobj('tag', 'intVar1Select'), 'value', newSetting);
        end
        
        set(findobj('tag', 'intVar1Select'), 'string', varList);
        
        currentValue = get(findobj('tag', 'intVar2Select'), 'value');
        if currentValue > length(varList)
            newSetting = length(varList);
            set(findobj('tag', 'intVar2Select'), 'value', newSetting);
        end
        
        set(findobj('tag', 'intVar2Select'), 'string', varList);
        
    end

    % Add interaction button
    function add_interaction_callback(src, event)
        
        % Get the selected covariate from each dropdown menu
        cov1Index = get(findobj('tag', 'intVar1Select'), 'value');
        cov2Index = get(findobj('tag', 'intVar2Select'), 'value');
        
        % If the two covariates are the same, return without doing
        % anything.
        if cov1Index == cov2Index; return; end
        
        % Get the corresponding strings
        covOptions = get(findobj('tag', 'intVar1Select'), 'string');
        selectedCov1 = covOptions{cov1Index};
        selectedCov2 = covOptions{cov2Index};
        
        % Check if this interaction already has been specified
        % this is done by checking in interactionsBase, which always has
        % the same number of columns regardless of which covariates have
        % been chosen for inclusion in the model.
        ibCovIndex1 = find(strcmp(ModelSpecData.variableNames, selectedCov1));
        ibCovIndex2 = find(strcmp(ModelSpecData.variableNames, selectedCov2));
        
        newInteraction = zeros(1, size(ModelSpecData.interactionsBase, 2));
        newInteraction(1, ibCovIndex1) = 1;
        newInteraction(1, ibCovIndex2) = 1;
        
        % Search for match in existing interactions
        [isMatch, idx] = ismember(newInteraction, ModelSpecData.interactionsBase, 'rows');
        
        % Add to interactionsBase
        if ~isMatch
            ModelSpecData.interactionsBase = [ModelSpecData.interactionsBase; newInteraction];
        end
        
        set_display;
                
    end

    function remove_interaction_callback(src, event)
        
        % Get the selected covariate from each dropdown menu
        cov1Index = get(findobj('tag', 'intVar1Select'), 'value');
        cov2Index = get(findobj('tag', 'intVar2Select'), 'value');
        
        % If the two covariates are the same, return without doing
        % anything.
        if cov1Index == cov2Index; return; end
        
        % Get the corresponding strings
        covOptions = get(findobj('tag', 'intVar1Select'), 'string');
        selectedCov1 = covOptions{cov1Index};
        selectedCov2 = covOptions{cov2Index};
        
        % Check if this interaction already has been specified
        % this is done by checking in interactionsBase, which always has
        % the same number of columns regardless of which covariates have
        % been chosen for inclusion in the model.
        ibCovIndex1 = find(strcmp(ModelSpecData.variableNames, selectedCov1));
        ibCovIndex2 = find(strcmp(ModelSpecData.variableNames, selectedCov2));
        
        newInteraction = zeros(1, size(ModelSpecData.interactionsBase, 2));
        newInteraction(1, ibCovIndex1) = 1;
        newInteraction(1, ibCovIndex2) = 1;
        
        % Search for match in existing interactions, if find the match,
        % remove it
        [isMatch, idx] = ismember(newInteraction, ModelSpecData.interactionsBase, 'rows');
        
        % Remove from interactionsBase
        if isMatch
            ModelSpecData.interactionsBase(idx, :) = [];
        end
        
        set_display;
                
    end

    %% Interactions Listbox
    function determine_interation_listbox;
        
        % Determine the interaction names using interactionsBase
        interactionNames = {};
        
        for iInt = 1:size(ModelSpecData.interactionsBase, 1)
            
            % Get the current interaction
            currentInteraction = ModelSpecData.interactionsBase(iInt, :);
            
            % Get the corresponding covariate names
            interactionVariables = ModelSpecData.variableNames(currentInteraction == 1);
            
            interactionName = append(interactionVariables{1}, ' x ', interactionVariables{2});
            
            interactionNames{iInt} = interactionName;
            
        end
        
        ModelSpecData.interactionNames = interactionNames;
        
        set(findobj('tag', 'intListBox'), 'String', ModelSpecData.interactionNames)
        
    end
    
    %% Effects Coding Settings functions
    function set_effects_coding_type(src, event)
        
        ModelSpecData.weighted = event.Source.Value == 1;
                
        ModelSpecData.effectsCodingsEncoders = {};
        for p = 1:length(ModelSpecData.covTypes)
            ModelSpecData.effectsCodingsEncoders{p} =...
                generate_effects_coding(ModelSpecData.covariates{:, p},...
                'weighted',  ModelSpecData.weighted == 1);
        end
        
        set_display;
        
    end

    function set_unit_scaling_yesno(src, event)
        
        ModelSpecData.unitScale = event.Source.Value;
        
        set_display;
        
    end

    %% General functions
    
    % Removes any interactions for which all variables are not longer
    % included in the model
    function remove_invalid_interactions
        
        nInt = size(ModelSpecData.interactionsBase, 1);
        
        intsKeep = [];
        for iInt = 1:nInt
            interaction = ModelSpecData.interactionsBase(iInt, :);
            if all( (ModelSpecData.varInModel(:) .* interaction(:)) == interaction(:))
                intsKeep = [intsKeep; iInt];
            end
        end
        ModelSpecData.interactionsBase =  ModelSpecData.interactionsBase(intsKeep, :);        
        
    end
    
    %% Main Display Function
    
    function display_current_model_matrix
        
        ModelSpecData.covariateMeans = zeros(sum(ModelSpecData.varInModel),1);
        ModelSpecData.covariateSDevs = zeros(sum(ModelSpecData.varInModel),1);
        
        % First, get the main effects for each covariate
        % TODO replace with generate_model_matrix function from src folder
        ModelSpecData.X = [];
        ModelSpecData.varNamesX = {};
        for p = 1:length(ModelSpecData.covTypes)
            if ModelSpecData.varInModel(p) == 1
                covariateValues = ModelSpecData.covariates{:, p};
                varName = ModelSpecData.variableNames{p};
                if ModelSpecData.covTypes(p) == 1
                    ModelSpecData.X = [ModelSpecData.X apply_effects_coding(covariateValues, ModelSpecData.effectsCodingsEncoders{p})];
                    for iset = 1:length(ModelSpecData.effectsCodingsEncoders{p}.variableNames)
                        ModelSpecData.varNamesX{length(ModelSpecData.varNamesX) + 1} = [varName '_' ModelSpecData.effectsCodingsEncoders{p}.variableNames{iset}];
                    end
                else
                    ModelSpecData.covariateMeans(p) = mean(covariateValues);
                    ModelSpecData.covariateSDevs(p) = std(covariateValues);
                    covariateValues = covariateValues - ModelSpecData.covariateMeans(p);
                    if (ModelSpecData.unitScale == 1)
                        covariateValues = covariateValues / ModelSpecData.covariateSDevs(p);
                    end
                    ModelSpecData.X = [ModelSpecData.X covariateValues];
                    ModelSpecData.varNamesX{length(ModelSpecData.varNamesX) + 1} = varName;
                end
            end
        end
        
        % Add weighted/unweighted interaction effects
        if ModelSpecData.weighted == 1
            [ModelSpecData.X, ModelSpecData.varNamesX] = generate_ints_from_covariates_weighted(ModelSpecData.X, ModelSpecData.interactionsBase,...
                ModelSpecData.covTypes,  ModelSpecData.covariates,...
                ModelSpecData.variableNames,  ModelSpecData.effectsCodingsEncoders, ModelSpecData.varNamesX,...
                ModelSpecData.covariateMeans, ModelSpecData.covariateSDevs, ModelSpecData.unitScale);
        else
            [ModelSpecData.X, ModelSpecData.varNamesX] = generate_ints_from_covariates_unweighted(ModelSpecData.X, ModelSpecData.interactionsBase,...
                ModelSpecData.covTypes,  ModelSpecData.covariates,...
                ModelSpecData.variableNames,  ModelSpecData.effectsCodingsEncoders, ModelSpecData.varNamesX,...
                ModelSpecData.covariateMeans, ModelSpecData.covariateSDevs, ModelSpecData.unitScale);
        end
                
        % Convert to a table
        ModelSpecData.modelMatrix = array2table(ModelSpecData.X);
        ModelSpecData.modelMatrix.Properties.VariableNames = ModelSpecData.varNamesX;
                
        % Display
        set(findobj('tag', 'modelMatrixTable'), 'Data', table2cell(ModelSpecData.modelMatrix));
        set(findobj('tag', 'modelMatrixTable'), 'ColumnName',  ModelSpecData.varNamesX);
        
        
    end

    %% Other Functions
    function OK_buttonpress(src, event)
        
        handles.output = struct();
        handles.output.variableNames = ModelSpecData.variableNames;
        handles.output.varInModel = ModelSpecData.varInModel;
        handles.output.covTypes = ModelSpecData.covTypes;
        handles.output.effectsCodingsEncoders = ModelSpecData.effectsCodingsEncoders;
        handles.output.covariates = ModelSpecData.covariates;
        handles.output.interactionsBase = ModelSpecData.interactionsBase;
        handles.output.weighted = ModelSpecData.weighted;
        handles.output.unitScale = ModelSpecData.unitScale;
        handles.output.X = ModelSpecData.X;
        handles.output.varNamesX = ModelSpecData.varNamesX;
        
        guidata(hs.fig, handles);
        uiresume(hs.fig)
        
    end

    function cancel_buttonpress(src, event)
        
        handles.output = struct();
        handles.output.variableNames = parser.Results.variableNames;
        handles.output.varInModel = parser.Results.varInModel;
        handles.output.covTypes = parser.Results.covTypes;
        handles.output.effectsCodingsEncoders = parser.Results.effectsCodingsEncoders;
        handles.output.covariates = parser.Results.covariates;
        handles.output.interactionsBase = parser.Results.interactionsBase;
        handles.output.weighted = parser.Results.weighted;
        handles.output.unitScale = parser.Results.unitScale;
        handles.output.X = parser.Results.X;
        handles.output.varNamesX = parser.Results.varNamesX;

        guidata(hs.fig, handles);
        uiresume(hs.fig)
        
    end



end

