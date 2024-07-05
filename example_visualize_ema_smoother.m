%EXAMPLE_VISUALIZE_EMA_SMOOTHER
close all force;
clear;
clc;
% Define the alpha and beta parameters
alpha = 0.05:0.05:0.95; % Change this to your desired alpha value
fc = nan(size(alpha));

% Define the sample rate
Fs = 25; % Sample rate in samples per second

for ii = 1:numel(alpha)
    % Define the state-space matrices
    beta = 1 - alpha(ii);
    A = beta;
    B = alpha(ii);
    C = 1;
    D = 0;

    % Create the state-space system
    sys = idss(A, B, C, D, 'Ts', 1/Fs);

    % Convert state-space to transfer function
    [b, a] = ss2tf(A, B, C, D);

    % Analyze the frequency response
    n = 1000; % Number of frequency points
    w = linspace(0, pi, n); % Frequency vector (normalized from 0 to pi)
    [h, w] = freqz(b, a, w, Fs); % Compute the frequency response

    % Plot the frequency response in terms of sample rate
    fig = figure('Color','w','Name','EMA Filter Details');
    L = tiledlayout(fig,2,1);
    ax = nexttile(L);
    set(ax,'NextPlot','add','XLim',[0,Fs/2],'FontName','Tahoma','FontSize',14);
    h_mag = mag2db(abs(h));
    i_fc = find(h_mag-min(h_mag) < 0.62*(max(h_mag)-min(h_mag)),1,'first');
    f = (w./pi).*(Fs/2);
    fc(ii) = f(i_fc);
    plot(ax,f, h_mag,'LineWidth',1.5,'Color','k',...
        'MarkerIndices',i_fc,'Marker','v','MarkerFaceColor','b');
    text(ax,f(i_fc)+0.5,h_mag(i_fc)+0.1*(max(h_mag)-min(h_mag)),sprintf('f_c = %g Hz', round(f(i_fc),1)),'FontName','Tahoma','Color','b');
    title(ax,'Magnitude Response');
    xlabel(ax,'Frequency (Hz)');
    ylabel(ax,'|H(f)|');

    ax = nexttile(L);
    set(ax,'NextPlot','add','XLim',[0,Fs/2],'FontName','Tahoma','FontSize',14);
    plot(ax,f, angle(h),'LineWidth',1.5,'Color','k');
    title(ax,'Phase Response');
    xlabel(ax,'Frequency (Hz)');
    ylabel(ax,'Angle(H(f))');

    title(L,sprintf('EMA: \\beta=%g | f_s=%d',beta,Fs),'FontName','Tahoma','Color','k');
    utils.save_figure(fig,fullfile(pwd,'export','EMA'),sprintf('alpha=%g',alpha(ii)),'ExportAs',{'.png'},'SaveFigure',false);
end

%%
fig = figure('Color','w','Name','Fc and Lag','Position',[488   338   560   261]);
ax = axes(fig,'NextPlot','add','FontName','Tahoma','FontSize',14);
plot(ax,1-alpha,fc,'Color','b','Marker','o','MarkerFaceColor','k');
xlabel(ax,'Lag (\beta)','FontName','Tahoma','Color','k');
ylabel(ax,'f_c (Hz)','FontName','Tahoma','Color','k');
utils.save_figure(fig,fullfile(pwd,'export','EMA'),'summary','ExportAs',{'.png'},'SaveFigure',false);