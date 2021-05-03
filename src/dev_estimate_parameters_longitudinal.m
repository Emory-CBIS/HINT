function [theta_new,...
    beta_new,...
    ESi,...
    ES0,...
    ES0S0t,...
    Eb,...
    iter_time,...
    theta_change,...
    beta_change,...
    z_mode,...
    PostProbs] = dev_estimate_parameters_longitudinal(Y,...
    X_mtx,...
    theta,...
    beta,...
    N,...
    J,...
    q,...
    p,...
    m,...
    V,...
    maxit,...
    isScriptVersion, writelog)


% Josh renaming a few things here
disp(['Time points: ', num2str(J)])

iter_time = [];

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

sum_Yij_sq =  sum(Yij(:).^2);

X_mtx2 = X_mtx;               % no intercept for alpha p*N
X_mtx = [ones([1 N]); X_mtx];
sumXiXiT_inv  = eye(p+1)/(X_mtx*X_mtx');  sumXiXiT_inv2  = eye(p)/(X_mtx2*X_mtx2');

%% Josh Version

% Define
ESi       = zeros(q, V, N, J);
Eb        = zeros(q, V, N);
ES0       = zeros(q, V);
ES0S0t    = zeros(q, q, V);

% Ceta is Q x P+1 x V x J ? first 2 dims might be flippeds
XB = zeros(q, V, N, J); % fixed effects contribution
Yi_bar = zeros(q, V, N);
AY = zeros(q, V, N, J);
Y_star   = zeros(q, V);
Yij_star   = zeros(q, V, N, J);

Ebbt = zeros(q, q, V);
YibarES0 = zeros(q, q, V);
EbS0t = zeros(q, q, V);
ESiSit = zeros(q, q, V, J);
ESiS0t = zeros(q, q, V, J);
ESibt = zeros(q, q, V, J);

Si_term_W = zeros(q, q, V);
ES0eit = zeros(q, q, V);
Ebgeit = zeros(q, q, V);
Si_term_A = zeros(q, V);
xbbx = zeros(q, q, V);

for i = 1:N
    for j = 1:J
        %XB(:, :, i, j)    = squeeze(mtimesx(theta.iniguessCeta(:, :, :, j), X_mtx(:, i) ));
        XB(:, :, i, j)    = squeeze(mtimesx(beta(:, :, :, j), X_mtx(:, i) ));
    end
end

currentPlotRange = 10;
theta_change = zeros(maxit, 1);
beta_change = zeros(maxit, 1);

