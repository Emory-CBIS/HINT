function [ theta, beta, Ytilde, CmatStar ] = reEstimateIniGuess( N, p, outpath, prefix, X, maskf, validVoxels )
%reEstimateIniGuess - Function to re-estimate the initial values for
%selected ICs
%This function is to be run after the user has already generated an initial
%guess using GIFT and selected the ICs that they are interested in using
%hc-ICA for. The function removes the effects of the uninteresting ICs from
%the data and then re-estimates theta and beta as before.
%
%Syntax:  [ theta, beta, Ytilde, CmatStar ] = reEstimateIniGuess( N, p, outpath, prefix, X, maskf, validVoxels )
%
%Inputs:
%    N           - Number of subjects
%    p           - Number of principal components
%    outpath     - Path to the output directory
%    prefix      - prefixed attached to all files for this analysis
%    X           - covariate file
%    maskf       - file path to the binary mask
%    validVoxels - list of voxels that are 1s in the binary mask
%
%Outputs:
%    theta    - Object containing new estimates for the EM algorithm
%    beta     - Regression coefficients
%    Ytilde   - Data with the nusiance ICs contributions removed
%    CmatStar - Identity matrix
%
%See also: main.m,  runGIFT.m

    % Redeclare the list of ICs to be used and calculate the new q
    global keeplist;
    qstar = sum(keeplist);
    
    % Setup the waitbar
    h = waitbar(0,'Re-Estimating Initial Guess For Selected ICs...');
    steps = 10;

    filepath = [outpath '/' prefix '_iniguess/' prefix];

    % Go to the directory with the initial guess output and load
    grplevel = load([filepath '_ica.mat']);
    pca2 = load([filepath '_pca_r2-1.mat']);
    
    % This block of code is Josh's new way. Idea is to rebuild Zbar from
    % the individual subject data to avoid losing the beta effects. To do
    % this, we have to re-create each subjects p x V data set.
    Zbar = zeros( p*N, size(grplevel.icasig, 2) );
    % Get the W matrix, remove the unwanted ic, and find its inverse
    W = grplevel.W;
    %W(:,keeplist == 0) = 0;
    A = pinv(W);
    A(:,keeplist == 0) = 0;
    % For each subject, create the p * V data set
    whiteMatrix = pca2.whiteM;
    %q = size(whiteMatrix,1);
    for iSubj = 1:N
        % get the index from 1 to Np for the whitening Matrix
        ind1 = (iSubj-1)*p+1; ind2 = iSubj*p;
        % Load the subject level weight matrix q x p
        subjDat = load([filepath '_ica_br' num2str(iSubj) '.mat']);
        % Get the corresponding columns of the whitening matrix
        Mi = whiteMatrix(:, ind1:ind2);
        Mi(keeplist == 0,:) = 0;
        Zbar(ind1:ind2, :) = pinv(Mi) * A * subjDat.compSet.ic;
    end    
    
    waitbar(1/steps);

    % Calculate V, lambda, the whitening and dewhitening matrices
    cov_m = icatb_cov(Zbar', 0);
    [V, Lambda] = icatb_eig_symm(cov_m, N*p, 'num_eigs', qstar, ...
        'eig_solver', 'selective', 'create_copy', 0);
    whiteM = sqrtm(Lambda) \ V';
    dewhiteM = V * sqrtm(Lambda);

    % Setup the ICA options GIFT needs as arguments
    sessionInfo = load([filepath '_ica_parameter_info.mat']);
    sessionInfo = sessionInfo.sesInfo;
    ICA_options = sessionInfo.ICA_Options;
    % Update ICA options with the new q
    ICA_options{20} = qstar;
    algorithmName = 'Infomax';
    dataForICA = whiteM * Zbar;
    [~, W, ~, ~] = icatb_icaAlgorithm(algorithmName, dataForICA, ICA_options);
    
    waitbar(2/steps);

    Ytilde = zeros( size(whiteM * Zbar) );
    
    % Josh changed this 3/19
    for iSubj = 1:N
        ind1 = (iSubj-1)*p+1; ind2 = iSubj*p;
        Ytilde( ((iSubj-1)*qstar)+1:(iSubj*qstar),:) = whiteM(:,ind1:ind2) * Zbar(ind1:ind2,:);
    end    

    % Back Reconstruction

    % can use old dewhitening matrix and old whitening matrix?
    icInfo = {eye(size(W, 2), size(W, 2))};
    tcInfo = icInfo;
    numOfPCBeforeCAT = p;
    numOfPrevGroupsInEachNewGroupAfterCAT = N;
    tmpICInfo = cell(1, sum(numOfPrevGroupsInEachNewGroupAfterCAT));
    tmpTCInfo = tmpICInfo;

    endT = 0;  countN = 0;
    groupIndex = 1;
    for nP = 1:numOfPrevGroupsInEachNewGroupAfterCAT(groupIndex)
        countN = countN + 1;
        startT = endT + 1;
        endT = endT + numOfPCBeforeCAT;
        tmpICInfo{countN} = icInfo{groupIndex}*whiteM(:, startT:endT);
        tmpTCInfo{countN} = dewhiteM(startT:endT, :)*tcInfo{groupIndex};
        tmpICInfo{countN} = icInfo{groupIndex}*whiteM(:, startT:endT);
    end
    icInfo = tmpICInfo;
    tcInfo = tmpTCInfo;
    
    waitbar(3/steps);

    mask = load_nii(maskf);

    % Get the back reconstructed subject level estimates
    for iSubj = 1:N
        dat = load([filepath '_pca_r', num2str(1), '-', num2str(iSubj), '.mat']);
        % Supressing warning, variables are created to be saved
        ic = W*icInfo{iSubj}*Zbar( (p*(iSubj-1)+1):p*(iSubj)  ,: ) ; %#ok<NASGU>
        tc = dat.dewhiteM*tcInfo{iSubj}*pinv(W); %#ok<NASGU>
        save([filepath '_reduced_br_subj_' num2str(iSubj)], 'ic', 'tc');
    end        
    
    waitbar(4/steps);
    
    ttt = load([filepath '_reduced_br_subj_' num2str(iSubj)]);
    % XXX delete this, save the subject level ICs
    %emptyImage = zeros(size(mask.img));
    %for i=1:qstar
    %    emptyImage(validVoxels) = ttt.ic(i,:);
    %    new_image = make_nii( emptyImage );
    %    save_nii( new_image, [filepath '_reducedIniGuess_SUBJ_IC_', num2str(i) '.nii'] )
    %end

    % Initial Value Re-Estimation

    [~, p] = size(X);
    V = sum(mask.img(:),'omitnan');
    S_i = zeros(qstar, V, N);   % empty matrix for initial ICs

    for iSubj=1:N
        dat = load([filepath '_reduced_br_subj_' num2str(iSubj)]);
        S_i(:,:,iSubj) = dat.ic;
        emptyImage(validVoxels) = dat.ic(1,:);
        new_image = make_nii( emptyImage );
        save_nii( new_image, [filepath '_reduced_subjlevel_ic1_subj', num2str(iSubj), '.nii'] )
    end
    
    waitbar(5/steps);

    beta = zeros(p,qstar,V);
    Xint = [ ones(N,1) X ];
    S0 = zeros(qstar, V);
    epsilon2temp = zeros(qstar, V, N);
    for v = 1:V
        estimate = (Xint'*Xint)^(-1) * Xint' *squeeze(S_i(:,v,:))';
        beta(:,:,v) = estimate(2:(p+1), :);
        S0(:,v) = estimate(1,:)';
        epsilon2temp(:,v,:) = squeeze(S_i(:,v,:)) - (Xint * estimate)';
    end
    sigma2_sq = var(reshape(epsilon2temp, [qstar,V*N]), 0, 2);
    
    waitbar(6/steps);
    
    % XXX delete this
    %emptyImage = zeros(size(mask.img));
    %for i=1:qstar
    %    for j=1:p
    %        emptyImage(validVoxels) = beta(j,i,:);
    %        new_image = make_nii( emptyImage );
    %        save_nii( new_image, [filepath '_reduced_BETA_ic', num2str(i), '_covariate_', num2str(j), '.nii'] )
    %    end
    %end


    % Get the mixing matrices USING THE NEW YTILDE
    A = zeros(qstar, qstar, N);
    for i = 1:N
        cS_i = S_i(:,:,i); sInd = qstar*(i-1)+1; eInd = i*qstar;
        A_tempi = (cS_i * cS_i')^(-1) * cS_i * Ytilde(sInd:eInd,:)';
        Asym = A_tempi';
        A(:,:,i) = Asym*real(inv(Asym'*Asym)^(1/2));
    end
    
    waitbar(7/steps);

    % Finally calculate sigma1_squared
    qstar = sum(keeplist);
    errors = zeros(qstar, V, N);
    for i=1:N
        sInd = qstar*(i-1)+1; eInd = i*qstar;
        errors(:,:,i) = Ytilde(sInd:eInd,:) - A(:,:,i)*S_i(:,:,i);
    end
    sigma1_sq = var(reshape(errors, [1, qstar*V*N]));
    
    waitbar(8/steps);

    % Initial Guess: fit a Gaussian mixture
    m=2;
    for ji=1:qstar
        GMModel = fitgmdist(S0(ji,:)' ,m+1);
        id = find(abs(GMModel.mu) == max(abs(GMModel.mu)));
        theta.miu3(1+m*(ji-1): m*ji, 1) =[GMModel.mu(id), 0];
        idzero = (abs(GMModel.mu) == min(abs(GMModel.mu)));
        theta.sigma3_sq(1+m*(ji-1): m*ji, 1) = [GMModel.Sigma(id), GMModel.Sigma(idzero)];
        theta.pi(1+m*(ji-1): m*ji, 1)  =[GMModel.PComponents(id),...
                                       1-GMModel.PComponents(id)];
    end
    
    waitbar(9/steps);

    % create the final variables to return (beta already created)
    theta.sigma1_sq = sigma1_sq;
    theta.sigma2_sq = sigma2_sq;
    theta.A = A;

    % Save the aggregate map for IC selection; these are only used for IC
    % selection
    s0_agg = S0;

    emptyImage = zeros(size(mask.img));
    for i=1:qstar
        emptyImage(validVoxels) = s0_agg(i,:);
        new_image = make_nii( emptyImage );
        save_nii( new_image, [filepath '_reducedIniGuess_GroupMap_IC_', num2str(i) '.nii'] )
    end
    
    waitbar(10/steps);

    % C matrix diag
    CmatStar = ones( N * qstar,1 );

    disp('------------------------------------')
    disp('Initial Guess Re-Estimation Complete')
    disp('------------------------------------')
    
    move_iniguess_to_folder(outpath, prefix)

    close(h)
    
 end

