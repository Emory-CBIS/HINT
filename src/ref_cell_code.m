function [ X, varNamesX, interactions ] = ref_cell_code( covariates, covTypes, varInModel,...
    interactions, interactionsBase, includeInteractions, referenceGroupNumber  )
% ref_cell_code - Function to perform reference cell coding of the
% covariates
%
% Syntax:
% [ X, varNamesX, interactions ] = ref_cell_code( covariates, covTypes,...
%    interactions, includeInteractions  )
%
% Inputs:
%   covariates   - matrix of covariate settings
%   covTypes     - vector that is 1 if a covariate is categorical
%   varInModel   - vector that is 1 if a covariate should be included in
%                   the model
%   interactions - matrix of user-specified interactions
%   interactionsBase - interactions in terms of the un-ref-celled covs
%   includeInteractions - 1 if interactions are to be calculated
%   referenceGroupNumber - level to use as reference level
%
% Outputs:
%   X            - reference cell coded design matrix
%   varNamesX    - auto-determined variable names for covariates 
%   interactions - matrix of interactions
%
% See also: auto_identify_covariate_types.m

[N, ~] = size(covariates);

X = zeros(N, 0);
varLevels = zeros(numel(covTypes), 1);
% Storage for column names for ref cell covariates
varNamesX = [];
for iCov = 1:numel(covTypes)
    % Get the name of this covariate
    if varInModel(iCov) == 1
        if covTypes(iCov) == 1
            covLevels = unique(covariates{:, iCov} );
            % if the covariate is originally numeric, need to force it to
            % be a cell array
            nLevel = numel(covLevels);
            numFlag = 0;
            if ~iscell(covLevels)
                numFlag = 1;
                covLevels = cellstr(num2str(covLevels));
            end
            varLevels(iCov) = nLevel - 1;
            covLevels(referenceGroupNumber(iCov)) = [];
            rcCovariate = zeros(N, nLevel-1);
            for iLevel = 1:(nLevel-1)
                % Perform string conversion if originally numeric
                if numFlag == 1
                    rcCovariate(:,iLevel) = strcmp(cellstr(num2str(covariates{:,iCov})), covLevels{iLevel});
                else
                    rcCovariate(:,iLevel) = strcmp(covariates{:,iCov}, covLevels{iLevel});
                end
      
                % Get the name for this reference factor
                factorName = strcat( covariates.Properties.VariableNames{iCov},...
                    '=', covLevels(iLevel)  );
                varNamesX = [varNamesX, factorName];
            end
            X = [X, rcCovariate];
        else
            varLevels(iCov) = 1;
            X = [X, table2array(covariates(:, iCov) )];
            varNamesX = [varNamesX, covariates.Properties.VariableNames(iCov)];
        end
        
        % Create the intermediate interactions info
        
    end % end of check that covariate is to be included in the model
end

% This chunk is required to handle the possibility of categorical variables
% with more than two levels
interactions = zeros(0, sum(varLevels));
[nInt, ~] = size(interactionsBase);
for iInt = 1:nInt
    % Find the relevant variables
    intTerms = find(interactionsBase(iInt,:));
    intTerm1 = intTerms(1);
    intTerm2 = intTerms(2);
    % Now, use the number of var levels to figure out how many rows
    % need to be added to interactions matrix
    nRowAdd = varLevels(intTerm1) * varLevels(intTerm2);
    [lp1, lp2] = meshgrid(1:varLevels(intTerm1), 1:varLevels(intTerm2));
    % Now get 'actual' columns by adding up previous factor levels
    start1 = sum(varLevels(1:(intTerm1-1)));
    start2 = sum(varLevels(1:(intTerm2-1)));
    newInt = zeros(nRowAdd, sum(varLevels));
    for iSubInt = 1:nRowAdd
        newInt(iSubInt, start1+lp1(iSubInt)) = 1;
        newInt(iSubInt, start2+lp2(iSubInt)) = 1;
    end
    interactions = [interactions; newInt];
end

% Now handle interactions
if includeInteractions
    [nInteractions, ~] = size(interactions);
    % Loop over interactions
    for iInt = 1:nInteractions
        intTerms = find(interactions(iInt,:));
        intTerm1 = intTerms(1);
        intTerm2 = intTerms(2);
        nColAdd=1;
        newColumns = zeros(N, nColAdd);
        % Loop over the first variable
        colIndex = 1;
        
        newColumns(:, :) = X(:, intTerm1) .* X(:, intTerm2);
        factorName = strcat( '(', varNamesX(intTerm1), ')_x_(',...
                    varNamesX(intTerm2), ')' );
        varNamesX = [varNamesX, factorName];
        
        X = [X, newColumns];
    end
end


end

