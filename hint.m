function varargout = hint(varargin)

%hint.m - The main function for the HINT toolbox. This function
%loads the required toolboxes and opens the GUI window.
% 
%Authors: Joshua Lukemire, Amit Verma
%
%See also: hint.m

    hintFnPath = which('hint.m');
    [hcicadir, ~, ~] = fileparts(hintFnPath);

    % Add paths to all subfolders
    addpath(genpath(fullfile(hcicadir, 'toolboxes')))
    addpath(genpath(fullfile(hcicadir, 'displayWindow')))
    addpath(genpath(fullfile(hcicadir, 'src')))
    addpath(genpath(fullfile(hcicadir, 'gui')))
    addpath(genpath(fullfile(hcicadir, 'test')))    
%     
%     addpath(genpath('displayWindow'))
%     addpath('src')
%     addpath(genpath('gui'))
%     addpath(genpath('toolboxes/GroupICATv4.0b'))
%     addpath(genpath('test'))

    % Run the main GUI script
    main();

