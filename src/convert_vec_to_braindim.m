function [image3d] = convert_vec_to_braindim(vecdata, validVoxels, voxSize)
%image_vec_to_3d Takes data in vectorized form and returns a 3d image of
%dimension voxSize where the values corresponding to the validVoxels are
%populated with the elements of the input vector

    % Check input
    errMsg = ['Length of input data (', num2str(numel(vecdata)),...
        ') not equal to number of voxels in mask (', numel(validVoxels),...
        ').'];
    assert( numel(vecdata) == numel(validVoxels), errMsg);
    
    image3d = zeros(voxSize);
    
    image3d(validVoxels) = vecdata;
    
end

