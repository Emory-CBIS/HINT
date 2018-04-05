function [theta, beta, z_mode, subICmean, subICvar, grpICmean, grpICvar,...
    success, G_z_dict, finalIter] = CoeffpICA_EM (Y, X, theta0, C_matrix_diag, beta0, maxiter,...
                            epsilon1, epsilon2, algo, outpath, prefix,...
                            isScriptVersion)
% CoeffpICA_EM - Function to run EM algorithm for hc-ICA
% This function calls one of the EM algorithm choices for hc-ICA for given
% number of iterations or till the algorithm converges.
%
% Syntax:
% [theta, beta, z_mode, subICmean, subICvar, grpICmean, grpICvar, success]
%       = CoeffpICA_EM (Y, X, theta0, C_matrix_diag, beta0, maxiter, ...
%                       epsilon1, epsilon2, algo)
%
% Inputs:
%    Y          - NT x V, orignial imaging data matrix
%    X          - N x p, covariate matrix
%    theta0     - Object containing initial estimates for the EM algorithm
%    C_matrix_diag  - Gives the product of whitening matrix and its
%                     transpose
%    beta0      - Initial estimates for regression coefficients
%    maxit      - Maximum number of iterations
%    epsilon1   - Convergence condition for theta; Algorithm stops when
%                 improvement in theta drops below epsilon1
%    epsilon2   - Convergence condition for beta;Algorithm stops when
%                 improvement in beta drops below epsilon2
%    algo       - EM algorithm, options are: 
%                   'Exact': UpdateThetaBeta.m
%                   'Approx': UpdateThetaBetaAprx_Vect.m
%    outpath    - path of the output folder. Used for saving parameter
%                   estimates after each iteration
%    prefix     - prefix for the analysis
%    isScriptVersion - boolean. Is 1 is 'estimateFromSavedData' calls the
%                       function
%
% Outputs:
%    theta      - Object containing estimates for the EM algorithm
%    beta       - Regression coefficients
%    z_mode     - IC membership for voxels
%    subICmean  - Subject level IC mean
%    subICvar   - Subject level IC var
%    grpICmean  - Group level IC mean
%    grpICvar   - Group level IC variance
%    success    - 1 if algorithm converges successfully
%    iter       - the final iteration number
%
% See also: UpdateThetaBetaAprx_Vect.m, UpdateThetaBeta.m,
% estimateFromSavedData.m

    global keepRunning
    keepRunning = 1;

    algofunc = @UpdateThetaBetaAprx_Vect_Experimental;
    isApprox = true;
    disp('Starting the estimation using approximate EM algorithm ...');
    
    % Track the final iteration
    finalIter = 0;

    X_mtx = X';
    N = size(X,1);
    p = size(X,2);
    q = size(theta0.sigma2_sq, 1);
    T = q;
    m = 2;
    V = size(Y, 2);
    itr = 1;
    err1 = 1000;
    err2 = 1000;
    theta = theta0;
    beta = beta0;
    success = 1;

    err1vec = [];
    err2vec = [];
    
    % Measure the time taken between plot updates
    plotIncr = 1;
    tic()
    
    while (err1 > epsilon1 || err2 > epsilon2)

        [theta_new, beta_new, z_mode, subICmean, subICvar, grpICmean,...
            grpICvar, err, G_z_dict] = algofunc (Y, X_mtx, theta, C_matrix_diag,...
                                        beta, N, T, q, p, m, V);
        iterationTime = toc();    
        
        % Want to update plot every iteration or every 30 seconds
        updatePlot = 0;
        if (iterationTime / 10 > plotIncr)
            updatePlot = 1;
            plotIncr = plotIncr + 1;
        end
                                    
        if(err == 1)
            success = 0;
            disp('Fail to converge due to calculate of p(z|y)!');
            return;
        end;

        [vec_theta_new, vec_beta_new] = VectThetaBeta (theta_new, beta_new,...
                                                        p, q, V, T, N, m);

        [vec_theta, vec_beta] = VectThetaBeta (theta, beta, p, q, V, T, N, m);

        err1 = norm (vec_theta_new - vec_theta) / norm (vec_theta);
        err2 = norm (vec_beta_new  - vec_beta) / norm (vec_beta);  

        fprintf('iteration %6.0f: the difference is %6.6f for theta and %6.6f for beta \n',...
                itr, err1, err2);  

        theta = theta_new;
        beta  = beta_new;
        
        clear('vec_theta');
        clear('vec_beta');
        clear('vec_theta_new');
        clear('vec_beta_new');
        clear('theta_new');
        clear('beta_new');
        
        % Save the current iteration results. Keep the last iteration's
        % results as well. Any previous results are deleted to prevent
        % the folder from becoming too large.
        if itr > 2
            save([outpath '/' prefix '_iter' num2str(itr) '_parameter_estimates.mat'], 'theta',...
                'beta', 'subICmean', 'subICvar', 'grpICmean', 'grpICvar',...
                'z_mode', 'isApprox', 'err1vec', 'err2vec', 'G_z_dict', '-v7.3')
            delete([outpath '/' prefix '_iter' num2str(itr-2) '_parameter_estimates.mat'])
        else
            save([outpath '/' prefix '_iter' num2str(itr) '_parameter_estimates.mat'], 'theta',...
                'beta', 'subICmean', 'subICvar', 'grpICmean', 'grpICvar',...
                'z_mode', 'isApprox', 'err1vec', 'err2vec', 'G_z_dict', '-v7.3')
        end
        
        % Print out the progress to a graph     
        err1vec = [err1vec err1];
        err2vec = [err2vec err2];
        
        % If the gui version is being run then update the GUI
        if isScriptVersion == 0 && (updatePlot || itr == maxiter)
            
            % Theta change plot
            axes(findobj('tag','iterChangeAxis1'));
            set(gca,'NextPlot','add');
            plot(err1vec);
            xticks(1:5:itr);
            title('Change in Theta'); xlabel('Iteration');
            print(gcf, [outpath '/' prefix '_theta_progress_plot'],'-dpng')
            
            % Beta change plot
            axes(findobj('tag','iterChangeAxis2'));
            set(gca, 'NextPlot', 'add');
            plot(err2vec);
            xticks( [1:5:itr] );
            title('Change in Beta'); xlabel('Iteration');
            print(gcf, [outpath '/' prefix '_beta_progress_plot'],'-dpng')
            
            % Update the embedded waitbar
            axes(findobj('tag','analysisWaitbar'));
            cla;
            rectangle('Position',[0,0,0+(round(1000*itr/maxiter)),20],'FaceColor','g');
            text(482,10,[num2str(0+round(100*itr/maxiter)),'%']);
            pause(1)
        end
        
        % Update the saved progress plot if only script version running
        if isScriptVersion == 1
            plot(err1vec);
            title('Change in Theta'); xlabel('Iteration');
            print(gcf, [outpath '/' prefix '_theta_progress_plot'],'-dpng')
            plot(err2vec);
            title('Change in Beta'); xlabel('Iteration');
            print(gcf, [outpath '/' prefix '_beta_progress_plot'],'-dpng')
        end
        
        finalIter = itr;
        itr = itr + 1;
        if ( itr > maxiter )
            success = 0; 
            disp('Fail to converge within given number of iteration!');
            return;
        end
        
        % Check if the user requested early termination
        if ( keepRunning == 0 )
            success = 0; 
            disp('Terminating by user request');
            return;
        end
    end
    
    % Update the analysis progress to 100% (analysis is complete)
    if isScriptVersion == 0
         % Update the embedded waitbar
         axes(findobj('tag','analysisWaitbar'));
         cla;
         rectangle('Position',[0,0,0+(round(1000*maxiter/maxiter)),20],'FaceColor','g');
         text(482,10,[num2str(0+round(100*maxiter/maxiter)),'%']);
         pause(1)
    end
    
end

