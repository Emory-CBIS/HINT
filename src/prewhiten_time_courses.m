function whitenedData = prewhiten_time_courses(timeCourses, nIC)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

    [X_tilde_all, ] = remmean(timeCourses);

    [U_incr, D_incr] = pcamat(X_tilde_all, 1,...
        size (X_tilde_all, 1),'off', 'off');
    
    % sort the eig values, IX:index
    lambda = sort(diag(D_incr),'descend');
    
    U_q = U_incr(:,(size(U_incr,2)-nIC+1):size(U_incr,2));
    D_q = diag(D_incr((size(U_incr,2)-nIC+1):size(U_incr,2),...
        (size(U_incr,2)-nIC+1):size(U_incr,2)));
    
    % sum across all the remaining eigenvalues
    sigma2_ML = sum(lambda(nIC+1:length(lambda))) / (length(lambda)-nIC);
    
    % whitening, dewhitening matrix and whitened data;
    my_whiteningMatrix = diag((D_q-sigma2_ML).^(-1/2)) * U_q';
    whitenedData = my_whiteningMatrix * X_tilde_all;

end

