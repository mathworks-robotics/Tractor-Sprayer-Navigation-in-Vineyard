function [sceneImage, sceneRef] = helperGetVineyardSceneImage(showImage)
% helperShowVineyardSceneImage Helper to return a top-down orthographic vineyard
%   scene image and its scene reference object. If showImage is true then
%   the scene image is displayed along with its X and Y axis limits. The dimensional 
%   limits of the image are [-3.5 66.5] metres on the X-axis and [-26.5 18.5] 
%   metres on the Y-axis. The vineyard contains 5 rows of vines.
%
% Copyright 2024 The MathWorks, Inc.
sceneImage = imread("images/VineyardSceneWithFence.png");
imageSize = size(sceneImage);
xlims = [-3.5 66.5]; % in meters
ylims = [-26.50 18.50];  % in meters
sceneRef = imref2d(imageSize,xlims,ylims);
if showImage
    % Display and flip the image to keep correct image orientation after 
    % the next step
    imshow(flip(sceneImage,1), sceneRef)

    % Correct Y axis for right-handed world Cartesian coordinate system
    set(gca,YDir="normal",Visible="on")

    % Add axes labels
    xlabel("X (m)") 
    ylabel("Y (m)") 
end
end