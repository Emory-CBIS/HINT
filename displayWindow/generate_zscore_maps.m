function [ newImgs ] = generate_zscore_maps( mapType, toZ, oimg, ...
    varianceEstFile, validVoxels, LC )
%GENERATE_ZSCORE_MAPS - Converts cell arrays of images to and from
%z-scores. Intended to be called from displayResults.m's update_Z_maps
%function
%
%Arguments:
%mapType: describes which view is being used, determines how Z-scores are
% calculated. Options are 'grp', 'subpop', 'subj', 'Effect View',
% 'Contrast View', and 'Cross-Visit Contrast View'
%
%toZ: is true if we are converting to Z scores, false if we are reverting
%to original images
%
%oimg: the original image (cell array)
%
%varianceEstFile: the filepath to the .mat file containing the 5d
%
%variance-covariance estimates for the current independent component.
%
%validVoxels: contains a list of voxels that are not excluded by the brain
%mask. All voxels outside of this region are nans
%
%LC: linear combination variable. Only needed for contrasts
%
%See also: displayResults.m, z_normalize_image.m

[nRow, nCol] = size(oimg);

if toZ == true
    
    switch mapType
        
        case 'Effect View'
            
            normalizationWaitbar = waitbar(0, 'Loading Variance Estimates');
            
            varianceEst = load(varianceEstFile).betaVarEst;
            
            % Create the "contrast" corresponding to looking at each effect
            % at each visit
            normalizationWaitbar = waitbar(0.1, 'Creating Contrast List');
            ctrIndexList = num2cell(eye(nCol), 1);
                     
            % Each cell is a covariate effect, within each cell we have the
            % corresponding "contrast" for each visit
            ctrList = cellfun(@(x) createContrast(x, nCol, nRow), ctrIndexList,...
                'uniformoutput', false);
                        
            % Split so shape of contrasts matches shape of image cell array
            ctrCells = cellfun(@(x) num2cell(x, 1)', ctrList,...
                'uniformoutput', false);
            ctrCells = horzcat(ctrCells{:});
                                    
            % Divide by estimated standard error
            normalizationWaitbar = waitbar(0.2, 'Applying Z-transformation');
            newImgs = cellfun(@(x, y) se_normalize_image(x, varianceEst, y),...
                oimg, ctrCells, 'uniformoutput', false);
            
            close(normalizationWaitbar)
            
        case 'Contrast View'
            
            varianceEst = load(varianceEstFile).betaVarEst;
            
            P = size(LC, 2);
            
            LCCellArr = num2cell(LC, 2)';
            
            % Each cell is a contrast, within each cell we have the
            % corresponding "contrast" for each visit
            ctrList = cellfun(@(x) createContrast(x, P, nRow), LCCellArr,...
                'uniformoutput', false);
            
            % Split so shape of contrasts matches shape of image cell array
            ctrCells = cellfun(@(x) num2cell(x, 1)', ctrList,...
                'uniformoutput', false);
            ctrCells = horzcat(ctrCells{:});
            
            % Divide by estimated standard error
            newImgs = cellfun(@(x, y) se_normalize_image(x, varianceEst, y),...
                oimg, ctrCells, 'uniformoutput', false);
            
        case 'Cross-Visit Contrast View'
            
            varianceEst = load(varianceEstFile).betaVarEst;
            
            LCCellArr = num2cell(LC, 2)';
            
            nVisit = size(varianceEst, 1) - size(LC, 2) + 1;
            P = size(LC, 2) / nVisit;
            
            % Each cell is a contrast, within each cell we have the
            % corresponding "contrast" for each visit
            ctrList = cellfun(@(x) createContrast(x, P, nVisit), LCCellArr,...
                'uniformoutput', false);
            
            % Split so shape of contrasts matches shape of image cell array
            ctrCells = cellfun(@(x) num2cell(x, 1)', ctrList,...
                'uniformoutput', false);
            ctrCells = horzcat(ctrCells{:})';
            
            % Divide by estimated standard error
            newImgs = cellfun(@(x, y) se_normalize_image(x, varianceEst, y),...
                oimg, ctrCells, 'uniformoutput', false);
            
        otherwise
                        
            newImgs = cellfun(@(x) z_normalize_image(x, validVoxels),...
                oimg, 'uniformoutput', false);
            
    end
    
else
    
    newImgs = oimg;
    
end


end

