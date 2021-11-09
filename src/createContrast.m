function [ctrFormatted] = createContrast(c, P, nVisit)
%createContrast function to create a contrast that is the right dimension
%to multiply with the estimated variance covariance matrix
%P: number of fixed effects (including interactions)
%nVisit: number of visits in the study. 1 indicates a cross-sectional
% study

switch numel(c)
    
    %% Cross-visit contrast
    case P * nVisit
        numelFormatted = P + (P+1)*(nVisit-1);
        ctrFormatted = zeros(numelFormatted, 1);
        indContrast = 0;
        indC        = 0;
        for iVisit = 1:nVisit
            for icov = 1:P
             indContrast = indContrast + 1;
             indC        = indC + 1;
             ctrFormatted(indContrast, :) = c(indC);
            end
            % skip an element for alpha..
            indContrast = indContrast + 1;
        end
    
    %% Standard contrast
    case P
        numelFormatted = nVisit * (P+1) - 1;
        ctrFormatted = zeros(numelFormatted, nVisit);
        for iVisit = 1:nVisit
            if iVisit == 1
                ctrFormatted(1:P, 1) = c;
            else
                sind = P + (iVisit-2)*(P+1) + 2;
                eind = sind + P-1;
                ctrFormatted(sind:eind, iVisit) = c;
            end
        end
        
    % Error
    otherwise
        
end


% 
% if numel(c) == P + (P+1)*(nVisit-1);
%     
% 
%     P = length(c);
%     Pall = nVisit * P - 1;
%     % Create a version of the contrast that is applicable across all
%     % visits:
%     cFull = zeros(Pall, 1);
%     if visit == 1
%         cFull(1:(P-1), 1) = c(2:end);
%     else
%         sind = (P-1) + (visit-2)*(P) + 1;
%         eind = sind + P-1;
%         cFull(sind:eind, 1) = c;
%     end

end

