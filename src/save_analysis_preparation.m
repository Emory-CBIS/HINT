function [ prefix ] = save_analysis_preparation( data, prefix )
%save_analysis_preparation - function to save all of the preprocessing work
%in panel 1 to the runinfo file.
% if prefix is 0, asks user for prefix, otherwise uses input
    
prefixNotProvided = all((prefix == 0) == 1);

% Ask the user for a prefix for the analysis
if prefixNotProvided
    prefix = inputdlg('Please input a prefix for the analysis', 'Prefix Selection');
else
    ptemp = prefix;
    prefix = cell(0);
    prefix{1} = ptemp;
end

if ~isempty(prefix)
    
    prefix = prefix{1};
    
    % Check if this prefix is already in use. If it is, ask the user to
    % verify that they want to continue + delete current contents
    if exist([data.outpath '/' prefix '_results'], 'dir') && prefixNotProvided == 1
        qans = questdlg(['This prefix is already in use. If you continue, all previous results in the ', [data.outpath '/' prefix '_results'], ' folder will be deleted. Do you want to continue?' ] );
        % If yes, delete old results and proceed
        if strcmp(qans, 'Yes')
            % Delete all content from the folder
            rmdir(fullfile(data.outpath, [prefix '_results']), 's')
        else
            prefix = [];
            return
        end
    end
    
    % make the results directory
    mkdir([data.outpath '/' prefix '_results']);
    prefix = [prefix  '_results/' prefix];

end


end

