function varargout = main(varargin)
% main - Primary GUI script for the hc-ICA toolbox
% This function is called by the hcica function and opens the hc-ICA
% toolbox GUI.
%
% Syntax:  varargout = main(varargin)
%
% See also: hcica

% Add paths
varargout = cell(1);
% Global variables
global logfile;
global logfile_full;
global writelog;
writelog = 0;
global strMatch;
global myfont;
global data;
global analysisPrefix;
myfont = 'default';

if ispc
    myfont = 'default';
elseif ismac
    myfont = 12;
end

% Check if an instance of hcica already running
hs = findall(0,'tag','hcica');
if (isempty(hs))
    hs = addcomponents;
    set(hs.fig,'Visible','on');
else
    figure(hs);
end;
data = struct();
% Initial progress states
data.preprocessingComplete = 0;
data.tempiniGuessObtained = 0;
data.iniGuessComplete = 0;
data.dataLoaded = 0;
data.studyType = 'unselected';
hintFnPath = which('hint.m');
[data.hcicadir, ~, ~] = fileparts(hintFnPath);

    function hs = addcomponents
        % Add components, save handles in a struct
        hs.fig = figure('Tag','hcica','units', 'character', 'position', [50 15 109 30.8],...
            'MenuBar', 'none',... 'position', [400 250 650 400],...
            'NumberTitle','off',...
            'Name','HINT',...
            'Resize','off',...
            'Visible','off',...
            'Color',[51/256, 63/256, 127/256],...
            'WindowStyle', 'modal');
        % adjust the figure to look better on windows machines
        if ispc
            set(findobj('tag', 'hcica'), 'position', [50 15 119 30.8]);
        end
        tgroup = uitabgroup('Parent', hs.fig,...
            'Tag','tabGroup',...
            'units', 'normalized',...
            'position', [0 0 1 0.85]);
        tab1 = uitab('Parent', tgroup, 'Tag','tab1','Title', 'Prepare Analysis');
        tab2 = uitab('Parent', tgroup, 'Tag','tab2','Title', 'Run analysis');
        tab3 = uitab('Parent', tgroup, 'Tag','tab3','Title', 'Visualize');
        
        movegui('center')
        
        axes1 = axes('Units','Pixels',...
            'units', 'character', ...
            'Position',[76,26.8, 27,3.5],'CreateFcn',@axes1_CreateFcn); %#ok<NASGU>
        axes2 = axes('Units','Pixels',...
            'units', 'normalized', ...
            'tag', 'hintAxis',...
            'Position',[0.01,0.87, 0.4, 0.12],'CreateFcn',@axes2_CreateFcn); %#ok<NASGU>
        
        fileMenu = uimenu('Label','File');
        uimenu(fileMenu,'Label','Save','Callback','disp(''save'')');
        uimenu(fileMenu,'Label','Quit','Callback',@closeFig,...
            'Separator','on','Accelerator','Q');
        helpMenu = uimenu('Label','Help'); %#ok<NASGU>
        
        textalign = 'left';
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Toolbar:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        toolMenu = uimenu('Label','Tools');
        compileIterationResultOption = uimenu(toolMenu,'Label',...
            'Compile Iteration Results', 'Callback', @compileIterationResults);
        %createScriptAnalysisOption = uimenu(toolMenu,'Label',...
        %    'Create a GUI-free script', 'Callback', @createScriptAnalysis);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Tab1: Load data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %1. Analysis setup panel
        t1p1 = uipanel('Parent',tab1, 'units', 'normalized', ...
            'Position',[0.01 0.71 0.48 0.28],...
            'Title','1. Setup','FontSize',myfont);
        % Text for specifying the analysis folder
        text1 = uicontrol('Parent',t1p1,'Style','text','units', 'normalized', ...
            'Position',[0.05 0.65 0.3 0.28],...
            'String','Analysis folder','FontSize',myfont,...
            'HorizontalAlignment',textalign); %#ok<NASGU>
        edit1 = uicontrol('Parent',t1p1,'Tag','edit1', 'units', 'normalized', ...
            'Style','edit','Position',[0.36 0.65 0.3 0.28],...
            'FontSize',myfont,'HorizontalAlignment',textalign,...
            'Tag','analysisFolder',...
            'BackgroundColor','white'); %#ok<NASGU>
        outputDirectoryButton = uicontrol('Parent',t1p1,...
            'Style','pushbutton',...
            'String','Browse',...
            'units', 'normalized',...
            'Position',[0.67 0.65 0.2 0.28],...
            'Callback',@output_directory_button_callback,...
            'UserData','hello'); %#ok<NASGU>
        % Text for specifying the prefix
        text2 = uicontrol('Parent',t1p1,'Style','text','units', 'normalized',...
            'Position',[0.05 0.5 0.2 0.28],...
            'String','Prefix for analysis','FontSize',myfont,...
            'HorizontalAlignment',textalign,...
            'visible', 'off'); %#ok<NASGU>
        edit2 = uicontrol('Parent',t1p1,'Style','edit', 'units', 'normalized',...
            'Position',[0.36 0.5 0.3 0.28],...
            'FontSize',myfont,'HorizontalAlignment',textalign,...
            'Tag','prefix', 'visible', 'off',...
            'BackgroundColor','white'); %#ok<NASGU>
        % Text for specifying if a session log should be kept
        text3 = uicontrol('Parent',t1p1,'Style','text', 'units', 'normalized',...
            'Position',[0.05 0.30 0.4 0.25],...
            'String','Create session log','FontSize',myfont,...
            'HorizontalAlignment',textalign); %#ok<NASGU>
        cb1 = uicontrol('Parent',t1p1,'Style','checkbox', 'units', 'normalized',...
            'Tag','logCheckBox','Callback',@log_checkbox_callback,...
            'Position',[0.4 0.32 0.1 0.2]); %#ok<NASGU>
        
        %2. Input data panel
        t1p2 = uipanel('Parent',tab1, 'units', 'normalized',...
            'Position', [0.01 0.1 0.48 0.58],...
            'Title','2. Input','FontSize',myfont);
        
        bg1 = uibuttongroup('Parent',t1p2, 'units', 'normalized',...
            'Position',[0.05 0.3 0.9 0.65],...
            'Tag','loadDataRadioButtonPanel',...
            'SelectionChangeFcn',@dataselection,...
            'Title','Input method','FontSize',myfont);
        
        b1r1 = uicontrol(bg1,'Style','radiobutton',...
            'Tag','niftiData',...
            'String','Import Nifti data',...
            'FontSize',myfont, 'units', 'normalized',...
            'Position',[0.2 0.6 0.6 0.3]); %#ok<NASGU>
        
        b1r2 = uicontrol(bg1,'Style','radiobutton',...
            'Tag','matData',...
            'String','Load saved analysis',...
            'FontSize',myfont,'units', 'normalized',...
            'Position',[0.2 0.2 0.6 0.3]); %#ok<NASGU>
        
        loadDataButton = uicontrol('Parent',t1p2,'Tag','loadDataButton','Style',...
            'pushbutton','String','Load data',...
            'CallBack',@loadDataButton_Callback,...
            'FontSize',myfont,'units', 'normalized',...
            'Position',[0.15 0.1 0.3 0.15]); %#ok<NASGU>
        
        t1button3 = uicontrol('Parent',t1p2,'Style','pushbutton','String','Select Covariates',...
            'Callback',@openCovWindow_Callback,...
            'FontSize',myfont, 'units', 'normalized',...
            'Position', [0.5 0.1 0.3 0.15]); %#ok<NASGU>
        
        %3. Pre-process data
        t1p3 = uipanel('Parent',tab1,'units', 'normalized',...
            'tag', 'preprocpanel',...
            'Position',[0.51 0.3 0.48 0.69],...
            'Title','3. Pre-process data','FontSize',myfont);
        % Adjust size for windows users
