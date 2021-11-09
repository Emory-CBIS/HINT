function [ normalizedImg ] = se_normalize_image( img, varEst, ctr )
%this function is meant to be called on a cell array of images using
%cellfun

    % Variance estimate
    ctrVarEst = squeeze(mtimesx(mtimesx(ctr', varEst(:, :, :, :, :) ), ctr));
            
    % Testing versus 0 - so don't subtract the mean
    normalizedImg = img ./ sqrt(ctrVarEst);

end

