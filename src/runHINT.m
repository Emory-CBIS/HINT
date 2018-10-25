function [ output_args ] = runHINT( HINTpath, datadir, outdir, q, N, numberOfPCs, maskf,...
    covf, prefix, maxit, epsilon1, epsilon2)
%runHINT - function to run the entire HINT analysis from the command line.
% Author - Joshua Lukemire
%
% Arguments:
%    HINTpath    - path to the HINT toolbox
%    datadir     - filepath to the directory where the data are stored
%    outdir      - filepath to the directory where the output should be stored
%    q           - number of independent components for the analysis
%    N           - number of subjects for the analysis
%    numberOfPCs - number of principal components for tc-gica
%    maskname    - filepath to the mask for the analysis
%    covfilename - filepath to the covariate file for the analysis
%    prefix      - prefix for the output files for the analysis
%    maxit       - maximum number of iterations for the EM algorithm
%    epsilon1    - global convergence parameter. Suggested: 0.001
%    epsilon2    - local convergence parameter. Suggested: 0.1
% 


addpath(genpath(HINTpath))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The rest of this script will load the data, run the analysis and output
% to selected folder

global strMatch;
data = struct();

% Number of independent components
data.q = q;

% Number of iterations
data.maxiter = maxit;


%% Step 1, Loading the data and sorting on covariates 

% Loading the data
niifiles = cell(1, N);
% Get a list of the niifile names
filenames = dir( fullfile(datadir, 'subj*') );
for i = 1:N
    niifiles{1, i} = fullfile(datadir, filenames(i).name );
end

strMatch = length(strsplit(niifiles{1}, '/'));

data.niifiles_raw = niifiles;
data.maskf = maskf;
data.covf = covf;

% Match up each covariate with its row in the covariate
% file
data.covariateTable = readtable(covf);
data.covariates = data.covariateTable.Properties.VariableNames;
data.referenceGroupNumber = ones(1, length(data.covariates));

[data.niifiles, tempcov] = matchCovariatesToNiifiles(data.niifiles_raw,...
    data.covariateTable, strMatch);

% Get rid of the subject part of the data frame
data.covariates = tempcov(:, 2:width(tempcov));
data.covariates.Properties.VariableNames =...
    data.covariateTable.Properties.VariableNames(2:length(data.covariateTable.Properties.VariableNames));

% Create variables tracking whether or not the
% covariate is to be included in the hc-ICA model
data.varInCovFile = ones( width(tempcov) - 1, 1);
data.varInModel = ones( width(tempcov) - 1, 1);

% Identify categorical and continuous covariates
data.covTypes = auto_identify_covariate_types(data.covariates);

% Reference cell code based on covTypes, user can
% change these types in model specification later
[ data.X, data.varNamesX, data.interactions ] = ref_cell_code( data.covariates,...
    data.covTypes, data.varInModel,...
    0, zeros(0, length(data.covTypes)), 0, data.referenceGroupNumber  );

% Create the (empty) interactions matrix
[~, nCol] = size(data.X);
data.interactions = zeros(0, nCol);
data.interactionsBase = zeros(0, length(data.covTypes));

% Load the first data file and get its size.
image = load_nii(niifiles{1});
[m,n,l,k] = size(image.img);

% load the mask file.
if(~isempty(maskf))
    mask = load_nii(maskf);
    validVoxels = find(mask.img == 1);
else
    validVoxels = find(ones(m,n,l) == 1);
end

% Store the relevant information
data.time_num = k;
data.N = N;
data.validVoxels = validVoxels;
data.voxSize = size(mask.img);
data.dataLoaded = 1;

%% Step 2, Preprocessing
data.preprocessingComplete = 0;
data.tempiniGuessObtained = 0;
data.iniGuessComplete = 0;

data.q = q;
[data.Ytilde, data.C_matrix_diag, data.H_matrix_inv,  data.H_matrix, data.deWhite]...
    = PreProcICA(data.niifiles, data.validVoxels, data.q, data.time_num, data.N);

% Update the data structure to know that preprocessing is
% complete
data.preprocessingComplete = 1;
data.tempiniGuessObtained = 0;
data.iniGuessComplete = 0;

%% Step 3, Initial Guess via GIFT
data.iniGuessComplete = 0;
data.tempiniGuessObtained = 0;
global keeplist;
keeplist = ones(data.q,1);
data.prefix = '';
data.outpath = outdir;

% Perform GIFT
% Generate the text parameter file used by GIFT
hcicadir = pwd;
% run GIFT to get the initial guess. This function also outputs nifti files
% with initial values.
[ data.theta0, data.beta0, data.s0, s0_agg ] = runGIFT(data.niifiles, data.maskf, ...
    '',...
    outdir,...
    (numberOfPCs),...
    data.N, data.q, data.X, data.Ytilde, hcicadir);

% Turn all the initial group ICs into nifti files to allow user to
% view and select the ICs for hc-ICA.
template = zeros(data.voxSize);
template = reshape(template, [prod(data.voxSize), 1]);

anat = load_nii(data.maskf);
for ic=1:data.q
    newIC = template;
    newIC(data.validVoxels) = s0_agg(ic, :)';
    IC = reshape(newIC, data.voxSize);
    newIC = make_nii(IC);
    newIC.hdr.hist.originator = anat.hdr.hist.originator;
    fname = fullfile(outdir, ['_iniIC_' num2str(ic) '.nii'] );
    save_nii(newIC, fname, 'IC');
