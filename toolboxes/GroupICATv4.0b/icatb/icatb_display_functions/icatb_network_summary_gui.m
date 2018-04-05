function answers = icatb_network_summary_gui(file_names, fnc_matrix_file)
%% Network summary gui
%

icatb_defaults;
global UI_FS;
global THRESHOLD_VALUE;
global IMAGE_VALUES;
global CONVERT_Z;


if (~exist('file_names', 'var') || isempty(file_names))
    file_names = icatb_selectEntry('typeSelection', 'multiple', 'typeEntity', 'file', 'filter', '*.img;*.nii', 'title', 'Select component nifti images ...', 'fileType', 'image');
end

if (isempty(file_names))
    error('Files are not selected');
end

drawnow;


if (~exist('fnc_matrix_file', 'var'))
    questionFNC = icatb_questionDialog('title', 'FNC Matrix?', 'textbody', 'Do You Want To Select FNC Correlations file?');
    if (questionFNC)
        fnc_matrix_file = icatb_selectEntry('typeSelection', 'single', 'typeEntity', 'file', 'filter', '*.mat;*.txt;*.dat', 'title', 'Select FNC correlations file');
    else
        fnc_matrix_file = [];
    end
end


figData.numICs = size(file_names, 1); %% Draw graphics
figData.comp = [];
figureTag = 'summary_comp_networks_gui';
figHandle = findobj('tag', figureTag);
if (~isempty(figHandle))
    delete(figHandle);
end

outputDir = icatb_selectEntry('typeEntity', 'directory', 'title', 'Select a directory to save network summary results ...');

if (isempty(outputDir))
    error('Output directory is not selected');
end

% Setup figure for GUI
InputHandle = icatb_getGraphics('Group networks', 'displaygui', figureTag, 'on');
set(InputHandle, 'menubar', 'none');
set(InputHandle, 'userdata', figData);

promptWidth = 0.52; controlWidth = 0.32; promptHeight = 0.06;
xOffset = 0.02; yOffset = promptHeight; listboxHeight = 0.18; listboxWidth = controlWidth; yPos = 0.98;
okWidth = 0.12; okHeight = promptHeight;

promptPos = [xOffset, yPos - 0.5*yOffset, promptWidth, promptHeight];

compNetworkNameData = getCompData(file_names);
drawnow;


compGroupNames = '';

listboxXOrigin = promptPos(1) + promptPos(3) + xOffset;

%     %%  Groups listbox
%     textH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'text', 'position', promptPos, 'string', 'Add Groups', 'tag', ...
%         'prompt_components', 'fontsize', UI_FS - 1);
%     icatb_wrapStaticText(textH);
%     listboxYOrigin = promptPos(2) - 0.5*listboxHeight;
%     listboxPos = [listboxXOrigin, listboxYOrigin, listboxWidth, listboxHeight];
%     listCompH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'listbox', 'position', listboxPos, 'string', '', 'tag', ...
%         'groups', 'fontsize', UI_FS - 1, 'min', 0, 'max', 2, 'value', 1, 'callback', {@addGroups, InputHandle}, 'userdata', groupInfo);
%
%     addButtonPos = [listboxPos(1) + listboxPos(3) + xOffset, listboxPos(2) + 0.5*listboxPos(4) + 0.5*promptHeight, promptHeight + 0.01, promptHeight - 0.01];
%     removeButtonPos = [listboxPos(1) + listboxPos(3) + xOffset, listboxPos(2) + 0.5*listboxPos(4) - 0.5*promptHeight, promptHeight + 0.01, promptHeight - 0.01];
%     icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'pushbutton', 'position', addButtonPos, 'string', '+', 'tag', 'add_group_button', 'fontsize',...
%         UI_FS - 1, 'callback', {@addGroups, InputHandle});
%     icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'pushbutton', 'position', removeButtonPos, 'string', '-', 'tag', 'remove_group_button', 'fontsize',...
%         UI_FS - 1, 'callback', {@removeGroups, InputHandle});

