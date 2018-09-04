function [theta_new, beta_new, z_mode, subICmean, subICvar,...
        grpICmean, grpICvar, err, G_z_dict] = UpdateThetaBetaAprx_Vect_Experimental (...
        Y, X_mtx, theta, C_matrix_diag, beta, N, T, q, p, m, V)
% UpdateThetaBetaAprx_Vect - Function to run hc-ICA approximate EM algorithm
% Each run of this function performs one iteration of EM approximate
% algorithm
%`
% Syntax: 
% [theta_new, beta_new, z_mode, subICmean, subICvar, grpICmean, grpICvar, err]
%       = UpdateThetaBetaAprx_Vect (Y, X_mtx, theta, C_matrix_diag, beta,...
%                                   N, T, q, p, m, V)
%
% Inputs:
%    Y          - NQ x V, orignial imaging data matrix
%    X_mtx      - N x p, covariate matrix (transposed)
%    theta      - Object containing estimates for the EM algorithm
%    C_matrix_diag  - Gives the product of whitening matrix and its
%                     transpose
%    beta       - Estimates for regression coefficients
%    N          - Number of subjects
%    T          - Number of time points
%    q          - Number of Independent Components (IC)
%    p          - Number of co-variates
%    m          - Number of Gaussian components in MoG
%    V          - Number of voxels
%
% Outputs:
%    theta_new  - Object containing new estimates for the EM algorithm
%    beta_new   - New estimates for regression coefficients
%    z_mode     - IC membership for voxels
%    subICmean  - Subject level IC mean
%    subICvar   - Subject level IC mean
%    grpICmean  - Group level IC mean
%    grpICvar   - Group level IC variance
%    err      - 1 indicates that the execution ended in error condition
%    G_z_dict - combinations of ic membership
%
% See also: UpdateThetaBeta.m, CoeffpICA_EM.m    

    % Preallocate Space
    subICvar = 0;
    err = 0;
    theta_new.A = zeros(T, q, N);
    theta_new.sigma1_sq = 0;
    theta_new.sigma2_sq = zeros(q, 1);
    theta_new.miu3 = zeros( (m * q), 1);
    theta_new.sigma3_sq = zeros( (m * q), 1);
    theta_new.pi = zeros( (m * q), 1);
    beta_new = zeros(p, q, V);
    A_ProdPart1 = zeros(T, q, N);  %first part of the product format for Ai
    A_ProdPart2 = zeros(q, q, N);  %second part of the product format for Ai
    A_ProdPart1_vec = zeros(T*q*N, 1);  %first part of the product format for Ai
    A_ProdPart2_Vec = zeros(q, q, N);  %second part of the product format for Ai
    sigma2_sq_all_V = zeros(q, q, V); 
    sumXiXiT_inv  = eye(p) / (X_mtx * X_mtx');
    subICmean = zeros(q, N, V);
    grpICmean = zeros(q, V);
    grpICvar = zeros(q, q, V);
    A = zeros( (N * T), (N * q) ) ;
    
    % Store the mixing matrix (A) in proper format
    for i = 1:N
        A((i-1)*T+1 : (i-1)*T+T, (i-1)*q+1 : (i-1)*q+q) = theta.A(:,:,i);
    end

    B = kron( ones(N, 1), eye(q));
    W2 = [ eye(N * q), B];
    P = [ eye(N * q), B; zeros(q, N * q), eye(q) ];
    
    % First level variance
    Sigma1 = diag( theta.sigma1_sq);
    Sigma1_inv = diag(1 ./ diag(Sigma1));
    
    % Second level variance
    Sigma2 = kron( eye(N), diag(theta.sigma2_sq));
    Sigma_gamma0 = W2' * Sigma1_inv * W2 ;

    % dictionary for the z(v)s
    z_dict = [ 2 * ones(q) - eye(q), 2 * ones(q, 1)];
    G_z_dict = zeros( q, m * q, q + 1);
    for i = 1:(q + 1)
        G_z_dict(:,:,i) = G_zv_gen( z_dict(:,i), m, q);
    end

    Sigma23z = zeros( (N + 1) * q, (N + 1) * q, q + 1);

    % Calculate the possible mean configurations
    miu3z = mtimesx(G_z_dict, theta.miu3);

    % Covariate effects times the design matrix
    betaTimesXtemp = mtimesx( X_mtx, 't', beta);
    betaTimesX = reshape(permute(betaTimesXtemp, [2 1 3]), [N * q, V]);
    clear('betaTimesXtemp');
    
    % Obtain the corresponding IC means
    BX = mtimesx(B, miu3z);
    
    % Observed data with mean subtracted off
    Y_star_uncent = mtimesx(A', Y);

    % Second and third level variance
    for i = 1:(q + 1)
        Sigma23z(:,:,i) = diag([ diag(Sigma2);...
                                (G_z_dict(:,:,i) * theta.sigma3_sq)]);
    end
    
    % Calculate the probability of each configuration
    pi_z_prod = squeeze( prod( mtimesx( G_z_dict, theta.pi)))';

    % Calculate the covariance
    mvn_cov = sqrt(bsxfun( @plus, mtimesx( W2, mtimesx( Sigma23z, W2')), Sigma1));
    mvn_cov_wide = reshape( mvn_cov, [q * N, q * (q + 1) * N] );
    mvn_cov_tran_wide = reshape( mvn_cov_wide( find( kron(...
               repmat( eye(N), [1, (q + 1)]), ones(q)))), q, [], N * (q + 1));
           
           
    % Calculate the probability of belonging to ICs over subjects
    probBelong = bsxfun( @plus ,zeros(1, q+1, V), log(pi_z_prod) );
    probBelong = permute(probBelong, [1,3,2]);
    subj_sd = zeros(q, 1, q+1);
    for iSubj = 1:N
        % Grab this subjects processed data
        cov_index = iSubj:N:(N*(q+1));
        subj_sd_temp = (mvn_cov_tran_wide(:,:, cov_index ));
        for ii=1:(q+1)
            subj_sd(:,:,ii) = diag(subj_sd_temp(:,:,ii));
        end
        % Calculate the probabilities
        prob = normpdf(Y_star_uncent( q*(iSubj-1)+1:q*iSubj ,:),...
            bsxfun(@plus, BX( q*(iSubj-1)+1:q*iSubj ,:,:), betaTimesX( q*(iSubj-1)+1:q*iSubj,:)),...
            subj_sd) + 0.00000000000000000001;
        probBelong = probBelong + sum( log(prob), 1 );
    end
    
    % Remove things no longer needed
    clear('prob')
    clear('Y_star_subj')

    % Calculate the IC each voxel belongs to as the mode
    [~, maxid_all_new] = max( probBelong,[], 3);
    VoxelIC = squeeze( maxid_all_new);
    clear('maxid_all_new')
    z_mode = VoxelIC;

    % Variance and mean terms for calculating expectation of s0, si, beta
    sigma23z_diag = bsxfun( @rdivide, eye((N + 1) * q ), Sigma23z);
    sigma23z_diag( isnan( sigma23z_diag)) = 0;
    denom = bsxfun( @plus, sigma23z_diag, Sigma_gamma0 );
    Sigma_gamma_all = zeros((N + 1) * q, (N + 1) * q, q + 1);
    Sigma_star_all = zeros( (N + 1) * q, (N + 1) * q, q+1 );
    miu_gamma_all_ic = zeros((N + 1) * q, N * q, q + 1);
    w2PrimeSigmaInv = W2' * Sigma1_inv;
    miu_gamma_all = zeros((N + 1) * q, V );
    miu_temp_add = zeros((N + 1) * q, V );
    
    % note: Ystar alt = Y_star_uncent - miu_temp_ALT
        
    % Store the needed terms for s0, si, beta only for the mode z
    % configuration
    for ic = 1:(q + 1)
        Sigma_gamma_all(:,:,ic) = eye((N + 1) * q) / denom(:,:,ic);
        Sigma_star_all(:,:,ic) =  P * Sigma_gamma_all(:,:,ic) * P';
        miu_gamma_all_ic(:,:,ic) = Sigma_gamma_all(:,:,ic) * w2PrimeSigmaInv;
        yind = find( VoxelIC == ic);
        % This is the new version, have to calc miu_temp_ALT
        miu_temp_add(1:(q * N), yind) = bsxfun(@plus, BX(:,:,ic), betaTimesX(:, yind));
        miu_gamma_all(:, yind) = miu_gamma_all_ic(:,:,ic) *...
            (Y_star_uncent(:, yind) - bsxfun(@plus, BX(:,:,ic), betaTimesX(:, yind)) );
        miu_temp_add((q * N)+1 : (N+1) * q, yind) = ...
                            repmat( miu3z(:,:,ic), [1, length(yind)]); 
    end 
    
    clear('betaTimesX')
    %clear('miu_temp_ALT')
    pMiuGamma = P * miu_gamma_all;
    clear('miu_gamma_all')
    
    % overall mean
    miu_star_all = pMiuGamma + miu_temp_add;

    % Update the group IC information JOSH MADE THIS CHANGE
    grpICmean = miu_star_all( (q*N+1):(q*(N+1)), :);
    grpICvar = mtimesx(reshape(grpICmean, [q, 1, V]), reshape(grpICmean, [1, q, V])) + Sigma_star_all((q*N+1):(q*(N+1)), (q*N+1):(q*(N+1)),VoxelIC);
    
    % Term is sum of grpICvar and each subject level variance - for
    % sigma2sq
    addedVariance = N*grpICvar;
    
    for iSubj = 1:N
        % Corresponding elements from (q+1)N size structures
        startv = ((iSubj-1)*q)+1;
        endv = iSubj*q;
                
        miu_star_subj = miu_star_all(startv:endv, :);  
        miu_sv_all = miu_star_subj; 
        miu_sv_svT_all = mtimesx(reshape(miu_star_subj, [q, 1, V]),...
            reshape(miu_star_subj, [1, q, V])) + Sigma_star_all(startv:endv, startv:endv, VoxelIC);
        noise_columns = mtimesx(reshape(miu_star_subj, [q, 1, V]),...
            reshape(grpICmean, [1, q, V])) + Sigma_star_all(startv:endv, (q*N+1):(N+1)*q , VoxelIC);
        
        % Increment term for sigma2 sq
        addedVariance = addedVariance + miu_sv_svT_all - 2*noise_columns;   
        miu_svi = miu_sv_all;
        subICmean(:,iSubj,:) = squeeze( miu_svi);
        mtSum =  Y(startv:endv,:) * miu_svi';
        % This subject's contribution to the mixing matrix
        A_ProdPart1(:,:,iSubj) = A_ProdPart1(:,:,iSubj) + mtSum;
        A_ProdPart2(:,:,iSubj) = A_ProdPart2(:,:,iSubj) + sum(miu_sv_svT_all, 3);
        
    end
    [a, ~] = size(X_mtx);
    
    % Update beta coefficients
    diff = bsxfun( @minus, subICmean, reshape(grpICmean, [q, 1, V]));
    % Loop over ICs to avoid memory issues of permuting diff
    for iIC = 1:q
        beta_new(:, iIC, :) = reshape(X_mtx, [a,N] ) * squeeze(diff(iIC, :, :));
    end
    beta_new = mtimesx(sumXiXiT_inv, beta_new);
    
    % Xbeta squared for the second level variance calculation
    xprimeBetatemp = mtimesx(X_mtx', beta_new);
    xprimeBeta = xprimeBetatemp;
    xBetaSquared = mtimesx( xprimeBetatemp, 'T', xprimeBetatemp);
    
    % Update second level variance
     sigma2_sq_all_V = addedVariance +...
         mtimesx( 2*bsxfun( @minus, reshape(grpICmean, [q, 1, V]), subICmean),...
         xprimeBeta ) + ...
         xBetaSquared; 
    sigma2_sq_all = sum( sigma2_sq_all_V,3);
    clear('sigma2_sq_all_V');
    theta_new.sigma2_sq = 1 / double(N * V) * diag( sigma2_sq_all); 

    % Update mixture of gaussians
    for l = 1:q
        act = find( VoxelIC == l);
        nois = find( VoxelIC ~= l);
        theta_new.pi(1 + (l-1) * m) =  ( length(act) + 1) / ( length(nois) + length(act) + 1);
        theta_new.pi(2 + (l-1) * m) =  length(nois) / ( length(nois) + length(act) + 1);
        theta_new.miu3(1 + (l-1) * m) = mean( grpICmean(l, act));
        theta_new.miu3(2 + (l-1) * m) = mean( grpICmean(l, nois));
        theta_new.sigma3_sq(1 + (l-1) * m) = mean( grpICvar(l, l, act));
        theta_new.sigma3_sq(2 + (l-1) * m) = mean( grpICvar(l, l, nois));
    end
    theta_new.sigma3_sq = theta_new.sigma3_sq - theta_new.miu3 .^ 2;
    
    % Update that uses the probabilities
 
    % handle NaN in previous iteration
    nanid = find( isnan( theta_new.miu3));
    if ~ isempty( nanid)
        theta_new.sigma3_sq( nanid) = theta.sigma3_sq( nanid);
        theta_new.miu3( nanid) = theta.miu3( nanid);
    end

    % Update mixing matrix
    for i = 1:N
        theta_new.A(:,:,i) = A_ProdPart1(:,:,i) / (A_ProdPart2(:,:,i));
        theta_new.A(:,:,i) = theta_new.A(:,:,i) ...
            * real( inv(theta_new.A(:,:,i)' * theta_new.A(:,:,i)) ^ (1/2));
    end

    % Calculations for sigma 1 squared
    firstRow = sum( sum(Y .^ 2));
    theta_new_A_cell = num2cell( theta_new.A, [1, 2]);
    theta_term = blkdiag( theta_new_A_cell{:}); 
    subICmean_term = reshape( subICmean, [q * N, V]);
    second_term = sum( sum(2 * Y' * theta_term .* subICmean_term'));

    % get the trace term;
    ACA = mtimesx( theta_new.A, 'T', theta_new.A);

    theta_new_sigma1_sq_alt = 0.0;
    
    % ACA is a qxq x N matrix
    finalqcol = N*q+1;
    finalcol = (N+1)*q;
    Sigma_Star_allVoxel = zeros( (q), (q), V);
    
    % Loop through subjects for subject level variance update
    trace_term = zeros(1, 1, V);
    for iSubj = 1:N
        CA_i = theta_new.A(:,:,iSubj);
        ACA_i = ACA(:,:,iSubj);
        startv = ((iSubj-1)*q)+1;
        endv = iSubj*q;
        theta_new_sigma1_sq_par = 0.0;
        
        Sigma_Star_allVoxel(:,:, :) = Sigma_star_all(startv:endv, startv:endv, VoxelIC);
        
        subicvar_iv = mtimesx(subICmean(:,iSubj,:), permute(subICmean(:,iSubj,:), [2,1,3]) ) +...
                Sigma_Star_allVoxel;
            
        trace_term = trace_term +...
            sum(sum(bsxfun(@times, eye(q), ( mtimesx(ACA_i, subicvar_iv)))));
    end
    
    
    % now need to sum all diagonal elements to get final sigma1
    theta_new.sigma1_sq = firstRow - second_term + sum(trace_term);
    theta_new.sigma1_sq = 1 / double(N * T * V) * theta_new.sigma1_sq;

end






