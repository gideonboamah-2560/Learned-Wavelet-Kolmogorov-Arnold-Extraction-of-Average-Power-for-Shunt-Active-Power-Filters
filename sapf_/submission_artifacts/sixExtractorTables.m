% sixExtractorTables.m
% Unified summary of all six extractors from the two result CSVs
% (octave_multiseed.csv: LPF/FixedWNN/GRU/Wav-KAN; octave_litbaselines.csv:
% ADALINE/RBFNN). Prints mean +- std per scenario/metric and writes
% results/octave_six_extractor_summary.csv. Every number in the journal
% manuscript's Tables 3-4 comes from here.
run(fullfile(fileparts(mfilename('fullpath')),'setupExtPaths.m')); here = EXT_ROOT;
[h1,d1] = readCsvSimple(fullfile(FROZEN_ROOT,'results','octave_multiseed.csv'));
[h2,d2] = readCsvSimple(fullfile(FROZEN_ROOT,'results','octave_litbaselines.csv'));
D = [d1; d2]; H = h1;
col = @(n) D(:, strcmp(H, n));
ctrl = col('controller'); scen = col('scenario');
num = @(n) str2double(col(n));
thd = num('thd_pct'); st = num('settle_ms'); vp = num('vdc_peak_dev_V'); vs = num('vdc_settle_ms');
names = {'pq_pi','adaline','rbfnn','fixed_wnn','gru','wavkan'};
label = {'LPF-25Hz','ADALINE','RBFNN','FixedWNN','GRU','Wav-KAN'};
scens = {'steady','load_step','supraharmonic','weak_grid'};
ms = @(x) [mean(x(~isnan(x))), std(x(~isnan(x))), sum(~isnan(x))];
fid = fopen(fullfile(EXT_ROOT,'results','octave_six_extractor_summary.csv'),'w');
fprintf(fid,'extractor,scenario,metric,mean,std,n\n');
printf('\n== THD (%%) by scenario ==\n');
for i = 1:6
    printf('%-9s', label{i});
    for s = 1:4
        k = strcmp(ctrl,names{i}) & strcmp(scen,scens{s});
        r = ms(thd(k));
        if r(3) > 1, printf(' | %.2f +- %.2f', r(1), r(2)); else, printf(' | %.2f          ', r(1)); end
        fprintf(fid,'%s,%s,thd_pct,%.5f,%.5f,%d\n',names{i},scens{s},r(1),r(2),r(3));
    end
    printf('\n');
end
printf('\n== load step: settle (ms) | peak Vdc dev (V) | Vdc settle (ms) ==\n');
mets = {st,vp,vs}; mn = {'settle_ms','vdc_peak_dev_V','vdc_settle_ms'};
for i = 1:6
    printf('%-9s', label{i});
    for m = 1:3
        k = strcmp(ctrl,names{i}) & strcmp(scen,'load_step');
        r = ms(mets{m}(k));
        if r(3) > 1, printf(' | %.2f +- %.2f', r(1), r(2)); else, printf(' | %.2f          ', r(1)); end
        fprintf(fid,'%s,load_step,%s,%.5f,%.5f,%d\n',names{i},mn{m},r(1),r(2),r(3));
    end
    printf('\n');
end
fclose(fid);
