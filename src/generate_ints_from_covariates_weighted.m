function [X, varNamesX] = generate_ints_from_covariates_weighted(X, interactionsBase,...
    covTypes, covariates, variableNames, effectsCodingsEncoders, varNamesX,...
    covariateMeans, covariateSDevs, unitScale)

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
    freqTableInds1 = 0;
    if typeCov1 == 1
        X1 = apply_effects_coding(covariateValues, effectsCodingsEncoders{ind1});
        for iset = 1:length(effectsCodingsEncoders{ind1}.variableNames)
            varNamesX1{length(varNamesX1) + 1} = [varName1 '_' effectsCodingsEncoders{ind1}.variableNames{iset}];
        end
        % Get the corresponding index (1 for ref, otherwise is column id)
        [vals,inds] = max(X1,[],2);
        inds = inds + 1;
        inds(vals < 0.0) = 1;
        freqTableInds1 = inds;
    else
        X1 = covariateValues - covariateMeans(ind1);
        if unitScale == 1
            X1 = X1 ./ covariateSDevs(ind1);
        end
        varNamesX1{length(varNamesX1) + 1} = varName1;
    end
    
    % Code second covariate
    typeCov2 = covTypes(ind2);
    varNamesX2 = {};
    covariateValues = covariates{:, ind2};
    varName2 = variableNames{ind2};
    freqTableInds2 = 0;
    if typeCov2 == 1
        X2 = apply_effects_coding(covariateValues, effectsCodingsEncoders{ind2});
        for iset = 1:length(effectsCodingsEncoders{ind2}.variableNames)
            varNamesX2{length(varNamesX2) + 1} = [varName2 '_' effectsCodingsEncoders{ind2}.variableNames{iset}];
        end
        % Get the corresponding index (1 for ref, otherwise is column id)
        [vals,inds] = max(X2,[],2);
        inds = inds + 1;
        inds(vals < 0.0) = 1;
        freqTableInds2 = inds;
    else
        X2 = covariateValues - covariateMeans(ind2);
        if unitScale == 1
            X2 = X2 ./ covariateSDevs(ind2);
        end
        varNamesX2{length(varNamesX2) + 1} = varName2;
    end
    
    
    %%% Weighted terms - Case of 1 discrete and 1 continuous
    if (typeCov1 + typeCov2) == 1
        
        if typeCov2 == 1
            catCov = typeCov2;
            catX = X2;
            contX = X1;
            catInd = ind2;
        else
            catCov = typeCov1;
            catX = X1;
            contX = X2;
            catInd = ind1;
        end
        
        nCatCol = size(catX, 2);
        
        indsLevel = {};
        SSLevel = {};
        MSDE = effectsCodingsEncoders{catInd};
        refInds = find(strcmp(covariates{:, catInd}, MSDE.referenceCategory));
        refSS   = sum((contX(refInds, :) - mean(contX(refInds, :))).^2);
        
        for iCat = 1:length(MSDE.variableNames)
            indsLevel{iCat} = find(strcmp(covariates{:, catInd}, MSDE.variableNames{iCat}));
            SSLevel{iCat} = sum((contX(indsLevel{iCat}, :) - mean(contX(indsLevel{iCat}, :))).^2);
            catX(catX(:, iCat) < 0.0, iCat) = -1.0 * SSLevel{iCat} / refSS;
        end            
        
        if typeCov2 == 1
            X2 = catX;
            X1 = contX;
        else
            X1 = catX;
            X2 = contX;
        end
        
    end % end of re-work for weighted cont x cat interaction
    
    
    %% Weighted terms - case of both categorical - construct a frequency table
    if (typeCov1 + typeCov2) == 2
        % first make sure order matches
        covariates
        cov1 = covariates{:, ind1};
        cov2 = covariates{:, ind2};
        
        % construct table
        ft = crosstab(freqTableInds1, freqTableInds2);
    end
    
    % Add the interactions one at a time
    for i1 = 1:size(X1, 2)
        for i2 = 1:size(X2, 2)
            
            %% Weighted terms - 1 cat or no cat
            if (typeCov1 + typeCov2) < 2
                newInt = X1(:, i1).*X2(:, i2);
            else
                
                %% Weighted terms - case of both categorical
                neg1 = X1(:, i1) < 0.0;
                neg2 = X2(:, i2) < 0.0;
                
                
                newInt = zeros(size(X1, 1), 1);
                
                %newInt(simpleProdInds) = X1(simpleProdInds, i1).*X2(simpleProdInds, i2);
                newInt = X1(:, i1) .* X2(:, i2);
                simpleProdInds = find(neg1 == 0 & neg2 == 0 & newInt ~= 0);
                posFracInds    = find(neg1 == 1 & neg2 == 1 & newInt ~= 0);
                negFracInds    = find( (neg1 + neg2) == 1 & newInt ~= 0 );
                
                
                %newInt(posFracInds) =
                ftinds = size(ft, 1) .* (freqTableInds2(posFracInds)-1) + freqTableInds1(posFracInds);
                newInt(posFracInds) = ft(i1+1, i2+1) ./ ft(1, 1);
                
                % Have to get cell membership
                ftinds = size(ft, 1) .* (freqTableInds2(negFracInds)-1) + freqTableInds1(negFracInds);
                newInt(negFracInds) = -1.0 * ft(i1+1, i2+1) ./ ft(ftinds);
                
            end
            
            
            X = [X newInt];
            varNamesX{length(varNamesX) + 1} = [varNamesX1{i1} ' x ' varNamesX2{i2}];
            
            
        end
    end
    
    
end

end

