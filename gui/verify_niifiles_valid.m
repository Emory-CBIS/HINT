function [ niifiles, missingFiles, duplicateFiles ] = verify_niifiles_valid( covfl, nVisit, isGUI )
%verify_niifiles_valid - function to load the user-specific covariate file
%and check the first nVisit columsn for nifti filepaths. The script then
%loops through the paths and checks for missing files and duplicate files. 
%
%Author - Joshua Lukemire
%Last Modified - Feb 6 2019

%% Setup the output

% Cell array of filepaths to the nifti files. Ordered by subject
% (ie Subj 1 visit 1, Subj 1 visit 2, Subj 2 visit 1, ...)
niifiles = {};

% Cell array of any missing nifti files. Same order as niifiles.
missingFiles = {};

% Cell array of any duplicate nifti files.
duplicateFiles = {};

% Load the covariate file
covariateTable = readtable(covfl, 'Delimiter', ',');
covariates = covariateTable.Properties.VariableNames;

%% First verify that the file names end in .nii. If the files do not, then 
% add to the end of the file names

[~, ~, ext] = fileparts(char(covariateTable{1,1}));
if isempty(ext)
    file_extension_provided = 0;
else
    file_extension_provided = 1;
end

% Get the number of files, number of columns
[nFile, nCol] = size(covariateTable);
nCovariate = nCol - nVisit;

% If the file extension was not provided, then we want to go through and
% add .nii to the end of each of the files for each column 1, ..., nVisit
if ~file_extension_provided
    for iCol = 1:nVisit
        for iFile = 1:nFile
            covariateTable{iFile, iCol} = strcat(covariateTable{iFile, iCol}, '.nii');
        end
    end
end

%% Check for the existance of each file and verify that none are duplicates

% Setup a waitbar while everthting loads
wb = waitbar(0,'Please wait while the Nifti files are found...');
incr = 1 / (nFile*nVisit);
currentWaitStatus = 0;

% Loop is in this order so that niifiles will have the structure specified
% above
for iRow = 1:nFile
    
    for iVisit = 1:nVisit
        
        
        % First check if this is a duplicate
        if any(strcmp(niifiles,char(covariateTable{iRow, iVisit})))
            
            currentLength = length(duplicateFiles);
            duplicateFiles{currentLength + 1} = char(covariateTable{iRow, iVisit});
                        
            
        % Case where the file is not a duplicate    
        else
            
            % Now check for file existance
            if exist(char(covariateTable{iRow, iVisit}), 'file') == 2
                % file exists, add it to niifiles
                currentLength = length(niifiles);
                niifiles{currentLength + 1} = char(covariateTable{iRow, iVisit});
            else
                % file does not exist, add it to missingfiles
                currentLength = length(missingFiles);
                missingFiles{currentLength + 1} = char(covariateTable{iRow, iVisit});
            end
            
        end
        
        % Increment the waitbar
        currentWaitStatus = currentWaitStatus + incr;
        waitbar(currentWaitStatus, wb, 'Please wait while the Nifti files are found...');
        
    end
end

% Close the waitbar
close(wb)


end

