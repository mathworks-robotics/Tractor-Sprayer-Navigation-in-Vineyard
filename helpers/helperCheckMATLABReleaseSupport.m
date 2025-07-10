function helperCheckMATLABReleaseSupport()
%helperCheckMATLABReleaseSupport Check if example is supported by the
%current MATLAB release instance
%   Checks if PAK files are supported for the current MATLAB release
%   session. Otherwise an appropriate error is thrown.

% Copyright 2025 The MathWorks, Inc.

currRelease = matlabRelease;
fprintf("Your current MATLAB release is -> %s\n",currRelease.Release);
supportedReleases = "R2024b";
if contains(supportedReleases,currRelease.Release)
    disp('PAK files are supported in this release!');
else
    error('PAK files are not supported for this release. Kindly switch to a supported release:\n%s', strjoin(supportedReleases, ', '));
end