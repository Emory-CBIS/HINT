function [Ytilde, C_matrix_diag, H_matrix_inv, H_matrix, deWhite] =...
    PreProcICA(niifiles, validVoxels, q, T, N)
% PreProcICA - Function to perform two stage pre-processing of the fMRI
% data.
%
% [ Ytilde, C_matrix_diag, H_matrix_inv,  H_matrix, deWhite ] =
%                                    reEstimateIniGuess( Y, q, T, N )
%
% Inputs:
%    niifiles - List of all nii files
%    validVoxels - Brain voxels on the gray matter
%    q       - Targeted number of independent components (ICs)
%    T       - Number of time points
%    N       - Number of subjects
%
% Outputs:
%    Ytilde         - Nq x V, Pre-processed data matrix
%    C_matrix_diag  - Gives the product of whitening matrix and its
%                     transpose
%    H_matrix       - Whitening matrix
%    H_matrix_inv   - Inverse of whitening matrix
%    deWhite        - Dewhitening matrix
%
% See also: runGIFT.m, reEstimateIniGuess.m


deWhite = zeros(T, q, N);

% Waitbar during PCA
h = waitbar(0,'Performing PCA...', 'windowstyle', 'modal');
steps = N;

% Load the first data file and get its size.
% image_temp = load_nii(niifiles{1});
% [m,n,l,k] = size(image_temp.img);

% subject-speicifc dimension reduction and whitening matrix, uses pcamat for PCA
for i=1:N
    
    % Load the subject data
    image = load_nii(niifiles{i});
    [m,n,l,k] = size(image.img);
    res = reshape(image.img,[], k)';
    
    % X tilde all is raw T x V subject level data for subject i
    X_tilde_all = res(:,validVoxels);
    
    % Verify that the data are valid
    if any(any(isnan(X_tilde_all)))
        disp('Subjects masked data contains missing values')
    end
        
    % Center the data
    [X_tilde_all, ] = remmean(X_tilde_all);
    
    % run pca on X_tilde_all`
    [U_incr, D_incr] = pcamat(X_tilde_all, 1, size (X_tilde_all, 1),'off', 'off');
    
    % sort the eig values, IX:index
    lambda = sort(diag(D_incr),'descend');
    
    U_q = U_incr(:,(size(U_incr,2)-q+1):size(U_incr,2));
    D_q = diag(D_incr((size(U_incr,2)-q+1):size(U_incr,2),...
        (size(U_incr,2)-q+1):size(U_incr,2)));
    
    % sum across all the remaining eigenvalues
    sigma2_ML = sum(lambda(q+1:length(lambda))) / (length(lambda)-q);
    
    % whitening, dewhitening matrix and whitened data;
    my_whiteningMatrix = diag((D_q-sigma2_ML).^(-1/2)) * U_q';
    my_dewhiteningMatrix = U_q * diag((D_q-sigma2_ML) .^ (1/2));
    %deWhite(:,:,i) = my_dewhiteningMatrix;
    my_whitesig = my_whiteningMatrix * X_tilde_all;
    
    if (i == 1)
        % transform matrix for the two-stage dim reduction and whitening;
        H_matrix = my_whiteningMatrix * (eye(k)-1/k * ones(k));
        H_matrix_inv = my_dewhiteningMatrix;
        Y_tilde_all = my_whitesig;
    else
        newHmat = my_whiteningMatrix * (eye(k)-1/k * ones(k));
        H_matrix = blkdiag(H_matrix, newHmat);
        H_matrix_inv = blkdiag(H_matrix_inv, my_dewhiteningMatrix);
        Y_tilde_all = [Y_tilde_all; my_whitesig];
    end
    
    % Update the waitbar
    if isvalid(h)
        waitbar(i / steps, h)
    else
        h = waitbar(i / steps, 'Performing PCA...', 'windowstyle', 'modal');
    end
    
end

% close the waitbar
if isvalid(h)
    close(h)
end

C_matrix = H_matrix * H_matrix';
C_matrix_diag = diag(C_matrix);
Ytilde = Y_tilde_all;

end





