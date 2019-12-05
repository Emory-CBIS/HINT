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
        %% Case 2: Beta Viewer
    case 'subpop'
        %% Case 3: Sub-population Viewer
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