for iter = 1:maxit
    
    tic
    
    %% Iter starts here
    sigmasq_ybar = (diag(theta.D) + (1/J)*(theta.tau_sq*eye(q) + theta.sigma1_sq*eye(q))) / N ;
    
    alpha_priprec = J ./ (theta.tau_sq + theta.sigma1_sq);
    alpha_pvar = inv( J ./ (theta.tau_sq + theta.sigma1_sq) * eye(q) + diag(1 ./ theta.D) );
    
    theta_new.D      = zeros(q, q);
    theta_new.tau_sq = 0.0;
    
    %% Whole brain quantities - might not need all pieces if do v loop?
    Yi_bar(:, :, :) = zeros(q, V, N);
    for i = 1:N
        for j = 1:J
            AY(:, :, i, j) = theta.A(:, :, i, j)' * squeeze(Yij(:, i, j, :));
            Yij_star(:, :, i, j) = AY(:, :, i, j) - XB(:, :, i, j);
            Yi_bar(:, :, i) = Yi_bar(:, :, i) + Yij_star(:, :, i, j);
        end
        % Turn into an average instead of a sum
        Yi_bar(:, :, i) = Yi_bar(:, :, i) / J;
    end
    % Overall mean of unmixed, fixed effects centered data
    Y_star(:, :) = mean(Yi_bar, 3);
    
    %% Latent State Probabilities
    RectMu = theta.miu3;
    RectSig = theta.sigma3_sq;
    PriorProbs = theta.pi;
    %DataProbs  = zeros(q, m, V);
    DataProbsLog  = zeros(q, m, V);
    for im = 1:m
        prec =  1 ./ (diag(sigmasq_ybar) + RectSig(:, im));
        % this is correct but can underflow
        %DataProbs(:, im, :) = PriorProbs(:, im) .* exp(-0.5 * (Y_star - RectMu(:, im)).^2 .* prec) .* sqrt(prec);
        % Log sum exp version
        DataProbsLog(:, im, :) = log(PriorProbs(:, im))...
            + (-0.5 * (Y_star - RectMu(:, im)).^2 .* prec)...
            + 0.5*log(prec);
    end
    
    lsexp = logsumexp(DataProbsLog, 2);
    PostProbs = exp(DataProbsLog(:, :, :) - lsexp);
    %PostProbs = DataProbs(:, :, :) ./ sum(DataProbs, 2);
    
    theta_new.miu3 = zeros(q, m);
    theta_new.pi = zeros(q, m);
    theta_new.sigma3_sq = zeros(q, m);
    
    
    %% Expectation of S0, S0S0'
    avg_probs = mean(PostProbs, 3);
    phi_star_inv    = 1 ./ diag(sigmasq_ybar);
    ES0(:, :)    = zeros(q, V);
    ES0S0t(:, :, :)    = zeros(q, q, V);
    for im = 1:m
        % conditional mean and variance for S0
        % Precisions
        prior_precision = 1 ./ RectSig(:, im);
        
        % Conditional Mean and Variance
        posterior_var  = 1 ./ (phi_star_inv + prior_precision);
        posterior_mean = posterior_var .* (phi_star_inv .* Y_star + prior_precision .* RectMu(:, im) );
        
        ES0(:, :)       = ES0(:, :) + posterior_mean .* squeeze(PostProbs(:, im, :));
        
        tt = (posterior_var + posterior_mean.^2) .* squeeze(PostProbs(:, im, :));
        for v = 1:V
            ES0S0t(:, :, v) = ES0S0t(:, :, v) + diag(tt(:, v));
        end
        
        %% MoG parameters - M-step
        theta_new.miu3( :, im )     = mean(posterior_mean .* squeeze(PostProbs(:, im, :)), 2) ./ avg_probs(:, im);
        theta_new.sigma3_sq( :, im) = mean(tt, 2) ./ avg_probs(:, im) - theta_new.miu3( :, im ).^2;
        theta_new.pi(:, im) =  avg_probs(:, im);
    end
    
    %disp('dont forget me')
    prodterm = mtimesx( reshape(ES0, [q, 1, V]), reshape(ES0, [1, q, V]) ) ;
    for v = 1:V
        ES0S0t(:, :, v) = ES0S0t(:, :, v) + prodterm(:, :, v) - diag(diag(prodterm(:, :, v)));
    end
    
    % M - diag(diag(M))
    
    %% Subject Loop
    vstar = alpha_pvar * alpha_priprec;
    
    Sigma_Si = 1 / ( 1/theta.tau_sq + 1/theta.sigma1_sq);
    Omega_Si = Sigma_Si / theta.sigma1_sq;
    post_var_Sij  = 1 / ( 1/theta.tau_sq + 1/theta.sigma1_sq);
    varrat = post_var_Sij / theta.sigma1_sq;
    
    
    beta_new =  zeros(q,p+1,V, J);
    
    
    tausq = trace(sum(ES0S0t, 3)) * N * J;
    sum_tr_ESiSit = 0.0;
    
    for i = 1:N
        
        %% Random Intercept - This is stored and returned
        Eb(:, :, i) = alpha_pvar * (Yi_bar(:, :, i) - ES0) * alpha_priprec;
        
        %% Second non-central moment for random int. Not stored for storage resons
        % instead the computations that use it are incremented
        YibarES0(:, :, :) =  mtimesx( reshape(Yi_bar(:, :, i), [q, 1, V]), reshape(ES0, [1, q V]));
        Ebbt(:, :, :)     = alpha_pvar ...
            + mtimesx(mtimesx(vstar, ( mtimesx( reshape(Yi_bar(:, :, i), [q, 1, V]), reshape(Yi_bar(:, :, i), [1, q, V])) ...
            - YibarES0 ...
            - permute(YibarES0, [2, 1, 3]) + ES0S0t)), vstar);
        
        %% Cross product of random intercept and S0 maps, also only stored
        % for intermediate computations
        EbS0t(:, :, :) = mtimesx(vstar, (YibarES0 - ES0S0t));
        
        %% Sij update, vect across all visits, these are stored and returned
        %post_var = post_var_Sij
        post_mean = post_var_Sij * (1/theta.sigma1_sq * AY(:, :, i, :) +...
            1/theta.tau_sq * bsxfun(@plus, ES0 + Eb(:, :, i), XB(:, :, i, :)) );
        ESi(:, :, i, :) = post_mean;
        
        %% ESijSij', very large amount of storage, so not returned
        % Intermediate quantities
        Si_term_W(:, :, :) = ES0S0t + EbS0t + permute(EbS0t, [2, 1, 3]) + Ebbt;
        Si_term_A(:, :)    = ES0 + Eb(:, :, i);
        for j = 1:J
            xbbx(:, :, :) = mtimesx(reshape(XB(:, :, i, j), [q, 1, V]), reshape(XB(:, :, i, j), [1, q, V]));
            term_A =  mtimesx(reshape(Si_term_A, [q, 1, V]), reshape(XB(:, :, i, j), [1, q, V]));
            term2 = term_A + permute(term_A, [2, 1, 3]) + xbbx;
            
            s_b_xb_Yig = mtimesx(reshape(Si_term_A + XB(:, :, i, j), [q, 1, V]), reshape(Yij_star(:, :, i, j), [1, q, V])) * Omega_Si;
            
            term3 = s_b_xb_Yig - permute(term_A, [2, 1, 3])*Omega_Si - Si_term_W*Omega_Si;
            term3 = term3 + permute(term3, [2, 1, 3]);
            
            YSpB = mtimesx(reshape(Yij_star(:, :, i, j), [q, 1, V]), reshape(Si_term_A, [1, q, V]));
            
            term4 = Sigma_Si*eye(q) + Omega_Si *...
                ( mtimesx( reshape(Yij_star(:, :, i, j), [q, 1, V]), reshape(Yij_star(:, :, i, j), [1, q, V])) -...
                YSpB - permute(YSpB, [2, 1, 3]) + Si_term_W)*Omega_Si;
            
            ESiSit(:, :, :, j) = Si_term_W + term2 + term3 + term4;
            
            ES0eit(:, :, :) = ( mtimesx(reshape(ES0, [q, 1, V]), reshape(Yij_star(:, :, i, j), [1, q, V])) - ES0S0t - permute(EbS0t, [2, 1, 3]) ) * varrat;
            
            Ebgeit(:, :, :) = ( mtimesx(reshape(Eb(:, :, i), [q, 1, V]), reshape(Yij_star(:, :, i, j), [1, q, V])) - EbS0t - Ebbt ) * varrat';
            
            ESibt(:, :, :, j) = permute(EbS0t, [2, 1, 3]) + Ebbt +...
                mtimesx(reshape(XB(:, :, i, j), [q, 1, V]), reshape(Eb(:, :, i), [1, q, V])) + permute(Ebgeit, [2, 1, 3]);
            
            % Finally, ESiS0t
            ESiS0t(:, :, :, j) = ES0S0t + EbS0t + mtimesx(reshape(XB(:, :, i, j), [q, 1, V]), reshape(ES0, [1, q, V])) + permute(ES0eit, [2, 1, 3]);
            
            %% M-step for A
            % we do this here since it depends on ESijSij'
            A_ProdPart1 = squeeze(Yij(:, i, j, :)) * ESi(:, :, i, j)' ;
            A_ProdPart2 = sum(ESiSit(:, :, :, j), 3);
            theta_new.A(:,:,i,j) = A_ProdPart1/ (A_ProdPart2 );
            theta_new.A(:,:,i,j) = theta_new.A(:,:,i,j)*real( inv(theta_new.A(:,:,i,j)' * theta_new.A(:,:,i,j)) ^ (1/2));
            
            %% Contribtion to update for fixed effects
            resid = ESi(:, :, i, j) - ES0 - Eb(:, :, i); % q by V
            if j == 1
                beta_new(:,2:(p+1),:,j) = beta_new(:,2:(p+1),:,j)+mtimesx(reshape(resid,[q 1 V]), X_mtx2(:,i)');
            else
                beta_new(:,:,:,j)       = beta_new(:,:,:,j) + mtimesx(reshape(resid,[q 1 V]), X_mtx(:,i)');
            end
            
        end % end loop over visits
        
        % Parts of the tau update M-step that we do not store need to be
        % calculated now
        sum_tr_ESiSit = sum_tr_ESiSit + trace(sum(sum(ESiSit, 3), 4));
        
        tausq = tausq ...
            + J * trace(sum(Ebbt, 3)) ...
            + 2 * trace(sum(sum(EbS0t...
            - ESibt ...
            - ESiS0t, 3), 4));
        
        %% M-step, variance of random intercept
        theta_new.D = theta_new.D + 1 / (N*V) * sum(Ebbt, 3);
        
    end
    
    theta_new.D  = diag(theta_new.D);
    
    %% Finish updating betas
    for j = 1:J
        if j==1
            beta_new(:,2:(p+1),:,j)= mtimesx(beta_new(:,2:(p+1),:,j), sumXiXiT_inv2);  % new Ceta_j(v), coefficient matrix at voxel v
        else
            beta_new(:,:,:,j)      = mtimesx(beta_new(:,:,:,j), sumXiXiT_inv);  % new Ceta_j(v), coefficient matrix at voxel v
        end
    end
    
    %% Finish updating tau using new XB term
    tausq = tausq + sum_tr_ESiSit;
    for i = 1:N
        for j = 1:J
            XB(:, :, i, j) = squeeze(mtimesx(beta_new(:, :, :, j), X_mtx(:, i)));
            tausq = tausq ...
                + sum(sum(squeeze(XB(:, :, i, j)).^2)) ...
                + 2 * sum(sum(squeeze(XB(:, :, i, j)) .* squeeze((ES0 + Eb(:, :, i) - ESi(:, :, i, j)))));
        end
    end
    tausq = tausq / ( J*N*V*q );
    theta_new.tau_sq = tausq;
    
    %% Update the first-level variance term
    sum_YAS = 0.0;
    for i = 1:N
        for j = 1:J
            sum_YAS = sum_YAS + sum(sum(squeeze(Yij(:, i, j, :)) .* (theta_new.A(:,:,i,j) * ESi(:, :, i, j))));
        end
    end
    
    sigma1sq = sum_Yij_sq ...
        - 2 * (sum_YAS) ...
        + sum_tr_ESiSit;
    theta_new.sigma1_sq = sigma1sq / ( (J)*N*V*q );
    
    %% End of EM Updates
    
    % Handle renaming and setting, delta calculation
    D_change      = norm(theta.D - theta_new.D) / norm(theta.D);
    Tau_change    = norm(theta.tau_sq - theta_new.tau_sq) / norm(theta.tau_sq);
    Sig1_change   = norm(theta.sigma1_sq - theta_new.sigma1_sq) / norm(theta.sigma1_sq);
    A_change      = norm(theta.A(:) - theta_new.A(:)) / norm(theta.A(:));
    miu3_change   = norm(theta.miu3(:) - theta_new.miu3(:)) / norm(theta.miu3(:));
    sigma3_change = norm(theta.sigma3_sq(:) - theta_new.sigma3_sq(:)) / norm(theta.sigma3_sq(:));
    pi_change     = norm(theta.pi(:) - theta_new.pi(:)) / norm(theta.pi(:));
    beta_change_iter   = norm(beta(:) - beta_new(:)) / norm(beta(:));
    
    theta_change_iter = max([D_change, Tau_change, Sig1_change, A_change, miu3_change, sigma3_change, pi_change]);
    
    disp(['Theta relative change: ', num2str(theta_change_iter)])
    disp(['Beta relative change:  ', num2str(beta_change_iter)])
    
    theta_change(iter) = (theta_change_iter);
    beta_change(iter) = (beta_change_iter);
    
    xxx=1;
    
    %% Logging and User Feedback for this iteration
    
    % Write to the log file
    if isScriptVersion == 0 && writelog == 1
        outfile = fopen(outfilename_full, 'a' );
        fprintf(outfile, 'iteration %6.0f: the difference is %6.6f for theta and %6.6f for beta \n',...
            itr, theta_change_iter, beta_change_iter);
    end
    updatePlot=1;
    % count up by 10 for the plot axes
    if iter > currentPlotRange
        currentPlotRange = currentPlotRange + 10;
    end
    % If the gui version is being run then update the GUI
    if isScriptVersion == 0 && (updatePlot || iter == maxiter)

        % Theta change plot
        axes(findobj('tag','iterChangeAxis1'));
        set(gca,'NextPlot','add');
        h = findobj('tag','iterChangeAxis1');
        h = get(h,'Children');
        set(h,'xdata',(1:currentPlotRange),'ydata',[theta_change(1:iter)', zeros(1, currentPlotRange-iter) ]); drawnow;
        %print(gca, [outpath '/' prefix '_theta_progress_plot'],'-dpng')

        % Beta change plot
        axes(findobj('tag','iterChangeAxis2'));
        set(gca, 'NextPlot', 'add');
        h = findobj('tag','iterChangeAxis2');
        h = get(h,'Children');
        set(h,'xdata',(1:currentPlotRange),'ydata',[beta_change(1:iter)', zeros(1, currentPlotRange-iter) ]); drawnow;
        %print(plot2, [outpath '/' prefix '_beta_progress_plot'],'-dpng')

        % Update the embedded waitbar
        axes(findobj('tag','analysisWaitbar'));
        cla;
        rectangle('Position',[0,0,0+(round(1000*iter/maxit)),20],'FaceColor','g');
        text(482,10,[num2str(0+round(100*iter/maxit)),'%']);
        drawnow;
    end
    
%     theta_new.iniguessCeta = beta_new;
%     [vec_theta_new, vec_Ceta_new] = VectThetaBetaLICA ( theta_new);
%     [vec_theta, vec_Ceta]         = VectThetaBetaLICA ( theta );
%     err1(iter) = norm(vec_theta_new - vec_theta)/norm(vec_theta);
%     err2(iter) = norm(vec_Ceta_new  - vec_Ceta)/norm(vec_Ceta);
%     fprintf('iteration %6.0f and the difference is  %6.6f for theta and %6.6f for beta \n', iter, err1(iter), err2(iter));
    
    % Set theta
    theta = theta_new;
    beta = beta_new;
    
    iter_time = [iter_time; toc];
    
    
    
end

% Get the most likely latent state configuration for each voxel
z_mode = zeros(q, V);
for v = 1:V
    [~, z_mode(:, v)] = max(PostProbs(:, :, v), [], 2);
end

end
