function m = scenarioMetrics(out, cfg)
%SCENARIOMETRICS Compute THD, Vdc ripple, and (for load_step) transient
%   metrics from a runClosedLoopGeneric/runClosedLoopMATLAB output struct.
fs = 1/out.dt;
cyc = round(fs/50);
n10 = 10*cyc;
nUse = min(n10, size(out.i_s,1));

thdVals = zeros(1,3);
for ph = 1:3
    thdVals(ph) = computeTHD(out.i_s(end-nUse+1:end, ph), fs, 50, 25);
end
m.thd_pct = mean(thdVals);

vtail = out.vdc(end-nUse+1:end);
m.vdc_p2p_V = max(vtail) - min(vtail);
m.vdc_mean_V = mean(vtail);

m.settle_ms = NaN; m.vdc_peak_dev_V = NaN; m.vdc_settle_ms = NaN;
if isfield(cfg.load, 'step_t')
    tt = out.t; st = cfg.load.step_t;
    x = min(max((tt-st)/2e-3,0),1);
    I1t = cfg.load.I1_0 + (cfg.load.I1_1-cfg.load.I1_0).*(3*x.^2-2*x.^3);
    idealA = I1t .* cos(2*pi*50*tt);
    errA = out.i_s(:,1) - idealA;
    m.settle_ms = settlingTimeMs(errA, tt, st, out.dt, cfg.load.I1_1);

    after = tt >= st;
    m.vdc_peak_dev_V = max(abs(out.vdc(after) - 800.0));
    bad = find(after & abs(out.vdc-800.0) > 4.0);
    if isempty(bad)
        m.vdc_settle_ms = 0.0;
    else
        m.vdc_settle_ms = 1000*(tt(bad(end)) - st);
    end
end
end
