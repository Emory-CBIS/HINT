function [ normalizedImg ] = z_normalize_image( img, validVoxels )
%this function is meant to be called on a cell array of images using
%cellfun

normalizedImg = nan(size(img));

meanImg = mean(img(validVoxels));

% consider re-adding omitnan option?
stdImg  = std(img(validVoxels));
normalizedImg(validVoxels) = (img(validVoxels) - meanImg) ./ stdImg;

end

