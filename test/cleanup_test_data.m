% Script to cleanup all of the test data once the tests have been run

% Get the output directory for any generated data
spath = which('generate_test_data.m');
[testdatapathtemp, ~, ~] = fileparts(spath);
testdatapath = fullfile(testdatapathtemp, 'testdata');

%% Remove all data 
alzdir = fullfile(testdatapath, 'Alzheimers');
if isfolder(alzdir)
    rmdir(alzdir,'s');
end

outdir = fullfile(testdatapath, 'out');
if isfolder(outdir)
    rmdir(outdir, 's');
end


medDir = fullfile(testdatapath, 'Medication');
if isfolder(medDir)
    rmdir(medDir, 's');
end


CogAssessmentDir = fullfile(testdatapath, 'CogAssessment');
if isfolder(CogAssessmentDir)
    rmdir(CogAssessmentDir, 's');
end