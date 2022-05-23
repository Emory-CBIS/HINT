function saveInfo = display_get_nifti_export_info(nView, viewerTypes, outdir)
%display_get_nifti_export_info

% Check if an instance of inputWindow already running
hs = findall(0,'tag','displayGetNiftiExportInfo');
if (isempty(hs))
    hs = add_display_get_nifti_export_info_components;
    set(hs.fig,'Visible','on');
else
    figure(hs);
end

%saveInfo = struct();

uiwait(hs.fig);
if isvalid(hs.fig)
    saveInfo = guidata(hs.fig);
else
    saveInfo = struct();
    saveInfo.validRequest = false;
end
delete(hs.fig);

% Define gui components
    function hs = add_display_get_nifti_export_info_components
        
        % Add components, save handles in a struct
        hs.fig = figure('Tag','displayGetNiftiExportInfo',...
            'units', 'normalized', 'position', [0.3 0.4 0.4 0.3],...
            'MenuBar', 'none',...
            'NumberTitle','off',...
            'Name','Nifti File Exporter',...
            'Resize','off',...
            'Visible','off',...
            'Color', get(0,'defaultUicontrolBackgroundColor'));%,...
        %'WindowStyle', 'modal');
        
        %nView
        checkNames = cell(nView);
        checkVals = cell(nView);
        for i = 1:nView
            checkNames{i} = ['Brain View ' num2str(i)];
            checkVals{i} = false;
        end
        dataframe =[checkNames checkVals];
        columnname =   {'View', 'Save'};
        columnformat = {'char', 'logical'};
        columneditable =  [false true];
        
        SaveTable = uitable( hs.fig,...
            'Units','normalized',...
            'Position',...
            [0.1 0.1 0.4 0.8],...
            'tag', 'SaveTable',...
            'Data', dataframe,...
            'ColumnName', columnname,...
            'ColumnWidth', {150, 150},...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'RowName',[],...
            'CellEditCallback', @verify_brain_view_allowed);
        
        %% Radio button controlling if output estimates or p-values
        OutputTypeButtonGroup = uibuttongroup(hs.fig,...
            'units', 'normalized',...
            'tag', 'OutputTypeButtonGroup',...
            'visible', 'on',...
            'Position',[0.6 0.4 0.3 0.5]);
        
        OutputBrainmap = uicontrol(OutputTypeButtonGroup,...
            'string', 'Output brain map',...
            'tag', 'OutputBrainmap',...
            'style', 'radiobutton',...
            'TooltipString', 'Output file containing the brain maps as they currently appear in your viewer window. This includes thresholding.',...
            'units', 'normalized',...
            'Position',[0.1 0.65 0.9 0.3]); %#ok<NASGU>
        
        OutputPvalue = uicontrol(OutputTypeButtonGroup,...
            'style', 'radiobutton',...
            'string', 'Output p-value maps',...
            'units', 'normalized',...
            'TooltipString', 'Output file containing the hc-ICA model based p-values for the maps that you are currently viewing. Note that this is only available for covariate effects and contrasts.',...
            'tag', 'OutputPvalue',...
            'callback', @select_pvalues,...
            'Position',[0.1 0.35 0.9 0.3]); %#ok<NASGU>
        
        OutputMLogPvalue = uicontrol(OutputTypeButtonGroup,...
            'style', 'radiobutton',...
            'string', 'Output -log p-value maps',...
            'units', 'normalized',...
            'TooltipString', 'Output file containing the hc-ICA model based negative log p-values for the maps that you are currently viewing. Note that this is only available for covariate effects and contrasts.',...
            'tag', 'OutputMLogPvalue',...
            'callback', @select_pvalues,...
            'Position',[0.1 0.05 0.9 0.3]); %#ok<NASGU>
        
        % Textbox for filename
        FilenameEditbox = uicontrol('Parent', hs.fig, ...
                'Style', 'edit', ...
                'String', 'Input Filename (without path)',...
                'TooltipString', 'Input the filename here. The file will be saved in your analysis output directory in a sub-folder titled "exports"',...
                'Units', 'Normalized', ...
                'BackgroundColor','white',...
                'Position', [0.6, 0.25, 0.3, 0.08], ...
                'Tag', 'FilenameEditbox');
            
         % Save and cancel buttons
         OKButton = uicontrol('Style', 'pushbutton', ...
            'String', 'Save', ...
            'Units', 'Normalized', ...
            'Position', [0.625, 0.1, 0.1, 0.1], ...
            'Tag', 'OKButton',...
            'Callback', @OK_buttonpress); %#ok<NASGU>
        CancelButton = uicontrol('Style', 'pushbutton', ...
            'String', 'Cancel', ...
            'Units', 'Normalized', ...
            'Position', [0.775, 0.1, 0.1, 0.1], ...
            'Tag', 'CancelButton',...
            'Callback', @cancel_buttonpress); %#ok<NASGU>
        
    end

    function verify_brain_view_allowed(src, event)
        selectedView = event.Indices(1);
        
        % Only need to check if enabling
        if event.NewData == 0; return; end
        
        viewType = viewerTypes{selectedView};
        
        selectedSaveType = get(findobj('tag', 'OutputTypeButtonGroup'), 'selectedObject').String;
        
        % Only possible error is if a p-value has been requested, otherwise
        % can return
        if strcmp(selectedSaveType, 'Output brain map'); return; end
        
        % Check if this viewerType allows p-values
        tableData = get(findobj('tag', 'SaveTable'), 'Data');
        if ~strcmp(viewType, 'Covariate Effect') && ~strcmp(viewType, 'Contrast')
            disp(['P-value export is only available for covariate effects and contrasts. Removing brain map ' ...
                num2str(selectedView) ' from export list.']);
            tableData{selectedView, 2} = false;
        end
        set(findobj('tag', 'SaveTable'), 'Data', tableData);
                    
    end


    function select_pvalues(src, event)
        tableData = get(findobj('tag', 'SaveTable'), 'Data');
        nRow = size(tableData, 1);
        for iRow = 1:nRow
            % User has requested to save this map
            if tableData{iRow, 2} == true
                % Check if invalid type (not contrast or covariate)
                if ~strcmp(viewerTypes{iRow}, 'Covariate Effect') && ~strcmp(viewerTypes{iRow}, 'Contrast')
                    disp(['P-value export is only available for covariate effects and contrasts. Removing brain map ' ...
                        num2str(iRow) ' from export list.']);
                    tableData{iRow, 2} = false;
                end
            end
        end
        set(findobj('tag', 'SaveTable'), 'Data', tableData);
    end

