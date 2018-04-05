function [ niifiles, finalCov ] = matchCovariatesToNiifiles( fls, cov, matchOn )
% matchCovariatesToNiifiles - Function to match the order of the input
% niifiles to to the order of the data presented in the covariates file.
% Any data mismatches are reported to the user upon completion.
%
% Syntax: [niifiles, X] = matchCovariatesToNiifiles( niifiles, cov, matchOn )
%
% Inputs:
%   
%   fls         - array of subject data filepaths
%   cov         - covariate file
%   matchOn     - Fileparts location where the subject name is stored
%
% Outputs:
%   niifiles    - sorted list of nifti files
%   finalCov    - the final design matrix
%
% See also: refCellCode, auto_identify_covariate_types

% Get the dimensions of the data
[~, nNiiInput] = size(fls);
[nCovInput, nCov] = size(cov);

% Create empty objects to store new covariate file and niifiles
niifiles = cell(1, nNiiInput);
finalCov = cell(nNiiInput, nCov);

% Create new objects
iNewRow = 1;
for iRow = 1:nCovInput
    for iNii = 1:nNiiInput
        % Get the file parts that may contain the subject ID
        splitFile = strsplit( fls{iNii}, '/' );
        testVals = splitFile(matchOn);
        % Test if any are equal to the current row of the covariate file
        isMatch = sum(~cellfun(@isempty,regexp(testVals, string(cov{iRow, 1}))));
        if isMatch
            % It is possible the match is wrong, eg subject1 instead of
            % subject 10. Check for this issue here
            matchIndex = find(~cellfun(@isempty,regexp(testVals,string(cov{iRow, 1}))));
            for iMatch = 1:length(matchIndex)
                candVal = testVals( matchIndex(iMatch) );
                splitCandVal = strsplit(candVal{1}, string(cov{iRow, 1}));
                % check the first part of the 'post' part
                if ~isempty(splitCandVal{2})
                    firstChar = splitCandVal{2}(1);
                    if (all(ismember(firstChar, '0123456789dD')))
                        isMatch = 0;
                    end
                end
            end
            
            if isMatch
                niifiles{1, iNewRow} = fls{iNii};
                finalCov(iNewRow,:) = table2cell(cov(iRow, :));
                iNewRow = iNewRow+1;
                iNii=nNiiInput;
            end
            
        end
    end
end

% Drop the empty cells at the end
niifiles = niifiles(~cellfun('isempty', niifiles));
finalCov = finalCov(~cellfun('isempty', finalCov(:,1)), :);


%%% Now check for niifiles missing a covariate row
niiMissingCov = setdiff(fls, niifiles);
%%% Finally check for covariates missing an nii file
covMissingNii = setdiff( string(cellstr(string(cov{:,1}))), string(finalCov(:,1)));

if ~isempty(niiMissingCov)
    disp('Warning, the following niifiles did not have a matching row in the covariate file:')
    disp(niiMissingCov)
end
if ~isempty(covMissingNii)
    disp('Warning, the following covariate rows did not have a matching nii file:')
    disp(covMissingNii)
end

finalCov = cell2table(finalCov);

end