%         if ispc
%             set(findobj('tag', 'preprocpanel'), 'position', [54 6.82 59 15.7]);
%         end
        text4 = uicontrol('Parent',t1p3,'Style','text',...
            'units', 'normalized',...
            'Position',[0.25 0.75 0.3 0.15],...
            'String','Number of PCs','FontSize',myfont,...
            'HorizontalAlignment',textalign); %#ok<NASGU>
        text5 = uicontrol('Parent',t1p3,'Style','text','units', 'character',...
            'units', 'normalized',...
            'Position',[0.25 0.6 0.3 0.15],...
            'String','Number of ICs','FontSize',myfont,...
            'HorizontalAlignment',textalign); %#ok<NASGU>
        edit2 = uicontrol('Parent',t1p3,'Style','edit', 'units', 'character',...
            'units', 'normalized',...
            'Position',[0.55 0.8 0.2 0.13],...
            'FontSize',myfont,'HorizontalAlignment',textalign,...
            'Tag', 'numPCA',...
            'BackgroundColor','white',...
            'Callback', @edit_pcnum_callback); %#ok<NASGU>
        edit3 = uicontrol('Parent',t1p3,...
            'Style','edit',...
            'units', 'character',...
            'units', 'normalized',...
            'Position',[0.55 0.65 0.2 0.13],...
            'FontSize',myfont,'HorizontalAlignment',textalign,...
            'Tag', 'numICA',...
            'BackgroundColor','white',...
            'Callback', @edit_icnum_callback); %#ok<NASGU>
        % Explanation of number of PCs
        pchelpbutton = uicontrol('Parent',t1p3,'Style','pushbutton',...
            'String', '?', 'FontSize',myfont, 'units', 'normalized',...
            'units', 'normalized',...
            'Position', [0.8 0.83 0.09 0.09],...
            'Callback', @pcahelpcallback);
        t1button4 = uicontrol('Parent',t1p3,'Style','pushbutton',...
            'String','PCA dimension reduction','Callback',@getprewhitenedtimecourses,...
            'FontSize',myfont, 'units', 'normalize',...
            'units', 'normalized',...
            'Position',[0.275 0.45 0.45 0.15]); %#ok<NASGU>
        
        
        t1button5 = uicontrol('Parent',t1p3,'Style','pushbutton',...
            'units', 'normalized',...
            'String','Generate initial values',...
            'Callback',@calculate_initial_guess,...
            'FontSize',9, 'Position',[0.05 0.2 0.45 0.15]); %#ok<NASGU>
        %'FontSize',myfont, 'Position',[65 45 150 25]);
        
        t1button6 = uicontrol('Parent',t1p3,'Style','pushbutton',...
            'String','Choose ICs for hc-ICA',...
            'Callback',@test_Callback,...
            'Units', 'normalized',...
            'FontSize',9, 'Position',[0.5 0.2 0.45 0.15]); %#ok<NASGU>
        %'FontSize',myfont,'Position',[65 25 150 25]);
        
        regenButton = uicontrol('Parent',t1p3,'Style','pushbutton',...
            'String','Re-estimate Initial Values',...
            'Callback',@reEstimate_Callback,...
            'Units', 'normalized',...
            'Tag', 'reEstButton',...
            'Enable', 'Off',...
            'FontSize',9, 'Position',[0.05 0.05 0.45 0.15]); %#ok<NASGU>
        %'FontSize',myfont,'Position',[5 5 150 25]);
        
        viewRegenButton = uicontrol('Parent',t1p3,'Style','pushbutton',...
            'String','View Reduced Initial Values',...
            'Callback',@test_Callback2,...
            'Units', 'normalized',...
            'Tag', 'viewReduced',...
            'Enable', 'Off',...
            'FontSize',9, 'Position',[0.5 0.05 0.45 0.15]); %#ok<NASGU>
        %'FontSize',myfont,'Position',[120 5 150 25]);
        
        iniGuessType = uicontrol('Parent', t1p3, 'Style', 'popupmenu', ...
            'String', {'tc-gICA', 'GIFT'}, ...
            'FontSize', 12, ...
            'Position', [133 70 90 25], ...
            'visible', 'off',...
            'Tag', 'iniGuessType'); %#ok<NASGU>
        
        iniGuessText = uicontrol('Parent', t1p3, 'Style', 'text', ...
            'String', 'Initial Value Estimation Method', ...
            'visible', 'off',...
            'FontSize', 8, ...
            'Position', [55 70 90 25]); %#ok<NASGU>
        
        t1button7 = uicontrol('Parent',tab1,'Style','pushbutton',...
            'String','Save setup and continue',...
            'Callback',@saveContinueButton_Callback,...
            'Units', 'normalized',...
            'tag', 'saveContinueButton',...
            'FontSize',myfont,'Position',[0.69 0.18 0.25 0.1],...
            'enable', 'off'); %#ok<NASGU>
        
        t1button8 = uicontrol('Parent',tab1,'Style','pushbutton',...
            'String','Reset',...
            'Callback',@resetButtonCallback,...
            'Units', 'normalized',...
            'FontSize',myfont,'Position',[0.54 0.18 0.15 0.1]); %#ok<NASGU>
        
        %Progress bar
        t1pb = uipanel('Parent',tab1,'Position',[0.05 .03 .9 .05],...
            'BorderType','beveledin');
        t1pb1 = uicontrol('Parent',t1pb,'Style','text',...
            'String','Load data','enable','off','Tag','dataProgress',...
            'FontSize',8,'Position',[0 2 142 13]); %#ok<NASGU>
        t1pb2 = uicontrol('Parent',t1pb,'Style','text',...
            'String','PCA',...
            'enable','off','Tag','pcaProgress',...
            'FontSize',8,'Position',[142 2 142 13]); %#ok<NASGU>
        t1pb3 = uicontrol('Parent',t1pb,'Style','text',...
            'String','Initial values',...
            'enable','off','Tag','iniProgress',...
            'FontSize',8,'Position',[284 2 142 13]); %#ok<NASGU>
        t1pb4 = uicontrol('Parent',t1pb,'Style','text',...
            'String','Choose ICs',...
            'enable','off','Tag','icProgress',...
            'FontSize',8,'Position',[426 2 142 13]); %#ok<NASGU>
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Tab2: Run analysis
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        t2p = uipanel('Parent',tab2,'Position',[.05 .15 .39 .8],...
            'Title', 'Analysis Setup','FontSize',myfont, 'tag', 'analysisSetup');
        t2p1 = uipanel('Parent',t2p,'Position',[.05 .2 .9 .7],...
            'Title','hc-ICA Parameters','FontSize',myfont);
        % Max Iteration Selection
        t2text2 = uicontrol('Parent',t2p1,'Style','text',...
            'units', 'normalized','Position',[0.1, 0.55, 0.4, 0.1],...
            'String','Max Iterations','FontSize',myfont,...
            'HorizontalAlignment','right'); %#ok<NASGU>
        t2edit1 = uicontrol('Parent',t2p1,'Style','edit',...
            'units', 'normalized','Position',[0.65 0.55 0.3 0.1],...
            'FontSize',myfont,'String','100','HorizontalAlignment',textalign,...
            'Tag','maxIter',...
            'BackgroundColor','white'); %#ok<NASGU>
        % Epsilon 1 Selection
        t2text3 = uicontrol('Parent',t2p1,'Style','text',...
            'units', 'normalized','Position',[0.001, 0.4, 0.6, 0.1],...
            'String','Epsilon: Global Parameter','FontSize',myfont,...
            'HorizontalAlignment','right'); %#ok<NASGU>
        t2edit2 = uicontrol('Parent',t2p1,'Style','edit',...
            'units', 'normalized','Position',[0.65 0.4 0.3 0.1],...
            'FontSize',myfont,'String','0.001','HorizontalAlignment',textalign,...
            'Tag','epsilon1',...
            'BackgroundColor','white'); %#ok<NASGU>
        % Epsilon 2 Selection
        t2text4 = uicontrol('Parent',t2p1,'Style','text',...
            'units', 'normalized','Position',[0.001, 0.25, 0.6, 0.1],...
            'String','Epsilon: Local Parameter','FontSize',myfont,...
            'HorizontalAlignment','right'); %#ok<NASGU>
        t2edit3 = uicontrol('Parent',t2p1,'Style','edit',...
            'units', 'normalized','Position',[0.65 0.25 0.3 0.1],...
            'FontSize',myfont,'String','0.1','HorizontalAlignment',textalign,...
            'Tag','epsilon2',...
            'BackgroundColor','white'); %#ok<NASGU>
        t2button1 = uicontrol('Parent',t2p,'Style','pushbutton',...
            'String','Run','Callback',@runButton_Callback,...
            'tag', 'runButton',...
            'units', 'normalized',...
            'enable', 'off',...
            'FontSize',myfont,'Position',[0.4, 0.1, 0.2, 0.1]); %#ok<NASGU>
        
        analysisProgressPanel = uipanel('Parent',tab2,'Position',[.45 .15 .5 .8],...
            'FontSize',myfont, 'tag', 'analysisProgressPanel', 'Title', 'Analysis Progress');
        % Axis for the estimate change by iteration
        iterChangeAxis1 = axes('Parent',analysisProgressPanel,...
            'units', 'normalized',...
            'Position',[0.1 0.65 0.85 0.3],...
            'Tag','iterChangeAxis1'); %#ok<NASGU>
        iterChangeAxis2 = axes('Parent',analysisProgressPanel,...
            'units', 'normalized',...
            'Position',[0.1 0.15 0.85 0.3],...
            'Tag','iterChangeAxis2'); %#ok<NASGU>
        
        
        analysisStatusPanel = uipanel('Parent',tab2,'Position',[.05 .01 .9 .13],...
            'FontSize',myfont, 'tag', 'analysisStatusPanel', 'Title', 'Analysis Status');
        t2button2 = uicontrol('Parent',analysisStatusPanel,'Style','pushbutton',...
            'units', 'normalized',...
            'String','Display Results', 'tag', 'displayResultsButton',...
            'Callback',@switchDisplayTab,'enable','off',...
            'FontSize',myfont,'Position',[0.8 0.18 0.18 0.8]); %#ok<NASGU>
        stopButton = uicontrol('Parent',analysisStatusPanel,'Style','pushbutton',...
            'units', 'normalized', 'tag', 'stopButton',...
            'String','Stop',...
            'Callback',@stopButtonCallback,'enable','off',...
            'FontSize',myfont,'Position',[0.68 0.18 0.1 0.8]); %#ok<NASGU>
        % Analysis waitbar. The following code is by Yuanfei and can be
        % found at https://www.mathworks.com/matlabcentral/fileexchange/47896-embedding-waitbar-inside-a-gui
        ax1=axes('parent', analysisStatusPanel ,'Units','normalized','Position',[0.01 0.2 0.65 0.80]);
        set(ax1,'Xtick',[],'Ytick',[],'Xlim',[0 1000], 'Tag', 'analysisWaitbar');
        box on;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Tab3: Display
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        t3p = uipanel('Parent',tab3,'Position',[.1 .1 .8 .9],...
            'FontSize',myfont);
        bg2 = uibuttongroup('Parent',t3p,'Position',[.15 .20 .7 .5],...
            'SelectionChangeFcn',@dataselection,...
            'Tag', 'displayType',...
            'Title','Display type','FontSize',myfont);
        b2r1 = uicontrol(bg2,'Style','radiobutton',...
            'String','Population display maps',...
            'Tag', 'dt1',...
            'FontSize',myfont,...
            'units', 'normalized',...
            'Position',[0.25 0.8 0.7 0.15]); %#ok<NASGU>
        b2r2 = uicontrol(bg2,'Style','radiobutton',...
            'String','Sub-population display maps',...
            'Tag', 'dt2',...
            'FontSize',myfont,...
            'units', 'normalized',...
            'Position',[0.25 0.6 0.7 0.15]); %#ok<NASGU>
        b2r3 = uicontrol(bg2,'Style','radiobutton',...
            'String','Subject specific display maps',...
            'Tag', 'dt3',...
            'FontSize',myfont,...
            'units', 'normalized',...
            'Position',[0.25 0.4 0.7 0.15]); %#ok<NASGU>
        b2r4 = uicontrol(bg2,'Style','radiobutton',...
            'String','Beta-coefficients display maps',...
            'Tag', 'dt4',...
            'FontSize',myfont,...
            'units', 'normalized',...
            'Position',[0.25 0.2 0.7 0.15]); %#ok<NASGU>
        button7 = uicontrol('Parent',t3p,'Style','pushbutton',...
            'String','Display',...
            'tag', 'displayButton',...
            'enable', 'off',...
            'Callback', @displayCallback, ...
            'FontSize',myfont,'Position',[150 10 200 40]); %#ok<NASGU>
        loadResultsButton = uicontrol('Parent',t3p,'Style','pushbutton',...
            'String','Load Results',...
            'Callback', @loadResultsCallback, ...
            'Units', 'Normalize',...
            'FontSize',myfont,...
            'units', 'normalized',...
            'Position',[0.35 0.7 0.3 0.1]); %#ok<NASGU>
        t3text1 = uicontrol('Parent',t3p,'Style','text',...
            'units', 'normalized',...
            'Position',[0.10 0.82 0.25 0.15],...
            'String','Display Path','FontSize',myfont,...
            'HorizontalAlignment','right'); %#ok<NASGU>
        t3edit2 = uicontrol('Parent',t3p,'Style','edit',...
            'units', 'normalized',...
            'Position',[0.4 0.9 0.15 0.07],...
            'FontSize',myfont,'HorizontalAlignment',textalign,...
            'Tag','displayPath',...
            'BackgroundColor','white'); %#ok<NASGU>
        button8 = uicontrol('Parent',t3p,'Style','pushbutton',...
            'String','Browse',...
            'Callback',@browseDisplayPath,...
            'FontSize',myfont, 'units', 'normalized',...
            'Position',[0.60 0.9 0.15 0.07]); %#ok<NASGU>
        t3text2 = uicontrol('Parent',t3p,'Style','text',...
            'units', 'normalized',...
            'Position',[0.25 0.8 0.08 0.07],...
            'String','Prefix','FontSize',myfont,...
            'HorizontalAlignment','right'); %#ok<NASGU>
        t3edit3 = uicontrol('Parent',t3p,'Style','edit',...
            'units', 'normalized',...
            'Position',[0.4 0.8 0.15 0.07],...
            'FontSize',myfont,'HorizontalAlignment',textalign,...
            'Tag','displayPrefix',...
            'BackgroundColor','white'); %#ok<NASGU>
        
        set(findobj('tag', 'saveContinueButton'), 'enable', 'off');
        
    end

