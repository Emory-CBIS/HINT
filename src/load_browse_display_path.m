function [ prefix, vis_prefix, vis_covariates,...
            vis_covTypes, vis_X, vis_varNamesX,...
            vis_interactions, vis_interactionsBase,...
            vis_niifiles, vis_N, vis_nVisit,...
            vis_qstar] = load_browse_display_path( input_args )
%load_browse_display_path - function to load some of the basic information
%for the visualization window. This function does half the work,
%load_results_for_visualization does the rest
%see also: load_results_for_visualization.m


sel = 1;
for preIndex = 1:length(runinfofiles)
    prename = runinfofiles(preIndex).name;
    runinfofiles(preIndex).name = prename(1:length(prename)-12);
end

if ( length(runinfofiles) > 1 )
    sel = listdlg('PromptString','Choose a prefix:',...
        'SelectionMode','single',...
        'ListString',{runinfofiles.name});
end

% Create a waitbar while the runinfo file loads
waitLoad = waitbar(0, 'Please wait while the runinfo file loads...');

prefix = runinfofiles(sel).name;
% Read the runinfo .m file. Update "data" information.
vis_prefix = get(preEdit,'String');
runInfo = load([folderName '/' prefix '_runinfo.mat']);
waitbar(5/10)
vis_covariates = runInfo.covariates;
vis_covTypes = runInfo.covTypes;
vis_X = runInfo.X;
vis_varNamesX = runInfo.varNamesX;
vis_interactions = runInfo.interactions;
vis_interactionsBase = runInfo.interactionsBase;
vis_niifiles = runInfo.niifiles;
[vis_N, ~] = size(runInfo.X);
vis_nVisit = runInfo.nVisit;
vis_qstar = runInfo.q;
waitbar(1)
close(waitLoad);

%Force the keeplist variable to reflect the number of ICs
global keeplist
keeplist = ones(vis_qstar, 1);

disp('WARNING THIS NEEDS LICA VAR EST')

end

