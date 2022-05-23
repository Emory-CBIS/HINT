function isValid = verify_runinfo_valid(filePath)
%verify_runinfo_valid Checks to make sure that runinfo file specified by
%user contains all required fields.

        
    fileContents = who('-file', filePath);

    isValid = 1;
    
    variableList = {'prefix', 'q', 'time_num', 'X', 'validVoxels',...
        'niifiles', 'maskf', 'covfile', 'numPCA', 'outfolder', 'covariates',...
        'covTypes', 'varNamesX', 'interactions', 'interactionsBase',...
        'thetaStar', 'YtildeStar', 'CmatStar', 'beta0Star', 'voxSize',...
        'N', 'qold', 'varInModel', 'nVisit', 'varInCovFile',...
        'referenceGroupNumber'};

    for iVar = 1:length(variableList)
        compareTo = variableList{iVar};
        if ~ismember(compareTo, fileContents) 
            isValid = 0;
            disp( ['Runinfo file missing: ' compareTo] )
        end
    end


end

