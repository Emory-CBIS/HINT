spath = which('generate_test_data.m');
[testdatapath, ~, ~] = fileparts(spath);

% Test 1: Longitudinal with 3 visits, 2 covariates (1 cont, 1 dis)

Test1Correct = struct();
Test1Correct.nVisit=3;
Test1Correct.niifiles = fullfile(testdatapath,...
    strcat(strtrim(cellstr(strcat( num2str(repelem(1:10, 1, 3)', 'subj_%d')))),...
    '_visit', num2str(repmat(1:3, [1, 10])'), '.nii')');


fullfile(testdatapath, 'mask.nii');
covf = fullfile(testdatapath, ['test2_covariates.csv']);
maskf = fullfile(testdatapath, ['mask.nii']);
nVisit = 3;
TestResult = parse_and_format_input_files(maskf, covf, nVisit);

%% Test 1 A
assert( Test1Correct.nVisit == TestResult.nVisit )
%% Test 1 B
assert( all(cellfun(@isequal, TestResult.niifiles, Test1Correct.niifiles)) )
