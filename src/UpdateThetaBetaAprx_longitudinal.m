function [theta_new, beta_new, z_mode, subICmean, subICvar,...
        grpICmean, grpICvar, err, G_z_dict] = ...
    UpdateThetaBetaAprx_longitudinal(Y, X_mtx, theta, C_diag_matrix, beta, N, T, K, q, p, m, V)
    
    % X_mtx: p x N
    
    % Track if an error has occured
    err = 0;
    
    K = K - 1;
    
    NK = N*(1+K);
    X_mtx2 = X_mtx;               % no intercept for alpha p*N
    X_mtx = [ones([1 N]); X_mtx]; % Add intercept row to it, of dimension (p+1)*N. 
    
    U = kron(ones(NK, 1), eye(q)); 
    H = kron(kron(eye(N), ones(K+1,1)),eye(q));
    R = [H, U, eye(size(H,1))];
    P = [eye(q*(N+1)) zeros(q*(N+1),size(H,1));R];
    
    A   = zeros(NK*q, NK*q) ;
    star_index = 1;stop_index = q;
    for i = 1:N
        for j = 0:K
            A( star_index:stop_index , star_index:stop_index) = theta.A(:,:,i,j+1);
            star_index = stop_index+1;
            stop_index = stop_index+q;
        end
    end
    
    AR = A*R; 
    
    
    vspace = q+1;
    G_z_list = repmat([1 0],[vspace q]); % [1 0] is in background
	for i = 1:q
		G_z_list(i+1, [2*i-1 2*i]) = [0 1];
    end
    G_z_dict = zeros( q, m*q, q+1);
    for i = 1:vspace
        G_z_dict(:,:,i) = repmat(G_z_list(i,:), [q,1]).*kron(eye(q),ones(1,2));
    end
    
    
    %Sigma1   =   diag(C_diag_matrix.*theta.sigma1_sq);
    Sigma1   =   diag(theta.sigma1_sq);
    Sigma1_inv = diag(1./diag(Sigma1));     
    
    Sigma_gamma_part = AR'*Sigma1_inv;
    Sigma_gamma0  = Sigma_gamma_part*AR; % a part of variance of r_z(v)
    
    
    Sigma2   =   kron(eye(N), diag(theta.D)); % variance matrix of b(v) which is qN by qN
    
    
    % Calculate the possible mean configurations
    miu3z = mtimesx(G_z_dict, theta.miu3); % mu_z(v)'s all possible sets q x (q+1) 
    % Calculate the probability of each configuration
    pi_z_prod = squeeze( prod( mtimesx( G_z_dict, theta.pi)))'; % 1 x (q+1)
    
    
    
    % Second and third level variance
    Sigma23z = zeros( (NK + 1+N) * q, (NK +1+N) * q, q + 1);
    for i = 1:(q+1) 
        Sigma23z(:,:,i) = diag([ diag(Sigma2);...
            (G_z_dict(:,:,i) * theta.sigma3_sq);...
            theta.tau_sq*ones(NK*q,1)]);           % var of r_z(v)
    end
    
    
    % Calculate the mean of Y: 
    % 1 - First, Obtain the corresponding IC means
    Umiu_z = mtimesx(U, miu3z); % U*miu_z(v) which is qN x (q+1)
    
    % 2 - Second, C(v)X
    Ceta_matrix = zeros(q*(K+1),p+1,V);
    for j = 0:K
         Ceta_matrix((1+q*j):(q+q*j),:,:) = beta(:,:,:,j+1);
    end
    CvX = mtimesx( Ceta_matrix, X_mtx); % q*(K+1) by N by V
    CvX = reshape(CvX,[NK*q,V]);        % q*(K+1)*N by V
    clear('Ceta_matrix');
    
    
    % Calculate the covariance
    mvn_cov = bsxfun( @plus, mtimesx( AR, mtimesx( Sigma23z, AR')), Sigma1);
    
   
    
    % Calculate p( z(v)|y(v) )
    probBelong = bsxfun( @plus ,zeros(1, q+1, V), log(pi_z_prod) );
    probBelong = permute(probBelong, [1,3,2]); % V by q+1
    
    AUmiu_z = mtimesx(A, Umiu_z); % ? x (q+1)
    ACvX = mtimesx(A, CvX);       % ? x V
    
    Ystar0 = Y - ACvX;
    
    % There is a problem!
    for sp = 1:(q+1)
        
        Ystar = Ystar0 - AUmiu_z(:,1,sp);
        part1tmp = mtimesx(eye(q*NK)/mvn_cov(:,:,sp),Ystar);
        
        %prob_tmp = squeeze(diag(mtimesx(Ystar',part1tmp)))/2 + log(det(mvn_cov(:,:,sp)))/2;
        prob_tmp = sum(Ystar .* part1tmp, 1)'/2 + log(det(mvn_cov(:,:,sp)))/2;
        
        % new 
        %compare = squeeze(diag(mtimesx(Ystar',part1tmp)));
        %test = sum(Ystar .* part1tmp, 1)';
        
        if(sum(isnan(prob_tmp)) == 0)
            probBelong(1,:,sp) = squeeze(probBelong(1,:,sp))' - prob_tmp;
        else % If there is error, we use approximate prob by splitting subjects
            for sub_i = 1:N
                strindex = q*(K+1)*(sub_i-1)+1;
                endindex = q*(K+1)*sub_i;
                 
                Yi = Ystar( strindex:endindex,:); % Y - qK by V for subject i
                
                covtemj = mvn_cov( strindex:endindex, strindex:endindex, : );
                probBelong(1,:,sp) = squeeze(probBelong(1,:,sp))' - squeeze(diag(mtimesx(Yi',mtimesx(eye(q*(K+1))/covtemj(:,:,sp),Yi))))/2;
                probBelong(1,:,sp) = probBelong(1,:,sp)-log(det(covtemj(:,:,sp)))/2;
            end
        end
    end
    
    
    % Calculate the IC each voxel belongs to as the mode
    [~, maxid_all_new] = max( probBelong,[], 3);
    VoxelIC = squeeze( maxid_all_new);
    clear('maxid_all_new')
    z_mode = VoxelIC;
    
    % Calculate the Probability: 
    PostProbz_log = zeros(size(probBelong));
    for sp = 1:(q+1)
        PostProbz_log(1,:,sp) = 1./sum(squeeze(exp(bsxfun(@minus,probBelong, probBelong(1,:,sp))))');
    end
    
    
    % Variance and mean terms for calculating expectation of s0, si, beta
    sigma23z_diag = bsxfun( @rdivide, eye( (NK+1+N) * q ), Sigma23z); % Sigma23z always diagonal, check with Joshua
    sigma23z_diag( isnan( sigma23z_diag)) = 0;
    denom = bsxfun( @plus, sigma23z_diag, Sigma_gamma0 );
    
    Sigma_gamma_all = zeros( (NK+1+N)*q, (NK+1+N)*q , q + 1);
    Sigma_star_all = zeros( (NK+1+N) * q , (NK + 1+N) * q , q+1 ); % variance of L(v)|y(v),z(v) 
    
    w2PrimeSigmaInv = AR' * Sigma1_inv;
    miu_gamma_all = zeros((NK +N + 1) * q, V ); % mean of r_z(v)|y(v),z(v) 
    
    miu_gamma_all_ic = zeros( (NK+1+N)*q , NK*q, q+1);
    
        
    % Store the needed terms for s0, si, beta only for the mode z
    % configuration
    for sp = 1:(q+1)
        
        Sigma_gamma_all(:,:,sp) = eye( (NK+1+N) * q ) / denom(:,:,sp);
        Sigma_star_all(:,:,sp) =  P * Sigma_gamma_all(:,:,sp) * P';
        miu_gamma_all_ic(:,:,sp) = Sigma_gamma_all(:,:,sp) * w2PrimeSigmaInv;
        
    end
    clear denom Sigma_gamma_all
    
    
    miu_L_z = zeros((NK+1+N)*q,V);          % E{L(v)}
    S_L_z = zeros((NK+1+N)*q,(NK+1+N)*q,V); % E{L(v)L(v)'}  
    
    % sum over all possiblilities in the subspace: 
    for sp = 1:(q+1)
        
        p_z = PostProbz_log(1,:,sp); % of dimension V 
        MeanTmp = bsxfun(@plus, Umiu_z(:,:,sp), CvX);
        
        Q_z = zeros((NK+1+N)*q, V );  
        Q_z( ((q*N)+1):((N+1)*q), :) = repmat( miu3z(:,:,sp), [1, V]);
        Q_z( (q*(N+1)+1):((NK+1+N)*q) , :) = MeanTmp;
        
        tempmiu = P* miu_gamma_all_ic(:,:,sp)*(Y-A*MeanTmp) + Q_z; % mean of L(v) | y(v),z(v)
        
        miu_L_z = miu_L_z + tempmiu.* repmat(p_z,(NK+1+N)*q,1);
        
        tempmiu = reshape(tempmiu, [size(tempmiu,1), 1, V]);
        tempmiu_sq = bsxfun(@times, tempmiu, permute(tempmiu, [2, 1, 3])); 
        
        E2tmp = bsxfun(@plus, Sigma_star_all(:,:,sp), tempmiu_sq);
        
        %tmp = permute(bsxfun(@times,permute(E2tmp,[3 1 2]),...
        %          repmat(p_z,[size(E2tmp,1) 1])' ),[2 3 1]);
        
%         S_L_z = S_L_z+ permute(bsxfun(@times,permute(E2tmp,[3 1 2]),...
%                   repmat(p_z,[size(E2tmp,1) 1])' ),[2 3 1]);
              
        S_L_z = S_L_z + bsxfun(@times, reshape(p_z, [1,1,V]), E2tmp);
              
%          orig = permute(bsxfun(@times,permute(E2tmp,[3 1 2]),...
%                   repmat(p_z,[size(E2tmp,1) 1])' ),[2 3 1]);
%          new = bsxfun(@times, reshape(p_z, [1,1,V]), E2tmp);
        
    end
    
    
    % S0:
    grpICmean = miu_L_z( (q*N+1):(q*(N+1)), :);
    sv_svT_miu = S_L_z( (q*N+1):(q*(N+1)), (q*N+1):(q*(N+1)),:);
    grpICvar = sv_svT_miu;
    
    
    % Sij: 
    subICmean = miu_L_z( (q*(N+1)+1):size(miu_L_z,1), :);
    miu_svij_svijT = S_L_z( (q*(N+1)+1):size(miu_L_z,1),(q*(N+1)+1):size(miu_L_z,1),:);
    subICvar = miu_svij_svijT;
    
    
    % bi: 
    miu_bvi = miu_L_z( 1:(q*N), :);
    miu_bvi_bviT = S_L_z( 1:(q*N), 1:(q*N),:);
    
    % E{ bi*S0' }
    miu_bvi_svT = S_L_z( 1:(q*N), (q*N+1):(q*(N+1)) ,:);
    
    % E{ Sij * bi' }
    miu_svij_bivT = S_L_z( (q*(N+1)+1):size(miu_L_z,1) , 1:(q*N) ,:);
    
    % E{ Sij * S0' }
    miu_svij_svT  = S_L_z( (q*(N+1)+1):size(miu_L_z,1) , (q*N+1):(q*(N+1)),:);
    
    
    clear miu_L_z S_L_z 
    
    
    %%%%%%%%%%% this finished the E part %%%%%%%%%%%%%
    
    
    
    
    
    %%%%%%%%%%% M Step Starts %%%%%%%%%%% 

    sumXiXiT_inv  = eye(p+1)/(X_mtx*X_mtx');  sumXiXiT_inv2  = eye(p)/(X_mtx2*X_mtx2'); 
    
    % Update mixing matrix: 
    for i = 1:N
        for j = 0:K
            ij = j+1+(i-1)*(K+1);
            A_ProdPart1 = Y( ((1+q*(ij-1)):(q*ij)) ,:)*subICmean( ((1+q*(ij-1)):(q*ij)), :)' ;
            A_ProdPart2 = sum(miu_svij_svijT(((1+q*(ij-1)):(q*ij)) , ((1+q*(ij-1)):(q*ij)), :),3) ;           
            
            theta_new.A(:,:,i,j+1) = A_ProdPart1/ (A_ProdPart2 );
            theta_new.A(:,:,i,j+1) = theta_new.A(:,:,i,j+1)*real( inv(theta_new.A(:,:,i,j+1)' * theta_new.A(:,:,i,j+1)) ^ (1/2));
        
        end
    end
    
    % Update Subject Level Variance: 
    theta_new.D = repmat(eye(q),1,N) * diag(sum(miu_bvi_bviT,3))/N/V;  
    
    
    % Update Ceta:
    beta_new = zeros(q,p+1,V,K+1);
    for j = 0:K
        for i = 1:N
            ij = j+1+(i-1)*(K+1);
            tmp = subICmean(((1+q*(ij-1)):(q*ij)),:)-grpICmean-miu_bvi((1+q*(i-1)):(q*i),:); % q by V
            
            if j == 0
                beta_new(:,2:(p+1),:,j+1) = beta_new(:,2:(p+1),:,j+1)+mtimesx(reshape(tmp,[q 1 V]), X_mtx2(:,i)');
            else
                beta_new(:,:,:,j+1)       = beta_new(:,:,:,j+1) + mtimesx(reshape(tmp,[q 1 V]), X_mtx(:,i)');
            end
        end
        
        if j==0
             beta_new(:,2:(p+1),:,j+1)= mtimesx(beta_new(:,2:(p+1),:,j+1), sumXiXiT_inv2);  % new Ceta_j(v), coefficient matrix at voxel v
        else
             beta_new(:,:,:,j+1)      = mtimesx(beta_new(:,:,:,j+1), sumXiXiT_inv);  % new Ceta_j(v), coefficient matrix at voxel v
        end
        
    end
    
    
    %%% Update for tau^2, (Second Level Variance), requires Ceta_new
    theta_new.tau_sq = 0;   % The 2nd level variance
    for i = 1:N
        for j = 0:K
            ij = j+1+(i-1)*(K+1);
            
            theta_new.tau_sq = theta_new.tau_sq +  ...
                      trace(sum( sv_svT_miu ,3)) + ...
                      trace(sum(miu_bvi_bviT( (1+q*(i-1)):(q*i),(1+q*(i-1)):(q*i),:),3)) + ...
                      trace(sum(miu_svij_svijT(((1+q*(ij-1)):(q*ij)) ,((1+q*(ij-1)):(q*ij)),:),3)) + ...
                      2*trace( sum(miu_bvi_svT( (1+q*(i-1)):(q*i),:,:) ...
                        - miu_svij_bivT( ((1+q*(ij-1)):(q*ij)), (1+q*(i-1)):(q*i) ,:)...
                        - miu_svij_svT ( ((1+q*(ij-1)):(q*ij)), :,:),3) );
                    
            tmp = mtimesx(beta_new(:,:,:,j+1),X_mtx(:,i));
            theta_new.tau_sq = theta_new.tau_sq + sum(sum(tmp.^2));
            
            tmp2 = (grpICmean +miu_bvi((1+q*(i-1)):(q*i),:)- subICmean( ((1+q*(ij-1)):(q*ij)),:));
            theta_new.tau_sq = theta_new.tau_sq + 2*sum(sum(squeeze(tmp).*tmp2));
        end
    end
    theta_new.tau_sq = theta_new.tau_sq/NK/V/q;
    
    
    %%% Update for sigma^2, (first Level Variance)
    theta_new.sigma1_sq = 0;
    for i = 1:N
        for j = 0:K
            ij = j+1+(i-1)*(K+1);
            Yijv = Y(((1+q*(ij-1)):(q*ij)),:);
            
            C_inv = 1./C_diag_matrix(((1+q*(ij-1)):(q*ij)));
            
            tmp = theta_new.A(:,:,i,j+1)'* diag(C_inv)*theta_new.A(:,:,i,j+1);
            tmp2 = sum(mtimesx(tmp,miu_svij_svijT(((1+q*(ij-1)):(q*ij)),((1+q*(ij-1)):(q*ij)),:)),3);
            
            
            C_inv = 1./C_diag_matrix(((1+q*(ij-1)):(q*ij))); 
            
            theta_new.sigma1_sq = theta_new.sigma1_sq + sum( C_inv'* Yijv.^2 ) - ...
               sum(2 * C_inv' * (Yijv.*(theta_new.A(:,:,i,j+1) * subICmean(((1+q*(ij-1)):(q*ij)),:)))) + trace( tmp2 );

        end
    end
    theta_new.sigma1_sq = theta_new.sigma1_sq/NK/V/q;
    
    
    % Update mixture of gaussians
    theta_new.miu3      = zeros(m*q, 1);   %pi, miu3, sigma3 in the order of miul1,...,miulm, l=1:q
    theta_new.sigma3_sq = zeros(m*q, 1);
    theta_new.pi        = zeros(m*q, 1);
  
    for l = 1:q
        act  = find( VoxelIC == l+1); % VoxelIC: 1 means background, 2 -IC1, 3-IC2,.., q+1 is ICq
        nois = find( VoxelIC ~= l+1);
        
        theta_new.pi(2 + (l-1) * m) =  ( length(act) + 1) / ( length(nois) + length(act) + 1);
        theta_new.pi(1 + (l-1) * m) =  1-theta_new.pi(2 + (l-1) * m);
        
        theta_new.miu3(2 + (l-1) * m) = mean( grpICmean(l, act));
        theta_new.miu3(1 + (l-1) * m) = mean( grpICmean(l, nois));
        theta_new.sigma3_sq(2 + (l-1) * m) = mean( grpICvar(l, l, act));
        theta_new.sigma3_sq(1 + (l-1) * m) = mean( grpICvar(l, l, nois));
    end
    
    
    theta_new.sigma3_sq = theta_new.sigma3_sq - theta_new.miu3 .^ 2;
    
    theta_new.sigma3_sq(find(isnan(theta_new.sigma3_sq))) = theta.sigma3_sq(find(isnan(theta_new.sigma3_sq)));
    theta_new.miu3(find(isnan(theta_new.miu3))) = theta.miu3(find(isnan(theta_new.miu3))); 
    % Finished Updating Parameters (EM). 


    
end
