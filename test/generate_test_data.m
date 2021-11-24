%% Script to generate the test data. Included here in case more data needs to be 
% generated at some point

% Get the output directory for any generated data
spath = which('generate_test_data.m');
[testdatapath, ~, ~] = fileparts(spath);

%% Test Data 1

% some other variables needed for testing
Q = 2;
% 3 Covariate Effects, 2 Visits
P = 3; J = 2;

% Brain with 5, 20 x 20 slices
dx = 20; dy = 20; dz = 5;
S03D = zeros(dx, dy, dz, Q);

validVoxels = find(~isnan( zeros(dx, dy, dz) ));
V = length(validVoxels);

% Going to have 2 ICs, each contained in a 10 x 10 square
S03D(1:10 , 1:10 , 2, 1) = 3;   % IC 1 in slice 2
S03D(11:20, 11:20, 4, 2) = 3; % IC 2 in slice 4

% Get the 2d version of S0
S0 = zeros(Q, V);
temp1 = S03D(:, :, :, 1);
S0(1, :) = temp1(validVoxels); 
temp2 = S03D(:, :, :, 2);
S0(2, :) = temp2(validVoxels); 

% Generate the covariate effect maps
beta = zeros(Q, P+1, V, J);

% Covariates Effects for IC 1
beta(1, 2, :, 1) = randn(1, V) .* S0(1, :);
beta(1, 2, :, 2) = squeeze((beta(1, 2, :, 1) + 1))' .* S0(1, :);

beta(1, 3, :, 1) = randn(1, V) .* S0(1, :);
beta(1, 3, :, 2) = squeeze((beta(1, 3, :, 1) + 1))' .* S0(1, :);

beta(1, 4, :, 1) = randn(1, V) .* S0(1, :);
beta(1, 4, :, 2) = squeeze((beta(1, 4, :, 1) + 1))' .* S0(1, :);

% alpha only non-zero at visit 2

% Covariates Effects for IC 2
beta(2, 1, :, 2) = randn(1, V) .* S0(2, :);

beta(2, 2, :, 1) = randn(1, V) .* S0(2, :);
beta(2, 2, :, 2) = squeeze((beta(2, 2, :, 1) + 1))' .* S0(2, :);

beta(2, 3, :, 1) = randn(1, V) .* S0(2, :);
beta(2, 3, :, 2) = squeeze((beta(2, 3, :, 1) + 1))' .* S0(2, :);

beta(2, 4, :, 1) = randn(1, V) .* S0(2, :);
beta(2, 4, :, 2) = squeeze((beta(2, 4, :, 1) + 1))' .* S0(2, :);

% Create variance estimate files
varEstDim = P + (P+1)*(J-1);
betaVarEst = ones( varEstDim, varEstDim, dx, dy, dz );
varEst2 = ones( varEstDim, varEstDim, dx, dy, dz );

% Save the data 
fname1 = fullfile(testdatapath, 'demoData1VarianceEstimate_IC1.mat');
save(fname1, 'betaVarEst')






%% Test Data 2 

% Functions of interest: 
% parse_and_format_input_files.m

% This test dataset just generates a set of niifiles, a covariate file, and
% a mask for a longitudinal study.
% This is for testing functions related to reading in data. 

N = 10;
J = 3;
T = 30;
Ages = 1:10; % something simple for testing
GroupNum = [ones(5, 1); 2*ones(5, 1)];
Groups = ["grpA"; "grpB"];
variableNames = ["Visit1", "Visit2", "Visit3", "Age", "Group"];
variableTypes = ["string", "string", "string", "double", "string"];
covariates = table('Size', [N, J + 2],...
    'VariableNames', variableNames,...
    'VariableTypes', variableTypes);

niipath = testdatapath;

% Create a mask file for the toy example
maskf = fullfile(niipath, 'mask.nii');
mask = zeros(10, 10, 5);
mask(2:9, 2:9, 2:4) = 1;
masknii = make_nii(mask);
save_nii(masknii, maskf);

for i = 1:N
    for j = 1:J
        fname = fullfile(niipath, ['subj_', num2str(i), '_visit', num2str(j), '.nii']);
        covariates(i, j) = {fname};
                
        % Create a toy nifti file (we are just testing ability to load)
        toynifti = rand(10, 10, 5, T) .* mask;
        toynii = make_nii(toynifti);
        save_nii(toynii, fname);
        
    end
    covariates(i, J+1) = {Ages(i)};
    covariates(i, J+2) = {Groups( GroupNum(i) )};
end

% Store the csv file for loading
writetable(covariates, fullfile(niipath, ['test2_covariates.csv']));











