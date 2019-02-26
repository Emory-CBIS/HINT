function val = scale_in(val, minval, maxval, range)
%scale_in - Function to scale values for the colormap into a range
% 
%Syntax: val = scale_in(val, minval, maxval, range)
%
%Inputs:
%   val     - Tics for the colorbar
%   minval  - Minimum Value
%   maxval  - Maximum value
%   range   - Range to scale to (0:Range)
%
%See Also: colorbar_plot.m
%
%Function by: Lijun Zhang, Ph.D

% Convert the values to the proper range

val = range*((double(val)-double(minval))./(double(maxval-minval) + eps)) + 1;

  
