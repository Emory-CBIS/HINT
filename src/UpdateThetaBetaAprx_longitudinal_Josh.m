function [theta_new, beta_new, z_mode, subICmean, subICvar,...
        grpICmean, grpICvar, err, G_z_dict] = ...
    UpdateThetaBetaAprx_longitudinal_Josh(Y, X_mtx, theta, C_diag_matrix, beta, N, T, K, q, p, m, V)
    

    % Josh renaming a few things here
    J = K;
    disp(['Time points: ', num2str(J)])
    
    % Josh for future Y shape
    Yij = zeros(q, N, J, V);
    eind = 0;
    for i = 1:N
        for j = 1:J
            sind = eind + 1;
            eind = eind + q;
            Yij(:, i, j, :) = Y(sind:eind, :);
        end
    end
    
    % T ?
    % K
    % X_mtx: p x N
    % vert-version with loops 
    err = 0;
    IterV = 500; % Number of Loops to go through on voxels. 
    
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
    end;
    G_z_dict = zeros( q, m*q, q+1);
    for i = 1:vspace
        G_z_dict(:,:,i) = repmat(G_z_list(i,:), [q,1]).*kron(eye(q),ones(1,2));
    end;
    
    
    Sigma1   =   diag(C_diag_matrix.*theta.sigma1_sq);
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
    
       % mvn_cov2 = bsxfun( @plus, mtimesx( R, mtimesx( Sigma23z, R')), Sigma1);

    % Calculate p( z(v)|y(v) )
    probBelong = bsxfun( @plus ,zeros(1, q+1, V), log(pi_z_prod) );
    probBelong = permute(probBelong, [1,3,2]); % V by q+1
    
    probBelongExact = ones(size(probBelong));
    
    AUmiu_z = mtimesx(A, Umiu_z); % ? x (q+1)
    ACvX = mtimesx(A, CvX);       % ? x V
    
    Ystar0 = Y - ACvX;
    
    for sp = 1:(q+1)
        Ystar = Ystar0 - AUmiu_z(:,1,sp);
        for sub_i = 1:N
            strindex = q*(K+1)*(sub_i-1)+1;
            endindex = q*(K+1)*sub_i;
             
            Yi = Ystar( strindex:endindex,:); % Y - qK by V for subject i
            covtemj = eye(q*(K+1))/mvn_cov( strindex:endindex, strindex:endindex, sp);
            probBelong(1,:,sp) = squeeze(probBelong(1,:,sp))' - squeeze(diag(mtimesx(Yi',mtimesx(covtemj,Yi))))/2;
            probBelong(1,:,sp) = probBelong(1,:,sp)-log(det(covtemj))/2;
            
