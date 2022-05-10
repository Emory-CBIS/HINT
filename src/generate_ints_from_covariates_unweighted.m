function [X, varNamesX] = generate_ints_from_covariates_unweighted(X, interactionsBase,...
    covTypes, covariates, variableNames, effectsCodingsEncoders, varNamesX)

for iInt = 1:size( interactionsBase )
    
    currentInteraction = interactionsBase(iInt, :);
    
    % Get the two corresponding variables
    inds = find(currentInteraction(:) == 1);
    ind1 = inds(1); ind2 = inds(2);
    
    % Code first covariate
    typeCov1 = covTypes(ind1);
    varNamesX1 = {};
    covariateValues = covariates{:, ind1};
    varName1 = variableNames{ind1};
    if typeCov1 == 1
        X1 = apply_effects_coding(covariateValues, effectsCodingsEncoders{ind1});
        for iset = 1:length(effectsCodingsEncoders{ind1}.variableNames)
            varNamesX1{length(varNamesX1) + 1} = [varName1 '_' effectsCodingsEncoders{ind1}.variableNames{iset}];
        end
    else
        X1 = covariateValues - mean(covariateValues);
        varNamesX1{length(varNamesX1) + 1} = varName1;
    end
    
    % Code second covariate
    typeCov2 = covTypes(ind2);
    varNamesX2 = {};
    covariateValues = covariates{:, ind2};
    varName2 = variableNames{ind2};
    if typeCov2 == 1
        X2 = apply_effects_coding(covariateValues, effectsCodingsEncoders{ind2});
        for iset = 1:length(effectsCodingsEncoders{ind2}.variableNames)
            varNamesX2{length(varNamesX2) + 1} = [varName2 '_' effectsCodingsEncoders{ind2}.variableNames{iset}];
        end
    else
        X2 = covariateValues - mean(covariateValues);
        varNamesX2{length(varNamesX2) + 1} = varName2;
    end

    % Add the interactions one at a time
    for i1 = 1:size(X1, 2)
        for i2 = 1:size(X2, 2)
            
            newInt = X1(:, i1).*X2(:, i2);
            X = [X newInt];
            varNamesX{length(varNamesX) + 1} = [varNamesX1{i1} ' x ' varNamesX2{i2}];
            
            
        end
    end
    
    
end

end

