function updatePose(squiggles, poseString)
%UPDATEPOSE  Update the relevant squiggles sub-field
%
% Example:
%   updatePose(param.gui.squiggles, "Neutral");
%   -> Sets subtitle text to "Pose: Neutral"

if ~startsWith(poseString,"Pose: ")
    poseString = sprintf("Pose: %s", poseString);
end
squiggles.h.Pose.String = poseString;
end