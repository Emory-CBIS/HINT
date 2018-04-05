function [betaSE] = VarEst(theta_est, beta_est, X, z_mode,  approx)
% VarEst - Function to calculate the standard error of the beta estimate at
% each voxel
%
% Syntax:
% [betaSE] = VarEst(theta_est, beta_est, X, z_mode,  approx)
%
% Inputs:
%    theta_est   - estimates for the model parameters from the EM alg
%    beta_est    - Beta maps estimated by EM alg
%    z_mode      - Assignment of voxels to ICs (output by EM)
%    approx      - bool value keeping track of it approximate EM was used
%
% Outputs:
%    betaSE   - q x V matrix of standard error estimates for beta
%
% See also: UpdateThetaBetaAprx_Vect.m, UpdateThetaBeta.m 

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

% Generate the dictionary structure
if approx == 1
    z_dict = [2*ones(q)-eye(q), 2*ones(q, 1)];
    G_z_dict = zeros(q, m*q, q+1);
    for i = 1:(q+1)
        G_z_dict(:,:,i) = G_zv_gen(z_dict(:,i), m, q);
    end
else
    z_dict = zeros(q, m^q);
    G_z_dict = zeros(q, m*q, m^q);
    for i = 1:m^q
        z_dict(:,i) = z_gen(i-1, m, q);
        G_z_dict(:,:,i) = G_zv_gen(z_dict(:,i), m, q);
    end
end

% Stack the covariate matrices
CapX = kron(eye(q), X);
CapR = [eye(N*q), kron(ones(N, 1), eye(q))];

% Empty matrix to store the standard error estimates
betaSE = zeros(size(beta_est));
Sigma1   =   kron(eye(N*q), theta_est.sigma1_sq);
Sigma2   =   kron(eye(N), diag(theta_est.sigma2_sq));

% Loop over each voxel
for v=1:V
    i = z_mode(v);
    G_z = G_z_dict(:,:,i);
    Sigma3z  = diag(G_z * theta_est.sigma3_sq);
    Sigma23z = blkdiag(Sigma2, Sigma3z);
    varcovVecBeta = 1/N*(CapX'*(CapR*Sigma23z*CapR' + Sigma1)^(-1)*CapX)^(-1);
    betaSE(:, :, v) = sqrt(reshape(diag(varcovVecBeta), p, q));
end

end