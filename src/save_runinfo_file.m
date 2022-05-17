function save_runinfo_file(fname, prefix, data)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% Waitbar to let the user know data is saving
waitSave = waitbar(0,'Please wait while the analysis setup saves to the runinfo file');

%  save the run info
q = data.qstar; 
time_num = data.time_num;
X = data.X;       
waitbar(1/20)
validVoxels=data.validVoxels;
niifiles = data.niifiles;     
waitbar(2/20)
maskf = data.maskf; covfile = data.covf;    
studyType = data.studyType;
waitbar(3/20)
numPCA = data.numPCA;
waitbar(4/20)
outfolder = data.outpath;
waitbar(5/20)
covariates = data.covariates;                               
waitbar(6/20)
covTypes = data.covTypes;                                   
waitbar(7/20)
varNamesX = data.varNamesX;                                 
waitbar(8/20)
interactions = data.interactions  ;                         
interactionsBase = data.interactionsBase;
waitbar(9/20)
thetaStar = data.thetaStar;                                 
waitbar(10/20)
YtildeStar = data.YtildeStar;                               
waitbar(11/20)
CmatStar = data.CmatStar;                                  
waitbar(12/20)
beta0Star = data.beta0Star;                                 
waitbar(13/20)
voxSize = data.voxSize;                                     
waitbar(14/20)
N = data.N;                                                 
waitbar(15/20)
qold = data.q;                                              
waitbar(16/20)
varInModel = data.varInModel;
nVisit = data.nVisit;
waitbar(17/20)
varInCovFile = data.varInCovFile;
referenceGroupNumber = data.referenceGroupNumber;
waitbar(18/20)
variableCodingInformation = struct();
variableCodingInformation.effectsCodingsEncoders = data.effectsCodingsEncoders;
variableCodingInformation.weighted = data.weighted;
variableCodingInformation.unitScale = data.unitScale;
maskOriginator = data.maskOriginator;


save(fname, 'q', ...
    'time_num', 'X', 'validVoxels', 'niifiles', 'maskf', 'covfile', 'numPCA', ...
    'outfolder', 'prefix', 'covariates', 'covTypes', 'beta0Star', 'CmatStar',...
    'YtildeStar', 'thetaStar', 'voxSize', 'N', 'qold', 'varNamesX',...
    'interactions', 'varInModel', 'varInCovFile', 'interactionsBase',...
    'referenceGroupNumber', 'nVisit', 'variableCodingInformation', 'studyType',...
    'maskOriginator');

waitbar(20/20)

close(waitSave)

end

