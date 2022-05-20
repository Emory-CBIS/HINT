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
P = 3; % 2 Covariates
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

% The categorical factor has three levels, so include 2 versions of
% covariate, a base effect and a smaller one corresponding to the treatment
% group - no difference in visual group
Beta2files = {fullfile(resourcepath, 'DMN_LAG_1.nii'), fullfile(resourcepath, 'DMN_LAG_2.nii');
    fullfile(resourcepath, 'SM_ROI2_0.nii'), fullfile(resourcepath, 'SM_ROI2_1.nii');
    fullfile(resourcepath, 'VIS_Sphere2_0.nii'), fullfile(resourcepath, 'VIS_Sphere2_0.nii')};

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
beta2_1 = zeros(Q, V, J);
beta2_2 = zeros(Q, V, J);
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

        beta2q = load_nii(Beta2files{q, 1});
        beta2qvec = beta2q.img(validVoxels);
        beta2qvec = beta2qvec * beta_magnitude(q, 2) * j;
        beta2_1(q, :, j) = beta2qvec;
        
        beta2q = load_nii(Beta2files{q, 2});
        beta2qvec = beta2q.img(validVoxels);
        beta2qvec = beta2qvec * beta_magnitude(q, 2) * j;
        beta2_2(q, :, j) = beta2qvec;

        alphaq = load_nii(Alphafiles{q});
        alphaqvec = alphaq.img(validVoxels) / 5;
        alphaqvec = alphaqvec * alpha_magnitude(q, 1) * j;
        alpha(q, :, j) = alphaqvec;
    end
    
end

% Setup covariate table (some initialized to missing)
Ages = unifrnd(0, 2, N, 1); % something simple for testing
Ages = (Ages - mean(Ages)); % center
Ages = (Ages) / max(abs(Ages)); % scale

% No treatment, traditional treatment, new treatment
GroupNum = [ones(N/2, 1); 1 + ones(7, 1); 2 + ones(8, 1)];
Groups = ["Control"; "Traditional"; "Novel"];
% Medicine type - no effect
medNum = repmat(1:3, [1, 10])';
medTypes = ["Capsule"; "Injection"; "Powder"];
variableNames = ["Visit1", "Visit2", "Visit3", "Age", "Group", "MedType"];
variableTypes = ["string", "string", "string", "double", "string", "string"];
covariates = table('Size', [N, J + P],...
    'VariableNames', variableNames,...
    'VariableTypes', variableTypes);

niipath = testdatapath;

if not(isfolder(fullfile(testdatapath, 'Medication')))
    mkdir(fullfile(testdatapath, 'Medication'))
end


%% Create the effects coded covariate matrix
covariatesTemp = table('Size', [N, P],...
    'VariableNames', variableNames(J+1:end),...
    'VariableTypes', variableTypes(J+1:end));
for i = 1:N
    covariatesTemp(i, 1) = {Ages(i)};
    covariatesTemp(i, 2) = {Groups( GroupNum(i) )};
    covariatesTemp(i, 3) = {medTypes( medNum(i) )};
end
covariateNamesTemp = covariatesTemp.Properties.VariableNames;
covTypes           = [0 1 1];
effectsCodingsEncoders = cell(1, length(covTypes));
for p = 1:length(covTypes)
    effectsCodingsEncoders{p} = generate_effects_coding(covariatesTemp{:, p});
end
% Create the corresponding model matrix
weighted = false;
unitScale = 1;
cm = zeros(length(covariateNamesTemp), 1);
sds = zeros(length(covariateNamesTemp), 1);
for p = 1:length(covariateNamesTemp)
    if covTypes(p) == 0
        cm(p) = mean(covariatesTemp{:, p});
        sds(p) = std(covariatesTemp{:, p});
    end
end
covariateMeans = cm;
covariateSDevs = sds;
[X, varNamesX] = generate_model_matrix(covTypes, [1 1 1],...
    covariatesTemp, effectsCodingsEncoders, unitScale, weighted,...
    zeros(0, P), covariateNamesTemp, covariateMeans, covariateSDevs);

ti = zeros(1, P);
ti(1, 1:2) = 1;
[X, varNamesX] = generate_model_matrix(covTypes, [1 1 1],...
    covariatesTemp, effectsCodingsEncoders, unitScale, weighted,...
    ti, covariateNamesTemp, covariateMeans, covariateSDevs);



% Create variance estimate files
varEstDim = P + (P+1)*(J-1);
betaVarEst = ones( varEstDim, varEstDim, dx, dy, dz );
varEst2 = ones( varEstDim, varEstDim, dx, dy, dz );

% Save the data 
% TODO create correct version of variance at each voxel using the true
% sigmas
fname1 = fullfile(testdatapath, 'Medication', 'medication_data_varianceest_IC1.mat');
save(fname1, 'betaVarEst')

