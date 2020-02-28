function [ map_fields, visit_fields ] = generate_info_box_fields( viewerType, viewTracker,...
    varargin)
%generate_info_box_fields - generates the map and visit fields for each
%displaid brain image
%
% Returns:
%

% Storage for map names
map_fields = cell(size(viewTracker, 1), size(viewTracker, 2));
visit_fields = cell(size(viewTracker, 1), size(viewTracker, 2)); 

switch viewerType
    case 'grp'
        %% Case 1: Using aggregate viewer
        % Loop through the view table and label
        for iVisit = 1:size(viewTracker, 2)
            map_fields{1, iVisit} = 'Population Aggregate';
            visit_fields{1, iVisit} = ['Visit ' num2str(iVisit)];
        end
    case 'beta'
        %% Case 2: Beta Viewer - Depends on whether contrast is being viewed
        contrast_selected = strcmp(get(get(findobj('tag',...
                'EffectTypeButtonGroup'), 'SelectedObject'),...
                'String'), 'Contrast View');
        display_names = get(findobj('tag', 'ViewSelectTable'), 'ColumnName');
        if contrast_selected == 1
            for iContrast = 1:size(viewTracker, 1)
                for iVisit = 1:size(viewTracker, 2)
                    map_fields{iContrast, iVisit} = ['Contrast: ' display_names{iContrast}];
                    visit_fields{iContrast, iVisit} = ['Visit ' num2str(iVisit)];
                end
            end
        else
            for iCovariate = 1:size(viewTracker, 1)
                for iVisit = 1:size(viewTracker, 2)
                    map_fields{iCovariate, iVisit} = ['Effect of: '  display_names{iCovariate}];
                    visit_fields{iCovariate, iVisit} = ['Visit ' num2str(iVisit)];
                end
            end
        end
        
    case 'subpop'
        %% Case 3: Sub-population Viewer
        display_names = get(findobj('tag', 'ViewSelectTable'), 'ColumnName');
        for iSubPop = 1:size(viewTracker, 1)
            for iVisit = 1:size(viewTracker, 2)
                map_fields{iSubPop, iVisit} = ['Sub-Population: ' display_names{iSubPop}];
                visit_fields{iSubPop, iVisit} = ['Visit ' num2str(iVisit)];
            end
        end
    case 'subj'
        %% Case 4: Subject level viewer
        % Loop through the view table and label
        for iVisit = 1:size(viewTracker, 2)
            map_fields{1, iVisit} = ['Subject ' num2str(varargin{1})];
            visit_fields{1, iVisit} = ['Visit ' num2str(iVisit)];
        end
        
    otherwise
        disp('ERROR, undefined map type')
end


end

