function [ covTypes ] = auto_identify_covariate_types( covariates )
% auto_identify_covariate_types - 

    [~, p] = size(covariates);
    
    covTypes = zeros(p, 1);
    
    for iCov = 1:p
        
        exampleValue = covariates{1,iCov};
        
        if iscell(exampleValue)
            covTypes(iCov) = 1;
        end
        
    end

end

