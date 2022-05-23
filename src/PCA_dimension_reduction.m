function [components, tsfmMat] = PCA_dimension_reduction(data, nPC)
%PCA_dimension_reduction  data - a T x V matrix.
% Output:
% components: nPC x V matrix, each row is component
% Reconstructed data would be tsfmMat * data + colMeans

    colMeans = mean(data);
    
    data = data - colMeans;
    
    [Ui, Si, Vi] = svds(double(data'), nPC);
    
    components = Ui * Si;
    
    % Transpose so nPC x V
    components = components';
    
    Ti = size(data, 1);
    tsfmMat = Vi' * (eye(Ti)-1/Ti * ones(Ti));
        
end

