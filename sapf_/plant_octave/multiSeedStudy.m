% multiSeedStudy.m
% The Octave-native multi-seed closed-loop study. This is the evidence
% base for the Octave-authored manuscript (manuscript_octave.tex) --
% Everything (training, closed-loop plant, statistics) is implemented
% and executed in Octave/MATLAB; Octave is the ground-truth platform.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(here);
addpath(fullfile(here, '../models'));
addpath(fullfile(here, '../scripts'));
addpath(fullfile(here, '../simulink_automation'));  % computeTHD.m

SEEDS = 0:3;
WINDOW_N = 32;

SCEN = struct();
SCEN.steady        = struct('load', struct('I1_0',20.0), 'weak', false, 'T', 0.5);
SCEN.load_step     = struct('load', struct('I1_0',15.0,'I1_1',25.0,'step_t',0.2), 'weak', false, 'T', 0.7);
SCEN.supraharmonic = struct('load', struct('I1_0',20.0,'supra_on',true,'supra_f',5000.0,'supra_amp_frac',0.10,'supra_t0',0.2), 'weak', false, 'T', 0.5);
SCEN.weak_grid     = struct('load', struct('I1_0',20.0), 'weak', true, 'T', 0.5);
scenNames = fieldnames(SCEN);

%% ---- classical baseline (deterministic, run once) ----
fprintf('=== Classical LPF baseline ===\n');
[lpf_b, lpf_a] = biquadDesign(25.0, 10000.0);
rows = {};
for si = 1:numel(scenNames)
    sname = scenNames{si}; cfg = SCEN.(sname);
    extractFn = @(p,st) lpfStepGeneric(p, st, lpf_b, lpf_a);
    out = runClosedLoopGeneric(extractFn, [0,0], cfg.load, cfg.T, cfg.weak);
    m = scenarioMetrics(out, cfg);
    fprintf('  %-14s THD=%.2f%%  Vdc_p2p=%.2f  settle=%s\n', sname, m.thd_pct, m.vdc_p2p_V, ...
        num2str(m.settle_ms));
    rows(end+1,:) = {'pq_pi', 0, sname, m.thd_pct, m.vdc_p2p_V, m.vdc_mean_V, m.settle_ms, m.vdc_peak_dev_V, m.vdc_settle_ms}; %#ok<AGROW>
end

%% ---- current-loop bandwidth sensitivity (honesty check) ----
fprintf('\n=== Current-loop bandwidth sensitivity (steady scenario, pq_pi) ===\n');
wcSens = {};
for wc = [700, 1500, 2500]
    extractFn = @(p,st) lpfStepGeneric(p, st, lpf_b, lpf_a);
    out = runClosedLoopGeneric(extractFn, [0,0], SCEN.steady.load, SCEN.steady.T, false, wc);
    m = scenarioMetrics(out, SCEN.steady);
    fprintf('  wc=%5.0f Hz  THD=%.2f%%\n', wc, m.thd_pct);
    wcSens(end+1,:) = {wc, m.thd_pct}; %#ok<AGROW>
end