%%%%%%%%%%% General GUI Functions %%%%%%%%%%

% Add the CBIS logo to the hc-ICA window.
    function axes1_CreateFcn(~,~)
        [im, ~, alpha] = imread('CBIS_white_transparent.png');
        h = imshow(im);
        set(h, 'AlphaData', alpha);
    end

    function axes2_CreateFcn(~,~)
        axes(findobj('tag', 'hintAxis'))
        matlabImage = imread('hintLogo.png');
        image(matlabImage)
        axis off
        axis image
    end

% Delete the hc-ICA window.
    function closeFig(~,~)
        delete(hs.fig);
    end

    function pcahelpcallback(~,~)
        helpbox = msgbox('This is the number of principal components to be used in the first stage of dimension reduction in TC-GICA')
    end

    function edit_icnum_callback(hObject, callbackdata)
        
        % Verify a whole number was input
        userInput  = str2double(hObject.String);
        validInput = 1;
        
        % Verify a number was input
        if isnan(userInput)
            disp('Please enter a whole number')
            validInput = 0;
        end
        
        % Verify that the number was a whole number
        if userInput ~= floor(userInput)
            disp('Please enter a whole number')
            validInput = 0;
        end
        
        if validInput && data.preprocessingComplete == 1;
            if data.q ~= userInput
                
                % Ask user if they wish to redo preprocessing with the new
                % number of components
                questionString = ['Changing the number of components will ',...
                    'require redoing the preprocessing. Do you still ',...
                    'want to proceed?'];
                answer = questdlg(questionString, ...
                    'Yes', 'No');
                
                % Handle response
                switch answer
                    case 'Yes'
                        update_progress_bar(1);
                    otherwise
                        validInput = 0;
                end
            end
        end
        
        % Finally, if not changing q, revert to what it was before
        % this is either an empty space if no processing has been done yet,
        % or the old value for q if it has.
        if validInput == 0
            if data.preprocessingComplete == 1
                hObject.String = num2str(data.q);
            else
                hObject.String = '';
            end
        end
        
    end

    function edit_pcnum_callback(hObject, callbackdata)
        
        % Verify a whole number was input
        userInput  = str2double(hObject.String);
        validInput = 1;
        
        % Verify a number was input
        if isnan(userInput)
            disp('Please enter a whole number')
            validInput = 0;
        end
        
        % Verify that the number was a whole number
        if userInput ~= floor(userInput)
            disp('Please enter a whole number')
            validInput = 0;
        end
        
        if validInput && data.preprocessingComplete == 1;
            if data.numPCA ~= userInput

                % Ask user if they wish to redo preprocessing with the new
                % number of components
                questionString = ['Changing the number of components will ',...
                    'require redoing the preprocessing. Do you still ',...
                    'want to proceed?'];
                answer = questdlg(questionString, ...
                    'Yes', 'No');
                
                % Handle response
                switch answer
                    case 'Yes'
                        update_progress_bar(1);
                    otherwise
                        validInput = 0;
                end
            end
        end
        
        % Finally, if not changing q, revert to what it was before
        % this is either an empty space if no processing has been done yet,
        % or the old value for q if it has.
        if validInput == 0
            if data.preprocessingComplete == 1
                hObject.String = num2str(data.numPCA);
            else
                hObject.String = '';
            end
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%      General GUI functions      %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Function to toggle the progressbar
    function toggle_progress_bar(bar, complete)
        
        % bar is the tag. Will be one of:
        % dataProgress, pcaProgress, iniProgress, icProgress
        
        enable = 'off';
        backgroundColor = [0.94,0.94,0.94];
        if complete == 1
          enable = 'on';  
          backgroundColor = [51/256,153/256,0/256];
        end
        
        set(findobj('Tag', bar), 'BackgroundColor', backgroundColor,...
            'ForegroundColor',[0.9255,0.9255,0.9255],...
            'enable', enable);
        
    end


