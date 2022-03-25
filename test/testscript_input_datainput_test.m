spath = which('generate_test_data.m');
[testdatapathtemp, ~, ~] = fileparts(spath);
testdatapath = fullfile(testdatapathtemp, 'testdata');

%
% Test 1: Longitudinal with 3 visits, 2 covariates (1 cont, 1 dis)
%
% depends on: testdata_longitudinal_set1

% Setup the correct results
Test1Correct = struct();
Test1Correct.nVisit=3;
Test1Correct.niifiles = fullfile(testdatapath,...
    strcat(strtrim(cellstr(strcat( num2str(repelem(1:10, 1, 3)', 'testdata_longitudinal_set1_subj_%d')))),...
    '_visit', num2str(repmat(1:3, [1, 10])'), '.nii')');

% Actual input to HINT
covf = fullfile(testdatapath, 'testdata_longitudinal_set1_covariates.csv');
maskf = fullfile(testdatapath, 'testdata_longitudinal_set1_mask.nii');
nVisit = 3;
TestResult = parse_and_format_input_files(maskf, covf, nVisit);

%% Test 1A
assert( Test1Correct.nVisit == TestResult.nVisit )
%% Test 1B
assert( all(cellfun(@isequal, TestResult.niifiles, Test1Correct.niifiles)) )







% Test 2: Cross Sectional Data with 2 covariates (1 cont, 1 dis)
Test2Correct = struct();
Test2Correct.nVisit=1;
Test2Correct.niifiles = fullfile(testdatapath,...
    strcat(strtrim(cellstr(strcat( num2str(repelem(1:10, 1, 1)', 'subj_%d')))),...
    '.nii')');

fullfile(testdatapath, 'mask.nii');
covf = fullfile(testdatapath, 'test3_crosssec_covariates.csv');
maskf = fullfile(testdatapath, 'mask.nii');
nVisit = 1;
TestResult = parse_and_format_input_files(maskf, covf, nVisit);

%% Test 2A
assert( Test2Correct.nVisit == TestResult.nVisit )

%% Test 2B
assert( all(cellfun(@isequal, TestResult.niifiles, Test2Correct.niifiles)) )