% if cancel, exit the window and return 0
    function cancel_buttonpress(src, event)
        
        handles.filename = '';
        handles.validRequest = false;
        guidata(hs.fig, handles);
        uiresume(hs.fig)
        
    end

% OK button press. Checks to make sure valid input before continuing
    function OK_buttonpress(src, event)
                
        handles = struct();
        handles.filename = get(findobj('tag', 'FilenameEditbox'), 'String');
        
        % Check valid filename
        if ~endsWith(handles.filename, '.nii')
            handles.filename = [handles.filename '.nii'];
        end
        
        % Check at least one image selected
        viewOptions = get(findobj('tag', 'SaveTable'), 'Data');
        saveViews = find([viewOptions{:, 2}] > 0);
        if isempty(saveViews)
            warndlg('Please select at least one brain map for saving.', 'No Brain Views Selected', 'modal');
            return
        end
        
        handles.saveViews = saveViews;
        
        % Get the selection type
        %get(findobj('tag', 'OutputTypeButtonGroup'), 'selectedObject')
        handles.mapTypeSelection = get(findobj('tag', 'OutputTypeButtonGroup'), 'selectedObject').String;
        
        handles.validRequest = true;
        
        guidata(hs.fig, handles);
        uiresume(hs.fig)
        
    end

end

