function [ varCeta1 ] = var_est_longitudinal( theta_est, beta_est, X,...
    z_mode, YtildeStar, G_z_dict, voxSize,...
    validVoxels, prefix, outpath )
%var_est_longitudinal - Summary of this function goes here
%   Detailed explanation goes here

% Detect object dimensions
q = size(theta_est.sigma3_sq, 1) / 2;
T =  size(theta_est.A, 4);
V = size(beta_est, 3);
K = size(beta_est, 4) - 1;
p = size(beta_est, 2) - 1;
N = size(theta_est.A, 3);

X = [ones(N, 1), X(1:T:end, :)]';

% Allocate space
Zvalue1 = zeros(q*p*(T+1),V);
varCeta1 = zeros(q*(p+1)*(K+1),q*(p+1)*(K+1),V);
W_var1 = zeros(q*(K+1),q*(K+1),V);
%W_var2 = zeros(q*(K+1),q*(K+1),V);
%W_var3 = zeros(q*(K+1),q*(K+1),V);
%W_var4 = zeros(q*(K+1),q*(K+1),V);
U = kron(ones(K+1, 1), eye(q));

% Calculate variance at each voxel
for v = 1:V
    
    % Theoretical
    Sigma3z  = (G_z_dict(:,:,z_mode(v)) * theta_est.sigma3_sq);
    
    W_var1(:,:,v) = (theta_est.tau_sq + theta_est.sigma1_sq) *...
        eye(q*(K+1)) + U * diag(theta_est.D+Sigma3z)*U';
    
    %Ceta_matrix = zeros(q*(K+1),p+1,V);
    %for j = 0:K
    %    Ceta_matrix((1+q*j):(q+q*j),:,:) = theta_est.iniguessCeta(:,:,:,j+1);
    %end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    W_varinv1 = inv(W_var1(:,:,v));
    
    
    %%%%%%%%%%%%   Estimate the Covariance of Ceta; %%%%%%%%%%%%%%%
    X0star = eye(K+1);
    X0star(:,1) = ones(K+1, 1);
    X0star = kron(X0star,eye(q));
    
    for i =1:N
        Xistar = kron(eye(K+1),kron(X(2:(p+1),i)',eye(q)));
        Xiplus = [X0star Xistar];
        
        varCeta1(:,:,v) = varCeta1(:,:,v)+ Xiplus'*W_varinv1*Xiplus;
    end
    
    varCeta1(:,:,v) = inv(varCeta1(:,:,v));
end

% Finished estimate the covariance matrix for C(v)
%save([path_data 'varCeta_sel2.mat'],'varCeta1','-v7.3')

% Create the maps for each IC based on the theoretical variance
% estimator
for iIC = 1:q
    for iVisit = 1:T
        
        % Create an indexing array to grab the right elements of the
        % estimates
        
        % THIS IS INDEXING ASSUMING THAT IT GOES:
        indArrStart = (iVisit-1)*( (p+1)*q ) + (iIC-1)*(p+1) + 1;
        indArr = indArrStart:(indArrStart+(p));
        %disp(indArr)

        % Fill out the variance estimate
        newMap = zeros( [p+1, p+1, voxSize] ); % empty for intermediate var map
        tempData = squeeze(varCeta1(indArr, indArr, :));
        newMap( :,:, validVoxels ) = tempData;
        betaVarEst = newMap;

        % Save as a .mat file to be loaded in the display viewer
        fname = fullfile(outpath, [prefix '_BetaVarEst_IC' num2str(iIC)...
            '_visit' num2str(iVisit) '.mat']);
        save(fname, 'betaVarEst');
    end
end


end

