function whitenedData = prewhiten_time_courses(timeCourses, nIC)
%prewhiten_time_courses Function to whiten the data from T time points to
%nIC time points. Used in initial preprocessing for both hcica and
%longitudinal hcica

    % Center each voxel's time course
    [X_tilde_all, ] = remmean(timeCourses);
    
    % Make sure not all 0
    uniqueVals = unique(X_tilde_all(:));
    if numel(uniqueVals) == 1
        error(['ERROR - all values in brain are: ' num2str(uniqueVals) '. Please check input data.']);
    end
    
    % Check for NANs
    if any(isnan(uniqueVals(:)))
        error('ERROR - NAs detected in time courses. Please check brain mask.');
    end
    
    disp( ['Number of voxels: ' num2str(size(X_tilde_all, 1)) ', Number of time points: ' num2str(size(X_tilde_all, 2))] )

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

