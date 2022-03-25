function [ output_args ] = compileIterResults( outdir, runinfopath,...
    iterpath, maskpath )
% compileIterResults - Function to take the iteration results file that is
% saved at each completed EM iteration and generate all output files needed
% for the display viewer.
%
% Inputs: Inputs should be entered in the following order (all done within
% other functions)
%
%   outdir - the output directory where the files will be stored
%   runinfopath - path to the runinfo file for this analysis
%   iterpath - path to the EM iteration output file
%   maskpath - path to the mask used for the analysis
%   covpath - path to the covariate file used for the analysis
%
% Author: Joshua Lukemire

display('Compiling iteration results...')

% Load the results
iterResults = load( iterpath );

% Load the runinfo file
runinfo = load(runinfopath);
prefix = runinfo.prefix;

% Load the mask file
%maskf = maskpath;
%mask = load_nii(maskf);
%validVoxels = find(mask.img == 1);
[mask, validVoxels, V] = load_mask(maskf);

nValidVoxel = length(validVoxels);
voxSize = size(mask.img);

vxl = voxSize;
locs = validVoxels;

waitSave = waitbar(0, 'Compiling Results - Subject Level IC Estimates');

% Save a file with the subject level IC map information
subjFilename = [outdir '/' prefix '_subject_IC_estimates.mat'];
subICmean = iterResults.subICmean;
save(subjFilename, 'subICmean');

for i=1:runinfo.q
    
    waitbar(i/(runinfo.q+1), waitSave, ['Compiling Results for IC ', num2str(i)])
    
    % Save the S0 map
    gfilename = [prefix '_S0_IC_' num2str(i) '.nii'];
    nmat = nan(vxl);
    nmat(locs) = iterResults.grpICmean(i,:);
    nii = make_nii(nmat);
    save_nii(nii,strcat(outdir,'/',gfilename));
    
    % Create aggregate IC maps
    nullAggregateMatrix = nan(vxl);
    nullAggregateMatrix(locs) = 0.0;
    for j=1:runinfo.N
        nullAggregateMatrix(locs) = nullAggregateMatrix(locs) +...
            1/runinfo.N * squeeze(iterResults.subICmean(i,j,:));
    end
    gfilename = [prefix '_aggregateIC_' num2str(i) '.nii'];
    nii = make_nii(nullAggregateMatrix);
    save_nii(nii,strcat(outdir,'/',gfilename));
    
    % Create IC maps for the betas.
    for k=1:size(iterResults.beta,1)
        bfilename = [prefix '_beta_cov' num2str(k) '_IC' num2str(i) '.nii'];
        nmat = nan(vxl);
        nmat(locs) = iterResults.beta(k,i,:);
        nii = make_nii(nmat);
        save_nii(nii,strcat(outdir,'/',bfilename));
    end
   
end

waitbar(1, waitSave, 'Estimating variance of covariate effects. This may take a minute.')

% Calculate the variance estimates for the beta maps
theory_var = VarEst_hcica(iterResults.theta, iterResults.beta,...
    runinfo.X, iterResults.z_mode, runinfo.YtildeStar,...
    iterResults.G_z_dict, voxSize,...
    validVoxels, prefix, outdir);

% Last, make a copy of the runinfo file in the output directory if the file
% is not already there
if exist([outdir '/' prefix '_runinfo.mat']) == 0
    copyfile(runinfopath, [outdir '/' prefix '_runinfo.mat']);
end

close(waitSave);

% Move the user to the view results tab
set(findobj('Tag','tabGroup'),'SelectedTab',findobj('Tag','tab3'));

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

disp('Result Compilation Complete')

msgbox('Result Compilation Complete')

end

