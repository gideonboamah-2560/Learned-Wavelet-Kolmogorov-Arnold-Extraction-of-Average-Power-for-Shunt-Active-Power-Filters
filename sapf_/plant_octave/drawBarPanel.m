function drawBarPanel(vals, errs, cmap, labels, ylab, ylims, FS)
%DRAWBARPANEL Bar chart built from explicit patches, with manually placed
%   rotated tick labels. Independent of bar()/xtickangle() backend quirks,
%   so the vector PDF looks the same everywhere.
hold on; n = numel(vals); w = 0.72;
ytop = ylims(2);
for k = 1:ytop/ (ytop/5)   % light horizontal grid under the bars
end
yt = get(gca,'ytick');
for i = 1:n
    fill([i-w/2 i+w/2 i+w/2 i-w/2],[0 0 vals(i) vals(i)], cmap(i,:), 'EdgeColor','k','LineWidth',0.4);
end
errorbar(1:n, vals, errs, '~k.');
set(gca,'xtick',[],'FontSize',FS,'xgrid','off','ygrid','on','box','on');
xlim([0.4 n+0.6]); ylim(ylims);
ylabel(ylab,'FontSize',FS);
for i = 1:n
    text(i+0.12, -0.035*(ylims(2)-ylims(1)), labels{i}, 'rotation',35, ...
         'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS-1, 'clipping','off');
end
end