%% ---- learned controllers, 4 seeds each ----
extractSummary = {};
certRows = {};
for seed = SEEDS
    fprintf('\n=== Seed %d ===\n', seed);
    [Xtr, ytr] = genDataset(70, 0.6, WINDOW_N, 6, 1 + seed*10);
    [Xva, yva] = genDataset(15, 0.6, WINDOW_N, 6, 2 + seed*10);
    [Xte, yte] = genDataset(15, 0.6, WINDOW_N, 6, 3 + seed*10);
    [Xtr_n, ytr_n, ~]   = normalizeWindow(Xtr, ytr);
    [Xva_n, yva_n, ~]   = normalizeWindow(Xva, yva);
    [Xte_n, yte_n, ste] = normalizeWindow(Xte, yte);

    fprintf('  training FixedWNN...\n');
    [wnnP, wnnFixed, wnnOpt] = wnnInit(WINDOW_N, 12, seed);
    [wnnP, wnnOpt] = trainLoop(@(p,o,X,y) wnnTrainStep(p, wnnFixed, o, X, y), ...
        wnnP, wnnOpt, Xtr_n, ytr_n, 60, 256, sprintf('WNN-s%d',seed), ...
        @(p,X) wnnForward(p, wnnFixed, X), Xva_n, yva_n);
    yhat = wnnForward(wnnP, wnnFixed, Xte_n);
    rmseWnn = sqrt(mean(((yhat-yte_n).*ste).^2));

    fprintf('  training GRU...\n');
    [gruP, gruOpt, gruH] = gruInit(WINDOW_N, 8, seed);
    [gruP, gruOpt] = trainLoop(@(p,o,X,y) gruTrainStep(p, o, X, y, gruH), ...
        gruP, gruOpt, Xtr_n, ytr_n, 40, 256, sprintf('GRU-s%d',seed), ...
        @(p,X) gruForward(p, X, gruH), Xva_n, yva_n);
    yhat = gruForward(gruP, Xte_n, gruH);
    rmseGru = sqrt(mean(((yhat(:)-yte_n(:)).*ste(:)).^2));

    fprintf('  training WavKAN...\n');
    [wkP, wkOpt] = wavkanInit(WINDOW_N, 8, seed);
    [wkP, wkOpt] = trainLoop(@(p,o,X,y) wavkanTrainStep(p, o, X, y), ...
        wkP, wkOpt, Xtr_n, ytr_n, 60, 256, sprintf('WavKAN-s%d',seed), ...
        @(p,X) wavkanForward(p, X), Xva_n, yva_n);
    yhat = wavkanForward(wkP, Xte_n);
    rmseWk = sqrt(mean(((yhat-yte_n).*ste).^2));

    fprintf('  open-loop test RMSE: WNN=%.1fW  GRU=%.1fW  WavKAN=%.1fW\n', rmseWnn, rmseGru, rmseWk);
    extractSummary(end+1,:) = {seed, rmseWnn, rmseGru, rmseWk}; %#ok<AGROW>

    % Wav-KAN boundedness certificate (Proposition 1) from THIS seed's trained weights
    u = linspace(-12,12,20001);
    psi = (1-u.^2).*exp(-0.5*u.^2); psiMax = max(abs(psi));
    dpsi = (u.^3-3*u).*exp(-0.5*u.^2); dpsiMax = max(abs(dpsi));
    By = sum(abs(wkP.c2)) + abs(wkP.bias);
    L1 = sum(abs(wkP.c1)./wkP.a1, 1) * dpsiMax;  % per-hidden-node, 1xK
    Lip = sum((abs(wkP.c2)'./wkP.a2') .* dpsiMax .* L1);
    aMin = min([wkP.a1(:); wkP.a2(:)]);
    certRows(end+1,:) = {seed, By, Lip, aMin}; %#ok<AGROW>

    models = struct('fixed_wnn', struct('step', @(p,st) wnnStepGeneric(p,st,wnnP,wnnFixed)), ...
                     'gru',       struct('step', @(p,st) gruStepGeneric(p,st,gruP,gruH)), ...
                     'wavkan',    struct('step', @(p,st) wavkanStepGeneric(p,st,wkP)));
    mnames = fieldnames(models);
    for mi = 1:numel(mnames)
        cname = mnames{mi};
        for si = 1:numel(scenNames)
            sname = scenNames{si}; cfg = SCEN.(sname);
            out = runClosedLoopGeneric(models.(cname).step, zeros(1,WINDOW_N), cfg.load, cfg.T, cfg.weak);
            m = scenarioMetrics(out, cfg);
            fprintf('  [seed %d] %-10s %-14s THD=%.2f%%  Vdc_p2p=%.2f  settle=%s\n', ...
                seed, cname, sname, m.thd_pct, m.vdc_p2p_V, num2str(m.settle_ms));
            rows(end+1,:) = {cname, seed, sname, m.thd_pct, m.vdc_p2p_V, m.vdc_mean_V, ...
                m.settle_ms, m.vdc_peak_dev_V, m.vdc_settle_ms}; %#ok<AGROW>
        end
    end
end

%% ---- save everything ----
outDir = fullfile(here, '../results');
if ~exist(outDir,'dir'), mkdir(outDir); end

fid = fopen(fullfile(outDir,'octave_multiseed.csv'),'w');
fprintf(fid, 'controller,seed,scenario,thd_pct,vdc_p2p_V,vdc_mean_V,settle_ms,vdc_peak_dev_V,vdc_settle_ms\n');
for i = 1:size(rows,1)
    r = rows(i,:);
    fprintf(fid, '%s,%d,%s,%.6f,%.6f,%.6f,%s,%s,%s\n', r{1}, r{2}, r{3}, r{4}, r{5}, r{6}, ...
        numOrEmpty(r{7}), numOrEmpty(r{8}), numOrEmpty(r{9}));
end
fclose(fid);

fid = fopen(fullfile(outDir,'octave_extraction.csv'),'w');
fprintf(fid, 'seed,rmse_wnn_W,rmse_gru_W,rmse_wavkan_W\n');
for i = 1:size(extractSummary,1)
    fprintf(fid, '%d,%.4f,%.4f,%.4f\n', extractSummary{i,1}, extractSummary{i,2}, extractSummary{i,3}, extractSummary{i,4});
end
fclose(fid);

fid = fopen(fullfile(outDir,'octave_cert.csv'),'w');
fprintf(fid, 'seed,B_y,Lipschitz,a_min\n');
for i = 1:size(certRows,1)
    fprintf(fid, '%d,%.4f,%.4f,%.4f\n', certRows{i,1}, certRows{i,2}, certRows{i,3}, certRows{i,4});
end
fclose(fid);

fid = fopen(fullfile(outDir,'octave_wc_sensitivity.csv'),'w');
fprintf(fid, 'wc_hz,thd_pct\n');
for i = 1:size(wcSens,1)
    fprintf(fid, '%d,%.4f\n', wcSens{i,1}, wcSens{i,2});
end
fclose(fid);

fprintf('\nSaved results/octave_multiseed.csv, octave_extraction.csv, octave_cert.csv, octave_wc_sensitivity.csv\n');
