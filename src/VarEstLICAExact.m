function VarEstLICAExact( theta_est, beta_est, Xin,...
    PostProbs, YtildeStar, voxSize,...
    validVoxels, prefix, outpath )

%var_est_longitudinal - Summary of this function goes here
%   Detailed explanation goes here

% Detect object dimensions
q = size(theta_est.sigma3_sq, 1) ;
T =  size(theta_est.A, 4);
V = size(beta_est, 3);
K = T - 1;
p = size(beta_est, 2);
N = size(theta_est.A, 3);

% Fixup the model matrix to include visit information
Xtemp = Xin;
X = [];
% Create X as a N x P*nVisit matrix.
for i = 1:N
    X = [X; kron(eye(T), Xtemp(i, :))];
end

% Next we add a column for the intercept (S0) followed by the effects
% coded visit effects
basicBlock = [-1 * ones(1, T-1) ; eye(T - 1)];
X = [repmat([ones(T, 1) basicBlock], [N, 1]) X];

% Estimate using loop over components
% Mog variance contribution
sigma3All = sum( bsxfun(@times, PostProbs, theta_est.sigma3_sq), 2 );
varEstIC = zeros(p+1, p+1, V);
for qq = 1:q

    baseVar = (theta_est.tau_sq + theta_est.sigma1_sq) * eye(T);
    
    mogContrib = theta_est.D(qq)+sigma3All(qq, :);
        
    % Invert (sherman morrison formula based)
    Winv = diag(1.0 ./ diag(baseVar));
    subtractTerm = (mogContrib ./ (baseVar(1,1)^2 + T * baseVar(1,1) .* mogContrib) );
    Winv = Winv - bsxfun(@times, reshape(subtractTerm(:), [1, 1, V]), ones(T, T, V));
    
    % Multiply for each subjects
    indEnd = 0;
    for i = 1:N
        indStart = indEnd + 1;
        indEnd = indEnd + T;
                
        varEstIC(:,:,:) = varEstIC(:,:,:) +...
            mtimesx( mtimesx(X(indStart:indEnd, :)', Winv), X(indStart:indEnd, :));
    end
        
    % Save the estimates to a .mat file
    fname = fullfile(outpath, [prefix '_BetaVarEst_IC' num2str(qq)...
            '.mat']);
    save(fname, 'varEstIC');

end


end

