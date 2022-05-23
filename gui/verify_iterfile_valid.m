function isValid = verify_iterfile_valid(filePath)
%verify_iterfile_valid Checks to make sure that a .mat file specified by
%the user contains the results from a given iteration of the EM algorithm.

        
    fileContents = who('-file', filePath);

    isValid = 1;
    
    variableList = {'theta', 'beta'};

    for iVar = 1:length(variableList)
        compareTo = variableList{iVar};
        if ~ismember(compareTo, fileContents) 
            isValid = 0;
            disp( ['Iteration results file missing: ' compareTo] )
        end
    end


end

