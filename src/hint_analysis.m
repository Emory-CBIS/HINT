function hint_analysis(outputDir, covFile, maskFile, prefix,...
    studyType, nVisit, Q, varargin)
%hint_analysis function to run the entire HINT analysis. 
%
% Arguments:
% outputDir: directory where output should be stored
% covFile: filepath to the csv file containing the nifti paths and
% covariate values
% maskFile: filepath to the nifti file containing the mask
% prefix: the prefix for the analysis
% studyType: Longitudinal or Cross-Sectional
% nVisit: integer number of visits
% Optional Arguments:
% numPCA: number of principal components. Default is 2 times Q;
% maxit: maximum number of iterations for the EM algorithm. Default is 100.
% epsilon1: relative change in model parameters excluding covariate effects
% required for EM convergence. Default is 0.001
% epsilon2: relative change in covariate effects required for EM convergence.
% Default is 0.1
% 
%

%% Parse input
parser = inputParser;
validIntegerPosNum = @(x) (rem(x,1) == 0) && (x > 0);
validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);
addRequired(parser, 'outputDir');
addRequired(parser, 'covFile');
addRequired(parser, 'maskFile');
addRequired(parser, 'prefix');
addRequired(parser, 'studyType');
addRequired(parser, 'nVisit');
addRequired(parser, 'Q');
addOptional(parser, 'maxit', 100, validIntegerPosNum);
addOptional(parser, 'epsilon1', 0.001, validScalarPosNum);
addOptional(parser, 'epsilon2', 0.1, validScalarPosNum);
addOptional(parser, 'numPCA', 2*Q, validIntegerPosNum);
parse(parser, outputDir, covFile, maskFile, prefix,...
    studyType, nVisit, Q, varargin{:});

analysisData = struct();
analysisData.q = parser.Results.Q;
analysisData.studyType = parser.Results.studyType;
analysisData.nVisit = parser.Results.nVisit;
analysisData.prefix = parser.Results.prefix;
analysisData.numPCA = parser.Results.numPCA;
analysisData.outdir = parser.Results.outputDir;
analysisData.outpath = parser.Results.outputDir;
analysisData.maxit = parser.Results.maxit;
analysisData.epsilon1 = parser.Results.epsilon1;
analysisData.epsilon2 = parser.Results.epsilon2;

%% Create output directory if it does not already exist
disp('Checking if output directory exists...')
if isfolder(analysisData.outdir)
    disp('output directory already exists.')
else
    disp('output directory does not exsit. Creating...')
    mkdir(analysisData.outdir)
    disp('done.')
end

%% Load covariates, mask, and input nifti files
inputDataParsed = parse_and_format_input_files(parser.Results.maskFile,...
    parser.Results.covFile, parser.Results.nVisit, parser.Results.studyType);
analysisData = add_all_structure_fields(analysisData, inputDataParsed);

%% Preprocess and obtain initial guess for S0
[analysisData.YtildeStar, analysisData.S0Init] = initial_guess_preproc_fastica(analysisData.niifiles,...
                analysisData.validVoxels, analysisData.numPCA, analysisData.q,...
                analysisData.time_num);

%% Obtain initial guess for remaining model parameters
switch analysisData.studyType
    case 'Cross-Sectional'
        [ analysisData.thetaStar, analysisData.beta0Star, popAvgComponents ] =...
            initial_guess_crosssectional(analysisData.YtildeStar,...
            analysisData.S0Init, analysisData.X);
    case 'Longitudinal'
        [ analysisData.thetaStar, analysisData.beta0Star, popAvgComponents ] =...
            initial_guess_longitudinal(analysisData.YtildeStar,...
            analysisData.S0Init, analysisData.X, analysisData.nVisit);
    otherwise
        disp('WARNING - unrecognized study type')
end  

analysisPrefix = save_analysis_preparation( analysisData, analysisData.prefix );
fname = fullfile(analysisData.outpath, [analysisPrefix '_runinfo.mat']);
analysisData.qstar = analysisData.q;
analysisData.CmatStar = 0;
save_runinfo_file(fname, analysisPrefix, analysisData)

%% Run EM algorithm
[analysisData.theta_est, analysisData.beta_est, analysisData.z_mode, ...
                    analysisData.subICmean, analysisData.subICvar, analysisData.grpICmean, ...
                    analysisData.grpICvar, analysisData.success,...
                    analysisData.G_z_dict, analysisData.PostProbs, analysisData.finalIter] = ...
                    CoeffpICA_EM (analysisData.YtildeStar, analysisData.X, analysisData.thetaStar, ...
                    0, analysisData.beta0Star, analysisData.maxit, ...
                    analysisData.epsilon1, analysisData.epsilon2, 'approxVec_Experimental',...
                    analysisData.outpath, analysisData.prefix, 1, analysisData.studyType);

%% Save results

save_analysis_results(analysisPrefix, analysisData);



end