function varargout = hint(varargin)

%hint.m - The main function for the HINT toolbox. This function
%loads the required toolboxes and opens the GUI window.
% 
%Authors: Joshua Lukemire, Amit Verma
%
%See also: hint.m

    % https://undocumentedmatlab.com/articles/modifying-matlab-look-and-feel
%     if usejava('swing') 
%         %javax.swing.UIManager.setLookAndFeel('com.apple.laf.AquaLookAndFeel');
%         javax.swing.UIManager.setLookAndFeel('javax.swing.plaf.nimbus.NimbusLookAndFeel');
%     end

    hintFnPath = which('hint.m');
    [hcicadir, ~, ~] = fileparts(hintFnPath);

    % Add paths to all subfolders
    addpath(genpath(fullfile(hcicadir, 'toolboxes')))
    addpath(genpath(fullfile(hcicadir, 'displayWindow')))
    addpath(genpath(fullfile(hcicadir, 'src')))
    addpath(genpath(fullfile(hcicadir, 'gui')))
    addpath(genpath(fullfile(hcicadir, 'test')))    

    % Run the main GUI script
    main();

