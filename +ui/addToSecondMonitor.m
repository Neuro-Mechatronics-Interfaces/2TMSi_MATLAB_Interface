function pos = addToSecondMonitor(Units,NORMSIZE)
%ADDTOSECONDMONITOR  Return position coordinates for 2nd mon if possible
%
%  pos = ui.addToSecondMonitor();
%  pos = ui.addToSecondMonitor(NORMSIZE);
%  pos = ui.addToSecondMonitor('Normalized'); % Default
%  pos = ui.addToSecondMonitor('Pixels');     % Return `pos` in pixels
%  pos = ui.addToSecondMonitor(__,NORMSIZE); 
%     --> default NORMSIZE is [0.1 0.1 0.8 0.8] (for pixels or norm)


switch nargin
   case 0
      Units = 'Normalized';
      NORMSIZE = [0.1 0.1 0.8 0.8];
   case 1
      if isnumeric(Units)
         NORMSIZE = Units;
         Units = 'Normalized';
      else
         NORMSIZE = [0.1 0.1 0.8 0.8];
      end
   otherwise % Do nothing
      
end

rr = groot;
set(rr,'Units',Units);
if size(rr.MonitorPositions,1)>1
   switch lower(Units)
      case 'normalized'
         pos = getMonitorPosition(rr,2,NORMSIZE);
      case 'pixels'
         pos = getMonitorPosition(rr,2,NORMSIZE);
         pos = round(pos);
      otherwise
         error(...
            ['\nInvalid "Units" argument:\n' ...
            '%s (should be ''Normalized'' or ''Pixels'')\n'],Units);
   end
else
   switch lower(Units)
      case 'normalized'
         pos = getMonitorPosition(rr,1,NORMSIZE);
      case 'pixels'
         pos = getMonitorPosition(rr,1,NORMSIZE);
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