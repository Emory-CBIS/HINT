%% Script to generate the test data. Included here in case more data needs to be 
% generated at some point

% Get the output directory for any generated data
spath = which('generate_test_data.m');
[testdatapathtemp, ~, ~] = fileparts(spath);
testdatapath = fullfile(testdatapathtemp, 'testdata');

resourcepath = fullfile(testdatapathtemp, 'testresources');

%% Test Data 1

% Used in: 
% dataInputTest.m Test 1

N = 30; % 10 Subjects
T = 100; % 30 Time points measured
Q = 3; % 3 Components
P = 2; % 2 Covariate Effects
J = 3; % 3 Visits

% Some True Settings
sigma1sq = 0.5;
sigma2sq = [0.1; 0.5; 0.7];

% Specification of the MoG terms. First column is the active 
% setting and second is the background noise
mu3z      = [6.0 0.0; 6.5 0.0; 6.0 0.0];
sigmasq3z = [0.5 0.1; 0.4 0.1; 0.3 0.1];

% This is the raw beta magnitude at each visit (row) and covariate
% (column). Note that this will not be the strength of the final map, which
% is scaled by multiplying by the magnitude of the region mask (which is
% scaled between 0 and 1)
beta_magnitude = [1.0 1.0; 1.0 1.0; 1.0 1.0];
alpha_magnitude = [1.0; 1.0; 1.0];

% List of the NIFTI files used to generate the different ICs
S0files = {fullfile(resourcepath, 'DMN_Population_Level.nii');
    fullfile(resourcepath, 'SM_Population_Level.nii');
    fullfile(resourcepath, 'VIS_Population_Level.nii')};

Beta1files = {fullfile(resourcepath, 'DMN_PCC_1.nii');
    fullfile(resourcepath, 'SM_ROI1_0.nii');
    fullfile(resourcepath, 'VIS_Sphere1_0.nii')};

Beta2files = {fullfile(resourcepath, 'DMN_LAG_1.nii');
    fullfile(resourcepath, 'SM_ROI2_0.nii');
    fullfile(resourcepath, 'VIS_Sphere2_0.nii')};

% This is visit fixed effects. Going to use the s0 maps but with a much
% weaker intensity (adjusted after loading them in);
Alphafiles = {fullfile(resourcepath, 'DMN_Population_Level.nii');
    fullfile(resourcepath, 'SM_Population_Level.nii');
    fullfile(resourcepath, 'VIS_Population_Level.nii')};

% Setup mask and data size information
brainfile = fullfile(resourcepath, 'brain.nii');
brain = load_nii(brainfile);
[dx, dy, dz] = size(brain.img);
validVoxels = find(brain.img ~= 0.0);
V = length(validVoxels);

% Storage for the true maps
s0    = zeros(Q, V);
beta1 = zeros(Q, V, J);
beta2 = zeros(Q, V, J);
alpha = zeros(Q, V, J);

% Generate the maps using the specified settings
for q = 1:Q
    
    s0q = load_nii(S0files{q});
    s0qvec = s0q.img(validVoxels);
    inactive_voxels = find(s0qvec == 0);
    s0qvec = (s0qvec * mu3z(q, 1)) + normrnd(0, sqrt(sigmasq3z(q, 1)), V, 1);
    s0qvec(inactive_voxels) = normrnd(0, sqrt(sigmasq3z(q, 1)), length(inactive_voxels), 1);
    s0(q, :) = s0qvec;
    
    for j = 1:J
        beta1q = load_nii(Beta1files{q});
        beta1qvec = beta1q.img(validVoxels);
        beta1qvec = beta1qvec * beta_magnitude(q, 1) * j;
        beta1(q, :, j) = beta1qvec;

        beta2q = load_nii(Beta2files{q});
        beta2qvec = beta2q.img(validVoxels);
        beta2qvec = beta2qvec * beta_magnitude(q, 2) * j;
        beta2(q, :, j) = beta2qvec;

        alphaq = load_nii(Alphafiles{q});
        alphaqvec = alphaq.img(validVoxels) / 5;
        alphaqvec = alphaqvec * alpha_magnitude(q, 1) * j;
        alpha(q, :, j) = alphaqvec;
    end
    
end

% Setup covariate table (some initialized to missing)
Ages = 1:N; % something simple for testing
Ages = Ages - mean(Ages);
GroupNum = [ones(N/2, 1); 2*ones(N/2, 1)];
Groups = ["grpA"; "grpB"];
variableNames = ["Visit1", "Visit2", "Visit3", "Age", "Group"];
variableTypes = ["string", "string", "string", "double", "string"];
covariates = table('Size', [N, J + P],...
    'VariableNames', variableNames,...
    'VariableTypes', variableTypes);

niipath = testdatapath;

% Create variance estimate files
varEstDim = P + (P+1)*(J-1);
betaVarEst = ones( varEstDim, varEstDim, dx, dy, dz );
varEst2 = ones( varEstDim, varEstDim, dx, dy, dz );

% Save the data 
% TODO create correct version of variance at each voxel using the true
% sigmas
fname1 = fullfile(testdatapath, 'testdata_longitudinal_set1_varianceest_IC1.mat');
save(fname1, 'betaVarEst')