% Progress bar function
% level argument ->
% 0 : nothing done
% 1 : data loaded
% 2 : pca complete
% 3 : initial guess done
% 4 : IC selection complete
    function update_progress_bar(level)
        
        % Turn all off
        toggle_progress_bar('dataProgress', 0);
        toggle_progress_bar('pcaProgress', 0);
        toggle_progress_bar('iniProgress', 0);
        toggle_progress_bar('icProgress', 0);
        
        set(findobj('tag', 'saveContinueButton'), 'enable', 'off');
        
        reset_run_progress_bar;
        
        if level > 0
            data.dataLoaded = 1;
            toggle_progress_bar('dataProgress', 1);
        end
        
        if level > 1
            data.preprocessingComplete = 1;
            toggle_progress_bar('pcaProgress', 1);
        end
        
        if level > 2
            data.tempiniGuessObtained = 1;
            toggle_progress_bar('iniProgress', 1);
        end
        
        if level > 3
            data.iniGuessComplete = 1;
            toggle_progress_bar('icProgress', 1);
            set(findobj('tag', 'saveContinueButton'), 'enable', 'on');
        end
        
    end

    function reset_run_progress_bar(~, ~)
        axes(findobj('tag','analysisWaitbar'));
        cla;
        rectangle('Position',[0,0,0+(round(1000*0)),20],'FaceColor','g');
        text(482,10,[num2str(0+round(100*0)),'%']);
        drawnow;
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Functions for Panel 1: 1. Setup %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if the hc-ICA session is to be logged. Create log file.
    function log_checkbox_callback(hObject,~)
        
        % If disabling logfile, then just end here
        if hObject.Value == 0
            writelog = 0;
            return
        end
        
        % Check user input for analysis folder
        outdir = get(findobj('tag', 'analysisFolder'), 'string');
        
        % Verify that analysis folder specified, if not, request user input
        % and terminate early
        if strcmp(outdir, '')
            warndlg('Please specify an analysis folder before writing a log file.')
            set(hObject, 'Value', 0);
            return
        end
        
        % Set global to 1, indicates that should write to log
        writelog = 1;

        fname = strcat('_textlog_', date(), '_', datestr(now, 'HH_MM_SS'));

        logfile = fullfile(outdir, fname);

        % Open up a new log
        log_create_file(logfile);

    end

