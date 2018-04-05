function varargout = hint(varargin)

%hint.m - The main function for the HINT toolbox. This function
%loads the required toolboxes and opens the GUI window.
% 
%Authors: Joshua Lukemire, Amit Verma
%
%See also: hint.m

    % Add paths to all subfolders
    addpath(genpath('toolboxes'))
    addpath(genpath('displayWindow'))
    addpath('src')
    addpath('gui')
    addpath(genpath('toolboxes/GroupICATv4.0b'))

    % Run the main GUI script
    main();

