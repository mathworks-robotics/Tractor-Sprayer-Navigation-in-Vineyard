function varargout = helperSelectSceneWaypoints(varargin)
%helperSelectSceneWaypoints Interactively select waypoints for a scene
%   helperSelectSceneWaypoints(sceneName) launches an interactive app for
%   drawing a sequence of waypoints on a scene specified by name sceneName.
%   sceneName is a scalar string or character vector specifying the name of
%   a 3D simulation engine scene and must be one of the following:
%   "LargeParkingLot", "ParkingLot", "DoubleLaneChange", "USCityBlock",
%   "USHighway", "CurvedRoad", "VirtualMCity", "StraightRoad",
%   "OpenSurface".
%
%   helperSelectSceneWaypoints(sceneImage, sceneRef) launches an
%   interactive app for drawing a sequence of waypoints on the scene image
%   sceneImage with spatial reference sceneRef.
%
%   hFig = helperSelectSceneWaypoints(...) additionally returns a handle to
%   the app figure window.
%
%   1. Explore the scene by zooming and panning through the scene image.
%   Use the mouse scrollwheel or the axes toolbar to zoom. Hover over the
%   edge of the axes to pan in that direction.
%
%   2.  Begin drawing a path by clicking on the scene. A path
%   is created as a polyline, consisting of multiple points. Finish drawing
%   a path by double clicking or by right-clicking.
%
%   3. Once you are done drawing paths, click on the "Export to Workspace"
%   button to export the variables to the MATLAB workspace. Waypoints (x,y)
%   and reference poses (x,y,theta) can be exported to the MATLAB
%   workspace.
%   - The waypoints are exported as a cell array, with each cell element
%     containing an M-by-2 vector of [x,y] waypoints for each path drawn.
%   - The reference poses are exported as a cell array, with each cell
%     element containing an M-by-3 vector of [x,y,theta] poses for each
%     path drawn.

% Copyright 2024 The MathWorks, Inc.

nargoutchk(0,1);

% Parse inputs
[sceneImage, sceneRef] = parseInputs(varargin{:});

% Create figure and axis
[hFig, hAx, hIm] = createFigure(sceneImage, sceneRef);

% Return handle to app
if nargout==1
    varargout{1} = hFig;
end

% World coordinate limits
XYWorldRange = [sceneRef.XWorldLimits(2) - sceneRef.XWorldLimits(1), ...
    sceneRef.YWorldLimits(2) - sceneRef.YWorldLimits(1)];

% Current scene axes limits
sceneAxesLimits = [hAx.XLim, hAx.YLim];

% Text field to display current position in scene
labelPos = [0.11 0.04 0.2 0.07];
currentPositionLabel = uicontrol('Style','text','Parent',hFig,'Units','normalized','Position',labelPos,...
    'String',sprintf('Current Position \nX: 0m \nY: 0m'),'FontSize',10,'HorizontalAlignment','left');

% Add push button to export waypoints and reference poses to workspace
pushButtonPos = [0.4 0.02 0.2 0.03];
uicontrol('Style','pushbutton','Parent',hFig,'Units','normalized','Position',pushButtonPos,...
    'String','Export to workspace','FontSize',10,'Callback',@(varargin)exportPaths(hFig,varargin{:}));

% Add listener to enable zoom with mouse wheel while drawing
addlistener(hFig, 'WindowScrollWheel', @(varargin)zoomWithScroll(hAx,sceneAxesLimits,varargin{:}));

% Enter drawing mode when user clicks on image
hIm.ButtonDownFcn = @(varargin)startDrawingPolyline(hFig, hAx, varargin{:});

% Enable callback for panning using pointer motion
hFig.WindowButtonMotionFcn = @(varargin)panUsingMotion(hAx, sceneAxesLimits, XYWorldRange, currentPositionLabel, varargin{:});

end

%--------------------------------------------------------------------------
% parseInputs - Parse the input arguments
function [sceneImage, sceneRef] = parseInputs(varargin)

narginchk(1,2);

if nargin==1
    sceneName = varargin{1};
    [sceneImage, sceneRef] = helperGetSceneImage(sceneName);
elseif nargin==2
    sceneImage = varargin{1};
    sceneRef   = varargin{2};
end

