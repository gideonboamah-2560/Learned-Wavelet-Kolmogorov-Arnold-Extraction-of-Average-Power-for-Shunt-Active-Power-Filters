% trainControllers.m
% Trains FixedWNN, GRULite and WavKAN on the synthetic p_bar-extraction
% task, and benchmarks all three plus the classical analytic LPF on a
% held-out test set. Run this once before runExperiments.m.

clear; clc;
addpath('../models');
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '../models'));

windowN = 32; nHiddenWNN = 12; nHiddenWavKAN = 8; nHiddenGRU = 8;

fprintf('Generating datasets ...\n');
[Xtr, ytr] = genDataset(70, 0.6, windowN, 6, 1);
[Xva, yva] = genDataset(15, 0.6, windowN, 6, 2);
[Xte, yte] = genDataset(15, 0.6, windowN, 6, 3);
fprintf('train=%d  val=%d  test=%d\n', size(Xtr,1), size(Xva,1), size(Xte,1));

[Xtr_n, ytr_n, ~]   = normalizeWindow(Xtr, ytr);
[Xva_n, yva_n, sva] = normalizeWindow(Xva, yva);
[Xte_n, yte_n, ste] = normalizeWindow(Xte, yte);

%% --- FixedWNN ---
fprintf('\n--- Training FixedWNN ---\n');
[wnnP, wnnFixed, wnnOpt] = wnnInit(windowN, nHiddenWNN, 0);
[wnnP, wnnOpt] = trainLoop(@(p,o,X,y) wnnTrainStep(p, wnnFixed, o, X, y), ...
                            wnnP, wnnOpt, Xtr_n, ytr_n, 60, 256, 'WNN', ...
                            @(p,X) wnnForward(p, wnnFixed, X), Xva_n, yva_n);

%% --- GRULite ---
fprintf('\n--- Training GRULite ---\n');
[gruP, gruOpt, gruH] = gruInit(windowN, nHiddenGRU, 1);
[gruP, gruOpt] = trainLoop(@(p,o,X,y) gruTrainStep(p, o, X, y, gruH), ...
                            gruP, gruOpt, Xtr_n, ytr_n, 40, 256, 'GRU', ...
                            @(p,X) gruForward(p, X, gruH), Xva_n, yva_n);

%% --- WavKAN (proposed) ---
fprintf('\n--- Training WavKAN ---\n');
[wkP, wkOpt] = wavkanInit(windowN, nHiddenWavKAN, 2);
[wkP, wkOpt] = trainLoop(@(p,o,X,y) wavkanTrainStep(p, o, X, y), ...
                          wkP, wkOpt, Xtr_n, ytr_n, 60, 256, 'WavKAN', ...
                          @(p,X) wavkanForward(p, X), Xva_n, yva_n);

%% --- Analytic LPF (no training) ---
fs = 1/ (1/10000);
[lpf_b, lpf_a] = biquadDesign(25, 10000);

%% --- Evaluate ---
fprintf('\n=== Validation set (Watts) ===\n');
evalModel('AnalyticLPF', @(X) lpfPredictWindow(X, lpf_b, lpf_a, 50), Xva, yva, ones(size(yva)));
evalModel('FixedWNN',    @(X) wnnForward(wnnP, wnnFixed, X),          Xva_n, yva_n, sva);
evalModel('GRULite',     @(X) gruForward(gruP, X, gruH),              Xva_n, yva_n, sva);
evalModel('WavKAN',      @(X) wavkanForward(wkP, X),                  Xva_n, yva_n, sva);

fprintf('\n=== Held-out TEST set (Watts) ===\n');
evalModel('AnalyticLPF', @(X) lpfPredictWindow(X, lpf_b, lpf_a, 50), Xte, yte, ones(size(yte)));
evalModel('FixedWNN',    @(X) wnnForward(wnnP, wnnFixed, X),          Xte_n, yte_n, ste);
evalModel('GRULite',     @(X) gruForward(gruP, X, gruH),              Xte_n, yte_n, ste);
evalModel('WavKAN',      @(X) wavkanForward(wkP, X),                  Xte_n, yte_n, ste);

save(fullfile(here, '../results/trainedControllers.mat'), ...
     'wnnP', 'wnnFixed', 'gruP', 'gruH', 'wkP', 'lpf_b', 'lpf_a', 'windowN');
fprintf('\nSaved trained parameters -> results/trainedControllers.mat\n');
