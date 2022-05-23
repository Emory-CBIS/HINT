function [runinfo, varargout] = load_runinfo_file(runinfoFileName)
%load_runinfo_file - load a saved runinfo file, updating the datastructure

loadErr = 0;

% Check that file exists
if ~isfile(runinfoFileName)
    loadErr = 1;
    error( ['File: ', runinfoFileName, ' does not exist. Stopping load.'] )
end

runinfo = load(runinfoFileName);

% Resolve a naming inconsistency
runinfo.outpath = runinfo.outfolder;
runinfo.qstar = runinfo.q;
runinfo.covf = runinfo.covfile;
runinfo.effectsCodingsEncoders = runinfo.variableCodingInformation.effectsCodingsEncoders;
runinfo.weighted = runinfo.variableCodingInformation.weighted;
runinfo.unitScale = runinfo.variableCodingInformation.unitScale;

if runinfo.nVisit > 1
    runinfo.studyType = 'Longitudinal';
else
    runinfo.studyType = 'Cross-Sectional';
end

%% Space is reserved to check for fields or do any extra work required for
% different forms of hcica

if runinfo.nVisit > 1
    runinfo.analysisType = 'Longitudinal';
else
    runinfo.analysisType = 'Cross-Sectional';
end

varargout{1} = loadErr;

end

