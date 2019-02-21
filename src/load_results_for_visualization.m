function [ vis_q, vis_qstar, vis_outpath, vis_N, vis_covariates, vis_X,...
    vis_covTypes, vis_varNamesX, vis_interactions, vis_varInModel, vis_varInCovFile,...
    vis_referenceGroupNumber, vis_nVisit, prefix ] = load_results_for_visualization( runinfoLoc )
%load_results_for_visualization - function to load the basic results for
%the visualization window.
%see also: main.m, displayResults.m

% Open the waitbar
waitLoad = waitbar(0,'Please wait while the results load');

% Run the runinfo file
tempData = load(runinfoLoc);
waitbar(2/10)

% Add the important parts of the runinfo file to the data object
% for the viewer
vis_q = tempData.q;
waitbar(3/10)
vis_qstar = tempData.q;
waitbar(4/10)
vis_outpath = tempData.outfolder;
waitbar(5/10)
vis_N = size(tempData.X, 1);
waitbar(6/10)
vis_covariates = tempData.covariates;
waitbar(7/10)
vis_X = tempData.X;
waitbar(8/10)
vis_covTypes = tempData.covTypes;
vis_varNamesX = tempData.varNamesX;
waitbar(9/10)
vis_interactions = tempData.interactions;
vis_varInModel = tempData.varInModel;
vis_varInCovFile = tempData.varInCovFile;
vis_referenceGroupNumber = tempData.referenceGroupNumber;
vis_nVisit = tempData.nVisit;
prefix = tempData.prefix;

waitbar(10/10)

% Close the waitbar
close(waitLoad)

end

