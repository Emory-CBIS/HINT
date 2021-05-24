function [cFull] = createContrast(c, visit, nVisit)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    P = length(c);
    Pall = nVisit * P - 1;
    % Create a version of the contrast that is applicable across all
    % visits:
    cFull = zeros(Pall, 1);
    if visit == 1
        cFull(1:(P-1), 1) = c(2:end);
    else
        sind = (P-1) + (visit-2)*(P) + 1;
        eind = sind + P-1;
        cFull(sind:eind, 1) = c;
    end

end

