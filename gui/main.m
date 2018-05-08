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
    global outpath;
    global outfilename;
    global writelog;
    global strMatch;
    global myfont;
    global data;
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

    function hs = addcomponents
        % Add components, save handles in a struct
        hs.fig = figure('Tag','hcica','units', 'character', 'position', [50 15 109 30.8],...
            'MenuBar', 'none',... 'position', [400 250 650 400],...
            'NumberTitle','off',...
            'Name','HINT',...
            'Resize','off',...
            'Visible','off',...
            'Color',[51/256, 63/256, 127/256]);
        % adjust the figure to look better on windows machines
        if ispc
           set(findobj('tag', 'hcica'), 'position', [50 15 119 30.8]);
        end
        tgroup = uitabgroup('Parent', hs.fig,...
            'Tag','tabGroup',...
            'units', 'normalized',...
            'position', [0 0 1 0.85]);
        tab1 = uitab('Parent', tgroup, 'Tag','tab1','Title', 'Load data');
        tab2 = uitab('Parent', tgroup, 'Tag','tab2','Title', 'Run analysis');
        tab3 = uitab('Parent', tgroup, 'Tag','tab3','Title', 'Visualize');
        
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
        t1p1 = uipanel('Parent',tab1, 'units', 'character', ...
            'Position',[2.5 13.5 49 9],...
            'Title','1. Setup','FontSize',myfont);
        text1 = uicontrol('Parent',t1p1,'Style','text','units', 'character', ...
            'Position',[1.5 4.25 15 2],...
            'String','Analysis folder','FontSize',myfont,...
            'HorizontalAlignment',textalign); %#ok<NASGU>
        edit1 = uicontrol('Parent',t1p1,'Tag','edit1', 'units', 'character', ...
            'Style','edit','Position',[19.9 4.7 18 1.75],...
            'FontSize',myfont,'HorizontalAlignment',textalign,...
            'Tag','analysisFolder',...
            'BackgroundColor','white'); %#ok<NASGU>
        t1button1 = uicontrol('Parent',t1p1,'Style','pushbutton',...
            'String','Browse', 'units', 'character',...
            'Position',[38 4.6 10 2], 'Callback',@button1_Callback,'UserData','hello'); %#ok<NASGU>
        text2 = uicontrol('Parent',t1p1,'Style','text','units', 'character',...
            'Position',[1.5 2.4 18 2],...
            'String','Prefix for analysis','FontSize',myfont,...
            'HorizontalAlignment',textalign); %#ok<NASGU>
        edit2 = uicontrol('Parent',t1p1,'Style','edit', 'units', 'character',...
            'Position',[19.9 2.8 18 1.75],...
            'FontSize',myfont,'HorizontalAlignment',textalign,...
            'Tag','prefix',...
            'BackgroundColor','white'); %#ok<NASGU>
        text3 = uicontrol('Parent',t1p1,'Style','text', 'units', 'character',...
            'Position',[1.5 0.6 18 2],...
            'String','Create session log','FontSize',myfont,...
            'HorizontalAlignment',textalign); %#ok<NASGU>
        cb1 = uicontrol('Parent',t1p1,'Style','checkbox', 'units', 'character',...
            'Tag','logCheckBox','Callback',@logCheckBox_Callback,...
            'Position',[19.5 1.2 3 1.5]); %#ok<NASGU>
        
        %2. Input data panel
        t1p2 = uipanel('Parent',tab1, 'units', 'character',...
            'Position',[2.5 2.7 49 10.2],...
            'Title','2. Input','FontSize',myfont);
        bg1 = uibuttongroup('Parent',t1p2, 'units', 'character',...
            'Position',[2 3 45 5.4],...
            'Tag','loadDataRadioButtonPanel',...
            'SelectionChangeFcn',@dataselection,...
            'Title','Input method','FontSize',myfont);
        b1r1 = uicontrol(bg1,'Style','radiobutton',...
            'Tag','niftiData',...
            'String','Import Nifti data',...
            'FontSize',myfont, 'units', 'character',...
            'Position',[4 2.2 30 2]); %#ok<NASGU>
        
        b1r2 = uicontrol(bg1,'Style','radiobutton',...
            'Tag','matData',...
            'String','Load saved analysis',...
            'FontSize',myfont,'units', 'character',...
            'Position',[4 0.4 30 2]); %#ok<NASGU>
        
        loadDataButton = uicontrol('Parent',t1p2,'Tag','loadDataButton','Style',...
            'pushbutton','String','Load data',...
            'CallBack',@loadDataButton_Callback,...
            'FontSize',myfont,'units', 'character',...
            'Position',[4 0.8 17 1.5]); %#ok<NASGU>
        
        t1button3 = uicontrol('Parent',t1p2,'Style','pushbutton','String','View covariates',...
            'Callback',@openCovWindow_Callback,...
            'FontSize',myfont, 'units', 'character',...
            'Position', [25 0.8 20 1.5]); %#ok<NASGU>
        
        %3. Pre-process data
        t1p3 = uipanel('Parent',tab1,'units', 'character',...
            'tag', 'preprocpanel',...
            'Position',[54 6.82 49 15.7],...
            'Title','3. Pre-process data','FontSize',myfont);
        % Adjust size for windows users
        if ispc
           set(findobj('tag', 'preprocpanel'), 'position', [54 6.82 59 15.7]);
        end
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
            'BackgroundColor','white'); %#ok<NASGU>
        edit3 = uicontrol('Parent',t1p3,'Style','edit','units', 'character',...
            'units', 'normalized',...
            'Position',[0.55 0.65 0.2 0.13],...
            'FontSize',myfont,'HorizontalAlignment',textalign,...
            'Tag', 'numICA',...
            'BackgroundColor','white'); %#ok<NASGU>
        t1button4 = uicontrol('Parent',t1p3,'Style','pushbutton',...
            'String','PCA dimension reduction','Callback',@calculatePCA,...
            'FontSize',myfont, 'units', 'character',...
            'units', 'normalized',...
            'Position',[0.25 0.45 0.5 0.15]); %#ok<NASGU>
        
        t1button5 = uicontrol('Parent',t1p3,'Style','pushbutton',...
            'units', 'normalized',...
            'String','Generate initial values',...
            'Callback',@calculateInitialParams,...
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
        t2p1 = uipanel('Parent',t2p,'Position',[.1 .2 .8 .7],...
            'Title','hc-ICA Parameters','FontSize',myfont);
        % Max Iteration Selection
        t2text2 = uicontrol('Parent',t2p1,'Style','text',...
            'units', 'normalized','Position',[0.01, 0.55, 0.4, 0.1],...
            'String','Max Iterations','FontSize',myfont,...
            'HorizontalAlignment','right'); %#ok<NASGU>
        t2edit1 = uicontrol('Parent',t2p1,'Style','edit',...
            'units', 'normalized','Position',[0.5 0.55 0.4 0.1],...
            'FontSize',myfont,'String','100','HorizontalAlignment',textalign,...
            'Tag','maxIter',...
            'BackgroundColor','white'); %#ok<NASGU>
        % Epsilon 1 Selection
        t2text3 = uicontrol('Parent',t2p1,'Style','text',...
            'units', 'normalized','Position',[0.01, 0.4, 0.4, 0.1],...
            'String','Epsilon 1','FontSize',myfont,...
            'HorizontalAlignment','right'); %#ok<NASGU>
        t2edit2 = uicontrol('Parent',t2p1,'Style','edit',...
            'units', 'normalized','Position',[0.5 0.4 0.4 0.1],...
            'FontSize',myfont,'String','0.001','HorizontalAlignment',textalign,...
            'Tag','epsilon1',...
            'BackgroundColor','white'); %#ok<NASGU>
        % Epsilon 2 Selection
        t2text4 = uicontrol('Parent',t2p1,'Style','text',...
            'units', 'normalized','Position',[0.01, 0.25, 0.4, 0.1],...
            'String','Epsilon 2','FontSize',myfont,...
            'HorizontalAlignment','right'); %#ok<NASGU>
        t2edit3 = uicontrol('Parent',t2p1,'Style','edit',...
            'units', 'normalized','Position',[0.5 0.25 0.4 0.1],...
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
            'String','Aggregate display maps',...
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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%% Functions for Panel 1 %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Check if the hc-ICA session is to be logged. Create log file.
    function logCheckBox_Callback(hObject,~)
        if strcmp(get(findobj('tag', 'analysisFolder'), 'string'), '')
            warndlg('Please specify an analysis folder before writing a log file.')
            set(hObject, 'Value', 0);
        else
        if (get(hObject,'Value') == get(hObject,'Max'))
            writelog = 1;
            prefix = get(findobj('tag', 'prefix'), 'string');
            outdir = get(findobj('tag', 'analysisFolder'), 'string');
            outfilename = strcat(outdir, '/', prefix, '_textlog_', date(),...
                '_', datestr(now, 'HH:MM:SS') );
            outfile = fopen(outfilename, 'wt' );
            fprintf(outfile, strcat('Log for hcica session on',...
                [' ', date()], ' started at: ',...
                [' ', datestr(now, 'HH:MM:SS')] ) );
        end
        end
    end

    % Allow the user to select the output directory for the analysis.
    function button1_Callback(~,~)
        folderName = uigetdir(pwd);
        if folderName==0
            folderName='';
        end
        outpath = folderName;
        set(findobj('Tag','analysisFolder'), 'String', folderName);
    end

    % Load the nifti data, covariate file, and mask file specified by the
    % user.
    function loadDataButton_Callback(~,~)
        
        data.preprocessingComplete = 0;
        data.iniGuessComplete = 0;
        set(findobj('tag', 'saveContinueButton'), 'enable', 'off');
        
        % Update the progress bar to reflect loading new data
        set(findobj('Tag','dataProgress'),'BackgroundColor',...
            [0.94,0.94,0.94],...%[51/256,153/256,0/256],...
            'ForegroundColor',[0.9255,0.9255,0.9255],...
            'enable','off');
        set(findobj('Tag','pcaProgress'),'BackgroundColor',...
            [0.94,0.94,0.94],...%[51/256,153/256,0/256],...
            'ForegroundColor',[0.9255,0.9255,0.9255],...
            'enable','off');
        set(findobj('Tag','iniProgress'),'BackgroundColor',...
            [0.94,0.94,0.94],...%[51/256,153/256,0/256],...
            'ForegroundColor',[0.9255,0.9255,0.9255],...
            'enable','off');
        set(findobj('Tag','icProgress'),'BackgroundColor',...
            [0.94,0.94,0.94],...%[51/256,153/256,0/256],...
            'ForegroundColor',[0.9255,0.9255,0.9255],...
            'enable','off');
        
        bGroup = findobj('Tag','loadDataRadioButtonPanel');
        dataType = get(get(bGroup,'SelectedObject'),'Tag');
        % Handle input data in .mat form. This will load runinfo file
        if (strcmp(dataType, 'matData') == 1)
            % Direct the user to load a runinfo file
            [fname pathname] = uigetfile('.mat');
            runinfo = load([pathname fname]);
            
            % Update the appropriate data structures
            data.qstar = runinfo.q;
            data.q = runinfo.qold;
            data.CmatStar = runinfo.CmatStar;
            data.X = runinfo.X;
            data.YtildeStar = runinfo.YtildeStar;
            data.beta0Star = runinfo.beta0Star;
            data.covariates = runinfo.covariates;
            data.covf = runinfo.covfile;
            data.covTypes = runinfo.covTypes;
            data.maskf = runinfo.maskf;
            data.niifiles = runinfo.niifiles;
            data.numPCA = runinfo.numPCA;
            data.thetaStar = runinfo.thetaStar;
            data.time_num = runinfo.time_num;
            data.validVoxels = runinfo.validVoxels;
            data.outpath = runinfo.outfolder;
            data.prefix = runinfo.prefix;
            data.voxSize = runinfo.voxSize;
            data.N = runinfo.N;
            data.varNamesX = runinfo.varNamesX;
            data.interactions = runinfo.interactions;
            
            % Populate the display fields
            %set(findobj('tag', ''), 'string', num2str());
            set(findobj('tag', 'numICA'), 'string', num2str(runinfo.qold));
            set(findobj('tag', 'numPCA'), 'string', num2str(runinfo.numPCA));
            set(findobj('tag', 'prefix'), 'string', num2str(runinfo.prefix));
            set(findobj('tag', 'analysisFolder'), 'string', num2str(runinfo.outfolder));
            data.preprocessingComplete = 1;
            data.iniGuessComplete = 1;
            data.tempiniGuessObtained = 1;
            set(findobj('tag', 'runButton'), 'enable', 'on');
            
            % Fill in the blanks to reflect what was loaded

            % Update the GUI to reflect the loaded information
            set(findobj('Tag','dataProgress'),'BackgroundColor',[51/256,153/256,0/256],...
                'ForegroundColor',[0.9255,0.9255,0.9255],...
                'enable','on');
            set(findobj('Tag','pcaProgress'),'BackgroundColor',[51/256,153/256,0/256],...
                'ForegroundColor',[0.9255,0.9255,0.9255],...
                'enable','on'); 
            set(findobj('Tag','iniProgress'),'BackgroundColor',[51/256,153/256,0/256],...
                'ForegroundColor',[0.9255,0.9255,0.9255],...
                'enable','on'); 
            set(findobj('Tag','icProgress'),'BackgroundColor',[51/256,153/256,0/256],...
                'ForegroundColor',[0.9255,0.9255,0.9255],...
                'enable','on');
            data.dataLoaded = 1;
            
        % Handle data in nifti form.
        elseif (strcmp(dataType, 'niftiData') == 1)
            fls = loadNii;
            % outer check makes sure anything was input
            if (~isempty(fls))
            if (~isempty(fls{1}) && ~isempty(fls{2}) && ~isempty(fls{3}))
                niifiles = fls{1}; data.niifiles_raw = niifiles;
                maskf = fls{2}; data.maskf = maskf;
                covf = fls{3}; data.covf = covf;
                N = length(niifiles);
                if (N > 0)
                    % Match up each covariate with its row in the covariate
                    % file
                    data.covariateTable = readtable(covf);
                    data.covariates = data.covariateTable.Properties.VariableNames;
                    
                    [data.niifiles, tempcov] = matchCovariatesToNiifiles(data.niifiles_raw,...
                        data.covariateTable, strMatch);
                    % Get rid of the subject part of the data frame
                    data.covariates = tempcov(:, 2:width(tempcov));
                    data.covariates.Properties.VariableNames =...
                        data.covariateTable.Properties.VariableNames(2:length(data.covariateTable.Properties.VariableNames));
                    data.covTypes = auto_identify_covariate_types(data.covariates);
                    [ data.X, data.varNamesX ] = ref_cell_code( data.covariates, data.covTypes,...
                        0, 0  );
                    % Create the (empty) interactions matrix
                    [~, nCol] = size(data.X);
                    data.interactions = zeros(0, nCol);
                    
                    % Load the first data file and get its size.
                    image = load_nii(niifiles{1});
                    [m,n,l,k] = size(image.img);
                    
                    % load the mask file.
                    if(~isempty(maskf))
                        mask = load_nii(maskf);
                        validVoxels = find(mask.img == 1);
                    else
                        validVoxels = find(ones(m,n,l) == 1);
                    end
                    nValidVoxel = length(validVoxels);
                    
                    % Store the relevant information
                    data.time_num = k;
                    data.N = N;
                    data.validVoxels = validVoxels;
                    data.voxSize = size(mask.img);
                    data.dataLoaded = 1;
                end
                
                % Update main gui window to show that data has been loaded.
                set(findobj('Tag','dataProgress'),'BackgroundColor',[51/256,153/256,0/256],...
                    'ForegroundColor',[0.9255,0.9255,0.9255],...
                    'enable','on');
            end
            end
        end
    end

    % Perform the PCA data reduction. Output is Ytilde, C_matrix_diag,
    %    H_matrix_inv, H_matrix, and deWhite.
    function calculatePCA(~,~)
        
        if data.dataLoaded == 0;
            warndlg('Please load data before preprocessing.');
        else
        
            data.preprocessingComplete = 0;
            data.tempiniGuessObtained = 0;
            data.iniGuessComplete = 0;
            set(findobj('tag', 'saveContinueButton'), 'enable', 'off');

            data.q = str2double(get(findobj('Tag', 'numICA'), 'String'));
            [data.Ytilde, data.C_matrix_diag, data.H_matrix_inv,  data.H_matrix, data.deWhite]...
                = PreProcICA(data.niifiles, data.validVoxels, data.q, data.time_num, data.N);

            % Update GUI to show PCA completed
            data.dispPCA.String = 'PCA Completed';
            set(findobj('Tag','pcaProgress'),'BackgroundColor',[51/256,153/256,0/256],...
                'ForegroundColor',[0.9255,0.9255,0.9255],...
                'enable','on');

            % Update the data structure to know that preprocessing is
            % complete
            data.preprocessingComplete = 1;
            
            % write PCA information to log file.
            if (writelog == 1)
                outfile = fopen(outfilename, 'a' );
                fprintf(outfile, strcat('\n\n----------------- Preprocessing -----------------'));
                fprintf(outfile, strcat('\nPerformed PCA reduction to ', [' ',num2str(data.q),], ' components') );
            end
            
        end
    end

    % Calculate the initial guess parameters for hc-ICA. 2 options: tc-gica
    % and GIFT. GIFT is the better option.
    function calculateInitialParams(~,~)
        
        if data.preprocessingComplete == 1
            data.iniGuessComplete = 0;
            data.tempiniGuessObtained = 0;
            set(findobj('tag', 'saveContinueButton'), 'enable', 'off');
            data.q = str2double(get(findobj('Tag', 'numICA'), 'String'));
            global keeplist;
            keeplist = ones(data.q,1);
            addpath('FastICA_25');
            numberOfPCs = findobj('Tag', 'numPCA');
            data.prefix = get(findobj('Tag', 'prefix'), 'String');
            data.outpath = get(findobj('Tag', 'analysisFolder'), 'String');

            % Perform GIFT
            % Generate the text parameter file used by GIFT
            hcicadir = pwd;
            % run GIFT to get the initial guess. This function also outputs nifti files
            % with initial values.
            [ data.theta0, data.beta0, data.s0, s0_agg ] = runGIFT(data.niifiles, data.maskf, ...
                get(findobj('Tag', 'prefix'), 'String'),...
                get(findobj('Tag', 'analysisFolder'), 'String'),...
                str2double(numberOfPCs.String),...
                data.N, data.q, data.X, data.Ytilde, hcicadir);

            % Write to log file that initial guess stage is complete.
            if (writelog == 1)
                outfile = fopen(outfilename, 'a' );
                fprintf(outfile, strcat('\nCalculated initial guess values '));
            end

            % Turn all the initial group ICs into nifti files to allow user to
            % view and select the ICs for hc-ICA.
            template = zeros(data.voxSize);
            template = reshape(template, [prod(data.voxSize), 1]);

            anat = load_nii(data.maskf);
            for ic=1:data.q
                newIC = template;
                newIC(data.validVoxels) = s0_agg(ic, :)';
                IC = reshape(newIC, data.voxSize);
                newIC = make_nii(IC)
                newIC.hdr.hist.originator = anat.hdr.hist.originator
                save_nii(newIC, [get(findobj('Tag', 'analysisFolder'), 'String') '/' get(findobj('Tag', 'prefix'), 'String') '_iniIC_' num2str(ic) '.nii' ], 'IC');
            end

            % Update the gui main window to show that initial values
            % calculation is completed.
            set(findobj('Tag','iniProgress'),'BackgroundColor',[51/256,153/256,0/256],...
                'ForegroundColor',[0.9255,0.9255,0.9255],...
                'enable','on');
            data.tempiniGuessObtained = 1;

            chooseIC;
        else
            warndlg('Please complete preprocessing before obtaining an initial guess.');
        end
    end

    % Open viewer to allow user to select which ICs to use for hc-ICA.
    function chooseIC(~)
        if data.tempiniGuessObtained == 1
            global keeplist;
            keeplist = ones(data.q,1);
            displayResults(data.q, data.outpath, data.prefix,...
                data.N, 'icsel', data.covariates, data.X, data.covTypes, 999,...
                999, data.interactions);
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
                % Fill in the progress bar to let the user know that they can
                % move on to the analysis
                set(findobj('Tag','icProgress'),'BackgroundColor',[51/256,153/256,0/256],...
                'ForegroundColor',[0.9255,0.9255,0.9255],...
                'enable','on');
                data.iniGuessComplete = 1;
                set(findobj('tag', 'saveContinueButton'), 'enable', 'on');
            end
            % Else, if the user did select only a subset of ICs, allow them to
            % re-estimate the intial guess
            if (data.qstar < data.q)
                data.iniGuessComplete = 0;
                set(findobj('tag', 'saveContinueButton'), 'enable', 'off');
                set( findobj('Tag', 'reEstButton') ,'Enable','On') 
                set( findobj('Tag', 'viewReduced') ,'Enable','On') 
            end
        else
            warndlg('Please obtain initial guess before selecting ICs for analysis.');
        end
    end

    function test_Callback2(~,~)
        displayResults(data.q, data.outpath, data.prefix,...
            data.N, 'reEst', data.covariates, data.X, data.covTypes, 'NA',...
            'NA', data.interactions);
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
        
        % Call function to re-estimate the initial values for the hc-ica
        % algorithm based on the selected ICs
        [data.thetaStar, data.beta0Star, data.YtildeStar, data.CmatStar] = ...
            reEstimateIniGuess( data.N,...
            str2double(get(findobj('tag', 'numPCA'), 'String')), data.outpath,...
            data.prefix, data.X, data.maskf, data.validVoxels )
        
        % Fill in the progress bar to let the user know that they can
        % move on to the analysis
        set(findobj('Tag','icProgress'),'BackgroundColor',[51/256,153/256,0/256],...
            'ForegroundColor',[0.9255,0.9255,0.9255],...
            'enable','on');
        data.iniGuessComplete = 1;
        set(findobj('tag', 'saveContinueButton'), 'enable', 'on');
        
    end

    function resetButtonCallback(~, ~)
        hs = findall(0,'tag','hcica');
        close(hs);
        hs = addcomponents;
        data = struct();
        % Initial progress states
        data.preprocessingComplete = 0;
        data.tempiniGuessObtained = 0;
        data.iniGuessComplete = 0;
        data.dataLoaded = 0;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%% Functions for Panel 2 %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    % Run the selected algorithm.
    function runButton_Callback(~, ~)
        
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

        % Enable the stop button and disable the run button
        set(findobj('tag','stopButton'),'enable','on');   
        set(findall(findobj('tag', 'analysisSetup'),...
            '-property', 'enable'), 'enable', 'off')
        
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
            outfile = fopen(outfilename, 'a' );
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
                data.grpICvar, data.success, data.G_z_dict, data.finalIter] = ...
                CoeffpICA_EM (data.YtildeStar, data.X, data.thetaStar, ...
                data.CmatStar, data.beta0Star, data.maxiter, ...
                data.epsilon1, data.epsilon2, 'approxVec_Experimental', data.outpath, data.prefix,0);
            
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
                data.grpICvar, data.success, data.gz_dict] = ...
                CoeffpICA_EM (data.Ytilde, data.X, data.theta0, ...
                data.C_matrix_diag, data.beta0, data.maxiter, ...
                data.epsilon1, data.epsilon2, 'exact', data.outpath, data.prefix, 0);
        end
        
        % Analysis finished, write to log file.
        if (writelog == 1)
        fprintf(outfile, strcat('\nOutput is in',...
            [' ',get(findobj('Tag','analysisFolder'),'String')] )  );
        end
        path = get(findobj('Tag','analysisFolder'),'String');
        
        % Create nifti files for the group ICs, the subject specific ICs,
        % and the beta effects.
        prefix = get(findobj('Tag','prefix'),'String');
        vxl = data.voxSize;
        locs = data.validVoxels;
        path = [data.outpath '/'];
        
        % Save a file with the subject level IC map information
        subjFilename = [path prefix '_subject_IC_estimates.mat'];
        subICmean = data.subICmean;
        save(subjFilename, 'subICmean');
        
        for i=1:data.qstar
            
            % Save the S0 map
            gfilename = [prefix '_S0_IC_' num2str(i) '.nii'];
            nmat = nan(vxl);
            nmat(locs) = data.grpICmean(i,:);
            nii = make_nii(nmat);
            save_nii(nii,strcat(path,gfilename));
            
            % Create IC maps for the betas.
            for k=1:size(data.beta_est,1)
                bfilename = [prefix '_beta_cov' num2str(k) '_IC' num2str(i) '.nii'];
                nmat = nan(vxl);
                nmat(locs) = data.beta_est(k,i,:);
                nii = make_nii(nmat);
                save_nii(nii,strcat(path,bfilename));
            end
            
            % Create IC maps for the groups level.
