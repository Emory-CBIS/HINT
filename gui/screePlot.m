function varargout = screePlot(varargin)

% screePlot - Gui that opens to allow the user to decide how many ICs to
% include in the analysis.
%
% Syntax:
%
% Inputs:
%   niifiles - list of the niftifiles for the analysis
%   validVoxels - voxel list from the user-supplied mask
%
%
% Outputs:
%
%
% See also: PreProcICA.m

% Assign the input
global screeData
screeData.niifiles = varargin{1};
screeData.validVoxels = varargin{2};

screeData.N = length(screeData.niifiles);

scplt = findall(0,'tag','screeplot');

if (isempty(scplt))
    scplt = addcomponents;
    set(scplt.fig,'Visible','on');
else
    figure(scplt);
end

    function scplt = addcomponents
        % Add components, save handles in a struct
        scplt.fig = figure('Tag','screeplot','units', 'character',...
            'position', [50 15 40 30.8],...
            'MenuBar', 'none',... 'position', [400 250 650 400],...
            'NumberTitle','off',...
            'Name','Scree Plot',...
            'Resize','off',...
            'Visible','on');
        % adjust the figure to look better on windows machines
        if ispc
            set(findobj('tag', 'screeplot'), 'position', [50 15 119 30.8]);
        end
        
        movegui(scplt.fig, 'center')
        
        % Scree Plot Axis
        scplt.screeAxes = axes('Parent', scplt.fig,...
            'units', 'normalized',...
            'Position',[0.1 0.4 0.8 0.5],...
            'Tag','screeAxes'); %#ok<NASGU>
        
        controlPanel = uipanel('FontSize',12,...
             'Position',[.01, 0.01 0.98 0.3], ...
             'Tag', 'thresholdPanel', ...
             'Title', 'Options');
         
        % Subject select text label
        subjSelectInfo = uicontrol('Parent',controlPanel,'Style','text',...
            'units', 'normalized','Position',[0.001, 0.65, 0.5, 0.3],...
            'String','Currently Selected Subject:',...
            'HorizontalAlignment','right'); %#ok<NASGU>
       
        
        % Subject Select Dropdown Menu
        subjSelectDropdown = uicontrol('Parent', controlPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.51, 0.65, 0.4, 0.3], ...
            'Tag', 'subjSelect', 'Callback', @changeSubject, ...
            'String', 'Select Subject');
        
        % Text to the left of the NUM IC display
        varInfoText = uicontrol('Parent', controlPanel,'Style','text',...
            'units', 'normalized','Position',[0.001, 0.4, 0.5, 0.3],...
            'String','Number of included ICs:',...
            'HorizontalAlignment','right'); %#ok<NASGU>
        
        % Dropdown menu to select the number of ICs for the analysis
        subjNumICDropdown = uicontrol('Parent', controlPanel,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.51, 0.4, 0.4, 0.3], ...
            'Tag', 'subjNumIC', 'Callback', @changeNumIC, ...
            'String', 'Num. ICs');
        
        % Text to the left of the EXPLAINED VARIANCE display
        varInfoText = uicontrol('Parent', controlPanel,'Style','text',...
            'units', 'normalized','Position',[0.001, 0.15, 0.5, 0.3],...
            'String','Prop. of variance explained:',...
            'HorizontalAlignment','right'); %#ok<NASGU>
        
        % Display showing how much variance is explained
        varianceInfo = uicontrol('Parent', controlPanel, ...
            'Style', 'Text', ...
            'Units', 'Normalized', ...
            'Position', [0.53, 0.305, 0.35, 0.15], ...
            'Tag', 'varianceInfo', 'BackgroundColor', 'white', ...
            'ForegroundColor', 'black', ...
            'HorizontalAlignment', 'Left');
        
        % Close Button for the window
        screeCloseButton = uicontrol('parent', controlPanel,...
            'style', 'pushbutton',...
            'units', 'normalized', ...
            'Position', [0.1, 0.01, 0.8, 0.2],...
            'String', 'Close', ...
            'tag', 'screeClose', ...
            'Callback', @closeScreeWindow);
        
        screeInitialDisplay;
    
    end

    function screeInitialDisplay(hObject, callbackdata)
        
        % Create the cell array of niifiles for the subject drop down menu
        newstring = cell(screeData.N, 1);
        for iSubj=1:screeData.N
                newstring{iSubj} = strcat(['Subject ' num2str(iSubj)]);
        end
        % Assign the cell array to the subject drop down menu
        set(findobj('tag', 'subjSelect'), 'String', newstring);
        set(findobj('tag', 'subjSelect'), 'Value', 1);
        
        % Run the PCA for the first subject
        singleSubjPCA(1);
        
        % Update the maximum number of ICs and the dropdown menu
        updateICDropdown;
        
    end

    function changeSubject(hObject, callbackdata)
        newSubj = get(findobj('Tag', 'subjSelect'), 'val');
        % Run the PCA for the selected subject
        singleSubjPCA(newSubj);
    end

    function changeNumIC(hObject, callbackdata)
        %Get the selected subject for the plot title
        subjNum = get(findobj('tag', 'subjSelect'), 'Value');
        newICNumber = get(findobj('Tag', 'subjNumIC'), 'val');
        % Add a vertical line at the new IC number
        plot(scplt.screeAxes, screeData.propVar)
        line(scplt.screeAxes, [newICNumber newICNumber],... 
            get(scplt.screeAxes,'YLim'),'Color',[1 0 0]);
        title(scplt.screeAxes,...
                {'Proportion of variance explained',...
                ['by number of ICs - Subject ', num2str(subjNum)]})
            pctExplainedAll = cumsum(screeData.propVar);
            pctExplained = pctExplainedAll( get(findobj('tag', 'subjNumIC'), 'value') );
            midwaypoint = get(scplt.screeAxes,'YLim')/2;
        text(scplt.screeAxes, get(findobj('tag', 'subjNumIC'), 'value') + 1, midwaypoint(2),...
                ['Total: ' num2str(round(100*pctExplained, 1)) '%'], 'Color', [1 0 0]);
        % Update the percent explained text
        set(findobj('tag', 'varianceInfo'), 'string', ...
            [num2str(round(100*pctExplained, 1)) '%']);
    end

    % Function to update the number of allowable ICs and check to make sure
    % a valid value is selected
    function updateICDropdown(~)
        maxIC = length(screeData.propVar);
        % Create the cell array of ICs
        newstring = cell(maxIC, 1);
        for iSubj=1:maxIC
                newstring{iSubj} = strcat(num2str(iSubj));
        end
        
        % Handle case where user has selected a very large number of ICs
        % and then switched to a new subject with fewer ICs (This should
        % not be an issue for any reasonable selection, guard is here just in
        % case)
        if get(findobj('tag', 'subjNumIC'), 'Value') > maxIC
            set(findobj('tag', 'subjNumIC'), 'Value', maxIC);
        end
        
        % Assign the cell array to the subject drop down menu
        set(findobj('tag', 'subjNumIC'), 'String', newstring);
                
    end

    % Function to do PCA for a single subject
    function singleSubjPCA(subjNum, handles)
        
        % Get the currently selected number of ICs
        q = get(findobj('tag', 'subjNumIC'), 'Value');
        
        % Open a waitbar for the user
        pcawait = waitbar(0,'Performing PCA for the selected subject...');
        
        % Load the image for the selected subject
        image = load_nii(screeData.niifiles{subjNum});
        [m,n,l,k] = size(image.img);
        res = reshape(image.img,[], k)';
        
        % X tilde all is raw T x V subject level data for subject i
        X_tilde_all = res(:,screeData.validVoxels);
        waitbar(1 / 4)
        
        % Center the data
        [X_tilde_all, ] = remmean(X_tilde_all);
        waitbar(2 / 4)
        
        % run pca on X_tilde_all
        [~, D_incr] = pcamat(X_tilde_all);
        waitbar(3 / 4)
        
        lambda = sort(diag(D_incr),'descend');
        
        screeData.propVar = lambda / sum(lambda);
        
        % Set the plot to be the variance proportions
        axesHandle = findobj('Tag', 'screeAxes');
        if isempty(axesHandle)
            plot(scplt.screeAxes, screeData.propVar)
            title(scplt.screeAxes,...
                {'Proportion of variance explained',...
                ['by number of ICs - Subject ', num2str(subjNum)]})
            pctExplainedAll = cumsum(screeData.propVar);
            pctExplained = pctExplainedAll( get(findobj('tag', 'subjNumIC'), 'value') );
            midwaypoint = get(scplt.screeAxes,'YLim')/2;
            text(scplt.screeAxes, get(findobj('tag', 'subjNumIC'), 'value') + 1, midwaypoint(2),...
                ['Total: ' num2str(round(100*pctExplained, 1)) '%'], 'Color', [1 0 0]);
            drawnow;
            changeNumIC;
            % Update the percent explained text
            set(findobj('tag', 'varianceInfo'), 'string', ...
            [num2str(round(100*pctExplained, 1)) '%']);
        else
            plot(axesHandle, screeData.propVar)
            title(axesHandle,...
                {'Proportion of variance explained',...
                ['by number of ICs - Subject ', num2str(subjNum)]})
            line(axesHandle, [1 1],... 
            get(axesHandle,'YLim'),'Color',[1 0 0]);
            % Add label to line
            pctExplainedAll = cumsum(screeData.propVar);
            pctExplained = pctExplainedAll(1);
            midwaypoint = get(axesHandle,'YLim')/2;
            text(axesHandle, 2, midwaypoint(2),...
                ['Total: ' num2str(round(100*pctExplained, 1)) '%'], 'Color', [1 0 0]);
            % Update the percent explained text
            set(findobj('tag', 'varianceInfo'), 'string', ...
            [num2str(round(100*pctExplained, 1)) '%']);
        end
        waitbar(4 / 4)
        
        % Close the waitbar
        close(pcawait)
        
        updateICDropdown;
        
    end

    % Function to close the scree plot and return the selected IC number
    function closeScreeWindow(hObject, callbackdata)
        delete(hObject.Parent.Parent);
    end

end