function [X, varNamesX] = generate_model_matrix(covTypes, varInModel,...
    covariates, effectsCodingsEncoders, unitScale, weighted,...
    interactionsBase, variableNames, covariateMeans, covariateSDevs)
% if unit scale is true, scaled by stdev. This is calculated using the
% input data unless the scaleTerm argument is provided



X = [];
varNamesX = {};
for p = 1:length(covTypes)
    if varInModel(p) == 1
        covariateValues = covariates{:, p};
        varName = variableNames{p};
        if covTypes(p) == 1
            X = [X apply_effects_coding(covariateValues, effectsCodingsEncoders{p})];
            for iset = 1:length(effectsCodingsEncoders{p}.variableNames)
                varNamesX{length(varNamesX) + 1} = [varName '_' effectsCodingsEncoders{p}.variableNames{iset}];
            end
        else
            covariateValues = covariateValues - covariateMeans(p);
            if (unitScale == 1)
                covariateValues = covariateValues / covariateSDevs(p);
            end
            X = [X covariateValues];
            varNamesX{length(varNamesX) + 1} = varName;
        end
    end
end

% Add weighted/unweighted interaction effects
if weighted == 1
    [X, varNamesX] = generate_ints_from_covariates_weighted(X, interactionsBase,...
        covTypes,  covariates,...
        variableNames,  effectsCodingsEncoders, varNamesX);
else
    [X, varNamesX] = generate_ints_from_covariates_unweighted(X, interactionsBase,...
        covTypes,  covariates,...
        variableNames,  effectsCodingsEncoders, varNamesX);
end

end