% Allow the user to select the output directory for the analysis.
    function output_directory_button_callback(~,~)
        
        % Request output folder from user
        folderName = uigetdir(pwd);
        
        % Handle case where user did not input anything
        if folderName==0
            folderName='';
        end
                
        set(findobj('Tag','analysisFolder'), 'String', folderName);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Functions for Panel 1: 2. Input %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Check if the user wants to proceed
    function proceedWithLoad = warn_user_ask_proceed(dataLoaded)
        proceedWithLoad = 1;
        if dataLoaded == 1
            proceedWithLoad = 0; % default to 0 just to be safe
            opts.Interpreter = 'tex';
            opts.Default = 'No';
            userAnswer = questdlg('Continuing will reset the current analysis, are you sure you want to continue?',...
                'Continue?',...
                'Yes', 'No', opts);
            if strcmp(userAnswer, 'Yes')
                proceedWithLoad = 1;
            end
        end
    end

% If user specified files using "import Nifti data" then this function is
% used to check that all of the required input is there
    function validFileInput = check_input_panel_files(fls)
        validFileInput = 0;
        if (~isempty(fls))
            if (~isempty(fls{1}) && ~isempty(fls{2}) && ~isempty(fls{3}))
                validFileInput = 1;
            end
        end
    end

% Load the nifti data, covariate file, and mask file specified by the
% user. Alternatively, load a saved runinfo file if the user has already
% run an analysis
    function loadDataButton_Callback(~,~)

        bGroup = findobj('Tag','loadDataRadioButtonPanel');
        dataInputType = get(get(bGroup,'SelectedObject'),'Tag');
        
        switch dataInputType
            case 'matData'
                
                % Direct the user to load a runinfo file
                [fname, pathname] = uigetfile('.mat');
                
                if fname == 0
                    return
                end

                runinfoFileName = fullfile(pathname, fname);
                
                % Waitbar while the data loads, does not actually get
                % updated, just here to prevent using toolbox while data
                % load.
                waitLoad = waitbar(0, 'Please wait while the data load');

                [runinfo, loadErr] = load_runinfo_file(runinfoFileName);
                
                if loadErr == 1
                    return
                end

                data = add_all_structure_fields(data, runinfo);

                % Populate the display fields
                set(findobj('tag', 'numICA'), 'string', num2str(data.qold));
                set(findobj('tag', 'numPCA'), 'string', num2str(data.numPCA));
                [~, prefix, ~] = fileparts(data.prefix);
                set(findobj('tag', 'prefix'), 'string', prefix);
                set(findobj('tag', 'analysisFolder'), 'string', num2str(data.outfolder));

                % Update the GUI to reflect the loaded information
                update_progress_bar(4);

                waitbar(1)
                close(waitLoad);

                
            case 'niftiData'
                
                proceedWithLoad = warn_user_ask_proceed(data.dataLoaded);
                
                if proceedWithLoad == 0
                    return
                end

                update_progress_bar(0);

                fls = gui_input_mask_and_covariates;
                uiwait()
                
                if isempty(fls);
                    return
                end

                % validity check
                validFileInput = check_input_panel_files(fls);

                % outer check makes sure anything was input
                if validFileInput == 1

                        inputDataParsed = parse_and_format_input_files(fls{2}, fls{3}, fls{4}, fls{5});

                        data = add_all_structure_fields(data, inputDataParsed);

                        % Update the GUI to reflect the loaded information
                        update_progress_bar(1);

                end
                
            otherwise
                % do nothing
        end
       
    end

