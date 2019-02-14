function [ output_args ] = InitialGuessCrossSectional( prefix, Ytilde, N, q,...
    V, p, X, nVisit, maskfl )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here


% previous step will end in the output directory
% Load data needed to get the initial values
V = sum(mask.img(:), 'omitnan');
% some masks have 0s for non-voxels, other have nans. Try both
validVoxels = find(~isnan(mask.img));
if ( numel(validVoxels) == numel(mask.img) )
    validVoxels = find((mask.img) == 1); %#ok<NASGU>
end

% Create empty matrix to store the s_i
S_i = zeros( q, V, N );
for i=1:N
    dat = load([prefix '_ica_br' num2str(i) '.mat']);
    S_i(:,:,i) = dat.compSet.ic;
end

% Estimation of the betas and S_0
p = size(X,2);
beta = zeros(p,q,V);
Xint = [ ones(N,1) X ];
S0 = zeros(q, V);
epsilon2temp = zeros(q, V, N);
for v = 1:V
    estimate = (Xint'*Xint)^(-1) * Xint' *squeeze(S_i(:,v,:))';
    beta(:,:,v) = estimate(2:(p+1), :);
    S0(:,v) = estimate(1,:)';
    epsilon2temp(:,v,:) = squeeze(S_i(:,v,:)) - (Xint * estimate)';
end
sigma2_sq = var(reshape(epsilon2temp, [q,V*N]), 0, 2);

% Get the subject level mixing matrices
A = zeros(q,q,N);
for i = 1:N
    cS_i = S_i(:,:,i); sInd = q*(i-1)+1; eInd = i*q;
    A_tempi = (cS_i * cS_i')^(-1) * cS_i * Ytilde(sInd:eInd,:)';
    Asym = A_tempi';
    A(:,:,i) = Asym*real(inv(Asym'*Asym)^(1/2));
end

% Moving in the reverse direction, this allows everything to be on the
% scale of Ytilde
si2 = zeros(q, V, N);
for i = 1:N
    sInd = q*(i-1)+1; eInd = i*q;
    si2(:, :, i) = inv(A(:,:,i)) * Ytilde(sInd:eInd,:);
end

waitbar(9/10)

% Calculate sigma1_squared (subject level error)
errors = zeros(q, V, N);
for i=1:N
    sInd = q*(i-1)+1; eInd = i*q;
    errors(:,:,i) = Ytilde(sInd:eInd,:) - A(:,:,i)*si2(:,:,i);
end
sigma1_sq = var(reshape(errors, [1, q*V*N]));

% Beta and s0 estimate based on backwards moving ini guess
p = size(X,2);
beta = zeros(p,q,V);
Xint = [ ones(N,1) X ];
S0 = zeros(q, V);
epsilon2temp = zeros(q, V, N);
for v = 1:V
    estimate = (Xint'*Xint)^(-1) * Xint' *squeeze(si2(:,v,:))';
    beta(:,:,v) = estimate(2:(p+1), :);
    S0(:,v) = estimate(1,:)';
    epsilon2temp(:,v,:) = squeeze(si2(:,v,:)) - (Xint * estimate)';
end
sigma2_sq = var(reshape(epsilon2temp, [q,V*N]), 0, 2);


% Initial Guess: fit a Gaussian mixture
m=2;

for j =1:q
    GMModel = fitgmdist(S0(j,:)' ,m+1);
    id = find(abs(GMModel.mu) == max(abs(GMModel.mu)));
    theta.miu3(1+m*(j-1): m*j, 1) =[GMModel.mu(id), 0];
    idzero = abs(GMModel.mu) == min(abs(GMModel.mu));
    theta.sigma3_sq(1+m*(j-1): m*j, 1) = [GMModel.Sigma(id), GMModel.Sigma(idzero)];
    theta.pi(1+m*(j-1): m*j, 1)  =[GMModel.PComponents(id), 1-GMModel.PComponents(id)];
end


% create the final variables to return (beta already created)
theta.sigma1_sq = sigma1_sq;
theta.sigma2_sq = sigma2_sq;
theta.A = A;
grpSig = S0;

% Save the aggregate map for IC selection; these are only used for IC
% selection
agg_IC = load_nii([prefix '_agg__component_ica_.nii']);
s0_agg = zeros(q, V);
for c = 1:q
    tempVals = reshape(agg_IC.img(:,:,:,c), [1, numel(agg_IC.img(:,:,:,c))]);
    s0_agg(c,:) = reshape(tempVals(mask.img==1), [1, V]);
end

% Update the waitbar
waitbar(1)
close(h)

move_iniguess_to_folder(outdir, prefix)

cd(hcicadir);


end