%             probBelongExact(1, :, sp) = squeeze(probBelongExact(1, :, sp))' .*...
%                 exp(-0.5 * squeeze(diag(mtimesx(Yi',mtimesx(covtemj,Yi)))) ) .*...
%                 1.0 / sqrt(det(covtemj));
        end
       % probBelongExact(1, :, sp) = probBelongExact(1, :, sp) * pi_z_prod(sp);
    end
    
    
    probBelong2 = bsxfun( @plus ,zeros(1, q+1, V), log(pi_z_prod) );
    probBelong2 = permute(probBelong2, [1,3,2]); % V by q+1
    for sp = 1:(q+1)
        Ystar = Ystar0 - AUmiu_z(:,1,sp);
        covtemj = inv(mvn_cov( :, :, sp));
        probBelong2(1,:,sp) = squeeze(probBelong2(1,:,sp))' - squeeze(diag(mtimesx(Ystar',mtimesx(covtemj,Ystar))))/2;
        probBelong2(1,:,sp) = probBelong2(1,:,sp)-log(det(covtemj))/2;
    end
    

    % sum(abs(probBelong(:)) == Inf)

    
    % Calculate the IC each voxel belongs to as the mode
    [~, maxid_all_new] = max( probBelong,[], 3);
    VoxelIC = squeeze( maxid_all_new);
    clear('maxid_all_new')
    z_mode = VoxelIC;
    
    % Calculate the Probability: 
    PostProbz_log      = zeros(size(probBelong));
    PostProbz_regscale = zeros(size(probBelong));
    PostProbz_regscale2 = zeros(size(probBelong));
    for sp = 1:(q+1)
        PostProbz_log(1,:,sp) = 1./sum(squeeze(exp(bsxfun(@minus,probBelong, probBelong(1,:,sp))))');        
    end
    for v = 1:V
        PostProbz_regscale(1,v,:)  = exp(probBelong(1,v,:)) ./ sum( exp(probBelong(1,v,:)) );
        PostProbz_regscale2(1,v,:) = exp(probBelong2(1,v,:)) ./ sum( exp(probBelong2(1,v,:)) );
        %probBelongExact(1, v, :) = probBelongExact(1, v, :) ./ sum(probBelongExact(1, v, :));
        % Log sum exp version
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
    
    
    
    
    grpICmean = zeros(q,V);
    grpICvar = zeros(q,q,V);
    subICmean  = zeros(q*NK,V);
    subICvar = zeros(q,q,N,K+1,V);

    miu_bvi = zeros(q*N,V);
    miu_bvi_bviT = zeros(q*N,q*N);
    miu_bvi_svT = zeros(q*N,q);
    miu_svij_bivT = zeros(q*NK,q*N);
    miu_svij_svT = zeros(q*NK,q);
    
    batch_n = fix(V/IterV);
    
    
    %% Josh Version of E-step
    % Ceta is Q x P+1 x V x J ? first 2 dims might be flippeds
    XB = zeros(q, N, J); % fixed effects contribution
    Y_star   = zeros(q, 1);
    %Yij_star = zeros(q, N);
    Yi_bar   = zeros(q, N);
    
    % Variance of mean of unmixed, fixed effects centered data (Ybar)
    %sigmasq_ybar = (1 / (N*J)) * (theta.tau_sq*eye(q) + theta.sigma1_sq*eye(q)) +...
    %    (1 / N) * diag(theta.D);
    
    %% This will match the contrast below
    %(J^2 * diag(theta.D) + J^2 * VarZv + J*(theta.tau_sq*eye(q)+theta.sigma1_sq*eye(q)))/(J^2)
    %(ctr * mvn_cov2( strindex:endindex, strindex:endindex, 1) * ctr') / 9
    %(diag(theta.D) + VarZv + (1/J)*(theta.tau_sq*eye(q)+theta.sigma1_sq*eye(q)))
    
    sigmasq_ybar = (diag(theta.D) + (1/J)*(theta.tau_sq*eye(q) + theta.sigma1_sq*eye(q))) / N ;
    
%     sigmasq_ybar = (1 / (N*J)) * (theta.tau_sq*eye(q) + theta.sigma1_sq*eye(q)) +...
%         (1 / (N*J)) * diag(theta.D) +...
%         (J-1) * diag(theta.D / (N));
    
%     (ctr * mvn_cov2( strindex:endindex, strindex:endindex, 1) * ctr') / (3 * N)
%     
%     (ctr * mvn_cov2( strindex:endindex, strindex:endindex, 1) * ctr') / 3
%     N * sigmasq_ybar + VarZv
    
%      sigmasq_ybar = (1 / (J)) * (theta.tau_sq*eye(q) + theta.sigma1_sq*eye(q)) +...
%         (1 / (J)) * diag(theta.D) +...
%         (J-1) * diag(theta.D );
%         %(1 / (N * J^2)) * diag(theta.D + nchoosek(J, 2) * theta.D );
    
    % Conditional varaince
    VarYGivenZStore = zeros(q, q, (q+1));
    for i = 1:(q+1)
        G_z   = G_z_dict(:,:,i);
        VarZv = diag(G_z * theta.sigma3_sq);
        VarYGivenZStore(:, :, i)  = sigmasq_ybar + VarZv;
    end
    VarYGivenZStore(:, :, 1)
    
    Probzv = zeros(q + 1, 1);
    ProbZv_All = zeros((q+1), V);

    
    for v = 1:V
        
        % For checking
        %A' * Ystar0(:, v)
        %A' * ACvX(:, v)
        
        Yi_bar(:, :)   = zeros(q, N);
        for i = 1:N
            for j = 1:J
                XB(:, i, j) = theta.iniguessCeta(:, :, v, j) * X_mtx(:, i);
                Yi_bar(:, i) = Yi_bar(:, i) + ...
                    theta.A(:, :, i, j)' * Yij(:, i, j, v) -...  % unmixed time series
                    XB(:, i, j);
            end
            % Turn into an average instead of a sum
            Yi_bar(:, i) = Yi_bar(:, i) / J;
        end 
        % Overall mean of unmixed, fixed effects centered data
        Y_star(:, 1) = mean(Yi_bar, 2);
        
        %% Latent State Probabilities
        for i = 1:(q+1)
            G_z   = G_z_dict(:,:,i);
            MiuZv = G_z * theta.miu3;
            PiZv      = G_z * theta.pi;  
            VarYGivenZ = VarYGivenZStore(:, :, i);
            Probzv(i) = prod(PiZv)*(exp(-(Y_star - MiuZv)'/(VarYGivenZ)*(Y_star-MiuZv)/2)/sqrt(det(VarYGivenZ)));
        end    
        PostProbz = Probzv / sum(Probzv);
        ProbZv_All(:, v) = PostProbz;
        
        % This is to test at a voxel where beta is nonzero and S0 is active
%         if v == 4304
%             xxx=1;
%             PostProbz_log(:, v, :)
%             exp(PostProbz_log(:, v, :)) ./ sum(exp(PostProbz_log(:, v, :)))
%         end

        
        
    end
    
    % Compares to log probabilities - THIS IS WHAT HIS CODE ACTUALLY USES
%     t1 = ProbZv_All(:);
%     t2 = zeros(size(ProbZv_All));
%     for v = 1:V
%         t2(:, v) = exp(PostProbz_log(:, v, :)) ./ sum(exp(PostProbz_log(:, v, :)));
%     end
%     t22 = t2(:);
%     scatter(t1, t22)

    % Compares to regular probabilities
    t1 = ProbZv_All(:);
    t2 = zeros(size(ProbZv_All));
    for v = 1:V
        t2(:, v) = PostProbz_regscale2(1, v, :);
    end
    t22 = t2(:);
    scatter(t1, t22)
    corr(t1, t22)
    
    histogram(abs(t1 - t22));  
   
    scatter(squeeze(t2(1, :)'), squeeze(ProbZv_All(1, :)') ); refline([1 0]);
    scatter(squeeze(t2(2, :)'), squeeze(ProbZv_All(2, :)') ); refline([1 0]);
    scatter(squeeze(t2(3, :)'), squeeze(ProbZv_All(3, :)') ); refline([1 0]);
    scatter(squeeze(t2(4, :)'), squeeze(ProbZv_All(4, :)') ); refline([1 0]);
    
    %% Yikai Batch Version of E-step
    for rep = 1:IterV
        if rep == IterV
            begi = endd + 1;
            endd = V;
            batch_n = endd-begi+1;
        else
            begi = 1+(rep-1)*batch_n;
            endd = rep*batch_n;
        end
        
        miu_L_z = zeros((NK+1+N)*q,batch_n);          % E{L(v)}
        S_L_z = zeros((NK+1+N)*q,(NK+1+N)*q,batch_n); % E{L(v)L(v)'}  
        
        % sum over all possiblilities in the subspace: 
        for sp = 1:(q+1)

            p_z = PostProbz_log(1,begi:endd,sp); % of dimension batch_n (<< V)
            MeanTmp = bsxfun(@plus, Umiu_z(:,:,sp), CvX(:,begi:endd));

            Q_z = zeros((NK+1+N)*q, batch_n );  
            Q_z( ((q*N)+1):((N+1)*q), :) = repmat( miu3z(:,:,sp), [1, batch_n]);
            Q_z( (q*(N+1)+1):((NK+1+N)*q) , :) = MeanTmp;

            tempmiu = P* miu_gamma_all_ic(:,:,sp)*(Y(:,begi:endd)-A*MeanTmp) + Q_z; % mean of L(v) | y(v),z(v)

            miu_L_z = miu_L_z + tempmiu.* repmat(p_z,(NK+1+N)*q,1);

            %

            tempmiu = reshape(tempmiu, [size(tempmiu,1), 1, batch_n]);
            tempmiu_sq = bsxfun(@times, tempmiu, permute(tempmiu, [2, 1, 3])); 

            E2tmp = bsxfun(@plus, Sigma_star_all(:,:,sp), tempmiu_sq);
            S_L_z = S_L_z + bsxfun(@times, reshape(p_z, [1,1,batch_n]), E2tmp);
        end
        
        % S0:
        grpICmean(:,begi:endd) = miu_L_z( (q*N+1):(q*(N+1)), :);
        sv_svT_miu = S_L_z( (q*N+1):(q*(N+1)), (q*N+1):(q*(N+1)),:);
        grpICvar(:,:,begi:endd) = sv_svT_miu;
        
        % Sij: 
        subICmean(:,begi:endd) = miu_L_z( (q*(N+1)+1):size(miu_L_z,1), :);
        miu_svij_svijT = S_L_z( (q*(N+1)+1):size(miu_L_z,1),(q*(N+1)+1):size(miu_L_z,1),:);
        for i = 1:N
            for j = 0:K
                ij = j+1+(i-1)*(K+1);
                subICvar(:,:,i,j+1,begi:endd) = miu_svij_svijT(((1+q*(ij-1)):(q*ij)) , ((1+q*(ij-1)):(q*ij)), :);
            end
        end

        % bi: 
        miu_bvi(:,begi:endd) = miu_L_z( 1:(q*N), :);
        miu_bvi_bviT = miu_bvi_bviT + sum(S_L_z( 1:(q*N), 1:(q*N),:),3);
        
        % E{ bi*S0' }
        miu_bvi_svT = miu_bvi_svT + sum(S_L_z( 1:(q*N), (q*N+1):(q*(N+1)) ,:),3);

        % E{ Sij * bi' }
        miu_svij_bivT = miu_svij_bivT + sum(S_L_z( (q*(N+1)+1):size(miu_L_z,1) , 1:(q*N) ,:),3);

        % E{ Sij * S0' }
        miu_svij_svT  = miu_svij_svT + sum(S_L_z( (q*(N+1)+1):size(miu_L_z,1) , (q*N+1):(q*(N+1)),:),3);

        clear miu_L_z S_L_z 
        
        %%%%%%%%%%% this finished the E part %%%%%%%%%%%%%
    end
    
    %%%%%%%%%%% M Step Starts %%%%%%%%%%% 
    sumXiXiT_inv  = eye(p+1)/(X_mtx*X_mtx');  sumXiXiT_inv2  = eye(p)/(X_mtx2*X_mtx2'); 
    
    % Update mixing matrix (Part 2): 
    for i = 1:N
        for j = 0:K
            ij = j+1+(i-1)*(K+1);
            A_ProdPart1 = Y( ((1+q*(ij-1)):(q*ij)) ,:)*subICmean( ((1+q*(ij-1)):(q*ij)), :)' ;
            A_ProdPart2 = sum(squeeze(subICvar(:,:,i,j+1,:)),3);           
            theta_new.A(:,:,i,j+1) = A_ProdPart1/ (A_ProdPart2 );
            theta_new.A(:,:,i,j+1) = theta_new.A(:,:,i,j+1)*real( inv(theta_new.A(:,:,i,j+1)' * theta_new.A(:,:,i,j+1)) ^ (1/2));
        end
    end
    
    % Update Subject Level Variance: 
    theta_new.D = repmat(eye(q),1,N) * diag(miu_bvi_bviT)/N/V;  
    
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
    theta_new.tau_sq = trace(sum( grpICvar ,3)) *NK;   % The 2nd level variance
    for i = 1:N
        for j = 0:K
            ij = j+1+(i-1)*(K+1);
            
            theta_new.tau_sq = theta_new.tau_sq +  ...
                      trace(miu_bvi_bviT( (1+q*(i-1)):(q*i),(1+q*(i-1)):(q*i))) + ...
                      trace(sum(squeeze(subICvar(:,:,i,j+1,:)),3)) + ...
                      2*trace( miu_bvi_svT( (1+q*(i-1)):(q*i),:) ...
                             - miu_svij_bivT( (1+q*(ij-1)):(q*ij), (1+q*(i-1)):(q*i) ,:)...
                             - miu_svij_svT ( (1+q*(ij-1)):(q*ij), :,:) );
                    
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
            tmp2 = sum(mtimesx(tmp,squeeze(subICvar(:,:,i,j+1,:))),3);
            
            
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