% Perform the PCA data reduction for each subject's nifti file
    function getprewhitenedtimecourses(~,~)
        
        if data.dataLoaded == 0
            
            warndlg('Please load data before preprocessing.');
            
        else
            
            update_progress_bar(1);
            
            data.numPCA = str2double(get(findobj('Tag', 'numPCA'), 'String'));
            data.q      = str2double(get(findobj('Tag', 'numICA'), 'String'));
            
            [data.Ytilde, data.C_matrix_diag, data.H_matrix_inv,  data.H_matrix, data.deWhite]...
                = PreProcICA(data.niifiles, data.validVoxels, data.q, data.time_num, data.N*data.nVisit);
            
            % Update GUI to show PCA completed
            data.dispPCA.String = 'PCA Completed';
            
            update_progress_bar(2);
            
            % write PCA information to log file.
            if (writelog == 1)
                outfile = fopen(logfile, 'a' );
                fprintf(outfile, strcat('\n\n----------------- Preprocessing -----------------'));
                fprintf(outfile, strcat('\nPerformed PCA reduction to ', [' ',num2str(data.q),], ' components') );
            end
            
        end
    end

% Calculate the initial guess parameters for hc-ICA. 2 options: tc-gica
% and GIFT. GIFT is the better option.
    function calculate_initial_guess(~,~)
        
        % Verify that preprocessing is complete before running
        if data.preprocessingComplete == 0
            warndlg('Please complete preprocessing before obtaining an initial guess.');
            return;
        end
        
        % If the user loaded a runinfo file, make sure they know that 
        % obtaining an initial guess will require them to rerun the
        % preprocessing as well
        if ~isfield(data, 'Ytilde')
            redoPreproc = questdlg(['HINT is detecting that a runinfo'...
                'file has been loaded instead of the raw data.'...
                'Re-estimating the intitial guess will require'...
                'performing preprocessing again. Would you like to continue?']);
            if strcmp(redoPreproc, 'Yes')
                getprewhitenedtimecourses;
            else
                return;
            end
        end
                    
        % Assuming the two conditions above have been met, calculate the
        % initial guess. 
        
        update_progress_bar(2);

        % This is for the IC selection functionality.
        global keeplist;
        keeplist = ones(data.q,1);

        data.prefix = get(findobj('Tag', 'prefix'), 'String');
        data.outpath = get(findobj('Tag', 'analysisFolder'), 'String');

        % Perform GIFT
        [ data.theta0, data.beta0, data.s0, s0_agg ] = ...
            ObtainInitialGuess(data.niifiles,...
            data.maskf, ...
            data.prefix,...
            data.outpath,...
            data.numPCA,...
            data.N, data.q, data.X, data.Ytilde, data.hcicadir, data.nVisit);


        % Write to log file that initial guess stage is complete.
        if (writelog == 1)
            outfile = fopen(logfile, 'a' );
            fprintf(outfile, strcat('\nCalculated initial guess values '));
        end

        % Turn all the initial group ICs into nifti files to allow user to
        % view and select the ICs for hc-ICA.
        %template = zeros(data.voxSize);
        %template = reshape(template, [prod(data.voxSize), 1]);

        %anat = load_nii(data.maskf);
        for ic=1:data.q
            %newIC = template;
            %newIC(data.validVoxels) = s0_agg(ic, :)';
            %IC = reshape( s0_agg(ic, :), data.voxSize);
            IC = convert_vec_to_braindim(s0_agg(ic, :), data.validVoxels,...
                data.voxSize);
            
            newIC = make_nii(IC);
            newIC.hdr.hist.originator = data.maskOriginator;
            
            fname = [data.prefix '_iniIC_' num2str(ic) '.nii'];
            niftiPath = fullfile(data.outpath, fname);
            %save_nii(newIC, niftiPath, 'IC');
            save_nii(newIC, niftiPath);
        end

        % Update the gui main window to show that initial values
        % calculation is completed.
        update_progress_bar(3);

        %chooseIC;
   
    end

% Open viewer to allow user to select which ICs to use for hc-ICA.
    function chooseIC(~)
        
        if data.tempiniGuessObtained == 1
            
            global keeplist;
            keeplist = ones(data.q,1);
            displayResults(data.q, data.outpath, data.prefix,...
                data.N, 'icsel', data.covariates, data.X, data.covTypes,...
                data.interactions, 1, data.validVoxels, data.voxSize);
            uiwait()
            
            % qStar <= q contains the number of selected ICs.
            data.qstar = sum(keeplist);
            
            % If the user selected all ICs, then there is no reason to
            % re-estimate the values. Save the current set of values and lock
            % the user out of the re-estimate buttons.
            if (data.qstar == data.q)
                data.thetaStar = data.theta0;
                data.beta0Star = data.beta0;
                data.YtildeStar = data.Ytilde;
                data.CmatStar = data.C_matrix_diag;
                
                % Lock user out of re-restimate buttons
                set( findobj('Tag', 'reEstButton') ,'Enable','Off')
                set( findobj('Tag', 'viewReduced') ,'Enable','Off')
                
                update_progress_bar(4);
            end
            
            % Else, if the user did select only a subset of ICs, allow them to
            % re-estimate the intial guess
            if (data.qstar < data.q)
                
                update_progress_bar(3);
                
                set( findobj('Tag', 'reEstButton') ,'Enable','On')
                set( findobj('Tag', 'viewReduced') ,'Enable','On')
            end
        else
            warndlg('Please obtain initial guess before selecting ICs for analysis.');
        end
    end

    function test_Callback2(~,~)
        displayResults(data.q, data.outpath, data.prefix,...
            data.N, 'reEst', data.covariates, data.X, data.covTypes,...
            data.interactions, 1, data.validVoxels, data.voxSize);
    end

    function test_Callback(~,~)
        if data.tempiniGuessObtained == 1
            global keeplist;
            keeplist = ones(data.q, 1);
            chooseIC;
        else
            warndlg('Please obtain initial guess before selecting ICs for analysis.');
        end
    end

    function reEstimate_Callback(~,~)
        reEstimateIniGuess_callback;
    end

