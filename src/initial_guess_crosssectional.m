function [theta, guessBeta, popAvgComponents] = initial_guess_crosssectional(stackedWhitenedData,...
    S0Init, X)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

    theta = struct();
    
    [QN, V] = size(stackedWhitenedData);
    Q = size(S0Init, 1);
    N = QN / Q;
    P = size(X, 2);

    projectionMat = S0Init' * inv(S0Init * S0Init');
    Ai  = zeros(Q, Q, N);
    Si = zeros(Q, V, N);
    
    sSqError = 0.0;
    
    % Project each subject's data onto the initial guess for the ICs
    % to get the estimated mixing matrix, then regress again to get subject
    % specific component estimates
    for i = 1:N
        Atemp = stackedWhitenedData((Q*(i-1)+1):(Q*i), :) * projectionMat;
        
        % Orthogonalization transformation
        subjAi = Atemp * real(inv(Atemp'*Atemp)^(1/2));
        
        % Get the corresponding Si
        subjSi = subjAi' *  stackedWhitenedData((Q*(i-1)+1):(Q*i), :);
        
        % Get the error term
        errs = stackedWhitenedData( (Q*(i-1)+1):(Q*i), :) - subjSi;
        sSqError = sSqError + sum( errs(:).^2 );
        
        Ai(:, :, i) = subjAi;
        Si(:, :, i) = subjSi;
    end
    
    guessLevel1Var  = sSqError / (Q * N * V - 1);
    theta.sigma1_sq = guessLevel1Var;
    theta.A = Ai;

    
    % Fit regression model at each voxel to get the initial values
    Xall = [ones(size(X, 1), 1) X];
    XtXinv = inv(Xall' * Xall);
    proj = XtXinv * Xall';
    guessLevel2Var = zeros(Q, 1);
    guessS0 = zeros(Q, V);
    guessBeta = zeros(P, Q, V);
    for qq = 1:Q
        
        est  = proj * squeeze(Si(qq,:,:))';
        guessS0(qq, :) = est(1, :); 
        guessBeta(:,qq,:) = est(2:(P+1), :);
        
        % Get error term
        epsilon = squeeze(Si(qq,:,:))' - Xall*est;
        guessLevel2Var(qq) = var(epsilon(:));
        
    end
    theta.sigma2_sq = guessLevel2Var;
    
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

