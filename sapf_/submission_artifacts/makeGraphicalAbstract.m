% makeGraphicalAbstract.m -- 13 x 5 cm graphical abstract (Elsevier recommendation),
% from the approved results (via octave_six_extractor_summary.csv, derived from the
% approved octave_multiseed.csv / octave_litbaselines.csv). Writes into ijepes_submission/.
run(fullfile(fileparts(mfilename('fullpath')),'setupExtPaths.m'));
graphics_toolkit('gnuplot');
[h,d] = readCsvSimple(fullfile(EXT_ROOT,'results','octave_six_extractor_summary.csv'));
col = @(n) d(:, strcmp(h,n));
ex = col('extractor'); sc = col('scenario'); me = col('metric'); mu = str2double(col('mean')); sd = str2double(col('std'));
names = {'pq_pi','adaline','rbfnn','fixed_wnn','gru','wavkan'};
lab   = {'LPF','ADALINE','RBFNN','FixedWNN','GRU','Wav-KAN'};
cmap  = [0.55 0.55 0.55; 0.25 0.60 0.55; 0.78 0.63 0.13; 0.30 0.45 0.70; 0.85 0.55 0.30; 0.77 0.30 0.30];
settle = zeros(1,6); settleE = zeros(1,6); thd = zeros(1,6); thdE = zeros(1,6);
for i = 1:6
    k = strcmp(ex,names{i}) & strcmp(sc,'load_step') & strcmp(me,'settle_ms'); settle(i) = mu(k); settleE(i) = sd(k);
    k = strcmp(ex,names{i}) & strcmp(sc,'steady')    & strcmp(me,'thd_pct');   thd(i)    = mu(k); thdE(i)    = sd(k);
end
W = 5.12; H = 1.97;  FS = 7;
figure('visible','off'); setFigSize(W,H);
subplot('position',[0.075 0.30 0.395 0.50]); drawBarPanel(settle, settleE, cmap, lab, 'Load-step settling (ms)', [0 40], FS);
subplot('position',[0.575 0.30 0.395 0.50]); drawBarPanel(thd, thdE, cmap, lab, 'Steady-state THD (%)', [0 5], FS);
axes('position',[0 0 1 1],'visible','off'); hold on; axis([0 1 0 1]);
text(0.5,0.935,'Six average-power extractors in one closed-loop SAPF model (4 seeds)','HorizontalAlignment','center','FontSize',FS+1.5,'FontWeight','bold');
text(0.5,0.865,'Transient speed follows the estimator family: window-based about 7 ms vs. recursive about 34 ms','HorizontalAlignment','center','FontSize',FS);
text(0.5,0.03,'Wav-KAN: lowest THD, but 1 of 4 seeds reached 7.02% at L_s = 2 mH (classical: 5.30%)','HorizontalAlignment','center','FontSize',FS,'Color',[0.6 0.1 0.1]);
outPdf = fullfile(EXT_ROOT,'Graphical_Abstract.pdf');
print('-dpdf', outPdf); printf('wrote %s\n', outPdf);
