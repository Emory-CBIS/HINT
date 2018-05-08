function [ theta, beta, grpSig, s0_agg ] = runGIFT( subjfl, maskfl, prefix, outdir, numpc, N, q, X, Ytilde, hcicadir)
%runGIFT - Function to estimate the initial values for hc-ICA
%This function uses the GIFT toolbox to generate initial values for the
%hc-ICA algorithm. These values are also used to allow the user to select
%ICs of interest and ICs that they would like to remove from the data.
%
%Syntax:  [ theta, beta, grpSig, s0_agg ] =
%runGIFT( subjfl, maskfl, prefix, outdir, data, numpc, imageDim, N, T, q, X, Ytilde, hcicadir)
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
%    X        - Covariate matrix
%    Ytilde   - Pre-processed data
%    hcicadir - Path to hcica folder
%
%Outputs:
%    theta    - Object containing initial estimates for the EM algorithm
%    beta     - Regression coefficients
%    grpSig   - Group level initial IC estimates, used for viewing ICs
%    s0_agg   - Aggregate version of grpSig from GIFT
%
%See also: reEstimateIniGuess.m

    h = waitbar(0,'Generating Initial Guess Using GIFT...');
    steps = 10;

    % The first step is to create a .m file with all the information GIFT needs
    % for the analysis
    mask = load_nii(maskfl);
    fname = [outdir '/' prefix 'run_info_for_gift.m'];
    fid = fopen(fname,'w');
    fprintf(fid,'%s \n', 'dataSelectionMethod = 2;');
    
    % create a string with the selected subjects
    fprintf(fid,'%s', 'selectedSubjects = {''');
    for iSubj = 1:(N-1)
        % convert to just the file name
        [~,name,~] = fileparts(subjfl{iSubj});
        fprintf(fid, name);
        fprintf(fid, ''',''');
    end
    [~,name,~] = fileparts(subjfl{N});
    fprintf(fid, name);
    fprintf(fid,'%s \n', '''}');
    
    % Print the number of sessions
    fprintf(fid, '%s \n', 'numOfSess = 1;');
    
    % Print the file path information
    for i = 1:N
        % convert to just the file name
        [pathstr,name,ext] = fileparts(subjfl{i});
        string_label = [name '_s1 = {'''];
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

    % Increment the waitbar
    waitbar(1/10);
    
    %addpath(genpath([hcicadir 'GroupICATv3.0a/icatb']));
    addpath(genpath(hcicadir));
    % Run GIFT to get the initial estimates
    icatb_batch_file_run(fname);

    waitbar(8/10)
    
    % Now need to use the results from GIFT

    % previous step will end in the output directory
    % Load data needed to get the initial values
    V = sum(mask.img(:), 'omitnan');
    % some masks have 0s for non-voxels, other have nans. Try both
    validVoxels = find(~isnan(mask.img));
    if ( numel(validVoxels) == numel(mask.img) )
        validVoxels = find((mask.img) == 1); %#ok<NASGU>
    end

    % Create empty matrix to store the s_i
    S_i = zeros( q, V, N );
    for i=1:N
        dat = load([prefix '_ica_br' num2str(i) '.mat']);
        S_i(:,:,i) = dat.compSet.ic;
    end

    % Estimation of the betas and S_0
    p = size(X,2);
    beta = zeros(p,q,V);
    Xint = [ ones(N,1) X ];
    S0 = zeros(q, V);
    epsilon2temp = zeros(q, V, N);
    for v = 1:V
        estimate = (Xint'*Xint)^(-1) * Xint' *squeeze(S_i(:,v,:))';
        beta(:,:,v) = estimate(2:(p+1), :);
        S0(:,v) = estimate(1,:)';
        epsilon2temp(:,v,:) = squeeze(S_i(:,v,:)) - (Xint * estimate)';
    end
    sigma2_sq = var(reshape(epsilon2temp, [q,V*N]), 0, 2);

    % Get the subject level mixing matrices
    A = zeros(q,q,N);
    for i = 1:N
        cS_i = S_i(:,:,i); sInd = q*(i-1)+1; eInd = i*q;
        A_tempi = (cS_i * cS_i')^(-1) * cS_i * Ytilde(sInd:eInd,:)';
        Asym = A_tempi';
        A(:,:,i) = Asym*real(inv(Asym'*Asym)^(1/2));
    end
   
    waitbar(9/10)

    % Calculate sigma1_squared (subject level error)
    errors = zeros(q, V, N);
    for i=1:N
        sInd = q*(i-1)+1; eInd = i*q;
        errors(:,:,i) = Ytilde(sInd:eInd,:) - A(:,:,i)*S_i(:,:,i);
    end
    sigma1_sq = var(reshape(errors, [1, q*V*N]));

    % Initial Guess: fit a Gaussian mixture
    m=2;

    for j =1:q
        GMModel = fitgmdist(S0(j,:)' ,m+1);
        id = find(abs(GMModel.mu) == max(abs(GMModel.mu)));
        theta.miu3(1+m*(j-1): m*j, 1) =[GMModel.mu(id), 0];
        idzero = abs(GMModel.mu) == min(abs(GMModel.mu));
        theta.sigma3_sq(1+m*(j-1): m*j, 1) = [GMModel.Sigma(id), GMModel.Sigma(idzero)];
        theta.pi(1+m*(j-1): m*j, 1)  =[GMModel.PComponents(id), 1-GMModel.PComponents(id)];
    end


    % create the final variables to return (beta already created)
    theta.sigma1_sq = sigma1_sq;
    theta.sigma2_sq = sigma2_sq;
    theta.A = A;
    grpSig = S0;

    % Save the aggregate map for IC selection; these are only used for IC
    % selection
    agg_IC = load_nii([prefix '_agg__component_ica_.nii']);
    s0_agg = zeros(q, V);
    for c = 1:q
        tempVals = reshape(agg_IC.img(:,:,:,c), [1, numel(agg_IC.img(:,:,:,c))]);
        s0_agg(c,:) = reshape(tempVals(mask.img==1), [1, V]);
    end
    
    % Update the waitbar
    waitbar(1)
    close(h)
    
    move_iniguess_to_folder(outdir, prefix)

    cd(hcicadir);

end