%             gfilename = [prefix '_grpIC_' num2str(i) '.nii'];
%             nmat = nan(vxl);
%             nmat(locs) = data.grpICmean(i,:);
%             nii = make_nii(nmat);
%             save_nii(nii,strcat(path,gfilename));
            % Create aggregate IC maps
            nullAggregateMatrix = nan(vxl);
            nullAggregateMatrix(locs) = 0.0;
            for j=1:data.N
                nullAggregateMatrix(locs) = nullAggregateMatrix(locs) +...
                    1/data.N * squeeze(subICmean(i,j,:));
            end
            gfilename = [prefix '_aggregateIC_' num2str(i) '.nii'];
            nii = make_nii(nullAggregateMatrix);
            save_nii(nii,strcat(data.outpath,'/',gfilename));
        end
        
        % Calculate the standard error estimates for the beta maps
        [theory_var, beta_se_est] = VarEst_hcica(data.theta_est, data.beta_est, data.X,...
            data.z_mode, data.YtildeStar, data.G_z_dict);
        data.theoretical_beta_se_est = theory_var;
        data.beta_se_est = beta_se_est;
        save( [path prefix '_beta_se_est.mat' ], 'beta_se_est', 'theory_var' );
        
        data.outpath = path;
        data.prefix = prefix;
        
        % Disable the stop button
        set(findobj('Tag','stopButton'),'enable','off'); 
        % Enable the "Display Results" button
        set(findobj('Tag','displayResultsButton'),'enable','on'); 
        % Re-enable the analysis buttons
        set(findall(findobj('tag', 'analysisSetup'),...
            '-property', 'enable'), 'enable', 'on');
        % Enable the display results button
        %set(findobj('Tag','displayResultsButton'),'enable','off'); 
        
    end
    
    % Switch the display tab to the results display tab.
    function switchDisplayTab(~,~)
        set(findobj('Tag','tabGroup'),'SelectedTab',findobj('Tag','tab3'))
        set( findobj('tag', 'displayButton'), 'enable', 'on' );
        set( findobj('tag', 'displayButton'), 'string', 'Display' );
        % Update the display tab with the output path
        set( findobj('tag', 'displayPath'), 'string', data.outpath(1:end-1));
        set( findobj('tag', 'displayPrefix'), 'string', data.prefix);
    end

    % Function to terminate the analysis when the current iteration
    % finishes.
    function stopButtonCallback(~,~)
        global keepRunning;
        keepRunning = 0;
        set( findobj('tag', 'displayButton'), 'enable', 'on' );
        set( findobj('tag', 'displayButton'), 'string', 'Display' );
        set( findobj('tag', 'displayResultsButton'), 'enable', 'on');
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
            
            sel = 1;
            for preIndex = 1:length(runinfofiles)
                prename = runinfofiles(preIndex).name;
                runinfofiles(preIndex).name = prename(1:length(prename)-12);
            end
            
            if ( length(runinfofiles) > 1 )
                sel = listdlg('PromptString','Choose a prefix:',...
                    'SelectionMode','single',...
                    'ListString',{runinfofiles.name});
            end
            
            data.prefix = runinfofiles(sel).name;
            preEdit = findobj('Tag', 'displayPrefix');
            preEdit.String = data.prefix;
            
            % Read the runinfo .m file. Update "data" information.
            data.prefix = get(preEdit,'String');
            runInfo = load([folderName '/' data.prefix '_runinfo.mat']);
            data.covariates = runInfo.covariates;
            data.covTypes = runInfo.covTypes;
            data.X = runInfo.X;
            data.varNamesX = runInfo.varNamesX;
            data.interactions = runInfo.interactions;
            data.niifiles = runInfo.niifiles;
            [data.N, ~] = size(runInfo.X);
            data.qstar = runInfo.q;
            tempSeEst = load( [folderName '/' data.prefix '_beta_se_est.mat'] );
            data.beta_se_est = tempSeEst.beta_se_est;
            
            %Force the keeplist variable to reflect the number of ICs
            global keeplist
            keeplist = ones(data.qstar, 1);
                        
        else
            errordlg('No runinfo file found for the analysis!')
        end
        
    end
    
    % Function to open the display viewer. Belongs to Panel 3.
    function displayCallback(~,~)
        dgroup = findobj('Tag', 'displayType');
        disp_map =  get(get(dgroup, 'SelectedObject'), 'Tag');
        if strcmp(disp_map, 'dt1')
            displayResults(data.qstar, data.outpath, ...
   data.prefix, data.N, 'grp', data.varNamesX, data.X, data.covTypes,...
   data.beta_se_est,  data.theoretical_beta_se_est, data.interactions)
        elseif strcmp(disp_map, 'dt2')
            displayResults(data.qstar, data.outpath, ...
   data.prefix, data.N, 'subpop', data.varNamesX, data.X, data.covTypes,...
   data.beta_se_est,  data.theoretical_beta_se_est, data.interactions)
        elseif strcmp(disp_map, 'dt3')
            displayResults(data.qstar, data.outpath, ...
   data.prefix, data.N, 'subj', data.varNamesX, data.X, data.covTypes,...
   data.beta_se_est, data.theoretical_beta_se_est, data.interactions)
        elseif strcmp(disp_map, 'dt4')
            displayResults(data.qstar, data.outpath, ...
   data.prefix, data.N, 'beta', data.varNamesX, data.X, data.covTypes,...
   data.beta_se_est,  data.theoretical_beta_se_est, data.interactions)
        end
    end
    
    %%%%%%%%%%% Functions to Fix or classify %%%%%%%%%% 
    function dataselection(~,~)
    end

    % Save the run infoformation into a file called runinfo.mat.
    function saveContinueButton_Callback(~,~)
        set(findobj('Tag', 'runButton'), 'enable', 'on');
        set(findobj('Tag','tabGroup'),'SelectedTab',findobj('Tag','tab2'))

        %  save the run info, hide the warning that the variables are
        %  unused
        q = data.qstar; time_num = data.time_num; X = data.X;       %#ok<NASGU>
        validVoxels=data.validVoxels; niifiles = data.niifiles;     %#ok<NASGU>
        maskf = data.maskf; covfile = data.covf;                    %#ok<NASGU>
        numPCA = num2str(get(findobj('Tag', 'numPCA'), 'String'));  %#ok<NASGU>
        outfolder = data.outpath; prefix = data.prefix;             %#ok<NASGU>
        covariates = data.covariates;                               %#ok<NASGU>
        covTypes = data.covTypes;                                      %#ok<NASGU>
        varNamesX = data.varNamesX;                                 %#ok<NASGU>
        interactions = data.interactions                            %#ok<NASGU>
        thetaStar = data.thetaStar;                                 %#ok<NASGU>
        YtildeStar = data.YtildeStar;                               %#ok<NASGU>
        CmatStar = data.CmatStar;                                   %#ok<NASGU>
        beta0Star = data.beta0Star;                                 %#ok<NASGU>
        voxSize = data.voxSize;                                     %#ok<NASGU>
        N = data.N;                                                 %#ok<NASGU>
        qold = data.q;                                              %#ok<NASGU>        
        
        save([data.outpath '/' data.prefix '_runinfo.mat'], 'q', ...
            'time_num', 'X', 'validVoxels', 'niifiles', 'maskf', 'covfile', 'numPCA', ...
            'outfolder', 'prefix', 'covariates', 'covTypes', 'beta0Star', 'CmatStar',...
            'YtildeStar', 'thetaStar', 'voxSize', 'N', 'qold', 'varNamesX', 'interactions');
    end

    % Open the window to allow the user to view the covariate files.
    function openCovWindow_Callback(~,~)
        if (data.dataLoaded == 1)
            waitfor(viewCovariateDisplay(data.X, data.varNamesX, data.niifiles,...
                data.covTypes, data.varNamesX, data.covariates, data.interactions))
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
        runinfoLoc = [filepath, '/', fileprefix, '_runinfo.mat'];
        
        % Open the waitbar
        waitLoad = waitbar(0,'Please wait while the results load')
        
        % Run the runinfo file
        tempData = load(runinfoLoc);
        waitbar(2/10)
                
        % Add the important parts of the runinfo file to the data object
        % for the viewer
        data.q = tempData.q;
        waitbar(3/10)
        data.qstar = tempData.q;
        waitbar(4/10)
        data.outpath = tempData.outfolder;
        waitbar(5/10)
        data.prefix = tempData.prefix;
        waitbar(6/10)
        data.N = size(tempData.X, 1);
        waitbar(7/10)
        data.covariates = tempData.covariates;
        waitbar(8/10)
        data.X = tempData.X;
        waitbar(9/10)
        data.covTypes = tempData.covTypes; 
        data.varNamesX = tempData.varNamesX;
        data.interactions = tempData.interactions;
        
        tempSeEst = load( [filepath '/' data.prefix '_beta_se_est.mat'] );
        data.beta_se_est = tempSeEst.beta_se_est;
        data.theoretical_beta_se_est = tempSeEst.theory_var;
        waitbar(10/10)
        
        % Close the waitbar
        close(waitLoad)
        
        % Set the prefix box to show the loaded prefix
        set(findobj( 'tag', 'displayPrefix' ), 'string', data.prefix)
        
        % Indicate that data has been loaded
        set( findobj('tag', 'displayButton'), 'enable', 'on' );
        set( findobj('tag', 'displayButton'), 'string', 'Display' );
        
        % Update keeplist
        global keeplist;
        keeplist = ones(data.q, 1);
        
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