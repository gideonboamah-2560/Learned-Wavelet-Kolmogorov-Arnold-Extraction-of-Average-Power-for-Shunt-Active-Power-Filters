% buildOctaveDigest.m
% Aggregates results/octave_multiseed.csv (+ extraction/cert/wc-sensitivity
% CSVs) into mean+-std per controller/scenario, plus significance tests,
% entirely in Octave.

here = fileparts(mfilename('fullpath'));
resDir = fullfile(here, '../results');

[hdr, data] = readCsvSimple(fullfile(resDir, 'octave_multiseed.csv'));
col = @(name) data(:, strcmp(hdr, name));
controllers = col('controller');
seeds = str2double(col('seed'));
scenarios = col('scenario');
thd = str2double(col('thd_pct'));
vdcP2p = str2double(col('vdc_p2p_V'));
vdcMean = str2double(col('vdc_mean_V'));
settle = str2double(col('settle_ms'));
vdcPeak = str2double(col('vdc_peak_dev_V'));
vdcSettle = str2double(col('vdc_settle_ms'));

ctrlNames = {'pq_pi','fixed_wnn','gru','wavkan'};
scenNames = {'steady','load_step','supraharmonic','weak_grid'};

D = struct();
for ci = 1:numel(ctrlNames)
    for si = 1:numel(scenNames)
        mask = strcmp(controllers, ctrlNames{ci}) & strcmp(scenarios, scenNames{si});
        key = sprintf('%s_%s', ctrlNames{ci}, scenNames{si});
        D.(key).n = sum(mask);
        D.(key).thd_mean = mean(thd(mask)); D.(key).thd_std = std(thd(mask));
        D.(key).vdcp2p_mean = mean(vdcP2p(mask)); D.(key).vdcp2p_std = std(vdcP2p(mask));
        D.(key).vdcmean_mean = mean(vdcMean(mask));
        st = settle(mask); st = st(~isnan(st));
        if isempty(st), D.(key).settle_mean = NaN; D.(key).settle_std = NaN;
        else, D.(key).settle_mean = mean(st); D.(key).settle_std = std(st); end
        vp = vdcPeak(mask); vp = vp(~isnan(vp));
        if isempty(vp), D.(key).vdcpeak_mean = NaN; D.(key).vdcpeak_std = NaN;
        else, D.(key).vdcpeak_mean = mean(vp); D.(key).vdcpeak_std = std(vp); end
        vs = vdcSettle(mask); vs = vs(~isnan(vs));
        if isempty(vs), D.(key).vdcsettle_mean = NaN; D.(key).vdcsettle_std = NaN;
        else, D.(key).vdcsettle_mean = mean(vs); D.(key).vdcsettle_std = std(vs); end
    end
end

% extraction accuracy summary
[hdr2, data2] = readCsvSimple(fullfile(resDir, 'octave_extraction.csv'));
rmseWnn = str2double(data2(:, strcmp(hdr2,'rmse_wnn_W')));
rmseGru = str2double(data2(:, strcmp(hdr2,'rmse_gru_W')));
rmseWk  = str2double(data2(:, strcmp(hdr2,'rmse_wavkan_W')));
D.extract.wnn_mean = mean(rmseWnn); D.extract.wnn_std = std(rmseWnn);
D.extract.gru_mean = mean(rmseGru); D.extract.gru_std = std(rmseGru);
D.extract.wavkan_mean = mean(rmseWk); D.extract.wavkan_std = std(rmseWk);

% boundedness certificate
[hdr3, data3] = readCsvSimple(fullfile(resDir, 'octave_cert.csv'));
By = str2double(data3(:, strcmp(hdr3,'B_y')));
Lip = str2double(data3(:, strcmp(hdr3,'Lipschitz')));
aMin = str2double(data3(:, strcmp(hdr3,'a_min')));
D.cert.By_min = min(By); D.cert.By_max = max(By);
D.cert.Lip_min = min(Lip); D.cert.Lip_max = max(Lip);
D.cert.aMin = min(aMin);

% wc sensitivity
[hdr4, data4] = readCsvSimple(fullfile(resDir, 'octave_wc_sensitivity.csv'));
wcHz = str2double(data4(:, strcmp(hdr4,'wc_hz')));
wcThd = str2double(data4(:, strcmp(hdr4,'thd_pct')));
D.wc.hz = wcHz; D.wc.thd = wcThd;

% ---- significance tests (Welch for learned-vs-learned, one-sample for vs. deterministic classical) ----
thdByKey = @(cname,sname) thd(strcmp(controllers,cname) & strcmp(scenarios,sname));
settleByKey = @(cname) settle(strcmp(controllers,cname) & strcmp(scenarios,'load_step') & ~isnan(settle));
vdcpeakByKey = @(cname) vdcPeak(strcmp(controllers,cname) & strcmp(scenarios,'load_step') & ~isnan(vdcPeak));

D.tests.steady_thd.wavkan_vs_wnn = welchTTest(thdByKey('wavkan','steady'), thdByKey('fixed_wnn','steady'));
D.tests.steady_thd.wavkan_vs_gru = welchTTest(thdByKey('wavkan','steady'), thdByKey('gru','steady'));
D.tests.steady_thd.wavkan_vs_pqpi = oneSampleTTest(thdByKey('wavkan','steady'), thdByKey('pq_pi','steady'));

D.tests.weak_thd.wavkan_vs_wnn = welchTTest(thdByKey('wavkan','weak_grid'), thdByKey('fixed_wnn','weak_grid'));
D.tests.weak_thd.wavkan_vs_gru = welchTTest(thdByKey('wavkan','weak_grid'), thdByKey('gru','weak_grid'));

D.tests.settle.wavkan_vs_wnn = welchTTest(settleByKey('wavkan'), settleByKey('fixed_wnn'));
D.tests.settle.wavkan_vs_gru = welchTTest(settleByKey('wavkan'), settleByKey('gru'));
D.tests.settle.wavkan_vs_pqpi = oneSampleTTest(settleByKey('wavkan'), settleByKey('pq_pi'));

D.tests.vdcpeak.wavkan_vs_wnn = welchTTest(vdcpeakByKey('wavkan'), vdcpeakByKey('fixed_wnn'));
D.tests.vdcpeak.wavkan_vs_gru = welchTTest(vdcpeakByKey('wavkan'), vdcpeakByKey('gru'));

D.tests.extract.wavkan_vs_wnn = welchTTest(rmseWk, rmseWnn);
D.tests.extract.wavkan_vs_gru = welchTTest(rmseWk, rmseGru);

save(fullfile(resDir, 'octave_digest.mat'), 'D');

% quick printout for a sanity glance
fprintf('=== Octave digest summary ===\n');
for ci = 1:numel(ctrlNames)
    key = sprintf('%s_steady', ctrlNames{ci});
    fprintf('  %-10s steady THD = %.2f +- %.2f %% (n=%d)\n', ctrlNames{ci}, D.(key).thd_mean, D.(key).thd_std, D.(key).n);
end
fprintf('Saved results/octave_digest.mat\n');
