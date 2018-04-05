function [ covTypes ] = auto_identify_covariate_types( covariates )
% auto_identify_covariate_types - Function to determine if each covariate
% is continuous or categorical
%
% Syntax:
% [covTypes] = auto_identify_covariate_types ( cpvariates )
%
% Inputs:
%    covariates  - matrix of covariate settings
%
% Outputs:
%    covTypes    - vector that is 1 if a covariate is categorical
%
% See also: ref_cell_code.m

    % Get the number of covariates
    [~, p] = size(covariates);
    
    % Storage for the results
    covTypes = zeros(p, 1);
    
    % Loop over each covariate and check if it is a char (using cell),
    % if it is then mark it as categorical
    for iCov = 1:p
        
        exampleValue = covariates{1,iCov};
        if iscell(exampleValue)
            covTypes(iCov) = 1;
        end
        
    end

end

