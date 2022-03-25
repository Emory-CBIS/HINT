function [InputData] = parse_and_format_input_files(maskf, covf, nVisit, studyType)
% returns InputData - a struct with covariate and niifiles information        

        InputData = struct();
        InputData.nVisit = nVisit;
        
        % NOTE - this is actually repeated if using the GUI version.
        [niifiles, ~, ~] = verify_niifiles_valid(covf, InputData.nVisit, 1);
        
        nfile = length(niifiles);
        
        % Match up each covariate with its row in the covariate
        % file
        InputData.covariateTable = readtable(covf, 'Delimiter', ',');
        InputData.covariates = InputData.covariateTable.Properties.VariableNames;
        InputData.referenceGroupNumber = ones(1,...
            length(InputData.covariates) - InputData.nVisit + 1);

        %% Extend the covariate table by repeating the
        % covariates for each subject nVisit times
        ncov = length(InputData.covariates) - InputData.nVisit;
        cellCov = {nfile, ncov + 1};
        subjindex = 0;
        for iSubj = 1:(nfile/InputData.nVisit)
            for iVisit = 1:InputData.nVisit
                subjindex = subjindex + 1;
                cellCov(subjindex, 1) = niifiles(subjindex);
                for icov = 1:ncov
                    cellCov{subjindex, icov+1} = InputData.covariateTable{iSubj, InputData.nVisit+icov};
                end
            end
        end

        % Finalize into a new table
        newTable = cell2table(cellCov);
        % Update the structures
        InputData.covariates = InputData.covariates(InputData.nVisit:length(InputData.covariates));
        InputData.covariates{1} = 'file';
        % update the column names of the new table and add it
        % to data
        newTable.Properties.VariableNames = InputData.covariates;
        InputData.covariateTable = newTable;

        tempcov = InputData.covariateTable;
        InputData.niifiles = niifiles;
        % Get rid of the subject part of the data frame
        InputData.covariates = tempcov(:, 2:width(tempcov));
        InputData.covariates.Properties.VariableNames =...
            InputData.covariateTable.Properties.VariableNames(2:length(InputData.covariateTable.Properties.VariableNames));

        % Create variables tracking whether or not the
        % covariate is to be included in the hc-ICA model
        InputData.varInCovFile = ones( width(tempcov) - 1, 1);
        InputData.varInModel = ones( width(tempcov) - 1, 1);

        % Identify categorical and continuous covariates
        InputData.covTypes = auto_identify_covariate_types(InputData.covariates);

        % Reference cell code based on covTypes, user can
        % change these types in model specification later
        [ InputData.X, InputData.varNamesX, InputData.interactions ] = ref_cell_code( InputData.covariates,...
            InputData.covTypes, InputData.varInModel,...
            0, zeros(0, length(InputData.covTypes)), 0, InputData.referenceGroupNumber  );

        % Create the (empty) interactions matrix
        [~, nCol] = size(InputData.X);
        InputData.interactions = zeros(0, nCol);
        InputData.interactionsBase = zeros(0, length(InputData.covTypes));

        % Load the first data file and get its size.
        image = load_nii(niifiles{1});
        [m,n,l,k] = size(image.img);

        % load the mask file.
%         if(~isempty(maskf))
%             mask = load_nii(maskf);
%             validVoxels = find(mask.img == 1);
%         else
%             validVoxels = find(ones(m,n,l) == 1);
%         end
        [mask, validVoxels, V] = load_mask(maskf);
        disp(['Identified ', num2str(V), ' voxels in brain mask.'])
        %nValidVoxel = length(validVoxels);

        % Store the relevant information
        InputData.covf = covf;
        InputData.maskf = maskf;
        InputData.time_num = k;
        InputData.N = nfile / InputData.nVisit;
        InputData.validVoxels = validVoxels;
        InputData.voxSize = size(mask.img);
        InputData.dataLoaded = 1;
        InputData.studyType = studyType;
end