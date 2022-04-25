function help_compile_iter_window_main_help()

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
            'units', 'normalized', 'position', [0.4 0.3 0.2 0.4],...
            'MenuBar', 'none',...
            'NumberTitle','off',...
            'Name','Covariates - Help',...
            'Resize','off',...
            'Visible','off',...
            'Color',get(0,'defaultUicontrolBackgroundColor'),...
            'WindowStyle', 'modal');
        
        helpString = fileread('help_compile_iter_window_main_help_text1.txt');
        
        % Text
        textPanel = uipanel('Parent', hs.fig,...
            'units', 'normalized',...
            'Position', [0.01 0.0 0.98 1],...
            'Title','Compiling Iteration Results');
        
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
        
       
        
    end

    

    function close_button_callback(src, event)
        delete(hs.fig);
    end


end
