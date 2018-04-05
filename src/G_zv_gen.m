function G_zv = G_zv_gen(zv, m, q) 

% G_zv_gen - Function to generate G_z matrix given vector z(v)
%
% Syntax:
% G_zv = G_zv_gen(zv, m, q)
%
% Inputs:
%    zv   - NT x V, orignial imaging data matrix
%    m    - Number of Gaussian components in MoG
%    q    - Number of Independent Components (IC)
%
% Outputs:
%    G_zv   - G_z matrix of possible IC membership permutations
%
% See also: UpdateThetaBetaAprx_Vect.m, UpdateThetaBeta.m 

    x=(1:q)';
    x = double(x);
    y=(x-1).*double(m) + zv;
    G_zv = zeros (q, m*q);
    G_zv( sub2ind(size(G_zv), x, y) ) = 1;
    
end
 