spath = which('generate_test_data.m');
[testdatapathtemp, ~, ~] = fileparts(spath);
testdatapath = fullfile(testdatapathtemp, 'testdata');

% Alzheimers
medPath = fullfile(testdatapath, 'Medication');

%% Test 1
covf1 = fullfile(medPath, 'Medication_data_covariates.csv');
maskf1 = fullfile(medPath, 'Medication_data_mask.nii');
outdir1 = fullfile(testdatapath, 'out', 'medicationTest1');

hint_analysis(outdir1, covf1, maskf1, 'longiTest', 'Longitudinal', 3, 3, 'maxit', 5);