function helperCheckMATLABReleaseSupport()
%helperCheckMATLABReleaseSupport Check if example is supported by the
%current MATLAB release instance
%   Checks if PAK files are supported for the current MATLAB release
%   session. Otherwise an appropriate error is thrown.

% Copyright 2025-26 The MathWorks, Inc.

currRelease = matlabRelease;
fprintf("Your current MATLAB release is -> %s\n",currRelease.Release);
supportedReleases = ["R2024b" "R2025a" "R2025b"];
if any(contains(supportedReleases,currRelease.Release))
    disp("PAK files are supported in this release!");
else
    error(...
        "PAK files are not supported for this release. Kindly switch to a supported release: %s.\n"+...
        "If you are in R2026b or later releases, refer to the following documented example instead:\n"+...
        '<a href="matlab:openExample(''offroad_autonomy/DriveAgriculturalTractorInVineyardUsingUnrealEngineExample'')">'+ ...
        'Drive Agricultural Tractor in Vineyard Using Unreal Engine Example'+ ...
        '</a>.',...
        strjoin(supportedReleases, ', '));
end