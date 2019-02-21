function [ theta, beta, grpSig, s0_agg ] = ObtainInitialGuess( subjfl,...
    maskfl, prefix, outdir, numpc, N, q, X, Ytilde, hcicadir,...
    nVisit )
%ObtainInitialGuess - Function use GIFT to obtain an initial guess for the
%EM algorithm. The initial guess procedure changes depending on the number
%of visits, which nVisit=1 resulting in the initial guess procedure for a
%cross-sectional study and nVisit > 1 resulting in the initial guess
%procedure for a longitudinal study. The number of visits does not affect
%the GIFT portion of the analysis.
%
%Syntax:  [ theta, beta, grpSig, s0_agg ] =
%ObtainInitialGuess( subjfl, maskfl, prefix, outdir, data, numpc, imageDim, N, T, q, X,
%        Ytilde, hcicadir, nVisit)
%
%Inputs:
%    subjfl   - Path to each subject's nii file
%    maskfl   - Path to the binary mask file
%    prefix   - Prefixed attached to all files for this analysis
%    outdir   - Output directory for this analysis
%    data     - Original data loaded from the nii files
%    numpc    - Number of principal components
%    imageDim - Dimension of the data
%    N        - Number of subjects
%    T        - Number of time points
%    q        - Number of ICs
%    hcicadir - Path to hcica folder
%    nVisit   - Number of visits per subject (1 for cross-sectional)
%
%See also: reEstimateIniGuess.m, InitialGuessGift.m

%% Open a waitbar
h = waitbar(0,'Generating Initial Guess Using GIFT...');
steps = 10;

V = size(Ytilde, 2);
p = size(X, 2);

%% Run the GIFT toolbox
InitialGuessGift( subjfl, maskfl, prefix, outdir, numpc, N, q, hcicadir, nVisit)

% Update the waitbar
waitbar(8/10)

%% Run the initial guess estimation based on the GIFT output

if nVisit > 1
    [theta, beta, grpSig, s0_agg] = InitialGuessLICA(prefix, Ytilde, N, q,...
        V, p, X, nVisit, maskfl);
else
    [theta, beta, grpSig, s0_agg] = InitialGuessCrossSectional(prefix, Ytilde, N, q,...
        V, p, X, nVisit, maskfl);
end

% Update the waitbar
waitbar(1)
close(h)

% Cleanup the GIFT output files
move_iniguess_to_folder(outdir, prefix)

cd(hcicadir);

end

