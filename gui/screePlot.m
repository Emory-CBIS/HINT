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
            'position', [50 15 109 30.8],...
            'MenuBar', 'none',... 'position', [400 250 650 400],...
            'NumberTitle','off',...
            'Name','Scree Plot',...
            'Resize','off',...
            'Visible','off');
        % adjust the figure to look better on windows machines
        if ispc
            set(findobj('tag', 'screeplot'), 'position', [50 15 119 30.8]);
        end
        
        % Scree Plot Axis
        scplt.screeAxes = axes('Parent', scplt.fig,...
            'units', 'normalized',...
            'Position',[0.1 0.4 0.8 0.5],...
            'Tag','screeAxes'); %#ok<NASGU>
        
        % Subject Select Dropdown Menu
        subjSelectDropdown = uicontrol('Parent', scplt.fig,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.2, 0.2, 0.1], ...
            'Tag', 'subjSelect', 'Callback', @changeSubject, ...
            'String', 'Select Subject');
        
        % Dropdown menu to select the number of ICs for the analysis
        subjNumICDropdown = uicontrol('Parent', scplt.fig,...
            'Style', 'popupmenu', ...
            'Units', 'Normalized', ...
            'Position', [0.31, 0.2, 0.2, 0.1], ...
            'Tag', 'subjNumIC', 'Callback', @changeNumIC, ...
            'String', 'Num. ICs');
        
        % Close Button for the window
        screeCloseButton = uicontrol('style', 'pushbutton',...
            'units', 'normalized', ...
            'Position', [0.8, 0.01, 0.20, 0.1],...
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
        
    end

    function changeSubject(hObject, callbackdata)
        newSubj = get(findobj('Tag', 'subjSelect'), 'val');
        % Run the PCA for the selected subject
        singleSubjPCA(newSubj);
    end

    function changeNumIC(hObject, callbackdata)
        newICNumber = get(findobj('Tag', 'subjNumIC'), 'val');
    end

    % Function to close the scree plot and return the selected IC number
    function closeScreeWindow(hObject, callbackdata)
        delete(hObject.Parent);
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
        [U_incr, D_incr] = pcamat(X_tilde_all);
        waitbar(3 / 4)
        
        lambda = sort(diag(D_incr),'descend');
        
        propVar = lambda / sum(lambda);
        
        % Set the plot to be the variance proportions
        axesHandle = findobj('Tag', 'screeAxes');
        if isempty(axesHandle)
            plot(scplt.screeAxes, propVar)
            title(scplt.screeAxes,...
                ['Proportion of variance explained by each IC - Subject ', num2str(subjNum)])
        else
            plot(axesHandle, propVar)
            title(axesHandle,...
                ['Proportion of variance explained by each IC - Subject ', num2str(subjNum)])
        end
 
        waitbar(4 / 4)
        
        % Close the waitbar
        close(pcawait)
        
    end

end