% Create a mask file for this longitudinal example
maskf = fullfile(niipath, 'Medication', 'medication_data_mask.nii');
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
    covariates(i, J+3) = {medTypes( medNum(i) )};
    for j = 1:J
        
        vis2 = -1;
        vis3 = -1;
        if j == 2
            vis2 = 1; vis3 = 0;
        elseif j == 2
            vis2 = 0; vis3 = 1;
        end
        
        % File path information for this subject
        fname = fullfile(niipath, 'Medication', ['medication_data_subj_', num2str(i), '_visit', num2str(j), '.nii']);
        covariates(i, j) = {fname};
        
        % Create this subject's mixing matrix
        Aij_temp = rand(Q, Q);
        Aij = Aij_temp*real(inv(Aij_temp'*Aij_temp)^(1/2));
        
        % Create this subjects IC maps (Sij)
        Sij = s0 + vis2*squeeze(alpha(:, :, 2)) + vis3*squeeze(alpha(:, :, 3)) + ...
            squeeze(X(i, 1)*beta1(:, :, j)) + squeeze(X(i, 2)*beta2_1(:, :, j)) + squeeze(X(i, 3)*beta2_2(:, :, j)) + ...
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
writetable(covariates, fullfile(niipath, 'Medication', ['medication_data_covariates.csv']));

% Save relevant test quantities/parameters/etc
fname = fullfile(niipath, 'Medication', ['medication_data_truevals.mat']);
save(fname, 'Ytilde', 'sigma1sq', 'sigma2sq', 's0', 'beta1', 'beta2_1','beta2_2', 'alpha');

























%% Test Data 2 - Cross-sectional data




N = 30; % 10 Subjects
T = 100; % 30 Time points measured
Q = 3; % 3 Components
P = 2; % 2 Covariate Effects

% Some True Settings
sigma1sq = 0.5;
sigma2sq = [0.1; 0.5; 0.7];

% Specification of the MoG terms. First column is the active 
% setting and second is the background noise
mu3z      = [3.0 0.0; 3.5 0.0; 3.0 0.0];
sigmasq3z = [0.5 0.1; 0.4 0.1; 0.3 0.1];

% This is the raw beta magnitude at each visit (row) and covariate
% (column). Note that this will not be the strength of the final map, which
% is scaled by multiplying by the magnitude of the region mask (which is
% scaled between 0 and 1)
beta_magnitude = [2.0 -2.0 -2.0; 2.0 -2.0 -2.0; 2.0 -2.0 -2.0];

% List of the NIFTI files used to generate the different ICs
S0files = {fullfile(resourcepath, 'DMN_Population_Level.nii');
    fullfile(resourcepath, 'FPR_Population_Level.nii');
    fullfile(resourcepath, 'VIS_Population_Level.nii')};

Beta1files = {fullfile(resourcepath, 'DMN_PCC_1.nii');
    fullfile(resourcepath, 'FPR_posterior_0.nii');
    fullfile(resourcepath, 'VIS_Sphere1_0.nii')};

Beta2files = {fullfile(resourcepath, 'DMN_LAG_1.nii');
    fullfile(resourcepath, 'FPR_frontal_1.nii');
    fullfile(resourcepath, 'VIS_Sphere2_0.nii')};

% Interaction Term
Beta3files = {fullfile(resourcepath, 'DMN_LAG_1.nii');
    fullfile(resourcepath, 'FPR_frontal_inv_1.nii');
    fullfile(resourcepath, 'VIS_Sphere2_0.nii')};

% Setup mask and data size information
brainfile = fullfile(resourcepath, 'brain.nii');
brain = load_nii(brainfile);
[dx, dy, dz] = size(brain.img);
validVoxels = find(brain.img ~= 0.0);
V = length(validVoxels);

% Storage for the true maps
s0    = zeros(Q, V);
beta1 = zeros(Q, V);
beta2 = zeros(Q, V);
beta3 = zeros(Q, V);

% Generate the maps using the specified settings
for q = 1:Q
    
    s0q = load_nii(S0files{q});
    s0qvec = s0q.img(validVoxels);
    inactive_voxels = find(s0qvec == 0);
    s0qvec = (s0qvec * mu3z(q, 1)) + normrnd(0, sqrt(sigmasq3z(q, 1)), V, 1);
    s0qvec(inactive_voxels) = normrnd(0, sqrt(sigmasq3z(q, 1)), length(inactive_voxels), 1);
    s0(q, :) = s0qvec;
    
    beta1q = load_nii(Beta1files{q});
    beta1qvec = beta1q.img(validVoxels);
    beta1qvec = beta1qvec * beta_magnitude(q, 1);
    beta1(q, :) = beta1qvec;

    beta2q = load_nii(Beta2files{q});
    beta2qvec = beta2q.img(validVoxels);
    beta2qvec = beta2qvec * beta_magnitude(q, 2);
    beta2(q, :) = beta2qvec;
    
    beta3q = load_nii(Beta3files{q});
    beta3qvec = beta3q.img(validVoxels);
    beta3qvec = beta3qvec * beta_magnitude(q, 3);
    beta3(q, :) = beta3qvec;

end

% Setup covariate table (some initialized to missing)
Age = round(unifrnd(50, 80, N, 1), 2); 
GroupNum = [ones(N/2, 1); 2*ones(N/2, 1)];
Groups = ["HC"; "AD"];
variableNames = ["File", "Age", "Group"];
variableTypes = ["string", "double", "string"];
covariates = table('Size', [N, P + 1],...
    'VariableNames', variableNames,...
    'VariableTypes', variableTypes);

niipath = testdatapath;

if not(isfolder(fullfile(testdatapath, 'Alzheimers')))
    mkdir(fullfile(testdatapath, 'Alzheimers'))
end

%% Create the effects coded covariate matrix
covariatesTemp = table('Size', [N, P],...
    'VariableNames', variableNames(2:end),...
    'VariableTypes', variableTypes(2:end));
for i = 1:N
    covariatesTemp(i, 1) = {Age(i)};
    covariatesTemp(i, 2) = {Groups( GroupNum(i) )};
end
covariateNamesTemp = covariatesTemp.Properties.VariableNames;
covTypes           = [0 1];
effectsCodingsEncoders = cell(1, length(covTypes));
for p = 1:length(covTypes)
    effectsCodingsEncoders{p} = generate_effects_coding(covariatesTemp{:, p});
end
% Create the corresponding model matrix
weighted = false;
unitScale = 1;
cm = zeros(length(covariateNamesTemp), 1);
sds = zeros(length(covariateNamesTemp), 1);
for p = 1:length(covariateNamesTemp)
    if covTypes(p) == 0
        cm(p) = mean(covariatesTemp{:, p});
        sds(p) = std(covariatesTemp{:, p});
    end
end
covariateMeans = cm;
covariateSDevs = sds;
[X, varNamesX] = generate_model_matrix(covTypes, [1 1],...
    covariatesTemp, effectsCodingsEncoders, unitScale, weighted,...
    ones(1, 2), covariateNamesTemp, covariateMeans, covariateSDevs);

% Create variance estimate files
varEstDim = P;
betaVarEst = ones( varEstDim, varEstDim, dx, dy, dz );
varEst2 = ones( varEstDim, varEstDim, dx, dy, dz );

% Create a mask file for this longitudinal example
maskf = fullfile(niipath, 'Alzheimers', 'Alzheimers_mask.nii');
mask = zeros(dx, dy, dz);
mask(validVoxels) = 1;
masknii = make_nii(mask);
save_nii(masknii, maskf);

% Create some known error terms which we will reuse (so that we can check
% correctness of results)
level1errors = normrnd(0.0, sqrt(sigma1sq), [Q, V, N]);
level2errors = zeros(Q, V, N);
for q = 1:Q
    level2errors(q, :, :) = normrnd(0.0, sqrt(sigma2sq(q)), [V, N]);
end

% Create the data for each subject
Ytilde = zeros(Q, V, N);
for i = 1:N
    covariates(i, 1+1) = {Age(i)};
    covariates(i, 1+2) = {Groups( GroupNum(i) )};
        
    % File path information for this subject
    fname = fullfile(niipath, 'Alzheimers', ['Alzheimers_subj_', num2str(i), '.nii']);
    covariates(i, 1) = {fname};

    % Create this subject's mixing matrix
    Aij_temp = rand(Q, Q);
    Aij = Aij_temp*real(inv(Aij_temp'*Aij_temp)^(1/2));

    % Create this subjects IC maps (Sij)
    Sij = s0 +...
        squeeze(X(i, 1)*beta1(:, :)) + (squeeze(X(i, 2) > 0)*beta2(:, :)) + X(i, 3) * (X(i, 2) > 0) *beta3(:, :) + ...
        level2errors(:, :, i);

    % Generate the prewhitened time series for this subject
    Yij = Aij * Sij + level1errors(:, :, i);
    Ytilde(:, :, i) = Yij;

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

% Store the csv file for loading
writetable(covariates, fullfile(niipath, 'Alzheimers', 'Alzheimers_covariates.csv'));

% Save relevant test quantities/parameters/etc
fname = fullfile(niipath, 'Alzheimers', 'Alzheimers_truevals.mat');
save(fname, 'Ytilde', 'sigma1sq', 'sigma2sq', 's0', 'beta1', 'beta2');

