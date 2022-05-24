function outputdata = gui_input_mask_and_covariates(varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% Default settings
% {1} is niifiles
% {2} is maskfile
% {3} is covfile
% {4} Is number of visits
% {5} Is type of study
varargout{4} = 1;
varargout{5} = 'Cross-Sectional';

% Check if an instance of inputWindow already running
hs = findall(0,'tag','inputWindow');
if (isempty(hs))
    hs = add_input_window_components;
    set(hs.fig,'Visible','on');
else
    figure(hs);
end

uiwait(hs.fig);
if isvalid(hs.fig)
    outputdata = guidata(hs.fig).output;
else
    outputdata = [];
end
delete(hs.fig);

% Define gui components
    function hs = add_input_window_components
        
        % Add components, save handles in a struct
        hs.fig = figure('Tag','inputWindow',...
            'units', 'normalized', 'position', [0.3 0.4 0.4 0.3],...
            'MenuBar', 'none',...
            'NumberTitle','off',...
            'Name','Input Analysis Data',...
            'Resize','off',...
            'Visible','off',...
            'Color', get(0,'defaultUicontrolBackgroundColor'),...
            'WindowStyle', 'modal');
                
        % Sub-panel for specifying analysis type and number of visits
        analysisTypePanel = uipanel('BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
            'Tag', 'analysisTypePanel',...
            'Title', 'Analysis Type',...
            'units', 'normalized',...
            'Position',[0.1, 0.74 0.8 0.23]);        
                
        % analysisTypePanel - Analysis type dropdown menu
        analysisTypePopup = uicontrol('Parent', analysisTypePanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.05, 0.40, 0.25, 0.30], ...
            'Tag', 'analysisTypePopup',...
            'String', {'Cross-Sectional', 'Longitudinal'},...
            'Callback', @select_analysis_type); %#ok<NASGU>
        numVisitTextbox = uicontrol('Parent', analysisTypePanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'String', 'Number of visits:',...
            'Position', [0.53, 0.4, 0.25, 0.3], ...
            'Tag', 'numVisitTextbox',...
            'HorizontalAlignment', 'Left'); %#ok<NASGU>
        numVisitEditbox = uicontrol('Parent', analysisTypePanel, ...
            'Style', 'Edit', ...
            'Units', 'Normalized', ...
            'Position', [0.75, 0.4, 0.10, 0.3], ...
            'Tag', 'numVisitEditbox', ...
            'enable', 'inactive',...
            'String', '1',...
            'BackgroundColor','white',...
            'callback', @check_visit_input); %#ok<NASGU>
        analysisTypePanelRatio  = analysisTypePanel.Position(3) / analysisTypePanel.Position(4);        
        analysisTypeHelpButton = uicontrol('Parent', analysisTypePanel, ...
            'Style', 'pushbutton', ...
            'String', '?', ...
            'Units', 'Normalized', ...
            'Position', [0.95, 0.4,...
            0.1 / analysisTypePanelRatio, 0.1 * analysisTypePanelRatio], ...
            'Tag', 'analysisTypeHelpButton',...
            'callback', @open_analysisTypeHelp); %#ok<NASGU>
                
        % Sub-panel for specifying the mask file
        maskSpecifyPanel = uipanel('BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
            'Tag', 'maskSpecifyPanel',...
            'Title', 'Load Mask',...
            'units', 'normalized',...
            'Position',[0.1, 0.46 0.8 0.24]);
        maskSpecifyButton = uicontrol('Parent', maskSpecifyPanel, ...
            'Style', 'pushbutton', ...
            'String', 'Select Mask', ...
            'Units', 'Normalized', ...
            'Position', [0.05, 0.40, 0.25, 0.30], ...
            'Tag', 'maskSpecifyButton',...
            'callback', @select_mask_buttonpress); %#ok<NASGU>
        maskPath = uicontrol('Parent', maskSpecifyPanel, ...
            'Style', 'Edit', ...
            'Units', 'Normalized', ...
            'Position', [0.35, 0.40, 0.5, 0.3], ...
            'Tag', 'maskPath', ...
            'enable', 'inactive',...
            'HorizontalAlignment','left',...
            'BackgroundColor','white'); %#ok<NASGU>
        maskSpecifyPanelRatio  = maskSpecifyPanel.Position(3) / maskSpecifyPanel.Position(4); 
        maskHelpButton = uicontrol('Parent', maskSpecifyPanel, ...
            'Style', 'pushbutton', ...
            'String', '?', ...
            'Units', 'Normalized', ...
            'Position', [0.95, 0.4,...
            0.1 / maskSpecifyPanelRatio, 0.1 * maskSpecifyPanelRatio], ...
            'Tag', 'maskHelpButton',...
            'callback', @open_maskHelp); %#ok<NASGU>
        
        
        % Sub-panel for specifying the covariates file
        covSpecifyPanel = uipanel('BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
            'Tag', 'covSpecifyPanel',...
            'Title', 'Load Covariate File',...
            'units', 'normalized',...
            'Position',[0.1, 0.18 0.8 0.24]);
        covSpecifyButton = uicontrol('Parent', covSpecifyPanel, ...
            'Style', 'pushbutton', ...
            'String', 'Select Covariate File', ...
            'Units', 'Normalized', ...
            'Position', [0.05, 0.40, 0.25, 0.30], ...
            'Tag', 'covSpecifyButton',...
            'callback', @select_covf_buttonpress); %#ok<NASGU>
        covPath = uicontrol('Parent', covSpecifyPanel, ...
            'Style', 'Edit', ...
            'Units', 'Normalized', ...
            'Position', [0.35, 0.40, 0.50, 0.3], ...
            'Tag', 'covPath', ...
            'enable', 'inactive',...
            'BackgroundColor','white'); %#ok<NASGU>
        covSpecifyPanelRatio  = covSpecifyPanel.Position(3) / covSpecifyPanel.Position(4); 
        covHelpButton = uicontrol('Parent', covSpecifyPanel, ...
            'Style', 'pushbutton', ...
            'String', '?', ...
            'Units', 'Normalized', ...
            'Position', [0.95, 0.4,...
            0.1 / covSpecifyPanelRatio, 0.1 * covSpecifyPanelRatio], ...
            'Tag', 'covHelpButton',...
            'callback', @open_covHelp); %#ok<NASGU>
        
        % OK and Cancel Buttons
        OKButton = uicontrol('Style', 'pushbutton', ...
            'String', 'OK', ...
            'Units', 'Normalized', ...
            'Position', [0.2533, 0.03, 0.2, 0.12], ...
            'Tag', 'OKButton',...
            'Callback', @OK_buttonpress); %#ok<NASGU>
        CancelButton = uicontrol('Style', 'pushbutton', ...
            'String', 'Cancel', ...
            'Units', 'Normalized', ...
            'Position', [0.6266, 0.03, 0.2, 0.12], ...
            'Tag', 'CancelButton',...
            'Callback', @cancel_buttonpress); %#ok<NASGU>
