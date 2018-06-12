function [ X, varNamesX ] = ref_cell_code( covariates, covTypes, varInModel,...
    interactions, includeInteractions  )
% ref_cell_code - Function to perform reference cell coding of the
% covariates
%
% Syntax:
% [ X, varNamesX ] = ref_cell_code( covariates, covTypes,...
%    interactions, includeInteractions  )
%
% Inputs:
%   covariates   - matrix of covariate settings
%   covTypes     - vector that is 1 if a covariate is categorical
%   varInModel   - vector that is 1 if a covariate should be included in
%                   the model
%   interactions - matrix of user-specified interactions
%   includeInteractions - 1 if interactions are to be calculated
%
% Outputs:
%   X         - reference cell coded design matrix
%   varNamesX - auto-determined variable names for covariates 
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
            nLevel = numel(covLevels);
            varLevels(iCov) = nLevel - 1;
            rcCovariate = zeros(N, nLevel-1);
            for iLevel = 1:(nLevel-1)
                rcCovariate(:,iLevel) = strcmp(covariates{:,iCov}, covLevels{iLevel});
                % Get the name for this reference factor
                factorName = strcat( covariates.Properties.VariableNames{iCov},...
                    '=', covLevels(iLevel)  );
                varNamesX = [varNamesX, factorName];
            end
            X = [X, rcCovariate];
        else
            varLevels(iCov) = 1;
            X = [X, table2array(covariates(:, iCov) )];
            varNamesX = [varNamesX, covariates.Properties.VariableNames{iCov}];
        end
    end % end of check that covariate is to be included in the model
end

% Now handle interactions
if includeInteractions
    [nInteractions, ~] = size(interactions);
    % Loop over interactions
    for iInt = 1:nInteractions
        intTerms = find(interactions(iInt,:));
        intTerm1 = intTerms(1);
        intTerm2 = intTerms(2);
        % Starting column index of X for each factor
        intTerm1Start = sum( varLevels(1:(intTerm1-1)) );
        intTerm2Start = sum( varLevels(1:(intTerm2-1)) );
        % Find out how many columns this interaction adds to the design matrix
        nColAdd = varLevels(intTerm1) * varLevels(intTerm2);
        newColumns = zeros(N, nColAdd);
        % Loop over the first variable
        colIndex = 0;
        for i1 = 1:varLevels(intTerm1)
            % Loop over the second variable
            for i2 = 1:varLevels(intTerm2)
                colIndex = colIndex + 1;
                newColumns(:,colIndex) = X(:,intTerm1Start+i1) .*...
                    X(:, intTerm2Start+i2);
                factorName = strcat( '(', varNamesX(intTerm1Start+i1), ')_x_(',...
                    varNamesX(intTerm2Start+i2), ')' );
                varNamesX = [varNamesX, factorName];
            end
        end
        X = [X, newColumns];
    end
end


end

