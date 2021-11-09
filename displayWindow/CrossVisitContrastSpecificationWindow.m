function [outCurrentContrasts, outContrastNames, outContrastStrings] = CrossVisitContrastSpecificationWindow(CovariateNames, CurrentContrasts, ContrastNames, nVisit)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here



cvcsw = findall(0,'tag','CrossVisitContrastSpecificationWindowInstance');
if (isempty(cvcsw))
    cvcsw = addcomponents;
    set(cvcsw.fig,'Visible','on');
else
    figure(cvcsw);
end

% Perform some initalization
update_cvcdisplay;

% Default output
outCurrentContrasts = CurrentContrasts;
outContrastNames    = ContrastNames;
outContrastStrings  = repmat({''}, length(ContrastNames), 1);

% Wait for the user to close the GUI
uiwait() 


    function cvcsw = addcomponents
        
        % Add components
        cvcsw.fig = figure('Units', 'normalized', ...,...
            'position', [0.3 0.3 0.3 0.3],...
            'MenuBar', 'none',...
            'Tag', 'CrossVisitContrastSpecificationWindowInstance',...
            'NumberTitle','off',...
            'Name','Cross-Visit Contrast Specification',...
            'Resize','on',...
            'Visible','off');
        
        cvc_data = struct();
        % Visit specific variable names
        cvc_data.FullTableNames = repmat(CovariateNames, 1, nVisit);
        ind = 0;
        for j = 1:nVisit
            for p = 1:length(CovariateNames)
                ind = ind + 1;
                cvc_data.FullTableNames{ind} = [cvc_data.FullTableNames{ind} ' (Visit ' num2str(j) ')'];
            end
        end
        
        cvc_data.CurrentContrasts = CurrentContrasts;
        cvc_data.ContrastNames = ContrastNames;
        guidata(cvcsw.fig, cvc_data);
        
        % Settings
        cvc_ContrastDisplayPanel = uipanel('BackgroundColor','white',...
            'Parent', cvcsw.fig,...
            'Tag', 'cvc_ContrastDisplayPanel',...
            'title', 'Contrast List',...
            'units', 'normalized',...
            'Position',[0.01, 0.31 0.98 0.68], ...;
            'BackgroundColor',get(cvcsw.fig,'color'));
        
        cvc_ControlPanel = uipanel('BackgroundColor','white',...
            'Parent', cvcsw.fig,...
            'Tag', 'cvc_ContrastControlPanel',...
            'title', 'Controls',...
            'units', 'normalized',...
            'Position',[0.01, 0.01 0.98 0.28], ...;
            'BackgroundColor',get(cvcsw.fig,'color'));
        
        % Controlling the Brain/Map and visit selection
        cvc_ContrastTable = uitable('Parent', cvc_ContrastDisplayPanel,...
            'Tag', 'cvc_ContrastTable',...
            'units', 'normalized',...
            'Position',[0.1, 0.1 0.8 0.8], ...;
            'BackgroundColor',get(cvcsw.fig,'color'),...
            'ColumnEditable', true,...
            'CellEditCallback', @cvc_ContrastTableCellEdit_callback);
        
        % Dropdown menu that lists all current contrasts
        cvc_ContrastDropdown = uicontrol('Parent', cvc_ControlPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.89, 0.4, 0.1], ...
            'Tag', 'cvc_ContrastDropdown',...
            'String', 'Select Cross-Visit Contrast'); %#ok<NASGU>
        % 'Callback', @(src, event)load_functional_images, ...
        
        % Control buttons at bottom
