function [stackedWhitenedData, S0Init] = initial_guess_preproc_fastica(niifiles, validVoxels, nPC, Q, Tmax)
%initial_guess_ica_decomposition Obtain the prewhitened data and the inital
%guess for S0. This part of the preprocessing procedure is agnostic to the
%type of study (longitudinal, cross-sectional etc)

    N = length(niifiles);
    V = length(validVoxels);

    % First stage of dimension reduction
    stackedPCs      = zeros(nPC * N, V);
    stackedPCA1Tsfm = zeros(nPC * N, Tmax);
    stackedWhitenedData = zeros(Q * N, V);
    stackIndexEnd   = 0;
    for i = 1:N
        
        disp( ['Starting PCA reduction for file ', num2str(i), '...'] )
                
        % Load data file
        subjData = load_nii(niifiles{i});
        
        % Reduce to valid voxels - data can be oriented in several ways
        if length(size(subjData.img)) == 4
            [m,n,l,k] = size(subjData.img);
            res = reshape(subjData.img,[], k)';
            X_tilde_all = res(:, validVoxels);
        elseif length(size(subjData.img)) == 2
            if size(subjData.img, 1) == V
                X_tilde_all = subjData.img;
            end
        else
            disp('WARNING - data dimension not recognized')
            return
        end
        
        % Whitened Data for full analyis
        whitenedData = prewhiten_time_courses(X_tilde_all, Q);
        stackedWhitenedData( (Q*(i-1)+1):(Q*i), : ) = whitenedData;

        % First stage of PCA
        [components, tsfmMat] = PCA_dimension_reduction(X_tilde_all, nPC);
        
        % Store
        stackIndexStart = stackIndexEnd + 1;
        stackIndexEnd   = stackIndexEnd + nPC;
        
        stackedPCs(stackIndexStart:stackIndexEnd, :) = components;
        %stackedPCA1Tsfm(stackIndexStart:stackIndexEnd, :) = tsfmMat;
         
    end
    
    % Second stage of dimension reduction
    [componentsQ, tsfmMatQ] = PCA_dimension_reduction(stackedPCs, Q);
    
    % FASTICA on whitened data
    S0Init = fastica (componentsQ, 'approach', 'symm', 'g', 'tanh',...
        'numOfIC', Q, 'verbose', 'off');
    
end

