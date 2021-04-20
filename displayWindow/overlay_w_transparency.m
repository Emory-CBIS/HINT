function combinedImg = overlay_w_transparency(anat, funct,...
    thresholded_functmap, opacity, newColormap, newColormap2)
%overlay_w_transparency - Function to overlay the functional data on the
%anatomical image.
%
%Syntax:  combinedImg = overlay_w_transparency(anat,
%funct, thresholded_functmap, opacity, newColormap, newColormap2)
%
%Inputs:
%    anat                   - anatomical image
%    funct                  - functional image (IC result)
%    thresholded_functmap   - No values below this value are drawn
%    opacity                - scalar value [0,1] that determines transparency
%    newColormap            - colormap for the anatomical
%    newColormap2           - colormap for the functional image
%
%Outputs:
%    combinedImg - Image with the functional map overlaid on the anatomical
%    map and thresholded as requested.
%
%
%Original function by DuBois Bowman, Emory University, January 28, 2009 [Adapted from R. Raizada]. 
%Modified by: Lijun Zhang, Ph.D  

%------- Perform some initial checks ------------
imdim=size(anat);
imdim0=size(funct);
if sum(imdim==imdim0)<3 % ensure funct and anat images have same dimensions.
    error('Anatomical and functional images MUST be of the same size')
end
%--------------------------------------------------------------------------
% Make full RGB-images by looking up the corresponding rows of the gray and 
% jet colormaps. A 2D RGB-image is stored in a 3D-matrix, with 3 "color 
% slabs" along the 3rd dimension.  The slabs represent images full of Red, 
% Green, and Blue values, respectively.  Since we are working on a 3D image, 
% we will create a "4D" structure, with each element (indexed by RGB_dim 
% below) representing an R, G, or B slab of a 3D image.
for RGB_dim = 1:3
    RGB(RGB_dim).anat = zeros(imdim); %%% initialize
    RGB(RGB_dim).funct = zeros(imdim);
    combinedImg(RGB_dim).compound = zeros(imdim);
end

newColormap2(1,:) = 0;

%---Look up and store the appropriate RGB values. ----------------------
for RGB_dim = 1:3  % Loop through the three slabs: R, G, and B
    % Each entry in the 1-to-256-scaled anatomical (functional) matrix gives 
    % a row in the colormap matrix to look up.  The three elements of that 
    % row gets assigned to the respective color slab.  Note that we 
    % actually look up all the rows at once, returning a vector which then
    % is reshaped to the appropriate size of the image.
    color_slab_vals_for_anat = newColormap(anat(:), RGB_dim);
    color_slab_vals_for_funct = newColormap2(funct(:), RGB_dim);
    RGB(RGB_dim).anat = reshape(color_slab_vals_for_anat, imdim);
    RGB(RGB_dim).funct = reshape(color_slab_vals_for_funct, imdim);
    
    % Make a compound image as a weighted sum of the anatomical image and the 
    % functional image. The more weighting we give to the functional image, 
    % the more opaque it will look. (opacity in [0, 1], with 0 being 
    % fully transparent).
    % Below the functional threshold, we only keep the anatomical's values.
    % Above the threshold, we take a weighted sum of the functional  RGB
    % values and the anatomical's RGB values.  'min' ensures RGB<=1.
    combinedImg(RGB_dim).combound=min(1, ...
        (thresholded_functmap==0) .* ...    % below threshold
            RGB(RGB_dim).anat  + ...  
        (thresholded_functmap>0).* ...      % above threshold
            ( (1-opacity) * RGB(RGB_dim).anat + ...
               opacity * RGB(RGB_dim).funct ));
end;  % End of loop through the RGB dimension. 

