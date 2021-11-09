function [ varargout ] = InitialGuessGift( subjfl, maskfl, prefix,...
    outdir, numpc, N, q, hcicadir, nVisit)
%runGIFT - Function to take care of the GIFT aspect of the initial
%guess. This function is called by ObtainInitialGuess and is used prior to
%the final initial guess function, which depends on whether a
%cross-sectional or LICA analysis is being performed.
%
%Syntax:  [ theta, beta, grpSig, s0_agg ] =
%runGIFT( subjfl, maskfl, prefix, outdir, data, numpc, imageDim, N, T, q, X,
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
%See also: reEstimateIniGuess.m

%% IF LICA, need to re-order the data for the initial guess
T = nVisit - 1;

if nVisit > 1
filecopy = subjfl;

% First step is to create a .m file with all the information
iter = 1;
for j = 0:T
    seqvals = (j+1):nVisit:(N*nVisit);
    for i = 1:N
        subjfl{iter} = filecopy{seqvals(i)} ; 
        iter = iter +1;
    end
end
end


%% GIFT
    % The first step is to create a .m file with all the information GIFT needs
    % for the analysis
    mask = load_nii(maskfl);
    fname = [outdir '/' prefix 'run_info_for_gift.m'];
    fid = fopen(fname,'w');
    fprintf(fid,'%s \n', 'dataSelectionMethod = 2;');
    
    % create a string with the selected subjects
    fprintf(fid,'%s', 'selectedSubjects = {''');
    for iSubj = 1:(N*nVisit-1)
        % convert to just the file name
        [~,name,~] = fileparts(subjfl{iSubj});
        fprintf(fid, ['subj' num2str(iSubj)]);
        fprintf(fid, ''',''');
    end
    [~,name,~] = fileparts(subjfl{N*nVisit});
    fprintf(fid, ['subj' num2str(N*nVisit)]);
    fprintf(fid,'%s \n', '''}');
    
    % Print the number of sessions
    fprintf(fid, '%s \n', 'numOfSess = 1;');
    
    % Print the file path information
    for i = 1:N*nVisit
        % convert to just the file name
        [pathstr,name,ext] = fileparts(subjfl{i});
        string_label = ['subj' num2str(i) '_s1 = {'''];
        fprintf(fid, '%s%s%s%s%s%s%s\n', string_label, pathstr,'''', ',', '''', [name ext], '''};');
    end   
    
    % Don't give gift a design matrix
    fprintf(fid, '%s \n', 'keyword_designMatrix =''no'';');
    
    % output information
    fprintf(fid, '%s%s%s%s \n', 'outputDir = ''',outdir, ''';' );
    fprintf(fid, '%s%s%s%s \n', 'prefix = ''',prefix, ''';' );
    fprintf(fid, '%s%s%s%s \n', 'maskFile = ''',maskfl, ''';' );
    % Data reduction information
    fprintf(fid, '%s \n', 'numReductionSteps = 2;');
    fprintf(fid, '%s \n', 'doEstimation = 0;');
    fprintf(fid, '%s%s%s \n', 'numOfPC1 =' , num2str(numpc) , ';' );
    fprintf(fid, '%s%s%s \n', 'numOfPC2 =' , num2str(q) , ';' );
    fprintf(fid, '%s \n', 'scaleType = 0;');
    fprintf(fid, '%s \n', 'algoType = ''Infomax'';');
    
    fclose(fid);
    
    %addpath(genpath([hcicadir 'GroupICATv3.0a/icatb']));
    addpath(genpath(hcicadir));
    % Run GIFT to get the initial estimates
    icatb_batch_file_run(fname);

end

