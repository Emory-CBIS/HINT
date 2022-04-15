function compile_iteration_results( outdir, iterpath,...
    runinfopath, maskf, varargin )
% compile_iteration_results - Function to take the iteration results file that is
% saved at each completed EM iteration and generate all output files needed
% for the display viewer.
%
% Inputs: Inputs should be entered in the following order (all done within
% other functions)
%
%   outdir   - the output directory where the files will be stored
%   runinfopath - path to the runinfo file for this analysis
%   iterpath - path to the EM iteration output file
%   maskpath - path to the mask used for the analysis
%   covpath  - path to the covariate file used for the analysis
%   isGUI    - 1 if called from GUI, 0 otherwise
%   includeSubjLevelEstimates - 0 or 1
%
% Last Modified: April 2022
% Author: Joshua Lukemire

isGUI = 0;
includeSubjLevelEstimates = 0;
prefix = '';
while ~isempty(varargin)
    switch lower(varargin{1})
        
        case 'isgui'
            selection = varargin{2};
            if selection == 1
                isGUI = 1;
            elseif selection == 0
                isGUI = 0;
            end
            
        case 'includesubjlevelestimates'
            selection = varargin{2};
            if selection == 1
                includeSubjLevelEstimates = 1;
            elseif selection == 0
                includeSubjLevelEstimates = 0;
            end
            
        case 'prefix'
            prefix = varargin{2};
            
        otherwise
            disp([varargin{1} 'is not a recognized argument.'])
    end
    
    varargin(1:2) = [];
    
end

if isGUI
    waitSave = waitbar(0, 'Please wait while EM results are compiled.');
end

% Load the results
iterResults = load( iterpath );

% Load the runinfo file
runinfo = load(runinfopath);

% Load the mask file
[mask, validVoxels, V, maskOriginator] = load_mask(maskf);

% Size of the brain
brainSize = size(mask.img);

%waitSave = waitbar(0, 'Compiling Results - Subject Level IC Estimates');

% Save a file with the subject level IC map information - this is only done
% if requested and if it was saved. For some larger analyses the subject
% level estimates are not included by default.
if includeSubjLevelEstimates == 1
    
    if isGUI
        waitbar(0.1, waitSave, 'Outputting subject level estimates.');
    end
    
    subjFilename = [outdir '/' prefix '_subject_IC_estimates.mat'];
    if isfield(iterResults,'subICmean')
        subICmean    = iterResults.subICmean;
        save(subjFilename, 'subICmean');
    else
        disp('Subject level estimates not included in iteration file.')
        disp('Not outputting subject level estimates.')
    end
    
end

nIC = size(iterResults.grpICmean, 1);
for i=1:nIC
    
    if isGUI
        waitbar(0.1 + 0.9 * (i/(nIC)), waitSave,...
            ['Compiling Results for IC ', num2str(i)]);
    end
        
    % Save the S0 map
    gfilename = [prefix '_S0_IC_' num2str(i) '.nii'];
    nmat = nan(brainSize);
    nmat(validVoxels) = iterResults.grpICmean(i,:);
    nii = make_nii(nmat);
    save_nii(nii,strcat(outdir,'/',gfilename));
    
    % Create aggregate IC maps
    if isfield(iterResults,'subICmean')
        nullAggregateMatrix = nan(brainSize);
        nullAggregateMatrix(validVoxels) = 0.0;
        for j=1:runinfo.N
            nullAggregateMatrix(validVoxels) = nullAggregateMatrix(validVoxels) +...
                1/runinfo.N * squeeze(iterResults.subICmean(i,j,:));
        end
        gfilename = [prefix '_aggregateIC_' num2str(i) '.nii'];
        nii = make_nii(nullAggregateMatrix);
        save_nii(nii,strcat(outdir,'/',gfilename));
    end
    
    % Create IC maps for the betas.
    if runinfo.nVisit == 1
        for k=1:size(iterResults.beta,1)
            bfilename = [prefix '_beta_cov' num2str(k) '_IC' num2str(i) '.nii'];
            nmat = nan(brainSize);
            nmat(validVoxels) = iterResults.beta(k,i,:);
            nii = make_nii(nmat);
            save_nii(nii,strcat(outdir,'/',bfilename));
        end
    else
        for iVisit = 1:runinfo.nVisit
            for k = 1:size(iterResults.beta_est,2) - 1
                % Setup the filename
                bfilename = [prefix '_beta_cov' num2str(k) '_IC'...
                    num2str(i) '_visit' num2str(iVisit) '.nii'];
                % Save the map
                nmat = nan(vxl);
                nmat(locs) = iterResults.beta_est(i, k+1, :, iVisit);
                nii = make_nii(nmat);
                save_nii(nii,strcat(path,bfilename));
            end
            % Save the random intercept for this visit
            ri_filename = [prefix '_visit_effect' '_IC'...
                    num2str(i) '_visit' num2str(iVisit) '.nii'];
            % Save the map
            nmat = nan(vxl);
            nmat(locs) = iterResults.beta_est(i, 1, :, iVisit);
            nii = make_nii(nmat);
            save_nii(nii,strcat(path,ri_filename));
        end
    end
   
end

waitbar(1, waitSave, 'Estimating variance of covariate effects. This may take a minute.')

% Calculate the variance estimates for the beta maps
if runinfo.nVisit == 1
    
    varianceEstimate = VarEst_hcica(iterResults.theta, iterResults.beta, runinfo.X,...
        iterResults.z_mode, runinfo.YtildeStar, iterResults.G_z_dict, brainSize,...
        validVoxels, prefix, outdir);
        
else
    
    % this is old version
%     theory_var = var_est_longitudinal(data.theta_est, data.beta_est, data.X,...
%         data.z_mode, data.YtildeStar, data.G_z_dict, data.voxSize,...
%         data.validVoxels, prefix, data.outpath);
%         data.theoretical_beta_se_est = theory_var;
        
    varianceEstimate = VarEstLICAExact(iterResults.theta, iterResults.beta, runinfo.X,...
        iterResults.PostProbs, runinfo.YtildeStar, brainSize,...
        validVoxels, prefix, outdir);
        
end

% Last, edit the runinfo file with the new prefix and the new
% mask file path
copyfile(runinfopath, [outdir '/' prefix '_runinfo.mat']);

if isvalid(waitSave)
    close(waitSave);
end

% Write out a text file to the output directory with what covariate
% each beta map corresponds to
nBeta = size(runinfo.X, 2);
fname = [outdir '/' prefix '_Beta_File_List'];
fileID = fopen(fname,'w');
formatSpec = 'Beta %4.2i is %s \r\n';
for i = 1:nBeta
    fprintf(fileID,formatSpec,i, runinfo.varNamesX{i});
end
fclose(fileID);

%disp('Result Compilation Complete')

%msgbox('Result Compilation Complete')

end

