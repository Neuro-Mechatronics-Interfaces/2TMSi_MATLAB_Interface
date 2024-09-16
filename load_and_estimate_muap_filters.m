function [newIPTs, newPulses, info, t, P, W] = load_and_estimate_muap_filters(poly5_file, options)

arguments
    poly5_file
    options.ApplyTextileRemap (1,1) logical = true;
    options.NumPCs (1,1) double = 6;
    options.ExtensionFactor (1,1) double = 18;
    options.MinNumPulses (1,1) double = 20;
    options.DiscretizationFactor (1,1) double = 1;
    options.PlotResult (1,1) logical = true;
    options.InitialThreshold (1,1) double = 0.5;
end

data = TMSiSAGA.Poly5.read(poly5_file);
iUni = get_saga_channel_masks(data.channels);
uni = data.samples(iUni,:);
[b,a] = butter(3,100/(data.sample_rate/2),'high');

if options.ApplyTextileRemap
    uni_f = uni([17	16	15	14	13	9	5	1	22	21	20	19	18	10	6	2	27	26	25	24	23	11	7	3	32	31	30	29	28	12	8	4	33	34	35	36	37	53	57	61	38	39	40	41	42	54	58	62	43	44	45	46	47	55	59	63	48	49	50	51	52	56	60	64],:);
    uni_f(1:32,:) = ckc.preproc__hpf_exclude_interp_del2(filtfilt(b,a,uni_f(1:32,:)')','GridSize',[8 4]);
    uni_f(33:64,:) = ckc.preproc__hpf_exclude_interp_del2(filtfilt(b,a,uni_f(33:64,:)')','GridSize',[8 4]);
else
    uni_f = ckc.preproc__hpf_exclude_interp_del2(uni);
end

[IPTs, MUPulses, info, t, R_inv] = ckc.initialize_decomposition(...
    abs(uni_f), data.sample_rate, ...
    'ExtensionFactor', options.ExtensionFactor, ...
    'NumPCs', options.NumPCs, ...
    'IPTThreshold', options.InitialThreshold);
Ye = ckc.extend(abs(uni_f),options.ExtensionFactor);
W = nan(numel(MUPulses),size(R_inv,1));
iExclude = false(numel(MUPulses),1);
for ii = 1:numel(MUPulses)
    if numel(MUPulses{ii})<options.MinNumPulses
        iExclude(ii) = true;
        continue;
    end
    W(ii,:) = sum(Ye(:,MUPulses{ii}),2)';
end
W(iExclude,:) = [];
IPTs(iExclude,:) = [];
MUPulses(iExclude) = [];

newPulses = cell(size(MUPulses));
newIPTs = zeros(size(IPTs,1).*options.DiscretizationFactor, size(IPTs,2));
W = zeros(size(IPTs,1).*options.DiscretizationFactor, size(W,2));
P = 10*R_inv;
for ii = 1:numel(MUPulses)
    tmp = discretize(IPTs(ii,MUPulses{ii}),options.DiscretizationFactor);
    newPulses{ii} = cell(options.DiscretizationFactor,1);
    for ik = 1:options.DiscretizationFactor
        newPulses{ii}{ik} = MUPulses{ii}(tmp==ik);
        W(ik+(ii-1)*options.DiscretizationFactor,:) = sum(Ye(:,newPulses{ii}{ik}),2)';
        newIPTs(ik+(ii-1)*options.DiscretizationFactor,:) = W(ik+(ii-1)*options.DiscretizationFactor,:)*P*Ye;
    end
end
newPulses = vertcat(newPulses{:});

if options.PlotResult
    fig = figure('Color','w','Units','inches','Position',[1 2 8 5]);
    L = tiledlayout(fig,'flow');
    for ii = 1:size(newIPTs,1)
        ax = nexttile(L);
        plot(ax, t, newIPTs(ii,:), 'Color', ax.ColorOrder(rem(ii-1,7)+1,:));
        title(ax,sprintf("(New) IPT-%d",ii));
    end
    title(L,sprintf("IPTs | Extension Factor = %d",options.ExtensionFactor));
    linkaxes(findobj(L.Children,'type','axes'),'x');
end

end