%%  Components listbox (Group components by name)
%promptPos(2) = listboxYOrigin - yOffset - 0.5*listboxHeight;
promptPos(2) = promptPos(2) - 0.3*listboxHeight - yOffset;
textH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'text', 'position', promptPos, 'string', 'Add Components', 'tag', ...
    'prompt_components', 'fontsize', UI_FS - 1);
icatb_wrapStaticText(textH);
listboxYOrigin = promptPos(2) - 0.5*listboxHeight;
listboxPos = [listboxXOrigin, listboxYOrigin, listboxWidth, listboxHeight];
listCompH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'listbox', 'position', listboxPos, 'string', compGroupNames, 'tag', ...
    'comp', 'fontsize', UI_FS - 1, 'min', 0, 'max', 2, 'value', 1, 'callback', {@addCompNetwork, InputHandle}, 'userdata', compNetworkNameData);

addButtonPos = [listboxPos(1) + listboxPos(3) + xOffset, listboxPos(2) + 0.5*listboxPos(4) + 0.5*promptHeight, promptHeight + 0.01, promptHeight - 0.01];
removeButtonPos = [listboxPos(1) + listboxPos(3) + xOffset, listboxPos(2) + 0.5*listboxPos(4) - 0.5*promptHeight, promptHeight + 0.01, promptHeight - 0.01];
icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'pushbutton', 'position', addButtonPos, 'string', '+', 'tag', 'add_comp_button', 'fontsize',...
    UI_FS - 1, 'callback', {@addCompNetwork, InputHandle});
icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'pushbutton', 'position', removeButtonPos, 'string', '-', 'tag', 'remove_comp_button', 'fontsize',...
    UI_FS - 1, 'callback', {@removeCompNetwork, InputHandle});


promptPos(2) = listboxYOrigin - yOffset - 0.5*promptHeight;
promptPos(3) = promptWidth;
textH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'text', 'position', promptPos, 'string', 'Enter prefix', 'tag', 'prompt_prefix', 'fontsize', UI_FS - 1);
icatb_wrapStaticText(textH);

editPos = promptPos;
editPos(1) = editPos(1) + editPos(3) + xOffset;
editPos(3) = controlWidth;
editH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'edit', 'position', editPos, 'string', 'IC', 'tag', 'prefix', 'fontsize', UI_FS - 1);

promptPos(2) = promptPos(2) - yOffset - 0.5*promptHeight;
promptPos(3) = promptWidth;
textH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'text', 'position', promptPos, 'string', 'Enter threshold', 'tag', 'prompt_threshold', 'fontsize', ...
    UI_FS - 1);
icatb_wrapStaticText(textH);

editPos = promptPos;
editPos(1) = editPos(1) + editPos(3) + xOffset;
editPos(3) = controlWidth;
editH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'edit', 'position', editPos, 'string', THRESHOLD_VALUE, 'tag', 'threshold', 'fontsize', UI_FS - 1);


promptPos(2) = promptPos(2) - yOffset - 0.5*promptHeight;
promptPos(3) = promptWidth;
textH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'text', 'position', promptPos, 'string', 'Convert to z-scores', 'tag', 'prompt_z', ...
    'fontsize', UI_FS - 1);
icatb_wrapStaticText(textH);

zOptions = char('Yes', 'No');
returnValue = strmatch(lower(CONVERT_Z), lower(zOptions), 'exact');

editPos = promptPos;
editPos(1) = editPos(1) + editPos(3) + xOffset;
editPos(3) = controlWidth;
popupH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'popup', 'position', editPos, 'string', zOptions, 'tag', 'convert_to_z', 'fontsize', UI_FS - 1, ...
    'value', returnValue);


promptPos(2) = promptPos(2) - yOffset - 0.5*promptHeight;
promptPos(3) = promptWidth;
textH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'text', 'position', promptPos, 'string', 'Select Image Values', 'tag', 'prompt_display', ...
    'fontsize', UI_FS - 1);
icatb_wrapStaticText(textH);

imOptions = char('Positive and Negative', 'Positive', 'Absolute value', 'Negative');
returnValue = strmatch(lower(IMAGE_VALUES), lower(imOptions), 'exact');

