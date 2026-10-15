function drawWavKANDiagramExt(outPath, wIn, hIn, sc)
%DRAWWAVKANDIAGRAM Wav-KAN network schematic, drawn natively in Octave.
if nargin < 2, wIn = 6.4; end
if nargin < 3, hIn = 3.8; end
if nargin < 4, sc = 1; end
graphics_toolkit('gnuplot');
figure('visible','off'); setFigSize(wIn,hIn);
axes('position',[0 0 1 1]); hold on; axis([0 10 0 6]); axis off;

nIn = 6; nH = 4;
ysIn = linspace(0.9, 5.1, nIn);
ysH  = linspace(1.5, 4.5, nH);
xi = 1.2; xh = 5.0; xo = 8.6;

% edges (input -> hidden), thin; every third edge gets a wavelet glyph
for i = 1:nIn
    for k = 1:nH
        plot([xi xh],[ysIn(i) ysH(k)],'Color',[0.78 0.38 0.42],'LineWidth',0.6);
        if mod(i+k,3)==0
            xm = xi + 0.5*(xh-xi); ym = ysIn(i) + 0.5*(ysH(k)-ysIn(i));
            u = linspace(-3,3,40);
            s = 0.6 + 0.8*mod(i*k,3)/2; b = 0.2*mod(i+k,4)-0.3;
            uu = (u-b)/s;
            w = (1-uu.^2).*exp(-0.5*uu.^2);
            plot(xm + u*0.06, ym + 0.12*w, 'Color',[0.55 0.18 0.2],'LineWidth',1.1);
        end
    end
end
% hidden -> output
for k = 1:nH
    plot([xh xo],[ysH(k) 3.0],'Color',[0.8 0.3 0.33],'LineWidth',1.1);
end
% nodes
th = linspace(0,2*pi,40);
for i = 1:nIn
    fill(xi+0.13*cos(th), ysIn(i)+0.13*sin(th), 'w','EdgeColor','k');
end
for k = 1:nH
    fill(xh+0.2*cos(th), ysH(k)+0.2*sin(th), [0.97 0.84 0.85],'EdgeColor','k');
    text(xh, ysH(k), 'S','HorizontalAlignment','center','FontSize',9*sc);
end
fill(xo+0.25*cos(th), 3.0+0.25*sin(th), [0.97 0.84 0.85],'EdgeColor','k');
text(xo, 3.0, 'S','HorizontalAlignment','center','FontSize',9*sc);
text(xo+0.55, 3.0, 'y-hat','FontSize',10*sc);

text(xi, 5.65, 'window of p','HorizontalAlignment','center','FontSize',9*sc);
text(xi, 5.4,  '(32 samples, 6 drawn)','HorizontalAlignment','center','FontSize',8*sc);
text(xi, 0.45, 'x_{1} ... x_{32}','HorizontalAlignment','center','FontSize',9*sc);
text(xh, 5.2, 'hidden nodes (8 in model, 4 drawn)','HorizontalAlignment','center','FontSize',9*sc);
text(7.4, 5.6, 'every edge = its own learnable wavelet','HorizontalAlignment','center','FontSize',9*sc,'Color',[0.55 0.18 0.2]);
text(7.4, 5.35, '(scale a, shift b, gain c)','HorizontalAlignment','center','FontSize',9*sc,'Color',[0.55 0.18 0.2]);
text(9.0, 4.2, 'p-hat = s * y-hat','HorizontalAlignment','center','FontSize',9*sc);
text(9.0, 3.95,'s = mean|x| + 1','HorizontalAlignment','center','FontSize',8*sc);
text(5.6, 0.95, 'h_k = sum_i c1_{ik} * psi( (x_i - b1_{ik}) / a1_{ik} )','HorizontalAlignment','center','FontSize',8*sc);
text(5.6, 0.55, 'y-hat = sum_k c2_{k} * psi( (h_k - b2_{k}) / a2_{k} ) + beta','HorizontalAlignment','center','FontSize',8*sc);
text(5.6, 0.15, 'psi(u) = (1 - u^2) exp(-u^2/2)   (Mexican-hat wavelet)','HorizontalAlignment','center','FontSize',8*sc);
print('-dpdf',outPath);
end
