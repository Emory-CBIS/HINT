function colorbar_plot(f, colorbar_labels, corresponding_values_on_1_to_64_scale, color_map)
%colorbar_plot - Internal function to plot the colorbar for the display
%window
%
%Syntax:  colorbar_plot(f, colorbar_labels, corresponding_values_on_1_to_64_scale)
%
%Inputs:
%    f                   - handle of colormap figure
%    colorbar_labels     - labels for the colorbar (i.e. tics)
%    corresponding_values_on_1_to_64_scale   - Scaled version of the
%       values for the colorbar. Obtained using the 'scale_in' function.
%
%See also: scale_in
%
%Function by: Lijun Zhang, Ph.D  
% Last edited by: Joshua Lukemire on 4/20/2021

colormap_range = size(color_map, 1);
vec64=[colormap_range:-1:1]';
image(vec64);

% Create the "hot" top color, bottom will be "cool"
% jet2=jet(64);
% jet2(38:end, :)=[];
% hot2=hot(64);
% hot2(end-5:end, :)=[];
% hot2(1:4, :)=[];
% hot2(1:2:38, :)=[];
% hot2(2:2:16, :)=[];
% hot2=flipud(hot2);
% 
% % Join the hot and cold colormaps into one map
% hot3=[flipud(hot2); flipud(jet2)];
% hot3 = flipud(jet(64));

% Set the new colormap as the colormap
colormap(flipud(color_map));

% Generate colorbar labels, xlimmode manual
set(f, 'YlimMode', 'manual',...
    'Ylim', [1,colormap_range],...
    'YColor',[1 0 0],'XColor',[1 0 0],'XTickLabel',[],...
    'YTickLabel',(colorbar_labels),'YAxisLocation','right',...
    'YTick',(corresponding_values_on_1_to_64_scale));