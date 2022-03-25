% Script to cleanup all of the test data once the tests have been run

% Get the output directory for any generated data
spath = which('generate_test_data.m');
[testdatapathtemp, ~, ~] = fileparts(spath);
testdatapath = fullfile(testdatapathtemp, 'testdata');

%% Remove all data from longitudinal set 1
all_files = dir( fullfile(testdatapath, 'testdata_longitudinal_set1*') );
for ifile = 1:length(all_files)
    delete( fullfile(all_files(ifile).folder, all_files(ifile).name) );
end

%% Remove all data from crosssectional set 1
all_files = dir( fullfile(testdatapath, 'testdata_crosssectional_set1*') );
for ifile = 1:length(all_files)
    delete( fullfile(all_files(ifile).folder, all_files(ifile).name) );
end