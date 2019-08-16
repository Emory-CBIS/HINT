function [ apos, cpos, spos, axesInfoPanelPos ] = generate_axes_positioning( viewTracker,...
    tileType)
%generate_axes_positioning - based on viewer type and user request, this
%returns values telling HINT where to place each axes
%
%Arguments:
%   viewTable
%   tileType - vertical or grouped (needs better names)
%
%Returns:
%   apos, cpos, spos, axesInfoPanelPos - each is a cell array with the
%   positioning of the corresponding element of the view tracker

% Storage for locations
apos = cell(size(viewTracker, 1), size(viewTracker, 2));
cpos = cell(size(viewTracker, 1), size(viewTracker, 2));
spos = cell(size(viewTracker, 1), size(viewTracker, 2));
axesInfoPanelPos = cell(size(viewTracker, 1), size(viewTracker, 2));


[visit_numbers, selected_pops] = find(viewTracker' > 0);
% get the number of maps being viewed
nMapsViewed = sum(viewTracker > 0);

% Find coordinates based on view type
switch tileType
    case 'vertical'
        %% Vertical case - easy, just stack plots on top of each other
        for i = 1:nMapsViewed 
            % Figure out which map to plot
            selected_pop = selected_pops(i);
            visit_number = visit_numbers(i);
            
            % Calculate the map position
            spos{selected_pop, visit_number} = [0.01 (.18 + 0.82*(nMapsViewed-i)/nMapsViewed) .27 0.82/nMapsViewed];
            cpos{selected_pop, visit_number} = [0.30 (.18 + 0.82*(nMapsViewed-i)/nMapsViewed) .27 0.82/nMapsViewed];
            apos{selected_pop, visit_number} = [0.59 (.18 + 0.82*(nMapsViewed-i)/nMapsViewed) .27 0.82/nMapsViewed];
            
            % Move the info panel to its position
            axesInfoPanelPos{selected_pop, visit_number} = [0.87 (.18 + 0.82*(nMapsViewed-i)/nMapsViewed) .13 0.82/nMapsViewed];
        end
    case 'grouped'
        %% Grouped case
        nTilePerRow = ceil(sqrt(nMapsViewed));
        nRow = ceil(nMapsViewed / nTilePerRow);
        individMapWidth = 0.98/nTilePerRow/2;
        % counter is to keep track when we jump to the next row
        counter = 0;
        rowCounter = 1;
        % Loop over maps
        for i = 1:nMapsViewed 
            
            % increment counter
            counter = counter + 1;
            
            % Figure out which map to plot
            selected_pop = selected_pops(i);
            visit_number = visit_numbers(i);
            
            % TODO ystart is still off for multirow (2nd element)
            
            % Calculate the map position
            spos{selected_pop, visit_number} = [(0.01+(counter-1)*0.98/nTilePerRow)...
                (.18 + 0.82*(nRow-rowCounter)/nRow) individMapWidth 0.82/nRow/2];
            
            cpos{selected_pop, visit_number} = [(0.01+(counter-1)*0.98/nTilePerRow)...
                (.18 + 0.82*(nRow-rowCounter)/nRow + 0.82/nRow/2) individMapWidth 0.82/nRow/2];
            
            apos{selected_pop, visit_number} = [(individMapWidth+0.01+(counter-1)*0.98/nTilePerRow)...
                (.18 + 0.82*(nRow-rowCounter)/nRow + 0.82/nRow/2) individMapWidth 0.82/nRow/2];
            % Move the info panel to its position
            axesInfoPanelPos{selected_pop, visit_number} = [(individMapWidth+0.01+(counter-1)*0.98/nTilePerRow)...
                 (.18 + 0.82*(nRow-rowCounter)/nRow) individMapWidth 0.82/nRow/2];
            
            if counter == nTilePerRow
                counter = 0;
                rowCounter = rowCounter + 1;
            end
            
        end
        
    otherwise
        warndlg('ERROR unspecific tile type')
end


end