%         HelpButton = uicontrol('Style', 'pushbutton', ...
%             'String', 'Help', ...
%             'Units', 'Normalized', ...
%             'Position', [0.7, 0.03, 0.2, 0.12], ...
%             'Tag', 'HelpButton'); %#ok<NASGU>
    end

    function select_analysis_type(src, event)
    
        previous_selection = varargout{5};
        selection = src.String{src.Value};
        
        % Check if covariates have already been loaded. If they have,
        % trigger a reload
        if ~strcmp(selection, previous_selection) && ~isempty(varargout{1})
            
            answer = questdlg( ['Changing the analysis type will require ',...
                're-selecting the covariate file. Would you like to proceed?'], ...
                'Yes', 'No');
            
            if strcmp(answer, 'Yes')
                % Clear out the covariate file and nifti files
                varargout{1} = [];
                varargout{3} = [];
                set(findobj('tag', 'covPath'),'String', '');
            else
                Index = find(contains(src.String, previous_selection));
                src.Value = Index;
                return
            end
            
        end
        
        switch selection
            case 'Longitudinal'
                % enable the edit box for the number of visits
                set(findobj('Tag', 'numVisitEditbox'), 'enable', 'on')
                
            case 'Cross-Sectional'
                % reset the edit box for the number of visits and disable
                % user input
                set(findobj('Tag', 'numVisitEditbox'), 'enable', 'inactive')
                set(findobj('Tag', 'numVisitEditbox'), 'String', '1')
                
            otherwise
                disp('WARNING - invalid selection')
        end
        
        varargout{5} = selection;
                
    end

    % Make sure the user input an integer as the visit number
    function check_visit_input(src, event)
              
        userInput  = str2double(src.String);
        previousVisitSetting = varargout{4};
        
        % Check if covariates have already been loaded. If they have,
        % trigger a reload
        if (userInput ~= previousVisitSetting) && ~isempty(varargout{1})
            
            answer = questdlg( ['Changing the visit number will require ',...
                're-selecting the covariate file. Would you like to proceed?'], ...
                'Yes', 'No');
            
            if strcmp(answer, 'Yes')
                % Clear out the covariate file and nifti files
                varargout{1} = [];
                varargout{3} = [];
                set(findobj('tag', 'covPath'),'String', '');
            else
                src.String = num2str(previousVisitSetting);
                return
            end
            
        end
        
        % Verify a number was input
        if isnan(userInput)
            disp('Please enter a whole number greater than 0')
            src.String = '1';
            varargout{4} = 1;
            return
        end
        
        % Check that the number was a whole number
        if userInput ~= floor(userInput)
            disp('Please enter a whole number greater than 0')
            src.String = '1';
            varargout{4} = 1;
            return
        end
        
        % Check that the number was not zero
        if userInput == 0
            disp('Please enter a whole number greater than 0')
            src.String = '1';
            varargout{4} = 1;
            return
        end
        
        % Update the output to reflect the number of visits
        varargout{4} = userInput;

    end

    % Get the mask from the user
    function select_mask_buttonpress(src, event)
        
        [filename, pathname] = uigetfile({'*.nii','*.hdr'},'File Selector');
         if filename~=0
             maskf = strcat(pathname, filename);
             % Set the editbox
             set( findobj('tag', 'maskPath'), 'string', maskf );
             % Set the output
             varargout{2} = maskf;
         else
             set( findobj('tag', 'maskPath'), 'string', '' );
         end
        
    end

    % Get the covariate file from the user
    function select_covf_buttonpress(src, event)
        [filename, pathname] = uigetfile({'*.csv'},'File Selector');
        
         if filename==0
            set(findobj('tag', 'covPath'),'String', '');
            return
         end
         
         covf = strcat(pathname, filename);

         % Open the file and verify that the number of columns
         % with niifiles is correct and that the files exist
         nVisit = str2double( get(findobj('tag', 'numVisitEditbox'),...
             'String') );
         [niifiles, missingFiles, duplicateFiles] =...
             verify_niifiles_valid(covf, nVisit, 1);

         % Create a summary of the loaded, missing, and duplicated files and
         % present it to the user and wait for response
         restart = view_input_summary(niifiles, missingFiles, duplicateFiles);

         % Update the handles structure
         if ~restart
            varargout{1} = niifiles;
            varargout{3} = covf;
            set(findobj('tag', 'covPath'),'String', covf);
         end

    end

    % if cancel, exit the window and return 0
    function cancel_buttonpress(src, event)
        
        varargout = [];
        handles.output = varargout;
        guidata(hs.fig, handles);
        uiresume(hs.fig)
        %delete(src.Parent);
        
    end

    % OK button press. Checks to make sure valid input before continuing
    function OK_buttonpress(src, event)
        

        if isempty(varargout{1})
            warndlg('Please load a covariate file before continuing', 'No Nifti Files Detected')
            return
        end
        
        if isempty(varargout{2})
            warndlg('Please load a mask file before continuing', 'No Mask File Detected')
            return
        end
        
        if isempty(varargout{3})
            warndlg('Please load a covariate file before continuing', 'No Covariates Detected')
            return
        end
        
         handles = struct();
         handles.output = varargout;
         guidata(hs.fig, handles);
         uiresume(hs.fig)
        
    end


    %% HELP BUTTON FUNCTIONS
    
    % Analysis Type Help Button
    function open_analysisTypeHelp(src, event)
        help_input_window_analysis_type;
    end

    % Mask Help Button
    function open_maskHelp(src, event)
        help_input_window_mask;
    end

    % Covariate help window
    function open_covHelp(src, event)
        help_input_window_covariates;
    end


end

