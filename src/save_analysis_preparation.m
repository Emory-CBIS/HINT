function [ prefix ] = save_analysis_preparation( data )
%save_analysis_preparation - function to save all of the preprocessing work
%in panel 1 to the runinfo file.

userNeedsToInputPrefix = 1;
prefix = '';
while userNeedsToInputPrefix
    
    % Ask the user for a prefix for the analysis
    prefix = inputdlg('Please input a prefix for the analysis', 'Prefix Selection');
    
    if ~isempty(prefix)
        prefix = prefix{1};
        % Check if this prefix is already in use. If it is, ask the user to
        % verify that they want to continue + delete current contents
        if exist([data.outpath '/' prefix '_results']) == 7
            qans = questdlg(['This prefix is already in use. If you continue, all previous results in the ', [data.outpath '/' prefix '_results'], ' folder will be deleted. Do you want to continue?' ] );
            % If yes, delete old results and proceed
            if strcmp(qans, 'Yes')
                userNeedsToInputPrefix = 0;
                % Delete all content from the folder
                rmdir(fullfile(data.outpath, [prefix '_results']), 's')
            end
            % Folder not already in use
        else
            userNeedsToInputPrefix = 0;
        end
    end
    
end

% make the results directory
mkdir([data.outpath '/' prefix '_results']);
prefix = [prefix  '_results/' prefix];

% Waitbar to let the user know data is saving
waitSave = waitbar(0,'Please wait while the analysis setup saves to the runinfo file');

%  save the run info, hide the warning that the variables are
%  unused
q = data.qstar; time_num = data.time_num; X = data.X;       %#ok<NASGU>
waitbar(1/20)
validVoxels=data.validVoxels; niifiles = data.niifiles;     %#ok<NASGU>
waitbar(2/20)
maskf = data.maskf; covfile = data.covf;                    %#ok<NASGU>
waitbar(3/20)
numPCA = num2str(get(findobj('Tag', 'numPCA'), 'String'));  %#ok<NASGU>
waitbar(4/20)
outfolder = data.outpath; %prefix = data.prefix;             %#ok<NASGU>
waitbar(5/20)
covariates = data.covariates;                               %#ok<NASGU>
waitbar(6/20)
covTypes = data.covTypes;                                   %#ok<NASGU>
waitbar(7/20)
varNamesX = data.varNamesX;                                 %#ok<NASGU>
waitbar(8/20)
interactions = data.interactions  ;                         %#ok<NASGU>
interactionsBase = data.interactionsBase;
waitbar(9/20)
thetaStar = data.thetaStar;                                 %#ok<NASGU>
waitbar(10/20)
YtildeStar = data.YtildeStar;                               %#ok<NASGU>
waitbar(11/20)
CmatStar = data.CmatStar;                                   %#ok<NASGU>
waitbar(12/20)
beta0Star = data.beta0Star;                                 %#ok<NASGU>
waitbar(13/20)
voxSize = data.voxSize;                                     %#ok<NASGU>
waitbar(14/20)
N = data.N;                                                 %#ok<NASGU>
waitbar(15/20)
qold = data.q;                                              %#ok<NASGU>
waitbar(16/20)
varInModel = data.varInModel;%#ok<NASGU>
nVisit = data.nVisit;%#ok<NASGU>
waitbar(17/20)
varInCovFile = data.varInCovFile;%#ok<NASGU>
referenceGroupNumber = data.referenceGroupNumber;
waitbar(18/20)

save([data.outpath '/' prefix '_runinfo.mat'], 'q', ...
    'time_num', 'X', 'validVoxels', 'niifiles', 'maskf', 'covfile', 'numPCA', ...
    'outfolder', 'prefix', 'covariates', 'covTypes', 'beta0Star', 'CmatStar',...
    'YtildeStar', 'thetaStar', 'voxSize', 'N', 'qold', 'varNamesX',...
    'interactions', 'varInModel', 'varInCovFile', 'interactionsBase',...
    'referenceGroupNumber', 'nVisit');
waitbar(20/20)
close(waitSave)


end

