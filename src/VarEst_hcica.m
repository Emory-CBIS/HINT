function [varBeta1] = VarEst_hcica(theta_est, beta_est, X,...
    z_mode, Y_tilde_all, G_z_dict, voxSize, validVoxels, prefix,...
    outpath)
% VarEst - Function to calculate the covariance matrix of the beta estimate at
% each voxel of the sub-space EM
%
% Assumption: mixing matrices are orthogonal and data are pre-whitened.  
%
% Syntax:
% [betaSE] = VarEst(theta_est, beta_est, X, z_mode,  approx)
%
% Inputs:
%    theta_est   - estimates for the model parameters from the EM alg
%    beta_est    - Beta maps estimated by EM alg
%    X           - The design matrix
%    z_mode      - Assignment of voxels to ICs (output by EM)
%    Y_tilde_all - fMRI data of qN x V (prewhitened Data)
%    G_z_dict    - Dictionary of latent states from EM alg.
%    voxSize     - dimension of image
%    validVoxels - Voxels in the brain mask
%    prefix      - prefix for the analysis
%    outpath     - output folder for the analysis
%
%
% Outputs:
%    varBeta1   - q(p+1) x q(p+1) x V matrix of covariance of the beta for
%                  each voxel of theoretical form

	% Number of covariates
	p=size(beta_est, 1);
	% Number of ICs
	q=size(beta_est, 2);
	% Number of voxels
	V=size(beta_est, 3);
	% Number of subjects
	N=size(X, 1);
	% gaussian mixture source distributions
	m=2;

	% Empty matrix to store the standard error estimates
	betaSE = zeros(size(beta_est));
	Sigma1   =   kron(eye(N*q), theta_est.sigma1_sq);
	Sigma2   =   kron(eye(N), diag(theta_est.sigma2_sq));

	W_var1 = zeros(q,q,V); % W_var1 of the theoretical form. 
	W_var2 = zeros(q,q,V); % W_var1 of the empirical form. 
	varBetaall1 = zeros(q*(p+1),q*(p+1));  % var-cov of (miu_z(v) beta(v))' based on theoretical W(v)
	varBetaall2 = zeros(q*(p+1),q*(p+1));  % var-cov of (miu_z(v) beta(v))' based on empirical W(v)
	varBeta1 = zeros(q*(p+1),q*(p+1),V);  % var-cov of beta(v)' based on theoretical W(v)
	varBeta2 = zeros(q*(p+1),q*(p+1),V);  % var-cov of beta(v)' based on empirical W(v)

	Index(:,1) = repmat( (1:q)',[p 1]); % IC 
	Index(:,2) = reshape( repmat(1:p, [q 1]), [q*p 1]); % Covariates
		
	for v=1:V
	
		%%% Estimating the W(v) for the residual of the stacked model: Ai'Yi(v) = Xi b(v) + N(0, W(v)) %%%
		
		G_z = G_z_dict(:,:,z_mode(v));
		Sigma3z = G_z * theta_est.sigma3_sq; % variance in S_0(v)
		
		% Theoretical one:
		W_var1(:,:,v)  = diag(Sigma3z + theta_est.sigma2_sq) + theta_est.sigma1_sq*eye(q); 
		
		%%% Estimating the variance-covariance of vec(beta(v)'): %%%
		W_varinv1 = inv(W_var1(:,:,v)) ;
		
        varBetaall1 = zeros(size(varBetaall1));
		for i =1:N
			Xistar = [eye(q) kron(reshape(X(i,:),[1 p]),eye(q))];
			varBetaall1 = varBetaall1 + Xistar'*W_varinv1*Xistar;
		end
		varBetaall1 = inv(varBetaall1);
		
		varBeta1(:,:,v) = varBetaall1;%( (q+1):(q*(p+1)) , (q+1):(q*(p+1)) );		
    end
    
    % Create the maps for each IC based on the theoretical variance
    % estimator
    for iIC = 1:q
        % Create an indexing array to grab the right elements of the
        % estimates
        indArrStart = (iIC + q);
        indArr = indArrStart:q:size(varBeta1, 1);
        % Fill out the variance estimate
        newMap = zeros( [p, p, voxSize] ); % empty for intermediate var map
        tempData = squeeze(varBeta1(indArr, indArr, :));
        newMap( :,:, validVoxels ) = tempData;
        betaVarEst = newMap;
        % Save as a .mat file to be loaded in the display viewer
        fname = fullfile(outpath, [prefix '_BetaVarEst_IC_' num2str(iIC) '.mat']);
        save(fname, 'betaVarEst');
    end

end

