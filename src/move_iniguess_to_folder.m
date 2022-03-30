function [ output_args ] = move_iniguess_to_folder( path, prefix )
%move_iniguess_to_folder
%   Function to take the initial guess from gift and move it to a separate
%   folder to avoid clogging up the primary output folder.
%
% Syntax:
% [ output_args ] = move_iniguess_to_folder( path, prefix )
%
% Inputs:
%   path   - path to the output folder
%   prefix - prefix for the analysis
%
% See also: ref_cell_code.m

% Get the current location to return to
currentPath = pwd();

% Switch to the output directory
cd(path);

% If the initial guess directory does not exist then create it
if 0 == exist([prefix, '_iniguess'], 'dir')
    mkdir([prefix, '_iniguess']);
end

iniStoreDir = [prefix, '_iniguess'];

% Now move from ini guess to new folder
% move the pcafiles
pcafiles = dir('*_pca_r*.mat');
for iFile = 1:length(pcafiles)
    movefile(pcafiles(iFile).name, iniStoreDir)
end

% move the icafiles
icafiles = dir('*ica*.mat');
for iFile = 1:length(icafiles)
    movefile(icafiles(iFile).name, iniStoreDir)
end

icafiles = dir('*timecourses*.nii');
for iFile = 1:length(icafiles)
    movefile(icafiles(iFile).name, iniStoreDir)
end

icafiles = dir('*component*.nii');
for iFile = 1:length(icafiles)
    movefile(icafiles(iFile).name, iniStoreDir)
end

icafiles = dir('*results*.log');
for iFile = 1:length(icafiles)
    movefile(icafiles(iFile).name, iniStoreDir)
end

icafiles = dir('*postprocess*.mat');
for iFile = 1:length(icafiles)
    movefile(icafiles(iFile).name, iniStoreDir)
end

icafiles = dir('*Mask*.hdr');
for iFile = 1:length(icafiles)
    movefile(icafiles(iFile).name, iniStoreDir)
end

icafiles = dir('*Mask*.img');
for iFile = 1:length(icafiles)
    movefile(icafiles(iFile).name, iniStoreDir)
end


icafiles = dir('*Subject.mat');
for iFile = 1:length(icafiles)
    movefile(icafiles(iFile).name, iniStoreDir)
end

end

