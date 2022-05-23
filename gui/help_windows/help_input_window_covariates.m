function help_input_window_Covariates()

    helpImages = {'help_input_window_cov_fig1.png',...
        'help_input_window_cov_fig2.png'};
    
    currentSelectedHelpImage = 1;

    % Check if an instance of helpInputWindowCovariates already running
    hs = findall(0,'tag','helpInputWindowCovariates');
    if (isempty(hs))
        hs = add_help_input_window_analysis_type_components;
        set(hs.fig,'Visible','on');
    else
        figure(hs);
    end
    
    function hs = add_help_input_window_analysis_type_components
        % Add components, save handles in a struct
        hs.fig = figure('Tag','helpInputWindowCovariates',...
            'units', 'normalized', 'position', [0.2 0.3 0.6 0.6],...
            'MenuBar', 'none',...
            'NumberTitle','off',...
            'Name','Covariates - Help',...
            'Resize','off',...
            'Visible','off',...
            'Color',get(0,'defaultUicontrolBackgroundColor'),...
            'WindowStyle', 'modal');
        
        helpString = fileread('help_input_window_Covariates_text1.txt');
        
        % Text
        textPanel = uipanel('Parent', hs.fig,...
            'units', 'normalized',...
            'Position', [0.01 0.0 0.38 1],...
            'Title','Covariate File Guidelines');
        
        mainHelpTextbox = uicontrol('Style', 'Text', ...
            'Parent', textPanel,...
            'Units', 'Normalized', ...
            'String', helpString,...
            'Position', [0.01, 0.0, 0.98, 1], ...
            'Tag', 'numVisitTextbox',...
            'HorizontalAlignment', 'Left'); %#ok<NASGU>
        
        CloseButton = uicontrol('Style', 'pushbutton', ...
            'Parent', textPanel,...
            'String', 'Close', ...
            'Units', 'Normalized', ...
            'Position', [0.45, 0.01, 0.1, 0.05], ...
            'Tag', 'CancelButton',...
            'callback', @close_button_callback ); %#ok<NASGU>
        
        % Example
        examplePanel = uipanel('Parent', hs.fig,...
            'units', 'normalized',...
            'Position', [0.41 0.0 0.58 1],...
            'Title','Examples');
        
        examplePanelImage = axes('Parent', examplePanel,...
            'units', 'normalized',...
            'Position',[0.1 0.1 0.8 0.89],...
            'Tag','examplePanelImage'); %#ok<NASGU>
        
        % Set default image
        img = imread(helpImages{currentSelectedHelpImage});
        axes(examplePanelImage)
        imshow(img);
        
        % Next and previous buttons
        nextExampleButton = uicontrol('Style', 'pushbutton', ...
            'Parent', examplePanel,...
            'String', 'Next Example', ...
            'Units', 'Normalized', ...
            'Position', [0.5835, 0.01, 0.15, 0.05], ...
            'Tag', 'nextExampleButton',...
            'Callback', @select_next_help_image_callback); %#ok<NASGU>
        
        previousExampleButton = uicontrol('Style', 'pushbutton', ...
            'Parent', examplePanel,...
            'String', 'Previous Example', ...
            'Units', 'Normalized', ...
            'Position', [0.2665, 0.01, 0.15, 0.05], ...
            'Tag', 'previousExampleButton',...
            'enable', 'off',...
            'callback', @select_previous_help_image_callback); %#ok<NASGU>

        
    end

    function select_next_help_image_callback(src, event)
        
        nHelpImage = numel(helpImages);
        
        % Increment selected help image
        currentSelectedHelpImage = currentSelectedHelpImage + 1;
        
        % Set the image
        imageDisplayAxes = findobj('tag', 'examplePanelImage');
        img = imread(helpImages{currentSelectedHelpImage});
        axes(imageDisplayAxes)
        imshow(img);
        
        % Check if next button needs to be disabled
        if currentSelectedHelpImage == nHelpImage
            set(findobj('tag', 'nextExampleButton'), 'enable', 'off')
        end
        
        % Check if previous button needs to be re-enabled
        if currentSelectedHelpImage > 1
            set(findobj('tag', 'previousExampleButton'), 'enable', 'on')
        end
        
    end

    function select_previous_help_image_callback(src, event)
        
        nHelpImage = numel(helpImages);
        
        % Increment selected help image
        currentSelectedHelpImage = currentSelectedHelpImage - 1;
        
        % Set the image
        imageDisplayAxes = findobj('tag', 'examplePanelImage');
        img = imread(helpImages{currentSelectedHelpImage});
        axes(imageDisplayAxes)
        imshow(img);
        
        % Check if previous button needs to be disabled
        if currentSelectedHelpImage == 1
            set(findobj('tag', 'previousExampleButton'), 'enable', 'off')
        end
        
        % Check if next button needs to be re-enabled
        if currentSelectedHelpImage < nHelpImage
            set(findobj('tag', 'nextExampleButton'), 'enable', 'on')
        end
        
    end

    function close_button_callback(src, event)
        delete(hs.fig);
    end


end