end

%% Do the setup
data.thetaStar = data.theta0;
data.beta0Star = data.beta0;
data.YtildeStar = data.Ytilde;
data.CmatStar = data.C_matrix_diag;
data.iniGuessComplete = 1;

%% Run the em algorithm
data.epsilon1 = epsilon1;
data.epsilon2 = epsilon2;

%% Save and continue portion
% make the results directory
mkdir([data.outpath '/' prefix '_results']);
analysisPrefix = [prefix  '_results/' prefix];

prefix = analysisPrefix;
data.qstar = data.q; % this is a script version thing
q = data.qstar; time_num = data.time_num; X = data.X;       %#ok<NASGU>
validVoxels=data.validVoxels; niifiles = data.niifiles;     %#ok<NASGU>
maskf = data.maskf; covfile = data.covf;                    %#ok<NASGU>
numPCA = num2str(get(findobj('Tag', 'numPCA'), 'String'));  %#ok<NASGU>
outfolder = data.outpath;                                   %#ok<NASGU>
covariates = data.covariates;                               %#ok<NASGU>
covTypes = data.covTypes;                                   %#ok<NASGU>
varNamesX = data.varNamesX;                                 %#ok<NASGU>
interactions = data.interactions  ;                         %#ok<NASGU>
interactionsBase = data.interactionsBase;                   %#ok<NASGU> 
thetaStar = data.thetaStar;                                 %#ok<NASGU>
YtildeStar = data.YtildeStar;                               %#ok<NASGU>
CmatStar = data.CmatStar;                                   %#ok<NASGU>
beta0Star = data.beta0Star;                                 %#ok<NASGU>
voxSize = data.voxSize;                                     %#ok<NASGU>
N = data.N;                                                 %#ok<NASGU>
qold = data.q;                                              %#ok<NASGU> 
varInModel = data.varInModel;%#ok<NASGU> 
varInCovFile = data.varInCovFile;%#ok<NASGU> 
referenceGroupNumber = data.referenceGroupNumber;           %#ok<NASGU>   

save([data.outpath '/' prefix '_runinfo.mat'], 'q', ...
    'time_num', 'X', 'validVoxels', 'niifiles', 'maskf', 'covfile', 'numPCA', ...
    'outfolder', 'prefix', 'covariates', 'covTypes', 'beta0Star', 'CmatStar',...
    'YtildeStar', 'thetaStar', 'voxSize', 'N', 'qold', 'varNamesX',...
    'interactions', 'varInModel', 'varInCovFile', 'interactionsBase',...
    'referenceGroupNumber');


%% Run the approximate EM algorithm.
[data.theta_est, data.beta_est, data.z_mode, ...
    data.subICmean, data.subICvar, data.grpICmean, ...
    data.grpICvar, data.success, data.G_z_dict, data.finalIter] = ...
    CoeffpICA_EM (data.YtildeStar, data.X, data.thetaStar, ...
    data.CmatStar, data.beta0Star, data.maxiter, ...
    data.epsilon1, data.epsilon2, 'approxVec_Experimental', data.outpath, data.prefix,1);

%% Format and save the results
% Create nifti files for the group ICs, the subject specific ICs,
% and the beta effects.
prefix = data.prefix;
vxl = data.voxSize;
locs = data.validVoxels;
path = [data.outpath '/'];

% Save a file with the subject level IC map information
subjFilename = [path analysisPrefix '_subject_IC_estimates.mat'];
subICmean = data.subICmean;
save(subjFilename, 'subICmean');

for i=1:data.qstar

    % Save the S0 map
    gfilename = [analysisPrefix '_S0_IC_' num2str(i) '.nii'];
    nmat = nan(vxl);
    nmat(locs) = data.grpICmean(i,:);
    nii = make_nii(nmat);
    save_nii(nii,strcat(path,gfilename));

    % Create IC maps for the betas.
    for k=1:size(data.beta_est,1)
        bfilename = [analysisPrefix '_beta_cov' num2str(k) '_IC' num2str(i) '.nii'];
        nmat = nan(vxl);
        nmat(locs) = data.beta_est(k,i,:);
        nii = make_nii(nmat);
        save_nii(nii,strcat(path,bfilename));
    end

    % Create aggregate IC maps
    nullAggregateMatrix = nan(vxl);
    nullAggregateMatrix(locs) = 0.0;
    for j=1:data.N
        nullAggregateMatrix(locs) = nullAggregateMatrix(locs) +...
            1/data.N * squeeze(subICmean(i,j,:));
    end
    gfilename = [analysisPrefix '_aggregateIC_' num2str(i) '.nii'];
    nii = make_nii(nullAggregateMatrix);
    save_nii(nii,strcat(data.outpath,'/',gfilename));

end

% Calculate the standard error estimates for the beta maps
theory_var = VarEst_hcica(data.theta_est, data.beta_est, data.X,...
    data.z_mode, data.YtildeStar, data.G_z_dict, data.voxSize,...
    data.validVoxels, analysisPrefix, data.outpath);
data.theoretical_beta_se_est = theory_var;

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

output_args = 1;

disp('HINT ANALYSIS COMPLETE');


end

