    
function [theta, beta, grpSig, s0_agg] = InitialGuessLICA( prefix, Ytilde,...
    N,q,V, p, X, nVisit, maskfl)

%% these shoould be the new arguments
% data.niifiles, data.maskf, ...
%                    get(findobj('Tag', 'prefix'), 'String'),...
%                    get(findobj('Tag', 'analysisFolder'), 'String'),...
%                    str2double(numberOfPCs.String),...
%                    data.N, data.q, data.X, data.Ytilde, hcicadir,
%                    data.nVisit


%% Changes to variable names
% T becomes nVisit
% N becomes N (needs to be number of subjects)
% Remove C_diag_matrix

%% Changes to variable names
% T becomes nVisit
% N becomes N (needs to be number of subjects)
% Remove C_diag_matrix

mask = load_nii(maskfl);

% Create a version of the design matrix that is appropriate for this script
Xorig = X;
selectRows = 1:nVisit:N*nVisit; % one row per subject
Xtemp = Xorig(selectRows, :);
% add a row of ones to the top
%X = [ones(1, N); Xtemp'];

%Xall = kron(eye(nVisit), Xtemp')';
%Xallint = [ones(N*nVisit, 1) Xall];
X = [];
for i = 1:N
    X = [X; kron(eye(nVisit), Xtemp(i, :))];
end

% above design matrix does not include alpha -> estimate that at the end

% rearrange Ytilde to be order visit -> subject within visit
% yinds = [];
% for j = 1:nVisit
%     yinds = [yinds; repmat(0:(q-1), 1, N)'  + repmat( (j:nVisit*q:nVisit*N)', q, 1) ];
% end
% YtildeVisitOrder = Ytilde(yinds, :);

% Load in the initial estimate for each Sij(v)
initial_guess_Sij = zeros(q, V, N, nVisit);
ind = 0;
for i = 1:N
    for j = 1:nVisit
        ind = ind + 1;
        subject_visit_data = load([prefix '_ica_br' num2str(ind) '.mat']); % q by V
        initial_guess_Sij(:, :, i, j) = subject_visit_data.compSet.ic;
    end
end

% Subject Specific Mixing Matrices
Aij = zeros(q, q, N, nVisit);
eind = 0;
for i = 1:N
    for j = 1:nVisit
        sind = eind + 1; eind = eind + q;
        Aijtemp = Ytilde(sind:eind, :) * initial_guess_Sij(:, :, i, j)' * inv(initial_guess_Sij(:, :, i, j) * initial_guess_Sij(:, :, i, j)');
        %Aijtemp = Aijtemp';
        Aij(:, :, i, j) = Aijtemp*real(inv(Aijtemp'*Aijtemp)^(1/2));
    end
end

% Now reverse direction to get Sij on the same scale as the Ytilde data
eind = 0;
initial_guess_Sij_stacked = zeros(q, V, N*nVisit);
ind = 0;
for i = 1:N
    for j = 1:nVisit
        ind = ind + 1; % for Sij
        sind = eind + 1; eind = eind + q; %for Y
        initial_guess_Sij(:, :, i, j) = Aij(:, :, i, j)' * Ytilde(sind:eind, :);
        initial_guess_Sij_stacked(:, :, ind) = Aij(:, :, i, j)' * Ytilde(sind:eind, :);
    end
end

% Next we fit voxel specific regression models to estimate beta and S0 (NOT
% alpha)
% S0temp   = zeros(q, V);
% betatemp = zeros(p, q, V, nVisit);
% Xint = [ones(N*nVisit, 1) X];
% proj = inv(Xint' * Xint) * Xint';
% for qq = 1:q
%     est  = proj * squeeze(initial_guess_Sij_stacked(qq,:, :))';
%     S0temp(qq, :) = est(1, :); 
%     for j = 1:nVisit
%         betatemp(:, qq, :, j) = est( (1 + (j-1)*p+1):(1 + j*p), :);
%     end
% end

% Next we fit voxel specific regression models to estimate beta and S0
% (WITH
% alpha)
S0temp   = zeros(q, V);
betatemp = zeros(p, q, V, nVisit);
alpha_guess = zeros(q, V, nVisit);
alphalead = eye(nVisit); alphalead(1, 1) = 0;
alphaX = repmat(alphalead, N, 1);
alphaX = alphaX(:, 2:end);
Xint = [ones(N*nVisit, 1) alphaX X];
proj = inv(Xint' * Xint) * Xint';
for qq = 1:q
    est  = proj * squeeze(initial_guess_Sij_stacked(qq,:, :))';
    S0temp(qq, :) = est(1, :); 
    for j = 1:nVisit
        if j > 1
            alpha_guess(qq, :, j) = est(j, :);
        end
        betatemp(:, qq, :, j) = est( (nVisit + (j-1)*p+1):(nVisit + j*p), :);
    end
end

% Now estimate alpha using the residuals
% alpha_guess = zeros(q, V, nVisit);
% ind = 0;
% for i = 1:N
%     for j = 1:nVisit
%         ind = ind + 1;
%         resid = initial_guess_Sij(:, :, i, j) ...
%             - S0temp ...
%             - squeeze(mtimesx( X(ind, ((j-1)*p+1):(j*p) ), betatemp(:, :, :, j) ));
%         alpha_guess(:, :, j) = alpha_guess(:, :, j) + resid;
%     end
% end
% % dimension q x V x n Visit
% alpha_guess = alpha_guess / N;

%% Estimation of subject specific random intercept
bi_est = zeros(q, V, N);
ind = 0;
for i = 1:N
    sum_level_2_residual(:, :) = 0;
    for j = 1:nVisit
        ind = ind + 1;
        resid = initial_guess_Sij(:, :, i, j) ...
            - S0temp ...
            - alpha_guess(:, :, j) ...
            - squeeze(mtimesx( X(ind, ((j-1)*p+1):(j*p) ), betatemp(:, :, :, j) ));
        sum_level_2_residual = sum_level_2_residual + resid;
    end
    bi_est(:, :, i) = sum_level_2_residual / nVisit;
end

%% Estimation of residual variance terms
% sum_level1_error = zeros(q, V);
% sum_level2_error = zeros(q, V);
% eind = 0;
% ind = 0;
% for i = 1:N
%     for j = 1:nVisit
%         ind = ind + 1;
%         sind = eind + 1; eind = eind + q;
%         % First level is Yij - AijSij
%         sum_level1_error = sum_level1_error ...
%             + (Ytilde(sind:eind, :) - Aij(:, :, i, j) * initial_guess_Sij(:, :, i, j));
%         sum_level2_error = sum_level2_error...
%             + (Aij(:, :, i, j)' * Ytilde(sind:eind, :) ...
%             - S0temp ...
%             - alpha_guess(:, :, j) ...
%             - bi_est(:, :, i)...
%             - squeeze(mtimesx( X(ind, ((j-1)*p+1):(j*p) ), betatemp(:, :, :, j) )) );
%     end
% end
sigma_1_sq = var(Ytilde(:));
sigma_2_sq = var(initial_guess_Sij(:));

%% Estimate parameters of MoG using heuristic approach
m = 2;
for j = 1:q
    S0_j = squeeze(S0temp(j,:)');
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
    
    theta.miu3(2+(j-1)*m)      = mean( S0_j( (S0_j*MoG_sign) > cutpoint ) );
    theta.sigma3_sq(2+(j-1)*m) = var( S0_j( (S0_j*MoG_sign) > cutpoint ) );
    theta.sigma3_sq(1+(j-1)*m) = sigma_noise^2;
    theta.pi(2+(j-1)*m)        = sum( (S0_j*MoG_sign) > cutpoint ) / numel(S0_j);
    theta.pi(1+(j-1)*m)        = 1 - theta.pi(2+(j-1)*m);

    % Zero out covariate effects that don't fall within 
    %Ceta_post( :, j, (S0_j*MoG_sign) < cutpoint ) = 0.0;
end
theta.miu3 = theta.miu3';
theta.sigma3_sq =  theta.sigma3_sq';

%% Prepare return objects
grpSig = S0temp;

% Combine alpha and beta
% iniguessCeta = zeros(q,p+1,V,T+1);
combined_alpha_beta = zeros(q, p+1, V, nVisit);
for j = 1:nVisit
    combined_alpha_beta(:, 1, :, j) = alpha_guess(:, :, j);
    for qq = 1:q
        combined_alpha_beta(qq, 2:(p+1), :, j) = betatemp(:, qq, :, j);
    end
end

% Second level variance 
theta.tau_sq = sigma_2_sq;
% Random effects variance
theta.D = var(bi_est, [], [2,3]) ;

theta.sigma1_sq = sigma_1_sq; % v0
    
theta.A = Aij;

agg_IC = load_nii([prefix '_agg__component_ica_.nii']);
s0_agg = zeros(q, V);
for c = 1:q
    tempVals = reshape(agg_IC.img(:,:,:,c), [1, numel(agg_IC.img(:,:,:,c))]);
    s0_agg(c,:) = reshape(tempVals(mask.img==1), [1, V]);
end

% for function return
beta = combined_alpha_beta;

theta.S0 = S0temp;

    

end