% Function to re-estimate the initial values based on a smaller
% selection of independent components. This is just a stripped down
% version of GIFT and still requires GIFT to run.
    function reEstimateIniGuess_callback(~)
        
        % Redeclare the list of ICs to be used and calculate the new q
        global keeplist;
        data.qstar = sum(keeplist);
        
        update_progress_bar(3);
        
        % Call function to re-estimate the initial values for the hc-ica
        % algorithm based on the selected ICs
        [data.thetaStar, data.beta0Star, data.YtildeStar, data.CmatStar] = ...
            reEstimateIniGuess( data.N,...
            str2double(get(findobj('tag', 'numPCA'), 'String')), data.outpath,...
            data.prefix, data.X, data.maskf, data.validVoxels )
        
        update_progress_bar(4);
    end

    function resetButtonCallback(~, ~)
        hs = findall(0,'tag','hcica');
        close(hs);
        hs = addcomponents;
        data = struct();
        
        % Initial progress states
        update_progress_bar(0);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Functions for Panel 2 %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Run the selected algorithm.
    function runButton_Callback(~, ~)
        
        % Make sure preprocessing complete
        if data.iniGuessComplete == 1
            
            % Enable the stop button and disable the run button
            set(findobj('tag','stopButton'),'enable','on');
            set(findall(findobj('tag', 'analysisSetup'),...
                '-property', 'enable'), 'enable', 'off')
            
            % Clear the progress bar
            axes(findobj('tag','analysisWaitbar'));
            cla
            rectangle('Position',[0,0,0,0],'FaceColor','g');
            text(482,10,[num2str(0),'%']);
            
            % Clear both of the progress plots
            axes(findobj('tag','iterChangeAxis1'));
            cla
            axes(findobj('tag','iterChangeAxis2'));
            cla
            pause(1)
            
            % Get all the settings.
            global prefix;
            global keeplist;
            %selectAlg = findobj('Tag', 'algoSelection');
            %selected_algo=get(selectAlg,'Value');
            selected_algo = 1;
            data.maxiter = str2double(get(findobj('Tag','maxIter'),'String'));
            data.epsilon1 = str2double(get(findobj('Tag','epsilon1'),'String'));
            data.epsilon2 = str2double(get(findobj('Tag','epsilon2'),'String'));
            
            % Write out algorithm information to log file.
            if (writelog == 1)
                outfile = fopen(logfile, 'a' );
                fprintf(outfile, '\n\n----------------- EM Algorithm Running -----------------');
            end
                        
            % User selected approximate EM algorithm.
            if(selected_algo == 1)
                
                % Write the analysis information to the log file.
                if (writelog == 1)
                    fprintf(outfile, '\nStarted approximate EM algorithm with the following settings:');
                    fprintf(outfile, strcat('\nMaximum Iterations: ',num2str(data.maxiter)));
                    fprintf(outfile, strcat('\nEpsilon 1: ',num2str(data.epsilon1)));
                    fprintf(outfile, strcat('\nEpsilon 2: ',num2str(data.epsilon2)));
                end
                
                % Run the approximate EM algorithm.
                [data.theta_est, data.beta_est, data.z_mode, ...
                    data.subICmean, data.subICvar, data.grpICmean, ...
                    data.grpICvar, data.success, data.G_z_dict, data.PostProbs, data.finalIter] = ...
                    CoeffpICA_EM (data.YtildeStar, data.X, data.thetaStar, ...
                    data.CmatStar, data.beta0Star, data.maxiter, ...
                    data.epsilon1, data.epsilon2, 'approxVec_Experimental',...
                    data.outpath, data.prefix, 0, data.studyType);
                
                % User selected exact EM algorithm, not currently included in
                % package
            else
                
                % Write analysis information to log file.
                if (writelog == 1)
                    fprintf(outfile, '\nStarted exact EM algorithm');
                end
                
                % Run the exact EM algorithm.
                [data.theta_est, data.beta_est, data.z_mode, ...
                    data.subICmean, data.subICvar, data.grpICmean, ...
                    data.grpICvar, data.success, data.gz_dict, data.PostProbs] = ...
                    CoeffpICA_EM (data.Ytilde, data.X, data.theta0, ...
                    data.C_matrix_diag, data.beta0, data.maxiter, ...
                    data.epsilon1, data.epsilon2, 'exact', data.outpath,...
                    data.prefix, 0, data.studyType);
            end
            
            % Analysis finished, write to log file.
            if (writelog == 1)
                fprintf(outfile, strcat('\nOutput is in',...
                    [' ',get(findobj('Tag','analysisFolder'),'String')] )  );
            end
            path = get(findobj('Tag','analysisFolder'),'String');
            
            
            % TODO split this function up so that name is more descriptive
            data.theoretical_beta_se_est = save_analysis_results(analysisPrefix, data);
            
            % Disable the stop button
            set(findobj('Tag','stopButton'),'enable','off');
            
            % Enable the "Display Results" button
            set(findobj('Tag','displayResultsButton'),'enable','on');
            
            % Re-enable the analysis buttons
            set(findall(findobj('tag', 'analysisSetup'),...
                '-property', 'enable'), 'enable', 'on');
            set(findobj('tag','runButton'),'enable','on');
            
            % Enable the display results button
            %set(findobj('Tag','displayResultsButton'),'enable','off');
            
        else
            warndlg('Please complete all preprocessing and obtain initial guess before running EM algorithm.')
        end
        
    end

% Switch the display tab to the results display tab.
    function switchDisplayTab(~,~)
        set(findobj('Tag','tabGroup'),'SelectedTab',findobj('Tag','tab3'))
        set( findobj('tag', 'displayButton'), 'enable', 'on' );
        set( findobj('tag', 'displayButton'), 'string', 'Display' );
        % Update the display tab with the output path
        folderName = strsplit(analysisPrefix, '/');
        set( findobj('tag', 'displayPath'), 'string', fullfile(data.outpath, folderName{1}));
        set( findobj('tag', 'displayPrefix'), 'string', folderName{2});
        % Press the load results button
        loadResultsCallback;
    end

