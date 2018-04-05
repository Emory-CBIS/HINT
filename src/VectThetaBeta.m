function [vec_theta, vec_beta] = VectThetaBeta (theta, beta, p, q, V, T, N, m)
% VectThetaBeta - Function to pack theta and beta parameters in vectors
% This function is used by CoeffpICA_EM.m to quantify change in theta and beta
% parameters between iterations.
%
% Syntax:
% [vec_theta, vec_beta] = VectThetaBeta (theta, beta, p, q, V, T, N, m)
%
% Inputs:
%    theta   - Object containing estimates for the EM algorithm
%    beta    - Estimates for regression coefficients
%    p       - Number of co-variates
%    q       - Number of Independent Componensts (IC)
%    V       - Convergence condition for beta;Algorithm 
%    T       - Number of time points
%    N       - Number of subjects
%    m       - Number of Gaussian components in MoG
%
% Outputs:
%    vec_theta  - Vector made of values from theta parameters
%    vec_beta   - Vector made of values from beta parameters
%
% See also: CoeffpICA_EM.m

    vec_beta = reshape( beta, (p * q * V), 1);
    
    vec_theta = [reshape( theta.A, (T * q * N), 1);
                 theta.sigma1_sq;
                 reshape( theta.sigma2_sq, q, 1);
                 reshape( theta.miu3, m*q, 1);
                 reshape( theta.sigma3_sq, m*q, 1);
                 reshape( theta.pi, m*q, 1)];
end
             
