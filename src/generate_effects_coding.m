function [covariateEffectsCoding] = generate_effects_coding(X, varargin)
% generate_effects_coding Generates effects coding for the input variables.
%
% Arguments:
% X - a N x 1 matrix containing the observed values for the covariate. This
% will be converted to a cell array of strings if it is not already one.
%
% ref - optional reference level. If not provided, the first observation in
% X is used
%
% weighted - whether the counts should be adjusted by the number of
% participants with that setting. This causes the estimate of S0 to be the
% arithmetic mean
%
% See also apply_effects_coding.

%% Parse function arguments

% Ensure that X is a cell array of strings
if isa(X, 'numeric')
    X = num2str(X);
end

X = cellstr(X);

% Defaults
defaultWeighted = false;
defaultRef = X{1};

p = inputParser;
addRequired(p, 'X');
addParameter(p, 'weighted', defaultWeighted, @islogical);
addParameter(p, 'ref', defaultRef, @(x) isstring(x) || ischar(x) );
parse(p, X, varargin{:});

% Set args to parsed inputs
X = p.Results.X;
ref = p.Results.ref;
weighted = p.Results.weighted;

% Determine basic properties of this variable
N = length(X);
uniqueLevels = unique(X, 'stable');
nLevels = length(unique(X));

% Depending on the input, the covariate might have a name. If so, store it.

%% Sort the unique levels so that the reference level is last
refLevelIndex = strcmp(uniqueLevels, ref);

% Do a check that the provided reference level exists. If not, use default
if sum(refLevelIndex) == 0
    disp(['Warnings - there is no category with setting: ', ref]);
    disp(['Valid options were: ', strjoin(uniqueLevels)]);
    disp(['Setting reference level to: ', uniqueLevels{1}]);
    ref = uniqueLevels{1};
    refLevelIndex = strcmp(uniqueLevels, ref);
end

% Sort
uniqueLevels(refLevelIndex == 1) = [];
uniqueLevels{length(uniqueLevels) + 1} = ref;


% Create a dictionary so can go back and forth
encoder = containers.Map;
nj = zeros(nLevels-1, 1);
for j = 1:nLevels-1
    coding = zeros(1, nLevels - 1);
    coding(1, j) = 1;
    nj(j) = sum(strcmp(X, uniqueLevels{j}));
    encoder(uniqueLevels{j}) = coding;
end
n0 = N - sum(nj);

% Assign the "negative" category. Exact values depend on if weighted
% effects coding is being used
if weighted == false
    encoder(uniqueLevels{nLevels}) = -1 * ones(1, nLevels -1);
else
    tempLevels =  -1 * ones(1, nLevels -1);
    for j = 1:nLevels-1
        weight = nj(j) / n0;
        tempLevels(j) = tempLevels(j) * weight;
    end
    encoder(uniqueLevels{nLevels}) = tempLevels;
end

% Column names are the non-reference values
effectsCodedVariableNames = uniqueLevels(1:nLevels-1);

% Combine output into structure
covariateEffectsCoding = struct();
covariateEffectsCoding.variableNames     = effectsCodedVariableNames;
covariateEffectsCoding.referenceCategory = ref;
covariateEffectsCoding.weighted          = weighted;
covariateEffectsCoding.encoder           = encoder;
covariateEffectsCoding.nj                = nj;
covariateEffectsCoding.n0                = n0;

end