% Function to terminate the analysis when the current iteration
% finishes.
    function stopButtonCallback(~,~)
        global keepRunning;
        keepRunning = 0;
        set( findobj('tag', 'displayButton'), 'enable', 'on' );
        set( findobj('tag', 'displayButton'), 'string', 'Display' );
        set( findobj('tag', 'displayResultsButton'), 'enable', 'on');
        set(findobj('tag','stopButton'),'enable','off');
        set(findall(findobj('tag', 'analysisSetup'),...
            '-property', 'enable'), 'enable', 'on')
        msgbox('EM Algorithm terminated early.')
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Functions for Panel 3 %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Function to point to display path
    function browseDisplayPath(~,~)
        
        folderName = uigetdir(pwd);
        if folderName==0
            folderName='';
        end
        
        data.outpath = folderName;
        ehandle = findobj('Tag','displayPath');
        set(ehandle,'String',folderName);
        runinfofiles = dir( [folderName '/*_runinfo.mat'] );
        
        if ( ~isempty(runinfofiles) )
            preEdit = findobj('Tag', 'displayPrefix');
            [data.prefix, data.vis_prefix, data.vis_covariates,...
                data.vis_covTypes, data.vis_X, data.vis_varNamesX,...
                data.vis_interactions, data.vis_interactionsBase,...
                data.vis_niifiles, data.vis_N, data.vis_nVisit,...
                data.vis_qstar] = load_browse_display_path(runinfofiles, preEdit, folderName);
            
            % Update the prefix
            preEdit = findobj('Tag', 'displayPrefix');
            preEdit.String = data.prefix;
        else
            errordlg('No runinfo file found for the analysis!')
        end
        
    end

% Function to open the display viewer. Belongs to Panel 3.
    function displayCallback(~,~)
        dgroup = findobj('Tag', 'displayType');
        disp_map =  get(get(dgroup, 'SelectedObject'), 'Tag');
        keeplist = ones(data.vis_q, 1);
        if strcmp(disp_map, 'dt1')
            displayResults(data.vis_qstar, data.vis_outpath, ...
                analysisPrefix, data.vis_N, 'grp', data.vis_varNamesX, data.vis_X, data.vis_covTypes,...
                data.vis_interactions, data.vis_nVisit, data.validVoxels, data.voxSize);
        elseif strcmp(disp_map, 'dt2')
            displayResults(data.vis_qstar, data.vis_outpath, ...
                analysisPrefix, data.vis_N, 'subpop', data.vis_varNamesX, data.vis_X, data.vis_covTypes,...
                data.vis_interactions, data.vis_nVisit, data.validVoxels, data.voxSize);
        elseif strcmp(disp_map, 'dt3')
            displayResults(data.vis_qstar, data.vis_outpath, ...
                analysisPrefix, data.vis_N, 'subj', data.vis_varNamesX, data.vis_X, data.vis_covTypes,...
                data.vis_interactions, data.vis_nVisit, data.validVoxels, data.voxSize);
        elseif strcmp(disp_map, 'dt4')
            displayResults(data.vis_qstar, data.vis_outpath, ...
                analysisPrefix, data.vis_N, 'beta', data.vis_varNamesX, data.vis_X, data.vis_covTypes,...
                data.vis_interactions, data.vis_nVisit, data.validVoxels, data.voxSize);
        end
    end

%%%%%%%%%%% Functions to Fix or classify %%%%%%%%%%
    function dataselection(~,~)
    end

% Save the run infoformation into a file called runinfo.mat.
    function saveContinueButton_Callback(~,~)
        
        [analysisPrefix] = save_analysis_preparation(data);
        
        % Now cleanup earlier files (iniGuess and logfile) using the new
        % prefix
        
        % Version of logfile that includes the prefix
        if (writelog == 1)
            logname =  strcat(prefix, '_textlog_', date(), '_',...
                datestr(now, 'HH_MM_SS') );
            logfile_full = fullfile(data.outpath, logname);
            
            %Copy the log file to the new log file that includes the prefix
            copyfile(logfile, logfile_full);
        end
        set(findobj('Tag', 'runButton'), 'enable', 'on');
        set(findobj('Tag','tabGroup'),'SelectedTab',findobj('Tag','tab2'))
        
    end

% Open the window to allow the user to view the covariate files.
    function openCovWindow_Callback(~,~)
        if (data.dataLoaded == 1)
            waitfor(viewCovariateDisplay(data.X, data.varNamesX, data.niifiles,...
                data.covTypes, data.covariates, data.interactions,...
                data.varInModel, data.varInCovFile, data.interactionsBase,...
                data.referenceGroupNumber))
            % Check if, as a result, further stages have been invalidated
            if data.preprocessingComplete == 0
                % Remove the progressbar
                set(findobj('Tag','pcaProgress'),'BackgroundColor',[0.94,0.94,0.94],...
                    'ForegroundColor',[0.9255,0.9255,0.9255],...
                    'enable','on');
                set(findobj('Tag','iniProgress'),'BackgroundColor',[0.94,0.94,0.94],...
                    'ForegroundColor',[0.9255,0.9255,0.9255],...
                    'enable','on');
                set(findobj('Tag','icProgress'),'BackgroundColor',[0.94,0.94,0.94],...
                    'ForegroundColor',[0.9255,0.9255,0.9255],...
                    'enable','on');
            end
        else
            msgbox('No data loaded');
        end
    end

% Load the runinfo file provided by the user add data to a structure
% called "data"
    function loadResultsCallback(~,~)
        
        % Get the user selected path to the runinfo file
        filepath = get( findobj('Tag', 'displayPath'), 'String' );
        fileprefix = get( findobj('Tag', 'displayPrefix'), 'String' );
        %runinfoLoc = [filepath, '/', fileprefix, '_runinfo.mat'];
        runinfoLoc = fullfile(filepath, [fileprefix, '_runinfo.mat']);
        
        
        [data.vis_q, data.vis_qstar, data.vis_outpath, data.vis_N,...
            data.vis_covariates, data.vis_X, data.vis_covTypes,...
            data.vis_varNamesX, data.vis_interactions, data.vis_varInModel,...
            data.vis_varInCovFile, data.vis_referenceGroupNumber,...
            data.vis_nVisit, analysisPrefix, data.validVoxels,...
            data.voxSize] = load_results_for_visualization(runinfoLoc);
        
        % Indicate that data has been loaded
        set( findobj('tag', 'displayButton'), 'enable', 'on' );
        set( findobj('tag', 'displayButton'), 'string', 'Display' );
        
        % Update keeplist
        global keeplist;
        keeplist = ones(data.vis_q, 1);
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions for the Toolbar:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Function to take the parameter estimates from a given iteration and
% convert them into the approporiate maps
    function compileIterationResults(~,~)
        waitfor(compileIterationResultsWindow)
    end

end