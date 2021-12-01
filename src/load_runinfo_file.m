function [runinfo, varargout] = load_runinfo_file(runinfoFileName)
%load_runinfo_file - load a saved runinfo file, updating the datastructure

loadErr = 0;

% Check that file exists
if ~isfile(runinfoFileName)
    loadErr = 1;
    error( ['File: ', runinfoFileName, ' does not exist. Stopping load.'] )
end

runinfo = load(runinfoFileName);

%% Space is reserved to check for fields or do any extra work required for
% different forms of hcica

if runinfo.nVisit > 1
    runinfo.analysisType = 'Longitudinal';
else
    runinfo.analysisType = 'Cross-Sectional';
end

varargout{1} = loadErr;

end