%         SaveButton = uicontrol(ms.fig,...
%             'style', 'pushbutton',...
%             'string', 'Save Mask',...
%             'units', 'normalized',...
%             'Position',[0.2 0.05 0.2 0.1],...
%             'callback', @mask_save_button_callback);

        cvc_NewCrossVisitContrastButton = uicontrol(cvcsw.fig,...
            'style', 'pushbutton',...
            'Parent', cvc_ControlPanel,...
            'string', 'New Cross-Visit Contrast',...
            'Tag', 'cvc_NewCrossVisitContrastButton',...
            'units', 'normalized',...
            'Position',[0.4 0.7 0.3 0.29],...
            'callback', @cvc_NewCrossVisitContrastButton_callback);
        
        cvc_DeleteCrossVisitContrastButton = uicontrol(cvcsw.fig,...
            'style', 'pushbutton',...
            'Parent', cvc_ControlPanel,...
            'string', 'Delete Selected Contrast',...
            'Tag', 'cvc_DeleteCrossVisitContrastButton',...
            'units', 'normalized',...
            'Position',[0.4 0.4 0.3 0.29],...
            'callback', @cvc_DeleteCrossVisitContrastButton_callback);
        
        cvc_RenameCrossVisitContrastButton = uicontrol(cvcsw.fig,...
            'style', 'pushbutton',...
            'Parent', cvc_ControlPanel,...
            'string', 'Rename Selected Contrast',...
            'Tag', 'cvc_RenameCrossVisitContrastButton',...
            'units', 'normalized',...
            'Position',[0.4 0.1 0.3 0.29],...
            'callback', @cvc_RenameCrossVisitContrastButton_callback);

        cvc_CloseButton = uicontrol(cvcsw.fig,...
            'style', 'pushbutton',...
            'Parent', cvc_ControlPanel,...
            'string', 'Close',...
            'units', 'normalized',...
            'Position',[0.8 0.01 0.18 0.1],...
            'callback', @close_cvcwindow_callback);
                
        movegui(cvcsw.fig, 'center');
        
    end

    % Function displays/re-displays all contrasts
    function update_cvcdisplay()
        
        data = guidata(cvcsw.fig);
        set(findobj('tag', 'cvc_ContrastTable'), 'ColumnName', data.FullTableNames);
        set(findobj('tag', 'cvc_ContrastTable'), 'Data', data.CurrentContrasts);
        set(findobj('tag', 'cvc_ContrastTable'), 'RowName', data.ContrastNames);
        
        % Set the dropdown menu to contain all contrast names
        if ~isempty(data.ContrastNames) > 0
            set(findobj('tag', 'cvc_ContrastDropdown'), 'String', data.ContrastNames);
        else
            set(findobj('tag', 'cvc_ContrastDropdown'), 'String', 'Select Cross-Visit Contrast');
        end
        
    end

    % Called by a few other functions
    % contrastName is the new name, ContrastNames is the current
    % set of all contrast names
    % defaultCVCName is the thing to revert to if naming fails (generally
    % CVC#)
    function [newContrastName] = verify_or_fix_cvc_name(newContrastName, ContrastNames, defaultCVCName, varargin)
        
        % Determine if a list of indices not not check was provided
        % this is needed for editing a contrast name to avoid renaming it
        
        % Check for cancel press
        if isempty(newContrastName)
            newContrastName = defaultCVCName;
        end
        
        % Trim any leading whitespace
        newContrastName{1} = strtrim(newContrastName{1});
        
        % If user did not input a name (different than pressing cancel) 
        % or just input blank space, then default back to CVC#
        if isempty(newContrastName{1})
            newContrastName = defaultCVCName;
        end
                
        % Make sure that contrast name is unique, otherwise append a number
        % to the end
        verifiedUnique = 0;
        counter = 0;
        tempContrastName = newContrastName{1};
        while verifiedUnique == 0
            counter = counter + 1;
            if any(strcmp(ContrastNames, tempContrastName)) && ~strcmp(tempContrastName, defaultCVCName)
                tempContrastName = [newContrastName{1} '_' num2str(counter)];
            else
                newContrastName{1} = tempContrastName;
                verifiedUnique = 1;
            end
        end
        % end of code block making sure name is unique
        
    end

    % Add a new contrast to the table
    function cvc_NewCrossVisitContrastButton_callback(hObject, callbackdata)
        
        % First step is to pull the guidata
        data = guidata(cvcsw.fig);
        
        % Get the contrast name from the user
        defaultCVCName = {['CVC' num2str(length(data.ContrastNames) + 1)]};
        newContrastName = inputdlg( 'Input a name for the contrast',...
            'Cross-Visit Contrast Name',...
            1,...
            defaultCVCName); 
        % Make sure is a string
        newContrastName = string(newContrastName);
        
        % Check/Fixup user input
        newContrastName = verify_or_fix_cvc_name(newContrastName,...
            data.ContrastNames, defaultCVCName); 
        
        % Now we want to create a new row of the contrast list
        % this row will be initialized to zeros
        data.CurrentContrasts = [data.CurrentContrasts; zeros(1, size(data.CurrentContrasts, 2))];
        data.ContrastNames{length(data.ContrastNames) + 1} = newContrastName{1};
        
        guidata(cvcsw.fig, data);
        
        update_cvcdisplay;
    end

function cvc_DeleteCrossVisitContrastButton_callback(hObject, callbackdata)
        
        % First step is to pull the guidata
        data = guidata(cvcsw.fig);
        
        % First make sure that a contrast exists in the first place
        if ~isempty(data.CurrentContrasts)
            % Get the contrast name from the user
            selectedListElement = get(findobj('tag', 'cvc_ContrastDropdown'), 'Value');
            selectedListString  = get(findobj('tag', 'cvc_ContrastDropdown'), 'String');

            % Remove from the contrast names
            data.ContrastNames(:, selectedListElement) = [];

            % Remove from the contrast data
            data.CurrentContrasts(selectedListElement, :) = [];

            % Reset listbox selection to 1st element
            set(findobj('tag', 'cvc_ContrastDropdown'), 'Value', 1);

            guidata(cvcsw.fig, data);

            update_cvcdisplay;
        else
            disp('There are no contrasts to delete.')
        end
    end

    function cvc_RenameCrossVisitContrastButton_callback(hObject, callbackdata)
        
        % First step is to pull the guidata
        data = guidata(cvcsw.fig);
        
        if ~isempty(data.CurrentContrasts)
        
            % Get the contrast name from the user
            selectedListElement = get(findobj('tag', 'cvc_ContrastDropdown'), 'Value');
            selectedListString  = get(findobj('tag', 'cvc_ContrastDropdown'), 'String');

            % Get the new name for the contrast from the user
            defaultCVCName = {selectedListString{selectedListElement}};
            newContrastName = inputdlg( 'Input a name for the contrast',...
                'Cross-Visit Contrast Name',...
                1,...
                defaultCVCName); 
            newContrastName = string(newContrastName);

            newContrastName = verify_or_fix_cvc_name(newContrastName,...
                data.ContrastNames, defaultCVCName); 
            
            data.ContrastNames{selectedListElement} = newContrastName{1};
        
            guidata(cvcsw.fig, data);

            update_cvcdisplay;
        else
            disp('There are no contrasts to rename.')
        end
        
    end

    function cvc_ContrastTableCellEdit_callback(hObject, callbackdata)
                
        % Make sure input value is a number and not a string
        if isnumeric(callbackdata.NewData) & ~isempty(callbackdata.NewData) & ~isnan(callbackdata.NewData)
            % update contrasts structure
            data = guidata(cvcsw.fig);
            data.CurrentContrasts(callbackdata.Indices(1), callbackdata.Indices(2)) = callbackdata.NewData;
            guidata(cvcsw.fig, data);
        else
            warndlg('Please input a number', 'Warning');
        end
        
        update_cvcdisplay;
        
    end

    % Returns a list of strings corresponding to the individual contrasts
    % Goal is to have relatively easy to read summary of what each contrast
    % is
    function [cvcstring] = generate_cvc_strings(contrasts, parameterNames)
        
        nContrast  = size(contrasts, 1);
        nParameter = length(parameterNames);
        
        cvcstring = repmat({''}, nContrast, 1);
        
        for i = 1:nContrast
            
            current_string = '';
            nTerm = 0; % to track if first or not (for if need leading + or -)
            
            for j = 1:nParameter
                
                coefficient = contrasts(i, j);
                
                if coefficient ~= 0
                    if nTerm == 0
                        current_string = [num2str(coefficient) ' x ' parameterNames{j}];
                    else
                        if sign(coefficient) == 1
                            current_string = [current_string ' + ' num2str(coefficient) ' x ' parameterNames{j}];
                        else
                            current_string = [current_string ' - ' num2str(abs(coefficient)) ' x ' parameterNames{j}];
                        end
                    end
                    nTerm = nTerm + 1;
                end
                
            end
            
            % Store the string
            cvcstring{i} = current_string;
            
        end
        
    end

    % Close Button
    % TODO verify all contrasts are valid
    function close_cvcwindow_callback(hObject, callbackdata)
        
        data = guidata(cvcsw.fig);
        
        % Get the strings for each contrast
        outContrastStrings = generate_cvc_strings(data.CurrentContrasts, data.FullTableNames);

        outCurrentContrasts = data.CurrentContrasts;
        outContrastNames = data.ContrastNames;
        
        delete(cvcsw.fig)
        uiresume() 
    end

    %test = char(hex2dec('DF'));

end

