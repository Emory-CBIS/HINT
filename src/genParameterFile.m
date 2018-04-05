function [  ] = genParameterFile( niipaths, mskFL, covpath, npc, nsub, prefix, outpath )
% genParameterFile - Function to generate the "runinfo" file for GIFT.
%
% Syntax:
%       genParameterFile (npc, mskFL, niipaths, covpath, nsub)
%
% Inputs:
%    npc            - number of principle components
%    mskFL          - filepath to the mask
%    niipaths       - paths to the nii files
%    covpath        - path to the covariate file
%    nsub           - number of subjects in the analysis
%    prefix         - prefix for the analysis
%    outpath        - output folder for the analysis
%
% See also: runGift.m

% Create and open the runinfo file for GIFT.
outputfile = [outpath '/' prefix];
fileID = fopen(outputfile, 'w');

% The rest of the file writes analysis options to the runinfo file for
% gift.

fprintf(fileID, 'dataSelectionMethod = 2;   \n');

% need to list each of the subjects.
fprintf(fileID, 'selectedSubjects = {');
for i = 1:nsub
    if i < nsub
    fprintf(fileID, strcat(char(39), 's', num2str(i), char(39),','));
    else
    fprintf(fileID, strcat(char(39), 's', num2str(i), char(39), '};\n') );
    end
end

fprintf(fileID, 'numOfSess = 1;   \n');

% this one is going to take some work
for i = 1:nsub
    %for c = 1:nsub
    [pathstr,name,ext] = fileparts(niipaths{i});
    %end
    path = pathstr;
    fprintf(fileID, strcat('s', num2str(i), '_s1 = {', char(39), path, char(39), ',', char(39), [name ext], char(39),  '};\n'));
end

fprintf(fileID, strcat('keyword_designMatrix = ', char(39), 'no', char(39),';\n'));

OutDir = '/Users/joshlukemire/repos/hcica/temp';
fprintf(fileID, strcat('outputDir = ', char(39), OutDir, char(39),';\n'));

pfx = 'temp';
fprintf(fileID, strcat('prefix = ', char(39), pfx, char(39),';\n'));

fprintf(fileID, strcat('maskFile = ', char(39), mskFL, char(39),';\n'));

numReductionSteps = 1; 
fprintf(fileID, 'numReductionSteps = 1;\n' );

doEstimation = 0;
fprintf(fileID, 'doEstimation = 0;\n' );

for i = 1:nsub
fprintf(fileID, strcat('numOfPC',num2str(i),' = ', num2str(npc), ';\n'));
end

scaleType = 0;
fprintf(fileID, 'scaleType = 0;\n' );

altype = 'Infomax';
fprintf(fileID, strcat('algoType = ', char(39), altype, char(39),';\n'));

fclose(fileID);


end

