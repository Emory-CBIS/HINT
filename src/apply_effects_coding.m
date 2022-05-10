function [XCoded] = apply_effects_coding(X, covariateEffectsCoding)
%apply_effects_coding function to apply the pre-generated effects coding
%scheme to a column of the design matrix. 
%
% see also generate_effects_coding.

% Ensure that X is a cell array of strings
if isa(X, 'numeric')
    X = num2str(X);
end
X = cellstr(X);

% Get problem dimensions
N = length(X);
nLevels = length(unique(X));

% Apply the encoder
XCoded = zeros(N, nLevels - 1);
for n = 1:N
    XCoded(n, :) = covariateEffectsCoding.encoder(X{n});
end

end