% Create a mask file for this longitudinal example
maskf = fullfile(niipath, 'testdata_longitudinal_set1_mask.nii');
mask = zeros(dx, dy, dz);
mask(validVoxels) = 1;
masknii = make_nii(mask);
save_nii(masknii, maskf);

% Create some known error terms which we will reuse (so that we can check
% correctness of results)
level1errors = normrnd(0.0, sqrt(sigma1sq), [Q, V, N, J]);
level2errors = zeros(Q, V, N, J);
for q = 1:Q
    level2errors(q, :, :, :) = normrnd(0.0, sqrt(sigma2sq(q)), [V, N, J]);
end

% Create the data for each subject
Ytilde = zeros(Q, V, N, J);
for i = 1:N
    covariates(i, J+1) = {Ages(i)};
    covariates(i, J+2) = {Groups( GroupNum(i) )};
    cov_ref = 0;
    if strcmp(covariates(i, J+2), 'grpB') 
        cov_ref = 1;
    end
    for j = 1:J
        
        % File path information for this subject
        fname = fullfile(niipath, ['testdata_longitudinal_set1_subj_', num2str(i), '_visit', num2str(j), '.nii']);
        covariates(i, j) = {fname};
        
        % Create this subject's mixing matrix
        Aij_temp = rand(Q, Q);
        Aij = Aij_temp*real(inv(Aij_temp'*Aij_temp)^(1/2));
        
        % Create this subjects IC maps (Sij)
        % recall: beta(:, 1, :, :) is ALPHA
        Sij = s0 +...
            squeeze(alpha(:, :, j)) +...
            squeeze(covariates{i, 4}*beta1(:, :, j)) + squeeze(cov_ref*beta2(:, :, j)) +...
            level2errors(:, :, i, j);
        
        % Generate the prewhitened time series for this subject
        Yij = Aij * Sij + level1errors(:, :, i, j);
        Ytilde(:, :, i, j) = Yij;
        
        % Generate the T x V non-prewhitened time series for this subject
        TxT_Covariance = wishrnd(eye(T), T + 1);
        Ytemp_TxV = mvnrnd(zeros(T, 1), TxT_Covariance, V)';
        % Get a corresponding whitening matrix
        [X_tilde_all, ] = remmean(Ytemp_TxV);
        % run pca on X_tilde_all`
        [U_incr, D_incr] = pcamat(X_tilde_all);
        % sort the eig values, IX:index
        U_q = U_incr(:,(size(U_incr,2)-(3*Q)+1):size(U_incr,2));
        D_q = diag(D_incr((size(U_incr,2)-(3*Q)+1):size(U_incr,2),...
            (size(U_incr,2)-(3*Q)+1):size(U_incr,2)));
        % Use these eigenvalues to create the whitening and dewhitening
        % matrices
        whitemat = diag((D_q - sigma1sq).^(-1/2)) * U_q';
        dewhitemat = U_q * diag((D_q-sigma1sq) .^ (1/2));
        % Now get the TxV data from simulated QxV data
        Yraw = dewhitemat * [Yij; normrnd(0.0, 0.001, 2*Q, V) ];
        
        % Convert Yraw into a 4D dataset
        Ynii = zeros(dx, dy, dz, T);
        Ytemp = zeros(dx, dy, dz);
        for t = 1:T
            Ytemp(validVoxels) = Yraw(t, :);
            Ynii(:, :, :, t) = Ytemp ;
        end
        toynii = make_nii(Ynii);
        
        % Create a toy nifti file (we are just testing ability to load)
        save_nii(toynii, fname);
        
    end
end

% Store the csv file for loading
writetable(covariates, fullfile(niipath, ['testdata_longitudinal_set1_covariates.csv']));

% Save relevant test quantities/parameters/etc
fname = fullfile(niipath, ['testdata_longitudinal_set1_truevals.mat']);
save(fname, 'Ytilde', 'sigma1sq', 'sigma2sq', 's0', 'beta1', 'beta2', 'alpha');










%% Test Data 2 - Cross-sectional data

N = 10;
J = 1;
T = 30;
Ages = 1:10; % something simple for testing
GroupNum = [ones(5, 1); 2*ones(5, 1)];
Groups = ["grpA"; "grpB"];
variableNames = ["Filepaths", "Age", "Group"];
variableTypes = ["string", "double", "string"];
covariates = table('Size', [N, J + 2],...
    'VariableNames', variableNames,...
    'VariableTypes', variableTypes);

niipath = testdatapath;

% Create a mask file for the toy example
maskf = fullfile(niipath, 'testdata_crosssectional_set1_mask.nii');
mask = zeros(10, 10, 5);
mask(2:9, 2:9, 2:4) = 1;
masknii = make_nii(mask);
save_nii(masknii, maskf);

for i = 1:N
        fname = fullfile(niipath, ['testdata_crosssectional_set1_subj_', num2str(i), '.nii']);
        covariates(i, 1) = {fname};
        % Create a toy nifti file (we are just testing ability to load)
        toynifti = rand(10, 10, 5, T) .* mask;
        toynii = make_nii(toynifti);
        save_nii(toynii, fname);
    covariates(i, J+1) = {Ages(i)};
    covariates(i, J+2) = {Groups( GroupNum(i) )};
end

% Store the csv file for loading
writetable(covariates, fullfile(niipath, 'testdata_crosssectional_set1_covariates.csv'));









