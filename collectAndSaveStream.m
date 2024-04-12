function collectAndSaveStream(src, ~)
msg = jsondecode(readline(src));
src.UserData.HasData.(msg.SAGA) = 1;
src.UserData.Samples.(msg.SAGA) = msg.data;
if ((src.UserData.HasData.A + src.UserData.HasData.B) == 2) && (src.UserData.Index < size(src.UserData.Data,2))
    src.UserData.Index = src.UserData.Index + 1;
    tmp = [src.UserData.Samples.A; src.UserData.Samples.B];
    tmp(isnan(tmp)) = 0;
    src.UserData.Data(:,src.UserData.Index) = tmp;
    src.UserData.HasData.A = 0;
    src.UserData.HasData.B = 0;
end
end