editPos = promptPos;
editPos(1) = editPos(1) + editPos(3) + xOffset;
editPos(3) = controlWidth;
popupH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'popup', 'position', editPos, 'string', imOptions, 'tag', 'image_values', 'fontsize', UI_FS - 1, ...
    'value', returnValue);


promptPos(2) = promptPos(2) - yOffset - 0.5*promptHeight;
promptPos(3) = promptWidth;
textH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'text', 'position', promptPos, 'string', 'Enter FNC label (Connectogram and FNC matrix)', 'tag', 'prompt_fnc', ...
    'fontsize', UI_FS - 1);
icatb_wrapStaticText(textH);


editPos = promptPos;
editPos(1) = editPos(1) + editPos(3) + xOffset;
editPos(3) = controlWidth;
editH = icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'edit', 'position', editPos, 'string', 'Corr', 'tag', 'fnc_label', 'fontsize', UI_FS - 1);


anatWidth = 0.2;
anatHeight = 0.05;
anatPos = [0.25 - 0.5*okWidth, promptPos(2) - yOffset - 0.5*okHeight, anatWidth, anatHeight];
anatPos(2) = anatPos(2) - 0.5*anatPos(4);
icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'pushbutton', 'position', anatPos, 'string', 'Select Anatomical', 'tag', 'anat_button', 'fontsize',...
    UI_FS - 1, 'callback', {@selectAnatomical, InputHandle});


%% Add cancel, save and run buttons
okPos = [0.75 - 0.5*okWidth, promptPos(2) - yOffset - 0.5*okHeight, okWidth, okHeight];
okPos(2) = okPos(2) - 0.5*okPos(4);
icatb_uicontrol('parent', InputHandle, 'units', 'normalized', 'style', 'pushbutton', 'position', okPos, 'string', 'Ok', 'tag', 'run_button', 'fontsize',...
    UI_FS - 1, 'callback', {@runCallback, InputHandle});

waitfor(InputHandle);


% check application data
if isappdata(0, 'inputDispData')
    % get the application data
    answers = getappdata(0, 'inputDispData');
    rmappdata(0, 'inputDispData'); % remove the application data
    answers.file_names = file_names;
    answers.fnc_matrix_file = fnc_matrix_file;
    network_names = answers.network_names;
    network_vals = answers.network_vals;
    thresholds = answers.threshold;
    image_values = answers.image_values;
    convert_to_z = answers.convert_to_z;
    prefix = answers.prefix;
    try
        structFile = answers.structFile;
    catch
    end
    
    
    if (~exist('network_names', 'var') || isempty(network_names))
        error('Network names doesn''t exist or is empty.');
    end
    
    if (~exist('network_vals', 'var') || isempty(network_vals))
        error('Network values doesn''t exist or is empty.');
    end
    
    if (length(network_names) ~= length(network_vals))
        error('Network names must match the network vals');
    end
    
    comp_network_names = [network_names(:), network_vals(:)];
    
    answers.comp_network_names = comp_network_names;
    
    network_opts = answers;
    network_opts.outputDir = outputDir;
    assignin('base', 'network_opts', network_opts);
    formatName = 'html';
    opts.format = formatName;
    opts.outputDir = outputDir;
    opts.showCode = false;
    opts.useNewFigure = false;
    opts.format = lower(formatName);
    opts.createThumbnail = true;
    if (strcmpi(opts.format, 'pdf'))
        opt.useNewFigure = false;
    end
    opts.codeToEvaluate = 'icatb_network_summary(network_opts);';
    %publish('icatb_gica_html_report', 'outputDir', outDir, 'showCode', false, 'useNewFigure', false);
    disp('Generating network summary. Please wait ....');
    drawnow;
    publish('icatb_network_summary', opts);
    
    newFile = fullfile(outputDir, [prefix, '_network_summary.', formatName]);
    oldFile = fullfile(outputDir, ['icatb_network_summary.', formatName]);
    movefile(oldFile, newFile);
    
    if (strcmpi(opts.format, 'html'))
        icatb_openHTMLHelpFile(newFile);
    else
        open(newFile);
    end
    
    disp('Done');
    
    close all;
    
