function handle_figure_timer_destruction(src, ~)
%HANDLE_FIGURE_TIMER_DESTRUCTION  To be used as DeleteFcn for figure or uifigure handle with 'Timer' object in UserData.

stop(src.UserData.timer);
try %#ok<*TRYNC> 
    delete(src.UserData.timer);
end
try
    delete(src.UserData.trigfig);
end
delete(src);

end