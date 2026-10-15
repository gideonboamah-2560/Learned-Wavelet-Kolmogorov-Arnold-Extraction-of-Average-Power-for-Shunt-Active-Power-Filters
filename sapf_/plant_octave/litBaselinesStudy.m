% litBaselinesStudy.m
% Adds two real, literature-standard SAPF harmonic-extraction techniques
% to the Octave-native study: ADALINE (Fourier-basis LMS, the single most
% common real SAPF-ML approach) and RBFNN (radial-basis-function network,
% second most common). Run through the identical closed-loop plant and
% scenario matrix as multiSeedStudy.m for a fair, apples-to-apples
% comparison. See RELATED_WORK_OCTAVE.md for the literature citations.
%
% ADALINE is NOT pretrained -- it adapts online from a cold (zero-weight)
% start during the closed-loop run itself, exactly as deployed in the
% real papers. RBFNN is trained offline (closed-form ridge regression on
% random fixed centers), 4 seeds varying center selection.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(here);
addpath(fullfile(here, '../models'));
addpath(fullfile(here, '../scripts'));
addpath(fullfile(here, '../simulink_automation'));

WINDOW_N = 32;
ADA_HARM = [300 600 900 1200];
ADA_MU = 0.08;
ADA_FS = 10000.0;
ADA_DT = 1/ADA_FS;

SCEN = struct();
SCEN.steady        = struct('load', struct('I1_0',20.0), 'weak', false, 'T', 0.5);
SCEN.load_step     = struct('load', struct('I1_0',15.0,'I1_1',25.0,'step_t',0.2), 'weak', false, 'T', 0.7);
SCEN.supraharmonic = struct('load', struct('I1_0',20.0,'supra_on',true,'supra_f',5000.0,'supra_amp_frac',0.10,'supra_t0',0.2), 'weak', false, 'T', 0.5);
SCEN.weak_grid     = struct('load', struct('I1_0',20.0), 'weak', true, 'T', 0.5);
scenNames = fieldnames(SCEN);

rows = {};

%% ---- ADALINE (deterministic cold start, literature-typical mu) ----
fprintf('=== ADALINE (mu=%.2f, literature-typical) ===\n', ADA_MU);
for si = 1:numel(scenNames)
    sname = scenNames{si}; cfg = SCEN.(sname);
    extractFn = @(p,st) adalineStepGeneric(p, st, ADA_HARM, ADA_MU, ADA_DT);
    stateInit = zeros(1, 1+2*numel(ADA_HARM)+1);
    out = runClosedLoopGeneric(extractFn, stateInit, cfg.load, cfg.T, cfg.weak);
    m = scenarioMetrics(out, cfg);
    fprintf('  %-14s THD=%.2f%%  Vdc_p2p=%.2f  settle=%s  peakdev=%s\n', sname, m.thd_pct, m.vdc_p2p_V, ...
        num2str(m.settle_ms), num2str(m.vdc_peak_dev_V));
    rows(end+1,:) = {'adaline', 0, sname, m.thd_pct, m.vdc_p2p_V, m.vdc_mean_V, m.settle_ms, m.vdc_peak_dev_V, m.vdc_settle_ms}; %#ok<AGROW>
end

%% ---- ADALINE mu-sensitivity sweep (steady + load_step + supraharmonic) ----
fprintf('\n=== ADALINE mu-sensitivity sweep ===\n');
muList = [0.02, 0.08, 0.3, 0.5, 0.8];
muRows = {};
for mu = muList
    extractFnS = @(p,st) adalineStepGeneric(p, st, ADA_HARM, mu, ADA_DT);
    stateInit = zeros(1, 1+2*numel(ADA_HARM)+1);
    outS = runClosedLoopGeneric(extractFnS, stateInit, SCEN.steady.load, SCEN.steady.T, false);
    mS = scenarioMetrics(outS, SCEN.steady);

    outL = runClosedLoopGeneric(extractFnS, stateInit, SCEN.load_step.load, SCEN.load_step.T, false);
    mL = scenarioMetrics(outL, SCEN.load_step);

    outP = runClosedLoopGeneric(extractFnS, stateInit, SCEN.supraharmonic.load, SCEN.supraharmonic.T, false);
    mP = scenarioMetrics(outP, SCEN.supraharmonic);

    fprintf('  mu=%.2f  steady_THD=%.2f%%  step_settle=%.1fms  supra_THD=%.2f%%\n', mu, mS.thd_pct, mL.settle_ms, mP.thd_pct);
    muRows(end+1,:) = {mu, mS.thd_pct, mL.settle_ms, mP.thd_pct}; %#ok<AGROW>
end

%% ---- RBFNN (4 seeds, fixed random centers + ridge regression) ----
fprintf('\n=== RBFNN (4 seeds) ===\n');
[Xtr, ytr] = genDataset(70, 0.6, WINDOW_N, 6, 1);
[Xtr_n, ytr_n, ~] = normalizeWindow(Xtr, ytr);

for seed = 0:3
    net = rbfnnFit(Xtr_n, ytr_n, 12, seed, 1e-2);
    extractFn = @(p,st) rbfnnStepGeneric(p, st, net);
    for si = 1:numel(scenNames)
        sname = scenNames{si}; cfg = SCEN.(sname);
        out = runClosedLoopGeneric(extractFn, zeros(1,WINDOW_N), cfg.load, cfg.T, cfg.weak);
        m = scenarioMetrics(out, cfg);
        fprintf('  [seed %d] %-14s THD=%.2f%%  Vdc_p2p=%.2f  settle=%s\n', seed, sname, m.thd_pct, m.vdc_p2p_V, ...
            num2str(m.settle_ms));
        rows(end+1,:) = {'rbfnn', seed, sname, m.thd_pct, m.vdc_p2p_V, m.vdc_mean_V, m.settle_ms, m.vdc_peak_dev_V, m.vdc_settle_ms}; %#ok<AGROW>
    end
end

%% ---- save ----
outDir = fullfile(here, '../results');
if ~exist(outDir,'dir'), mkdir(outDir); end

fid = fopen(fullfile(outDir,'octave_litbaselines.csv'),'w');
fprintf(fid, 'controller,seed,scenario,thd_pct,vdc_p2p_V,vdc_mean_V,settle_ms,vdc_peak_dev_V,vdc_settle_ms\n');
for i = 1:size(rows,1)
    r = rows(i,:);
    fprintf(fid, '%s,%d,%s,%.6f,%.6f,%.6f,%s,%s,%s\n', r{1}, r{2}, r{3}, r{4}, r{5}, r{6}, ...
        numOrEmpty(r{7}), numOrEmpty(r{8}), numOrEmpty(r{9}));
end
fclose(fid);

fid = fopen(fullfile(outDir,'octave_adaline_musweep.csv'),'w');
fprintf(fid, 'mu,steady_thd_pct,step_settle_ms,supra_thd_pct\n');
for i = 1:size(muRows,1)
    fprintf(fid, '%.4f,%.6f,%.6f,%.6f\n', muRows{i,1}, muRows{i,2}, muRows{i,3}, muRows{i,4});
end
fclose(fid);

fprintf('\nSaved results/octave_litbaselines.csv and results/octave_adaline_musweep.csv\n');
