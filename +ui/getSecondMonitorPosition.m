function pos = getSecondMonitorPosition(Units,Normalized_Size)
%GETSECONDMONITORPOSITION  Return 2nd (or 1st) monitor position coordinates
%
%  pos = ui.getSecondMonitorPosition();
%  pos = ui.getSecondMonitorPosition('Normalized'); 
%     --> Default (same as first call)
%
%  pos = ui.getSecondMonitorPosition('Pixels');     
%     --> Return `pos` in pixels
%
%  pos = ui.getSecondMonitorPosition(Normalized_Size);
%
%  pos = ui.getSecondMonitorPosition(__,Normalized_Size); 
%     --> default Normalized_Size is [0.1 0.1 0.8 0.8] 
%
%  pos : [x y w h] position vector

if nargin < 1
   Units = 'Normalized';
elseif isnumeric(Units)
   Normalized_Size = Units;
   Units = 'Normalized';
end

if nargin < 2
   Normalized_Size = [0.1 0.1 0.8 0.8];
end

rr = groot;
set(rr,'Units',Units);
if size(rr.MonitorPositions,1)>1
   switch lower(Units)
      case 'normalized'
         pos = getMonitorPosition(rr,2,Normalized_Size);
      case 'pixels'
         pos = getMonitorPosition(rr,2,Normalized_Size);
         pos = round(pos);
      otherwise
         error(...
            ['\nInvalid "Units" argument:\n' ...
            '%s (should be ''Normalized'' or ''Pixels'')\n'],Units);
   end
else
   switch lower(Units)
      case 'normalized'
         pos = getMonitorPosition(rr,1,Normalized_Size);
      case 'pixels'
         pos = getMonitorPosition(rr,1,Normalized_Size);
         pos = round(pos);
      otherwise
         error(...
            ['\nInvalid "Units" argument:\n' ...
            '%s (should be ''Normalized'' or ''Pixels'')\n'],Units);
   end
end
clear rr;

   function pos = getMonitorPosition(rootObj,monitorIndex,xywh)
      if nargin < 3
         xywh = [0.1 0.1 0.8 0.8]; % [X,Y,Width,Height]
      end
      pos = rootObj.MonitorPositions(monitorIndex,:);
      pos(1) = pos(1) + pos(3) * xywh(1);
      pos(3) = pos(3) * xywh(3);
      pos(2) = pos(2) + pos(4) * xywh(2);
      pos(4) = pos(4) * xywh(4);
   end

end