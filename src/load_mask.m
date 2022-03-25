function [mask, validVoxels, V] = load_mask(maskFile)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

mask = load_nii(maskFile);

% Mask could potentially be of several forms
% zeros or NaNs for voxels that are outside of the brain

% Get the number of NaNs in the image, if nans are present, then assume
% that all voxels with a non-NaN value are a part of the brain
nNaN = sum(isnan(mask.img));

% If there are NaNs, then assume that all non-NaN voxels are part of the
% brain
if nNaN > 0
    validVoxels = find( ~isnan(mask.img) );
else
    % No NaNs present, assume all non-zero voxels then are a part of the
    % brain
    validVoxels = find( mask.img ~= 0 );
end

V = length(validVoxels);

end

