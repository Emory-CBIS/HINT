function save_analysis_results( prefix, data )
%save_analysis_results - function to save all the output from the EM
%algorithm. Saves aggregate maps, ic maps, beta maps, and standard
%deviations

% Create nifti files for the group ICs, the subject specific ICs,
% and the beta effects.
vxl = data.voxSize;
locs = data.validVoxels;
path = [data.outpath '/'];

% Open a waitbar showing the user that the results are being saved
waitSave = waitbar(0,'Please wait while the results are saved');

% Save a file with the subject level IC map information
subjFilename = [path prefix '_subject_IC_estimates.mat'];

subICmean = data.subICmean;
if data.nVisit == 1
    subICmean = permute(subICmean, [1, 3, 2]);
end
save(subjFilename, 'subICmean');

waitbar(1 / (2+data.qstar))


% Loop over each independent component
for i=1:data.qstar
    
    waitbar((1+i) / (2+data.qstar), waitSave, ['Saving results for IC ', num2str(i)])
    
    % Save the S0 map
    gfilename = [prefix '_S0_IC_' num2str(i) '.nii'];
    nmat = nan(vxl);
    nmat(locs) = data.grpICmean(i,:);
    nii = make_nii(nmat);
    save_nii(nii,strcat(path, gfilename));
    
    %% Create IC maps for the betas.
    % Save in the Cross-Sectional Case
    if data.nVisit == 1
        for k=1:size(data.beta_est,1)
            bfilename = [prefix '_beta_cov' num2str(k) '_IC' num2str(i) '_visit1' '.nii'];
            nmat = convert_vec_to_braindim(data.beta_est(k, i, :),...
            data.validVoxels, data.voxSize);
            nii = make_nii(nmat);
            nii.hdr.hist.originator = data.maskOriginator;
            save_nii(nii, fullfile(path, bfilename));
        end
        
        % Save .mat version of ALL covariate effects, along with S0 in the
        % first position. This will make creating sub-populations later
        % easier
        allCoefs = zeros(size(data.beta_est, 1) + 1, length(data.validVoxels));
        allCoefs(1, :) = data.grpICmean(i, :);
        allCoefs(2:end, :) = squeeze(data.beta_est(:, i, :));
        fname = [prefix '_all_effect_ests_IC'...
                    num2str(i) '.mat'];
        save( fullfile(path, fname), 'allCoefs');
        
    % Save in the longitudinal case
    else
        % Save the alpha maps
        ind = 0;
        for iVisit = 2:data.nVisit
            ind = ind + 1;
            bfilename = [prefix '_visit_effect_IC'...
                    num2str(i) '_visit' num2str(iVisit) '.nii'];
            nmat = convert_vec_to_braindim(data.beta_est(i, ind, :),...
                data.validVoxels, data.voxSize);
            nii = make_nii(nmat);
            nii.hdr.hist.originator = data.maskOriginator;
            save_nii(nii, fullfile(path, bfilename));
        end
            
        % Save the covariate effects 
        for iVisit = 1:data.nVisit
            for p = 1:size(data.X, 2)
                ind = ind + 1;
                bfilename = [prefix '_beta_cov' num2str(p) '_IC'...
                    num2str(i) '_visit' num2str(iVisit) '.nii'];
                nmat = convert_vec_to_braindim(data.beta_est(i, ind, :),...
                    data.validVoxels, data.voxSize);
                nii = make_nii(nmat);
                %nii.hdr.hist.originator = data.maskOriginator;
                save_nii(nii, fullfile(path, bfilename));
            end
        end
        
        % Save .mat version of ALL covariate effects, along with S0 in the
        % first position. This will make creating sub-populations later
        % easier
        allCoefs = zeros(size(data.beta_est, 2) + 1, length(data.validVoxels));
        allCoefs(1, :) = data.grpICmean(i, :);
        allCoefs(2:end, :) = squeeze(data.beta_est(i, :, :));
        fname = [prefix '_all_effect_ests_IC'...
                    num2str(i) '.mat'];
        save( fullfile(path, fname), 'allCoefs');
          
    end
    
    %% Create aggregate IC maps
    % Save in the Cross-Sectional Case
    if data.nVisit == 1
        nullAggregateMatrix = nan(vxl);
        nullAggregateMatrix(locs) = 0.0;
        for j=1:data.N
            nullAggregateMatrix(locs) = nullAggregateMatrix(locs) +...
                1/data.N * squeeze(subICmean(i,:, j))';
        end
        gfilename = [prefix '_aggregateIC_' num2str(i) '_visit1.nii'];
        nii = make_nii(nullAggregateMatrix);
        save_nii(nii,strcat(data.outpath,'/',gfilename));
    else
        for iVisit = 1:data.nVisit
            
            nullAggregateMatrix = nan(vxl);
            nullAggregateMatrix(locs) = 0.0;
            
            q = data.qstar;
            for iSubj=1:data.N
                qvsubj = subICmean(:, :, iSubj, iVisit);
                
                nullAggregateMatrix(locs) = nullAggregateMatrix(locs) +...
                    1/data.N * squeeze(qvsubj(i, :))';
            end
            
            gfilename = [prefix '_aggregateIC_' num2str(i) '_visit'...
                num2str(iVisit) '.nii'];
            nii = make_nii(nullAggregateMatrix);
            save_nii(nii,strcat(data.outpath,'/',gfilename));
            
        end
    end
    
end

waitbar((data.qstar+1) / (2+data.qstar), waitSave, 'Estimating variance of covariate effects. This may take a minute.')

%% Calculate the standard error estimates for the beta maps
% Cross Sectional
if data.nVisit == 1
    
    VarEst_hcica(data.theta_est, data.beta_est, data.X,...
        data.z_mode, data.YtildeStar, data.G_z_dict, data.voxSize,...
        data.validVoxels, prefix, data.outpath);
                
else
    
    % this is old version
%     theory_var = var_est_longitudinal(data.theta_est, data.beta_est, data.X,...
%         data.z_mode, data.YtildeStar, data.G_z_dict, data.voxSize,...
%         data.validVoxels, prefix, data.outpath);
%         data.theoretical_beta_se_est = theory_var;
        
    VarEstLICAExact(data.theta_est, data.beta_est, data.X,...
        data.PostProbs, data.YtildeStar, data.voxSize,...
        data.validVoxels, prefix, data.outpath);
    
    %data.theoretical_beta_se_est = theory_var;
    
end

% % Save the variance estimates - SAVED ELSEWHERE
% varFilename = [path prefix '_varianceEstimates.mat'];
% theoretical_beta_se_est = data.theoretical_beta_se_est;
% save(varFilename, 'theoretical_beta_se_est');

waitbar(1)
close(waitSave)

data.outpath = path;
data.prefix = prefix;

% Write out a text file to the output directory with what covariate
% each beta map corresponds to
nBeta = size(data.X, 2);
fname = [data.outpath, data.prefix, '_Beta_File_List'];
fileID = fopen(fname,'w');
formatSpec = 'Beta %4.2i is %s \r\n';
for i = 1:nBeta
    fprintf(fileID,formatSpec,i,data.varNamesX{i});
end
fclose(fileID);

end