else
    
    error('Figure window was quit');
    
end


function c = charC(a, b)
%% Character array. Strings are centered.
%

len = max([length(a), length(b)]);

c = repmat(' ', 2, len);

s = ceil(len/2 - length(a)/2) + 1;
c(1, s:s+length(a) - 1) = a;
s = ceil(len/2 - length(b)/2) + 1;
c(2, s:s + length(b) - 1) = b;


function compNetworkNameData = getCompData(file_names)

structFile = deblank(file_names(1, :));

%% Get colormap associated with the image values
structData2 =  icatb_spm_read_vols(icatb_spm_vol(structFile));
structData2(isfinite(structData2) == 0) = 0;
structDIM = [size(structData2, 1), size(structData2, 2), 1];

for nC = 1:size(file_names, 1)
    
    tmp = icatb_spm_read_vols(icatb_spm_vol(file_names(nC, :)));
    tmp(isfinite(tmp)==0) = 0;
    
    tmp(tmp ~= 0) = detrend(tmp(tmp ~= 0), 0) ./ std(tmp(tmp ~= 0));
    tmp(abs(tmp) < 1.0) = 0;
    
    if (nC == 1)
        compData = zeros(size(tmp, 1), size(tmp, 2), size(file_names, 1));
    end
    
    [dd, inds] = max(tmp(:));
    
    [x, y, z] = ind2sub(size(tmp), inds);
    
    [tmp, maxICAIM, minICAIM, minInterval, maxInterval] = icatb_overlayImages(reshape(tmp(:, :, z), [1, size(tmp, 1), size(tmp, 2), 1]), structData2(:, :, z), structDIM, structDIM, 1);
    
    compData(:, :, nC) = reshape(tmp, structDIM);
    
end


clim = [minInterval, 2*maxInterval];
cmap = icatb_getColormap(1, 1, 1);

compNetworkNameData.clim = clim;
compNetworkNameData.cmap = cmap;
compNetworkNameData.compData = compData;


function addCompNetwork(hObject, event_data, figH)
%% Add Component network
%

icatb_defaults;
global UI_FS;

figureTag = 'add_comp_dfnc';
compFigHandle = findobj('tag', figureTag);
if (~isempty(compFigHandle))
    delete(compFigHandle);
end

figData = get(figH, 'userdata');

listH = findobj(figH, 'tag', 'comp');

compVals = [];
networkName = '';
if (listH == hObject)
    if (~strcmpi(get(figH, 'selectionType'), 'open'))
        return;
    end
    val = get(listH, 'value');
    try
        networkName = figData.comp(val).name;
        compVals = figData.comp(val).value;
    catch
    end
end

