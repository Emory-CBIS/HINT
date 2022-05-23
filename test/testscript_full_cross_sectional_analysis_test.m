spath = which('generate_test_data.m');
[testdatapathtemp, ~, ~] = fileparts(spath);
testdatapath = fullfile(testdatapathtemp, 'testdata');

% Alzheimers
alzPath = fullfile(testdatapath, 'Alzheimers');

%% Test 1
covf1 = fullfile(alzPath, 'Alzheimers_covariates.csv');
maskf1 = fullfile(alzPath, 'Alzheimers_mask.nii');
outdir1 = fullfile(testdatapath, 'out', 'alzTest1');

hint_analysis(outdir1, covf1, maskf1, 'test2', 'Cross-Sectional', 1, 3, 'maxit', 5);