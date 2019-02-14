    
function [theta, beta, grpSig, s0_agg] = InitialGuessLICA( prefix, Ytilde,...
    N,q,V, p, X, nVisit, maskfl)

%% these shoould be the new arguments
% data.niifiles, data.maskf, ...
%                    get(findobj('Tag', 'prefix'), 'String'),...
%                    get(findobj('Tag', 'analysisFolder'), 'String'),...
%                    str2double(numberOfPCs.String),...
%                    data.N, data.q, data.X, data.Ytilde, hcicadir,
%                    data.nVisit


%% Changes to variable names
% T becomes nVisit
% N becomes N (needs to be number of subjects)
% Remove C_diag_matrix

mask = load_nii(maskfl);

% Create a version of the design matrix that is appropriate for this script
Xorig = X;
selectRows = 1:nVisit:N*nVisit; % one row per subject
Xtemp = Xorig(selectRows, :);
% add a row of ones to the top
X = [ones(1, N); Xtemp'];

%% Start of Yikai's script
% T IS NVISIT-1 BECAUSE T STARTS FROM 0
T = nVisit - 1;

    % Index 2 is N*q*nVisit x ??? seems like by nVisit - CHECK
    Index2 = zeros([N*q*(T+1) 3]);iter = 1;
    for i = 1:N
        for j = 0:T
            for t = 1:q
                Index2(iter,:) = [i j t]; iter = iter+1;
            end
        end
    end
    
    % subj_PCA_R=6; % for simulated data which has 3 IC
    initalguessS0 = zeros(q,V,T+1);
    iniguessSij = zeros(q,V,N,T+1);
    epsilon2 = zeros(q,V,N,T+1); % Visit specific and subject specific error
    iniguessCeta = zeros(q,p+1,V,T+1); %p plus intercept % INCLUDES BOTH ALPHA AND BETA
    A = zeros(q,q,N,T+1);


    % above was in the GIFT part -> see what can be removed TODO
    
    iter = 1;
    errors = zeros(q, V, N, T+1);

    for j = 0:T
    % load the ICs for subject i
        for i=1:N
             dattempp = load([prefix '_ica_br' num2str(iter) '.mat']); % q by V
             iniguessSij(:,:,i,j+1) = dattempp.compSet.ic;        
             A(:,:,i,j+1) = ((iniguessSij(:,:,i,j+1)*iniguessSij(:,:,i,j+1)')^(-1)*...
                iniguessSij(:,:,i,j+1)*Ytilde(Index2(:,1)==i & Index2(:,2)==j,:)')';
            iter = iter +1;
        end
        
        % Esimate the Beta to make sure S0 is estimatable we do not estimate alpha
        % first. 
        X0 = X((2:(p+1)),:); % 1sr row of X is 1
        if j == 0
            for v = 1:V
                % alpha0 should be all 0
                     iniguessCeta(:,:,v,j+1) =  [zeros(q,1) squeeze(iniguessSij(:,v,:,j+1))* X0' * (X0*X0')^(-1)]; % alpha_0 needs to be all zeros
            end
        else
            for v = 1:V
                     iniguessCeta(:,:,v,j+1) =  squeeze(iniguessSij(:,v,:,j+1))* X' * (X*X')^(-1); % [alpha_j, beta_j] q x (p+1)
            end
        end            
        
        % get the S0
        S0_temp = zeros(q, V, N); 
        for i = 1:N
            eta = zeros(q, V);
            for covv = 1:(p+1)
                eta = eta + squeeze(X(covv, i) .* iniguessCeta(:,covv,:,j+1) );
            end
            S0_temp(:,:,i) = iniguessSij(:,:,i,j+1) - eta;
        end
        initalguessS0(:,:,j+1) = mean(S0_temp, 3);
        
        % calculating sigma2 squared
        for i = 1:N
            epsilon2(:, :, i,j+1) = S0_temp(:,:,i) - initalguessS0(:,:,j+1);
        end
        
% Finally calculate sigma1_squared
%ytilde - ai * si;
        
        for i=1:N
            ij = j+1+(i-1)*(T+1);
             errors(:,:,i,j+1) = Ytilde(Index2(:,1)==i & Index2(:,2)==j,:) - A(:,:,i,j+1)*iniguessSij(:,:,i,j+1);
             for ic1 = 1:q
                 errors(ic1,:,i,j+1) = errors(ic1,:,i,j+1);
             end
        end
   
    % Initial Guess: fit a Gaussian mixture
        if j ==0 
             m=2;
             if j ==0
                  for icl =1:q
                     GMModel = fitgmdist(initalguessS0(icl,:,j+1)' ,m+1);
                     id = find(abs(GMModel.mu) == max(abs(GMModel.mu)));
                     miu3(1+m*(icl-1): m*icl, j+1) =[0, GMModel.mu(id)];
                     sigma3_sq(1+m*(icl-1): m*icl, j+1) = [GMModel.Sigma(id), GMModel.Sigma(id)];
                     pi(1+m*(icl-1): m*icl, j+1)  =[1-GMModel.PComponents(id),...
                                           GMModel.PComponents(id)];
                  end
             end
        end
        
        
    end % end of loop over T (nVisit)


% First Level
    theta.sigma1_sq = (var(reshape(errors,1,prod(size(errors))))); % v0
    
    theta.A = A;

    % Second Level
    % first set the value of alpha2...T
    for j = 1:T
        for icl = 1:q
            iniguessCeta(icl,1,:,j+1) = initalguessS0(icl,:,j+1) - initalguessS0(icl,:,1);
        end
    end
    %theta.iniguessCeta = iniguessCeta;
    
    % Then extract the subject's variance D=diag(v1,..,vq) and 
    % time-subject variance tau
    for i = 1:N
        esilon_subj = squeeze(epsilon2(:,:,i,:));
        temp(:,:,i) = (esilon_subj(:,:,1) -mean(esilon_subj,3)).^2;
        for j = 1:T
        temp(:,:,i) = temp(:,:,i)+(esilon_subj(:,:,j+1) -mean(esilon_subj,3)).^2;
        end
    end

    temp = temp/T;
    theta.tau_sq = (mean(reshape(mean(temp,3),1,q*V)));
    theta.D = mean(var(mean(epsilon2,4),1,3),2);

    % Third Level of S0
    theta.sigma3_sq = sigma3_sq(:,1);
    theta.pi = pi(:,1);
    theta.miu3 = miu3(:,1);
    
    % renaming some things
    beta = iniguessCeta;
    
     % Save the aggregate map for IC selection; these are only used for IC
    % selection
    agg_IC = load_nii([prefix '_agg__component_ica_.nii']);
    s0_agg = zeros(q, V);
    for c = 1:q
        tempVals = reshape(agg_IC.img(:,:,:,c), [1, numel(agg_IC.img(:,:,:,c))]);
        s0_agg(c,:) = reshape(tempVals(mask.img==1), [1, V]);
    end
    
    grpSig = initalguessS0;
    

end