% Validate inputs
validateattributes(sceneRef, {'imref2d'}, {'scalar'}, mfilename, 'sceneRef');
imageSize = sceneRef.ImageSize;
validateattributes(sceneImage, {'numeric'}, {'real','nonsparse','size',[imageSize 3]}, mfilename, 'sceneImage');

end

%--------------------------------------------------------------------------
% createFigure - Create figure, axis and place scene
function [hFig, hAx, hIm] = createFigure(sceneImage, sceneRef)

% Create parent figure
hFig = figure('Name','Draw Scene Waypoints','MenuBar','none','NumberTitle','off');

% Place an axes on the figure
hAx = axes(hFig);

% Place image on the axes
hIm = imshow(sceneImage, sceneRef, 'Parent', hAx);
hAx.YDir = 'normal';
hAx.Toolbar.Visible = 'on';

% Change axes position to accomodate export push button
hAx.Position = [0.09 0.12 0.82 0.85];

xlabel(hAx, 'X (m)')
ylabel(hAx, 'Y (m)')

end

%--------------------------------------------------------------------------
% startDrawingPolyline - Start drawing polyline on scene button down
function startDrawingPolyline(hFig, hAx, varargin)

% Creating a polyline object
hPoly = images.roi.Polyline('Parent', hAx, 'InteractionsAllowed', 'none');

% Begin drawing from current point
currentPoint = [hAx.CurrentPoint(1,1), hAx.CurrentPoint(1,2)];
beginDrawingFromPoint(hPoly, currentPoint);

% Store the waypoints
if size(hPoly.Position, 1) > 1
    hFig.UserData = [hFig.UserData,hPoly];
else
    delete(hPoly)
end

end

%--------------------------------------------------------------------------
% panUsingMotion - Pan the scene by hovering over the axis
function panUsingMotion(hAx, sceneAxesLimits, XYWorldRange, dispCurrPos, ~, eventData)

% Determine current point on axes and current axis limits
currPoint = hAx.CurrentPoint;
XLim = hAx.XLim;
YLim = hAx.YLim;
XWorldRangeCurr = XLim(2) - XLim(1);
YWorldRangeCurr = YLim(2) - YLim(1);

% Distance (world coordinates) between the axis and figure boundaries
XDistAxisFig = [(XWorldRangeCurr * hAx.Position(1)) / hAx.Position(3);
    (XWorldRangeCurr * (1 - (hAx.Position(1) + hAx.Position(3)))) / hAx.Position(3)];
YDistAxisFig = [(YWorldRangeCurr * hAx.Position(2)) / hAx.Position(4);
    (YWorldRangeCurr * (1 - (hAx.Position(2) + hAx.Position(4)))) / hAx.Position(3)];

distUserMotionMax = [XDistAxisFig; YDistAxisFig];

% Display current position if inside the axes limits
if currPoint(1,1) >  XLim(1) && currPoint(1,1) < XLim(2) && ...
        currPoint(1,2) >  YLim(1) && currPoint(1,2) < YLim(2)
    dispCurrPos.String = sprintf('Current Position \nX: %0.2fm \nY: %0.2fm',currPoint(1,1),currPoint(1,2));
else
    dispCurrPos.String = sprintf('\nX: Outside Axis \nY: Outside Axis');
end

% Return if mode (zoom, pan, etc.) is active or if user clicked on the Axes
% Toolbar or if pointer is on the export push button or if the scene is
% zoomed out completely
if (isModeManagerActive(eventData.Source) || wasClickOnAxesToolbar(eventData) || ...
        isPointerOnExport(eventData) || maxZoomedOut(hAx, XYWorldRange))
    return
