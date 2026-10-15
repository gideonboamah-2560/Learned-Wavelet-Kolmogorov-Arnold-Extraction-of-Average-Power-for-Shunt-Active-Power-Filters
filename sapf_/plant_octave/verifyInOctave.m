% verifyInOctave.m
% End-to-end verification of the deployed controllers, entirely in Octave
% (no Simulink needed): runs the real simulink/ctrl_*.m controller
% functions -- the exact files meant for the Simulink MATLAB Function
% blocks -- inside the closed-loop plant, over the 4-scenario matrix, and
% reports THD / DC-link / settling-time metrics plus self-consistency
% checks: DC link regulates near 800 V, THD is in a plausible range, and
% the learned (short-window) extractors settle a load step faster than
% the classical low-pass filter.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(here);
addpath(fullfile(here, '../simulink'));
addpath(fullfile(here, '../simulink_automation'));

controllers = { 'pq_pi', @ctrl_pq_pi
                'fixed_wnn', @ctrl_fixed_wnn
                'gru', @ctrl_gru
                'wavkan', @ctrl_wavkan };

scenarios = struct( ...
    'steady',        struct('load', struct('I1_0',20.0), 'weak', false, 'T', 0.5), ...
    'load_step',     struct('load', struct('I1_0',15.0,'I1_1',25.0,'step_t',0.2), 'weak', false, 'T', 0.7), ...
    'supraharmonic', struct('load', struct('I1_0',20.0,'supra_on',true,'supra_f',5000.0,'supra_amp_frac',0.10,'supra_t0',0.2), 'weak', false, 'T', 0.5), ...
    'weak_grid',     struct('load', struct('I1_0',20.0), 'weak', true, 'T', 0.5) );

scenNames = fieldnames(scenarios);
results = {};
t0all = tic;

for ci = 1:size(controllers,1)
    cname = controllers{ci,1}; cfn = controllers{ci,2};
    fprintf('\n=== %s ===\n', cname);
    for si = 1:numel(scenNames)
        sname = scenNames{si};
        cfg = scenarios.(sname);
        t0 = tic;
        out = runClosedLoopMATLAB(cfn, cfg.load, cfg.T, cfg.weak);
        fs = 1/out.dt;
        cyc = round(fs/50);
        n10 = 10*cyc;
        nUse = min(n10, size(out.i_s,1));

        thdVals = zeros(1,3);
        for ph = 1:3
            [thdVals(ph), ~, ~] = computeTHD(out.i_s(end-nUse+1:end, ph), fs, 50, 25);
        end
        thd = mean(thdVals);

        vtail = out.vdc(end-nUse+1:end);
        vdcP2p = max(vtail) - min(vtail);
        vdcMean = mean(vtail);

        settleMs = NaN;
        if isfield(cfg.load, 'step_t')
            I1c = cfg.load.I1_1;
            % ideal fundamental-only source current for phase A
            tt = out.t;
            x = min(max((tt-cfg.load.step_t)/2e-3,0),1);
            I1t = cfg.load.I1_0 + (cfg.load.I1_1-cfg.load.I1_0).*(3*x.^2-2*x.^3);
            idealA = I1t .* cos(2*pi*50*tt);
            errA = out.i_s(:,1) - idealA;
            settleMs = settlingTimeMs(errA, tt, cfg.load.step_t, out.dt, I1c);
        end

        el = toc(t0);
        fprintf('  %-14s THD=%5.2f%%  Vdc_p2p=%5.2fV  Vdc_mean=%6.1fV  settle=%s  (%.1fs)\n', ...
            sname, thd, vdcP2p, vdcMean, ternary(isnan(settleMs), 'n/a', sprintf('%.1fms', settleMs)), el);

        results{end+1} = struct('controller', cname, 'scenario', sname, ...
            'thd_pct', thd, 'vdc_p2p_V', vdcP2p, 'vdc_mean_V', vdcMean, 'settle_ms', settleMs); %#ok<AGROW>
    end
end

fprintf('\nTotal verification time: %.1fs\n', toc(t0all));

%% ---- save + self-consistency checks ----
outDir = fullfile(here, '../results');
if ~exist(outDir,'dir'), mkdir(outDir); end
save(fullfile(outDir, 'octave_verification.mat'), 'results');

fid = fopen(fullfile(outDir, 'octave_verification.csv'), 'w');
fprintf(fid, 'controller,scenario,thd_pct,vdc_p2p_V,vdc_mean_V,settle_ms\n');
for i = 1:numel(results)
    r = results{i};
    fprintf(fid, '%s,%s,%.4f,%.4f,%.4f,%s\n', r.controller, r.scenario, ...
        r.thd_pct, r.vdc_p2p_V, r.vdc_mean_V, ternary(isnan(r.settle_ms), '', sprintf('%.4f', r.settle_ms)));
end
fclose(fid);
fprintf('Saved results/octave_verification.csv and .mat\n');

fprintf('\n=== Sanity checks ===\n');
sane = true;
for i = 1:numel(results)
    r = results{i};
    if r.thd_pct < 0.5 || r.thd_pct > 30
        fprintf('  FLAG: %s/%s THD=%.2f%% looks out of range\n', r.controller, r.scenario, r.thd_pct);
        sane = false;
    end
    if abs(r.vdc_mean_V - 800) > 50
        fprintf('  FLAG: %s/%s Vdc_mean=%.1fV far from 800V reference\n', r.controller, r.scenario, r.vdc_mean_V);
        sane = false;
    end
end
if sane
    fprintf('  All THD values in [0.5%%,30%%] and Vdc regulated within 50V of 800V reference. OK.\n');
end

% learned controllers should settle much faster than the classical pq_pi baseline
lookup = @(c,s) results{cellfun(@(r) strcmp(r.controller,c)&&strcmp(r.scenario,s), results)}.settle_ms;
pqSettle = lookup('pq_pi','load_step');
fprintf('\nLoad-step settling: pq_pi=%.1fms', pqSettle);
for c = {'fixed_wnn','gru','wavkan'}
    fprintf('  %s=%.1fms', c{1}, lookup(c{1},'load_step'));
end
fprintf('\n');
if pqSettle > lookup('wavkan','load_step')
    fprintf('  PASS: the learned extractor settles faster than the classical filter.\n');
else
    fprintf('  FAIL: the learned extractor is not faster than the classical filter -- investigate.\n');
end
