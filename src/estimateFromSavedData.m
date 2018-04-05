function [ varargout ] = estimateFromSavedData( datLocation, algSelection, maxiter, epsilon1, epsilon2 )
%estimateFromSavedData - Function to run the hc-ICA algorithm using saved
%analysis data. To get the saved data in the proper form, conduct the
%preprocessing steps in the first tab of the GUI and then click 'save and continue.'
%The runinfo .mat file will be in the output folder.
%
%Syntax:  [ ~ ] = estimateFromSavedData( subjfl, maskfl, prefix, outdir, data, numpc, imageDim, N, T, q, X, Ytilde, hcicadir)
%
%Inputs:
%    datLocation    - filepath to the runinfo.mat file for analysis
%    algSelection   - 'exact' or 'approx'
%    maxiter        - maximum number of EM algorithm iterations
%    epsilon1       - stopping criteria for theta (suggest 0.01)
%    epsilon2       - stopping criteria for beta maps (suggest 0.1)
%
%See also: reEstimateIniGuess.m runGIFT.m

load(datLocation);

if strcmp(algSelection, 'approxVec_Experimental')
    [theta_est, beta_est, z_mode, subICmean, subICvar, grpICmean, ...
    grpICvar, success, G_z_dict, finalIter] = CoeffpICA_EM (YtildeStar, X, thetaStar, ...
    CmatStar, beta0Star, maxiter, epsilon1, epsilon2, 'approxVec_Experimental', outfolder, prefix,1);
end

iterpath = [outfolder '/' prefix '_iter' num2str(finalIter) '_parameter_estimates'];
compileIterResults( outfolder, datLocation, iterpath, maskf );

end

