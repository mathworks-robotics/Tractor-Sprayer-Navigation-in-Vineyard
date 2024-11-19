function helperShowVineyardSceneImage(sceneImage)
% helperShowVineyardSceneImage Helper to show a top-down orthographic vineyard
%   scene image. The dimensional limits of the image are [-3.5 66.5] metres on
%   the X-axis and [-26.5 18.5] metres on the Y-axis. The vineyard contains
%   5 rows of vines. 
%
% Copyright 2024 The MathWorks, Inc.

imageSize = size(sceneImage);
xlims = [-3.5 66.5]; % in meters
ylims = [-26.50 18.50];  % in meters
sceneRef = imref2d(imageSize,xlims,ylims);
imshow(flip(sceneImage,1), sceneRef) % Display and flip the image to keep correct image orientation after the next step
set(gca,YDir="normal",Visible="on")  % Correct Y axis for right-handed world Cartesian coordinate system
xlabel("X (m)") 
ylabel("Y (m)") 
end