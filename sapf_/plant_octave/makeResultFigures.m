% makeResultFigures.m
% Generates the manuscript's result figures as VECTOR PDFs (sharp at any
% zoom), each designed at its final printed size. Inputs: results/*.csv and
% results/octave_digest.mat (run buildOctaveDigest.m first).
here = fileparts(mfilename('fullpath'));
addpath(here); addpath(fullfile(here,'../models')); addpath(fullfile(here,'../scripts'));
addpath(fullfile(here,'../simulink_automation'));
graphics_toolkit('gnuplot');
outDir = fullfile(here,'../latex_octave/plots');
load(fullfile(here,'../results/octave_digest.mat'));
FS = 8;   % axis/legend font size in points at final printed size

cmap = [0.55 0.55 0.55; 0.25 0.60 0.55; 0.78 0.63 0.13; 0.30 0.45 0.70; 0.85 0.55 0.30; 0.77 0.30 0.30];

%% ---- Fig A: THD by scenario, 4 controllers (full width) ----
C = {'pq_pi','fixed_wnn','gru','wavkan'}; S = {'steady','load_step','supraharmonic','weak_grid'};
names4 = {'LPF-25Hz','FixedWNN','GRU','Wav-KAN'}; scen_disp = {'steady','load step','supraharm.','weak grid'};
M = zeros(4,4); E = zeros(4,4);
for ci = 1:4, for si = 1:4
    d = D.(sprintf('%s_%s',C{ci},S{si})); M(ci,si) = d.thd_mean; E(ci,si) = d.thd_std;
end, end
c4 = cmap([1 4 5 6],:);
figure('visible','off'); setFigSize(7.1,2.9); hold on;
nb = 4; gw = 0.8;
for ci = 1:nb
    xc = (1:4) - gw/2 + (2*ci-1)*gw/(2*nb);
    hb(ci) = bar(xc, M(ci,:), gw/nb, 'FaceColor', c4(ci,:), 'EdgeColor','k','LineWidth',0.4);
    errorbar(xc, M(ci,:), E(ci,:), '~k.');
end
set(gca,'xtick',1:4,'xticklabel',scen_disp,'FontSize',FS); xlim([0.4 4.6]); ylim([0 6.8]);
ylabel('Source-current THD (%)','FontSize',FS); set(gca,'xgrid','off','ygrid','on');
hl = legend(hb, names4, 'location','northwest'); set(hl,'fontsize',FS-1);
print('-dpdf',fullfile(outDir,'fig_thd_octave.pdf')); close;

%% ---- Fig B: all six extractors, THD + settling (full width) ----
[hdr,data] = readCsvSimple(fullfile(here,'../results/octave_litbaselines.csv'));
col = @(n) data(:,strcmp(hdr,n));
c = col('controller'); s = col('scenario'); thdv = str2double(col('thd_pct')); setv = str2double(col('settle_ms'));
nm6 = {'LPF-25Hz','ADALINE','RBFNN','FixedWNN','GRU','Wav-KAN'};
sm = zeros(1,6); ss = zeros(1,6); tm = zeros(1,6); ts = zeros(1,6);
sm(1) = D.pq_pi_steady.thd_mean; ss(1) = D.pq_pi_steady.thd_std;
tm(1) = D.pq_pi_load_step.settle_mean; ts(1) = D.pq_pi_load_step.settle_std;
k = strcmp(c,'adaline')&strcmp(s,'steady');    sm(2) = mean(thdv(k)); ss(2) = std(thdv(k));
k = strcmp(c,'adaline')&strcmp(s,'load_step'); tm(2) = mean(setv(k)); ts(2) = std(setv(k));
k = strcmp(c,'rbfnn')&strcmp(s,'steady');      sm(3) = mean(thdv(k)); ss(3) = std(thdv(k));
k = strcmp(c,'rbfnn')&strcmp(s,'load_step');   tm(3) = mean(setv(k)); ts(3) = std(setv(k));
fn = {'fixed_wnn','gru','wavkan'};
for i = 1:3
    d = D.(sprintf('%s_steady',fn{i}));    sm(3+i) = d.thd_mean;    ss(3+i) = d.thd_std;
    d = D.(sprintf('%s_load_step',fn{i})); tm(3+i) = d.settle_mean; ts(3+i) = d.settle_std;
end
figure('visible','off'); setFigSize(7.1,2.8);
subplot('position',[0.07 0.25 0.40 0.70]);
drawBarPanel(sm, ss, cmap, nm6, 'Steady-state THD (%)', [0 5], FS);
subplot('position',[0.57 0.25 0.40 0.70]);
drawBarPanel(tm, ts, cmap, nm6, 'Load-step settling (ms)', [0 38], FS);
print('-dpdf',fullfile(outDir,'fig_all6_octave.pdf')); close;

%% ---- Fig C: DC-link voltage after the load step (single column) ----
W = 32;
[lb,la] = biquadDesign(25.0,10000.0);
load_cfg = struct('I1_0',15.0,'I1_1',25.0,'step_t',0.2);
oL = runClosedLoopGeneric(@(p,st) lpfStepGeneric(p,st,lb,la), [0,0], load_cfg, 0.35, false);
[Xtr,ytr] = genDataset(70,0.6,W,6,1); [Xva,yva] = genDataset(15,0.6,W,6,2);
[Xtr_n,ytr_n,~] = normalizeWindow(Xtr,ytr); [Xva_n,yva_n,~] = normalizeWindow(Xva,yva);
[wkP,wkOpt] = wavkanInit(W,8,0);
[wkP,wkOpt] = trainLoop(@(p,o,X,y) wavkanTrainStep(p,o,X,y), wkP,wkOpt,Xtr_n,ytr_n,60,256,'WavKAN', ...
                        @(p,X) wavkanForward(p,X), Xva_n, yva_n);
oW = runClosedLoopGeneric(@(p,st) wavkanStepGeneric(p,st,wkP), zeros(1,W), load_cfg, 0.35, false);
m = oL.t > 0.19 & oL.t < 0.28;
figure('visible','off'); setFigSize(3.45,2.5); hold on;
plot(oL.t(m)*1000, oL.vdc(m), 'Color',[0.45 0.45 0.45], 'LineWidth',1.6);
plot(oW.t(m)*1000, oW.vdc(m), 'Color',[0.77 0.30 0.30], 'LineWidth',1.6);
plot([200 200],[782 808],'k:','LineWidth',1.0);
set(gca,'FontSize',FS); xlabel('time (ms)','FontSize',FS); ylabel('V_{dc} (V)','FontSize',FS);
hl = legend('LPF-25Hz','Wav-KAN (seed 0)','location','southeast'); set(hl,'fontsize',FS-1);
xlim([190 280]); ylim([782 808]); set(gca,'xgrid','off','ygrid','on');
print('-dpdf',fullfile(outDir,'fig_vdc_step_octave.pdf')); close;
printf('result figures written to %s\n', outDir);

%% ---- architecture diagrams (vector PDF) ----
drawSystemDiagram(fullfile(outDir,'fig_system_octave.pdf'));
drawWavKANDiagram(fullfile(outDir,'fig_wavkan_octave.pdf'));
printf('diagrams written\n');