compStr = num2str((1:figData.numICs)');

compFigHandle = icatb_getGraphics('Select Component Networks', 'normal', figureTag);
set(compFigHandle, 'menubar', 'none');

promptWidth = 0.52; controlWidth = 0.32; promptHeight = 0.05;
xOffset = 0.02; yOffset = promptHeight; listboxHeight = 0.6; yPos = 0.9;
okWidth = 0.12; okHeight = promptHeight;

%% Features text and listbox
promptPos = [xOffset, yPos - 0.5*yOffset, promptWidth, promptHeight];
textH = icatb_uicontrol('parent', compFigHandle, 'units', 'normalized', 'style', 'text', 'position', promptPos, 'string', 'Enter Network Name', 'fontsize', UI_FS - 1);
icatb_wrapStaticText(textH);

promptPos = get(textH, 'position');

editPos = promptPos;
editPos(1) = editPos(1) + editPos(3) + xOffset;
editPos(3) = controlWidth;
icatb_uicontrol('parent', compFigHandle, 'units', 'normalized', 'style', 'edit', 'position', editPos, 'string', networkName, 'tag', 'comp_network_name', 'fontsize', UI_FS - 1);

%% Right Listbox
listbox2Wdith = 0.1;
promptPos(2) = promptPos(2) - yOffset - 0.5*promptHeight;
promptPos(1) = (1 - xOffset - 2*listbox2Wdith);
promptPos(3) = 2*listbox2Wdith;
textH = icatb_uicontrol('parent', compFigHandle, 'units', 'normalized', 'style', 'text', 'position', promptPos, 'string', 'Components', 'fontsize', UI_FS - 1);
icatb_wrapStaticText(textH);
promptPos = get(textH, 'position');
listboxYOrigin = promptPos(2) - 0.5*yOffset - listboxHeight;
listboxXOrigin = promptPos(1) + 0.5*listbox2Wdith;
listboxPos = [listboxXOrigin, listboxYOrigin, listbox2Wdith, listboxHeight];
compListH = icatb_uicontrol('parent', compFigHandle, 'units', 'normalized', 'style', 'listbox', 'position', listboxPos, 'string', compStr, 'tag', 'components', 'fontsize', UI_FS - 1, ...
    'min', 0, 'max', 2, 'value', compVals);

%% Show components
showWidth = 0.08; showHeight = 0.04;
showButtonPos = [listboxXOrigin + 0.5*listbox2Wdith - 0.5*showWidth, listboxYOrigin - yOffset - 0.5*showHeight, showWidth, showHeight];
showH = icatb_uicontrol('parent', compFigHandle, 'units', 'normalized', 'style', 'pushbutton', 'position', showButtonPos, 'string', 'Show', 'fontsize', UI_FS - 1, 'callback', ...
    {@drawComp, figH, compFigHandle});

%% Plot image on the left hand side
axesPos = [xOffset, listboxYOrigin, listboxHeight, listboxHeight];
axesH = axes('parent', compFigHandle, 'units', 'normalized', 'position', axesPos, 'tag', 'axes_display_comp');

promptPos = axesPos;

%% Add cancel and run buttons
okPos = [0.5 - 0.5*okWidth, promptPos(2) - yOffset - 0.5*okHeight, okWidth, okHeight];
okPos(2) = okPos(2) - 0.5*okPos(4);
icatb_uicontrol('parent', compFigHandle, 'units', 'normalized', 'style', 'pushbutton', 'position', okPos, 'string', 'Done', 'tag', 'done_button', 'fontsize', UI_FS - 1, 'callback', ...
    {@setCompCallback, compFigHandle, figH});

%% Draw components on the left hand side
drawComp(compListH, [], figH, compFigHandle);


function removeCompNetwork(hObject, event_data, figH)
%% Remove Component network
%

figData = get(figH, 'userdata');
listH = findobj(figH, 'tag', 'comp');
val = get(listH, 'value');

if (~isempty(val))
    check = icatb_questionDialog('title', 'Remove Component Network', 'textbody', 'Do you want to remove the component network from the list?');
    if (~check)
        return;
    end
end

try
    strs = cellstr(char(figData.comp.name));
    figData.comp(val) = [];
    strs(val) = [];
    set(listH, 'value', 1);
    set(listH, 'string', strs);
    set(figH, 'userdata', figData);
catch
end

function drawComp(hObject, event_data, figH, compFigHandle)
%% Draw component

icatb_defaults;
global UI_FONTNAME;
global FONT_COLOR;

fontSizeText = 8;
set(compFigHandle, 'pointer', 'watch');

listH = findobj(figH, 'tag', 'comp');
compNetworkNameData = get(listH, 'userdata');

axesH = get(compFigHandle, 'currentaxes');

clim = compNetworkNameData.clim;
cmap = compNetworkNameData.cmap;
compData = compNetworkNameData.compData;

sel_comp = get(findobj(compFigHandle, 'tag', 'components'), 'value');

if (~isempty(sel_comp))
    DIM = [size(compData, 1), size(compData, 2), length(sel_comp)];
    [im, numImagesX, numImagesY, textToPlot] = icatb_returnMontage(compData(:, :, sel_comp), [], DIM, [1, 1, 1], sel_comp);
    image(im, 'parent', axesH, 'CDataMapping', 'scaled');
    set(axesH, 'clim', clim); % set the axis positions to the specified
    axis(axesH, 'off');
    axis(axesH, 'image');
    colormap(cmap);
    textCount = 0;
    dim = size(im);
    yPos = 1 + dim(1) / numImagesY;
    for nTextRows = 1:numImagesY
        xPos = 1;
        for nTextCols = 1:numImagesX
            textCount = textCount + 1;
            if textCount <= DIM(3)
                text(xPos, yPos, num2str(round(textToPlot(textCount))), 'color', FONT_COLOR,  ...
                    'fontsize', fontSizeText, 'HorizontalAlignment', 'left', 'verticalalignment', 'bottom', ...
                    'FontName', UI_FONTNAME, 'parent', axesH);
            end
            xPos = xPos + (dim(2) / numImagesX);
        end
        % end for cols
        yPos = yPos + (dim(1) / numImagesY); % update the y position
    end
else
    cla(axesH);
end

set(compFigHandle, 'pointer', 'arrow');

function runCallback(hObject, event_data, handles)
%% Select values
%

figData = get(handles, 'userdata');

%% Prefix
figData.prefix = get(findobj(handles, 'tag', 'prefix'), 'string');

%% Image values
czH = findobj(handles, 'tag', 'convert_to_z');
strs = cellstr(get(czH, 'string'));
val = get(czH, 'value');
convert_to_z = lower(strs{val});
figData.convert_to_z = convert_to_z;


%% Threshold
threshH = findobj(handles, 'tag', 'threshold');
figData.threshold = str2num(get(threshH, 'string'));

%% FNC label
fnc_colorbar_label = get(findobj(handles, 'tag', 'fnc_label'), 'string');
figData.fnc_colorbar_label = fnc_colorbar_label;

%% Image values
imageH = findobj(handles, 'tag', 'image_values');
strs = cellstr(get(imageH, 'string'));
val = get(imageH, 'value');
image_values = lower(strs{val});
figData.image_values = image_values;

if (isempty(figData.comp))
    error('Please select components using + button');
end

network_names = cellstr(char(figData.comp.name));
network_values = cell(1, length(network_names));

for n = 1:length(network_values)
    network_values{n} = figData.comp(n).value;
end

%% Network names and values
figData.network_vals = network_values;
figData.network_names = network_names;

setappdata(0, 'inputDispData', figData);

drawnow;

delete(handles);


function setCompCallback(hObject, event_data, compFigH, handles)
%% Get fields from component

figData = get(handles, 'userdata');
networkNameH = findobj(compFigH, 'tag', 'comp_network_name');
networkName = deblank(get(networkNameH, 'string'));

try
    
    if (isempty(networkName))
        error('You must enter a component network name');
    end
    
    listH = findobj(compFigH, 'tag', 'components');
    comps = get(listH, 'value');
    
    if (isempty(comps))
        error('Components are not selected');
    end
    
    if (length(figData.comp) > 0)
        chk = strmatch(lower(networkName), lower(cellstr(char(figData.comp.name))), 'exact');
        if (~isempty(chk))
            ind = chk;
        end
    end
    
    if (~exist('ind', 'var'))
        ind = length(figData.comp) + 1;
    end
    
    %% Set user selected information in figure
    figData.comp(ind).name = networkName;
    figData.comp(ind).value =  comps(:)';
    set(handles, 'userdata', figData);
    compListH = findobj(handles, 'tag', 'comp');
    set(compListH, 'string', cellstr(char(figData.comp.name)));
    delete(compFigH);
    
catch
    icatb_errorDialog(lasterr, 'Component Selection');
end


function selectAnatomical(hObject, event_data, figH)
%% Anatomical callback
%

figData = get(figH, 'userdata');

startPath = fileparts(which('gift.m'));
startPath = fullfile(startPath, 'icatb_templates');

oldDir = pwd;

if (~exist(startPath, 'dir'))
    startPath = pwd;
end

% get the structural file
structFile = icatb_selectEntry('typeEntity', 'file', 'title', 'Select Structural File', 'filter', ...
    '*.img;*.nii', 'fileType', 'image', 'fileNumbers', 1, 'startpath', startPath);

drawnow;

cd(oldDir);

if (~isempty(structFile))
    figData.structFile = structFile;
    set(figH, 'userdata', figData);
end