else
    % Move scene to the right
    if currPoint(1,1) <  XLim(1)
        % Determine maximum movement speed based on axes limits or zoom
        % level (1m max movement for a 100m range)
        axesLen = XLim(2) - XLim(1);
        maxMovement = (1*axesLen) / 100;

        % Continue panning if pointer is outside the axes and inside the
        % figure window and if the scene world axes limits has not been
        % reached
        while(isvalid(hAx) && hAx.CurrentPoint(1,1) < hAx.XLim(1) && hAx.XLim(1) >= sceneAxesLimits(1) && ...
                hAx.XLim(1) - hAx.CurrentPoint(1,1) < distUserMotionMax(1)*0.95)
            % Determine movement scale based on position of pointer between
            % axes boundary and figure boundary
            scaleMotion = (hAx.XLim(1) - hAx.CurrentPoint(1,1))/ distUserMotionMax(1);

            % Change axes limits to move scene
            hAx.XLim = hAx.XLim - maxMovement*scaleMotion;
            drawnow('limitrate')
        end

    % Move scene to the left
    elseif currPoint(1,1) > XLim(2)
        axesLen = XLim(2) - XLim(1);
        maxMovement = (1*axesLen) / 100;

        while(isvalid(hAx) && hAx.CurrentPoint(1,1) > hAx.XLim(2) && hAx.XLim(2) <= sceneAxesLimits(2) &&...
                hAx.CurrentPoint(1,1) - hAx.XLim(2) < distUserMotionMax(2)*0.95)
            scaleMotion = -(hAx.XLim(2) - hAx.CurrentPoint(1,1))/ distUserMotionMax(2);
            hAx.XLim = hAx.XLim + maxMovement*scaleMotion;
            drawnow('limitrate')
        end

    % Move scene up
    elseif currPoint(1,2) <  YLim(1)
        axesLen = YLim(2) - YLim(1);
        maxMovement = (1*axesLen) / 100;

        while(isvalid(hAx) && hAx.CurrentPoint(1,2) < hAx.YLim(1) && hAx.YLim(1) >= sceneAxesLimits(3) && ...
                hAx.YLim(1) - hAx.CurrentPoint(1,2) < distUserMotionMax(3)*0.95 && ~isPointerOnExport(eventData))
            scaleMotion = (hAx.YLim(1) - hAx.CurrentPoint(1,2))/ distUserMotionMax(3);
            hAx.YLim = hAx.YLim - maxMovement*scaleMotion;
            drawnow('limitrate')
        end

    % Move scene down
    elseif currPoint(1,2) > YLim(2)
        axesLen = YLim(2) - YLim(1);
        maxMovement = (1*axesLen) / 100;

        while(isvalid(hAx) && hAx.CurrentPoint(1,2) > hAx.YLim(2) && hAx.YLim(2) <= sceneAxesLimits(4) &&...
                hAx.CurrentPoint(1,2) - hAx.YLim(2) < distUserMotionMax(4)*0.95)
            scaleMotion = -(hAx.YLim(2) - hAx.CurrentPoint(1,2))/ distUserMotionMax(4);
            hAx.YLim = hAx.YLim + maxMovement*scaleMotion;
            drawnow('limitrate')
        end
    end
end

end

%--------------------------------------------------------------------------
% exportPaths - Export waypoints and reference poses on push button down
function exportPaths(hFig,varargin)

checkBoxLabels = {...
    'Waypoints ([x y] only)', ...
    'Poses ([x y theta])'};

defaultVariableNames = {...
    'wayPoints', ...
    'refPoses'};

wayPoints = cell(1,numel(hFig.UserData));
refPoses = cell(1,numel(hFig.UserData));

% Store waypoints (x,y) and corresponding reference poses (x,y,theta) in
% an array of structs that can be exported to the base workspace
for i = 1:length(hFig.UserData)
    % Remove duplicate waypoints in the path to avoid bad reference poses
    [wayPoints{i}, ~, ~] = unique(hFig.UserData(i).Position, 'rows', 'stable');

    % Convert waypoints to path
    refPoses{i} = wayPointToPath(wayPoints{i});
end

% Use 'export2wsdlg' to export waypoints and reference points to workspace
itemsToExport = {wayPoints,refPoses};
titleStr = 'Export to workspace';
selected = true(size(itemsToExport));
flist = {{@dispExportInfo,itemsToExport{1},checkBoxLabels{1}},{@dispExportInfo,itemsToExport{2},checkBoxLabels{2}}};

export2wsdlg(checkBoxLabels, defaultVariableNames, itemsToExport, titleStr, selected, [], flist);

end

%--------------------------------------------------------------------------
% refPath - Convert waypoints(x,y) to path coordinates(x,y,theta)
function refPath = wayPointToPath(waypoints)

validateattributes(waypoints, {'single','double'}, ...
    {'real','2d','finite','nonempty','ncols', 2});

