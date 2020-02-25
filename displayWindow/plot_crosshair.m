function crosshair = plot_crosshair(varargin)
%creates a crosshair and returns a crosshair structure.
%
%Syntax crosshair = plot_crosshair(axis_position, cross, gca)
%
%Inputs:
%    axis_position   - A 2 dimensional vector of the point to be the center
%                      of the crosshair
%    cross           - Crosshair structure. Can be left blank using [].
%    gca             - axis handle to plot to
%
%   If omit crosshair, plot_crosshair will create a pair of crosshair; otherwise,
%   plot_crosshair will update the crosshair. If omit h_ax, current axes will
%   be used.
%
%Function modified from the bs-mac function by Lijun Zhang, Ph.D.
%Part of this file is copied and modified under GNU license from
%jimmy (jimmy@rotman-baycrest.on.ca)
%

if nargin == 0
  error('Please enter a point position as first argument');
  return;
end

if nargin > 0
  p = varargin{1};

  if ~isnumeric(p) || length(p) ~= 2
     error('Invalid point position');
     return;
  else
     crosshair = [];
  end
end

if nargin > 1
  crosshair = varargin{2};

  if ~isempty(crosshair)
     if ~isstruct(crosshair)
        error('Invalid crosshair struct');
        return;
     elseif ~isfield(crosshair,'lx') | ~isfield(crosshair,'ly')
        error('Invalid crosshair struct');
        return;
     elseif ~ishandle(crosshair.lx) | ~ishandle(crosshair.ly)
        error('Invalid crosshair struct');
        return;
     end

     lx = crosshair.lx;
     ly = crosshair.ly;
  else
     lx = [];
     ly = [];
  end
end

if nargin > 2
  h_ax = varargin{3};

  if ~ishandle(h_ax)
     error('Invalid axes handle');
     return;
  elseif ~strcmpi(get(h_ax,'type'), 'axes')
     error('Invalid axes handle');
     return;
  end
else
  h_ax = gca;
end

% Get the range of the plot
x_range = get(h_ax,'xlim');
y_range = get(h_ax,'ylim');

if ~isempty(crosshair)
  set(lx, 'ydata', [p(2) p(2)]);
  set(ly, 'xdata', [p(1) p(1)]);
  set(h_ax, 'selected', 'on');
  set(h_ax, 'selected', 'off');
else
    
 % Grab the parent object
 figure(get(get(get(h_ax,'parent'), 'parent'), 'parent'));
 axes(h_ax);

 % add the crosshair line coordinates
  crosshair.lx = line('xdata', x_range, 'ydata', [p(2) p(2)], ...
    'zdata', [11 11], 'color', [1, 0, 0], 'hittest', 'off');
  crosshair.ly = line('xdata', [p(1) p(1)], 'ydata', y_range, ...
    'zdata', [11 11], 'color', [1, 0, 0], 'hittest', 'off');
end

set(h_ax,'xlim',x_range);
set(h_ax,'ylim',y_range);

return;

