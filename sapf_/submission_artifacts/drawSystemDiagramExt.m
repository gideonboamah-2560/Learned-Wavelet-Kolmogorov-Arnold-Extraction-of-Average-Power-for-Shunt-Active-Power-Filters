function drawSystemDiagramExt(outPath, wIn, hIn, sc)
%DRAWSYSTEMDIAGRAM SAPF block diagram, drawn natively in Octave.
%   (multi-line box labels are drawn one text() per line -- the gnuplot
%   toolkit mishandles embedded newlines in a single text object)
if nargin < 2, wIn = 7.1; end
if nargin < 3, hIn = 4.0; end
if nargin < 4, sc = 1; end
graphics_toolkit('gnuplot');
figure('visible','off'); setFigSize(wIn,hIn);
axes('position',[0 0 1 1]); hold on; axis([0 12.4 0 7]); axis off;

boxFn = @(x,y,w,h,lines,fc) drawBoxExt(x,y,w,h,lines,fc,8*sc);
% control chain
boxFn(0.3,4.7,2.4,1.1,{'Clarke transform','p = v_\alpha i_\alpha + v_\beta i_\beta','q = v_\alpha i_\beta - v_\beta i_\alpha'},[1 0.96 0.84]);
boxFn(3.4,4.7,3.0,1.1,{'p-bar extractor','LPF | ADALINE | RBFNN |','WNN | GRU | Wav-KAN'},[0.97 0.84 0.85]);
boxFn(7.1,4.7,2.5,1.1,{'p_c = p - p-hat - \DeltaP','q_c = q','inverse transform'},[1 0.96 0.84]);
boxFn(10.2,4.7,2.0,1.1,{'Current loop','PI + v_{pcc} FF','(20 kHz)'},[0.89 0.95 0.87]);
boxFn(7.1,3.2,2.5,0.8,{'DC-link PI -> \DeltaP'},[1 0.96 0.84]);
drawArrow(2.7,5.25,3.4,5.25); text(2.95,5.5,'p','FontSize',9*sc);
drawArrow(6.4,5.25,7.1,5.25); text(6.55,5.5,'p-hat','FontSize',8*sc);
drawArrow(9.6,5.25,10.2,5.25); text(9.75,5.5,'i_c*','FontSize',8*sc);
drawArrow(8.35,4.0,8.35,4.7); text(8.5,4.3,'\DeltaP','FontSize',8*sc);
plot([1.5 1.5 8.35],[5.8 6.5 6.5],'k','LineWidth',1.2); drawArrow(8.35,6.5,8.35,5.8);
text(4.5,6.7,'p, q','FontSize',9*sc);
% power stage
boxFn(0.2,0.6,1.8,1.0,{'Grid','v_s, R_s, L_s'},[0.87 0.91 0.96]);
plot([2.0 5.2],[1.1 1.1],'k','LineWidth',2); text(3.0,1.35,'PCC','FontSize',9*sc,'FontWeight','bold');
boxFn(5.2,0.6,2.3,1.0,{'Nonlinear load','(6-pulse rectifier)'},[0.96 0.89 0.87]);
plot([3.0 3.0],[1.1 2.3],'k','LineWidth',2);
boxFn(2.4,2.3,1.2,0.8,{'L_f, R_f'},[0.87 0.91 0.96]);
boxFn(4.4,2.3,2.0,0.8,{'2-level VSI','(averaged)'},[0.89 0.95 0.87]);
boxFn(7.0,2.3,1.6,0.8,{'DC link','C, V_{dc}'},[0.89 0.95 0.87]);
plot([3.6 4.4],[2.7 2.7],'k','LineWidth',2); plot([6.4 7.0],[2.7 2.7],'k','LineWidth',2);
text(3.15,1.75,'i_c','FontSize',9*sc); text(4.5,0.35,'i_L','FontSize',9*sc);
text(0.2,2.7,'Shunt APF','FontSize',10*sc,'FontWeight','bold');
plot([11.2 11.2 5.4],[4.7 4.35 4.35],'k','LineWidth',1.2); plot([5.4 5.4],[4.35 3.2],'k','LineWidth',1.2); drawArrow(5.4,3.3,5.4,3.1);
text(10.9,4.5,'m_{abc} (PWM)','FontSize',8*sc,'HorizontalAlignment','right');
text(0.3,3.9,'measured: v_{pcc}, i_L, i_c, V_{dc}','FontSize',8*sc,'FontAngle','italic');
title('Shunt active power filter: power stage and reference-generation control','FontSize',10*sc);
print('-dpdf',outPath);
end