% Initialize path
path = [waypoints, zeros(size(waypoints,1),1,'like',waypoints)];

% Compute headings
waypointsDiff = diff(waypoints);
thetaDeg = acosd( waypointsDiff(:,1) ./ sqrt( waypointsDiff(:,1).^2 + waypointsDiff(:,2).^2 ) );

% Correct for 3rd and 4th quadrants
correctionNeeded = waypointsDiff(:,2) < 0;
thetaDeg(correctionNeeded) = 360 - thetaDeg(correctionNeeded);

path(2:end, end) = thetaDeg;
path(1, end)     = thetaDeg(1);

refPath = path;

end

%--------------------------------------------------------------------------
% zoomWithScroll - Zoom in/out of the scene using mouse wheel
function zoomWithScroll(hAx,sceneAxesLimits, ~, eventData)

scrollAmount = eventData.VerticalScrollCount;

% Update axes limits based on scroll amount and direction
updateXLim = (hAx.XLim - hAx.CurrentPoint(1,1))*((1.1)^scrollAmount) + hAx.CurrentPoint(1,1);
updateYLim = (hAx.YLim - hAx.CurrentPoint(1,2))*((1.1)^scrollAmount) + hAx.CurrentPoint(1,2);

% Ensure that the axes limits stay within the scene limits
hAx.XLim = [max(updateXLim(1),sceneAxesLimits(1)), min(updateXLim(2),sceneAxesLimits(2))];
hAx.YLim = [max(updateYLim(1),sceneAxesLimits(3)), min(updateYLim(2),sceneAxesLimits(4))];

end

%--------------------------------------------------------------------------
% isModeManagerActive - Check if any mode(zoom, pan, etc.) is active
function state = isModeManagerActive(hFig)

% Determine if any modes (zoom, pan, etc.) are active. This is used to
% determine if pan using motion should enabled/disabled
hManager = uigetmodemanager(hFig);
hMode = hManager.CurrentMode;
state = isobject(hMode) && isvalid(hMode) && ~isempty(hMode);

end

%--------------------------------------------------------------------------
% wasClickOnAxesToolbar - Check if Axes toolbar option is selected
function state = wasClickOnAxesToolbar(evt)

% Determine if the HitObject in event data is a descendant of
% the Axes Toolbar. This indicates whether or not the user just
% clicked on the Axes Toolbar.
state = ~isempty(ancestor(evt.HitObject,'matlab.graphics.controls.AxesToolbar'));

end

%--------------------------------------------------------------------------
% isPointerOnExport - Check if user is hovering over export push button
function state = isPointerOnExport(eventData)

% Determine if mouse pointer is on the 'Export to Workspace' push button
fig = eventData.Source;
button = eventData.Source.Children(1);
button.Units = 'pixels';

% Coordinates of the vertices of a rectangular region around the push
% button in pixels
xv = [button.Position(1) - 0.5*button.Position(3), button.Position(1) + button.Position(3)*1.5, ...
    button.Position(1) + button.Position(3)*1.5, button.Position(1) - 0.5*button.Position(3)];

yv = [button.Position(2) - button.Position(4), button.Position(2) - button.Position(4), ...
    button.Position(2) + button.Position(4)*2, button.Position(2) + button.Position(4)*2];

% Check if pointer is on the push button
state = inpolygon(fig.CurrentPoint(1,1), fig.CurrentPoint(1,2), xv, yv);

% Change the units to 'normalized' to ensure positioning during figure
% window resizing
button.Units = 'normalized';

end

%--------------------------------------------------------------------------
% maxZoomedOut - Check if scene is zoomed out to its actual world limits
function state = maxZoomedOut(hAx, XYWorldRange)

% Get current axes ranges
currXLimit = hAx.XLim(2) - hAx.XLim(1);
currYLimit = hAx.YLim(2) - hAx.YLim(1);

% Check if image is zoomed out to the maximum (within a threshold) by
% comparing with the original scene world limits
state = (currXLimit > 0.95*XYWorldRange(1)) && (currYLimit > 0.95*XYWorldRange(2));

end

%--------------------------------------------------------------------------
% dispExportInfo - Display description of exported variables
function value = dispExportInfo(value, varDesc)

% Description of the variables exported to the workspace
disp([varDesc, ' has been exported to the workspace.']);

end
