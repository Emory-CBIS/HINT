function [ newCovariates newX ] = updateCodingScheme( isCat, covariateNames, covtable, covariateColumnVarMembership )
% updateCodingScheme - Function to modify the coding scheme based on either
% a new interaction requested by the user or a change in the
% categorical/continuous status of a variables.
%
% Syntax: [ newCovariates newX factorarr covariateNames] = refCellCode( covtable, headers )
%
% Inputs:
%   
%   covTable    - A table object with all the covariate data
%   header      - File of covariate names
%
% See also: refCellCode

[nrow ncol] = size(covtable);

% array to store which columns need to be ref cell coded
factorarr = [999; isCat];
headers = covariateNames;

% Do the reference cell coding. Need:
%   1) Count the number of unique values in the column for each column
%   2) Choose a reference cell and code
%   3) Add to new structure with appropriate number of columns

newX = ones(nrow, 1); %this is temporary and will be removed at end
newCovariates = headers(1);
covariateColumnVarMembership = headers(1);
for col = 2:ncol
    if factorarr(col) == 1
        % find the factor levels, count them, and pick a reference cell
        %levels = unique( table2cell(covtable(:,col)) );
        levels = unique( cellfun(@num2str, table2cell(covtable(:,col)),...
            'UniformOutput',false));
        
        [n_levels ~] = size(levels);
        ncol_to_add = n_levels - 1;
        ref_level = levels(1, 1);
        if n_levels > 1
            % Create new factor names for the non-reference cell
            for lev = 2:n_levels
                newCovariates = [newCovariates levels(lev,1)];
                if 
                else
                    newXColumn = strcmp(table2cell(covtable(:,col)), levels(lev,1));
                end
                newX = [newX newXColumn];
            end
        end
    else
        newCovariates = [newCovariates headers(col)];
        newX = [newX cell2mat(table2cell(covtable(:,col)))];
    end
end

[nrow ncol] = size(newX);
newX = newX(:,2:ncol);
factorarr = factorarr(2:width(covtable));

end

