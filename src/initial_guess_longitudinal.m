function [theta, betaGuessAll, popAvgComponents] = initial_guess_longitudinal(stackedWhitenedData,...
    S0Init, X, nVisit)
%initial_guess_longitudinal Summary of this function goes here
%   Detailed explanation goes here

    theta = struct();
    
    [QNJ, V] = size(stackedWhitenedData);
    Q = size(S0Init, 1);
    N = QNJ / (Q*nVisit);
    P = size(X, 2);

    projectionMat = S0Init' * inv(S0Init * S0Init');
    Ai  = zeros(Q, Q, N, nVisit);
    Si = zeros(Q, V, N * nVisit);
    
    sSqError = 0.0;
    
    % Project each subject's data onto the initial guess for the ICs
    % to get the estimated mixing matrix, then regress again to get subject
    % specific component estimates
    eInd = 0;
    ind = 0; % for Si
    for i = 1:N
        for j = 1:nVisit
            ind = ind + 1;
            sInd = eInd + 1;
            eInd = eInd + Q;
            Atemp = stackedWhitenedData(sInd:eInd, :) * projectionMat;

            % Orthogonalization transformation
            subjAi = Atemp * real(inv(Atemp'*Atemp)^(1/2));

            % Get the corresponding Si
            subjSi = subjAi' *  stackedWhitenedData(sInd:eInd, :);

            % Get the error term
            errs = stackedWhitenedData( sInd:eInd, :) - subjSi;
            sSqError = sSqError + sum( errs(:).^2 );

            Ai(:, :, i, j) = subjAi;
            Si(:, :, ind) = subjSi;
        end
    end
    
    guessLevel1Var  = sSqError / (Q * N * V * nVisit - 1);
    theta.sigma1_sq = guessLevel1Var;
    theta.A = Ai;

    % Modified version of the design matrix to work better below:
    Xtemp = X;
    X = [];
    % Create X as a N x P*nVisit matrix.
    for i = 1:N
        X = [X; kron(eye(nVisit), Xtemp(i, :))];
    end
    
    % Next we add a column for the intercept (S0) followed by the effects
    % coded visit effects
    basicBlock = [-1 * ones(1, nVisit-1) ; eye(nVisit - 1)];
    blockWithS0 = [ones(nVisit, 1) basicBlock];
    X = [repmat(blockWithS0, [N, 1]) X];
    
    
    % Fit regression model at each voxel to get the initial values
    
    % Predictors corresponding to each visit    
    XtXinv = inv(X' * X);    
    proj = XtXinv * X';
    pStar = P * nVisit;
    guessLevel2Var = zeros(Q, 1);
    guessS0 = zeros(Q, V);
    guessAlpha = zeros(nVisit-1, Q, V);
    guessBeta  = zeros(pStar, Q, V);
    subjResidualMeans = zeros(Q, V, N);
    for qq = 1:Q
        
        est  = proj * squeeze(Si(qq,:,:))';
        guessS0(qq, :) = est(1, :); 
        guessAlpha(:,qq,:) = est(2:(nVisit), :);
        guessBeta(:,qq,:)  = est( (nVisit+1):(nVisit+pStar), :);
        
        % Get error term
        epsilon = squeeze(Si(qq,:,:))' - X*est;
        
        % Subject specific random effects - guess
        eInd = 0;
        for i = 1:N
            sInd = eInd + 1; eInd = eInd + nVisit;
            % rough estimate of subject level random effect (just for
            % guess)
            subjResidualMeans(qq, :, i) = mean(epsilon(sInd:eInd, :), 1);
        end
        
        guessLevel2Var(qq) = var(epsilon(:));
        
    end
    theta.tau_sq = mean(guessLevel2Var(:));
    
    % Variance of the "random effects"
    theta.D = var(subjResidualMeans, [], [2,3]) ;
    
    % Now create a combined version of alpha and beta to return as the
    % initial guess
%     betaGuessAll = zeros(Q, P+1, V, nVisit);
%     for j = 1:nVisit
%         if j > 1
%             betaGuessAll(:, 1, :, j) = guessAlpha(j-1, :, :);
%         end
%         for qq = 1:Q
%             betaGuessAll(qq, 2:(P+1), :, j) = guessBeta((P*(j-1)+1):(j*P),qq, :);
%         end
%     end
    betaGuessAll = zeros(Q, nVisit-1+P*nVisit, V);
    for qq = 1:Q
        betaGuessAll(qq, 1:nVisit-1, :) = guessAlpha(:,qq,:);
        betaGuessAll(qq, nVisit:end, :) = guessBeta(:,qq,:);
    end
    
    
    % Estimate parameters in MoG
    m = 2;
    for j = 1:Q
        S0_j = squeeze(guessS0(j,:)');
        sigma_noise = sqrt(var(S0_j));
        % Determine sign of activation mean
        quants = quantile(S0_j, [0.025, 0.975]);
        MoG_sign = 1;
        if abs(quants(1)) > abs(quants(2))
            MoG_sign = -1;
        end
        % Cutoff
        cutpoint = 1.64 * sigma_noise;
        if sum((S0_j*MoG_sign) > cutpoint) > 0
            if abs(quants(1)) > abs(quants(2))
                cutpoint = quants(1);
            else
                cutpoint = quants(2);
            end
        end
        theta.miu3(2+(j-1)*m)      = mean( S0_j( (S0_j*MoG_sign) > (MoG_sign*cutpoint) ) );
        theta.sigma3_sq(2+(j-1)*m) = var( S0_j( (S0_j*MoG_sign) > (MoG_sign*cutpoint) ) );
        theta.sigma3_sq(1+(j-1)*m) = sigma_noise^2;
        theta.pi(2+(j-1)*m)        = sum( (S0_j*MoG_sign) > (MoG_sign*cutpoint) ) / numel(S0_j);
        theta.pi(1+(j-1)*m)        = 1 - theta.pi(2+(j-1)*m);
    end
    theta.miu3 = theta.miu3';
    theta.sigma3_sq =  theta.sigma3_sq';
    theta.pi =     theta.pi';
    
    
    popAvgComponents = mean(Si, 3);

end

