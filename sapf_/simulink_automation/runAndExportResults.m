function runAndExportResults(modelName)
%RUNANDEXPORTRESULTS Run all 4 controllers, collect results, export CSV.
%
%   PREREQUISITES in your Simulink model (whatever base template you used):
%     1. A MATLAB Function block, anywhere, that will hold the controller
%        code. Note its full block path (e.g. 'sapf_model/SAPF_Controller').
%     2. Three "To Workspace" blocks logging (Save format = "Timeseries"):
%          logIsrc  <- source-side 3-phase current [iA iB iC]
%          logVdc   <- DC-link voltage (scalar)
%          logIload <- load-side 3-phase current [iA iB iC]  (optional,
%                      only needed if you want "before" THD too)
%     3. Simulation stop time long enough to reach steady state plus
%        whatever transient you're testing (e.g. 0.5 s).
%
%   This script does NOT touch your circuit topology or parameters -- it
%   only swaps which controller file is loaded into the MATLAB Function
%   block, runs the model, and post-processes the logged signals. Grid
%   weak/stiff, load-step timing, and supraharmonic burst on/off should
%   be set as your own model's parameters/masks; adjust the `scenarios`
%   struct array below to match whatever you exposed (e.g. via model
%   workspace variables set with set_param(modelName,'Ls_grid','2e-3')
%   or Simulink.Parameter objects in the base workspace).

here = fileparts(mfilename('fullpath'));
ctrlDir = fullfile(here, '../simulink');
controllerBlockPath = [modelName '/SAPF_Controller'];   % <-- EDIT to match your model
f0 = 50; fs_log = 10000; stopTime = 0.5;                % <-- EDIT if different

controllers = {
    'pq_pi',     fullfile(ctrlDir, 'ctrl_pq_pi.m')
    'fixed_wnn', fullfile(ctrlDir, 'ctrl_fixed_wnn.m')
    'gru',       fullfile(ctrlDir, 'ctrl_gru.m')
    'wavkan',    fullfile(ctrlDir, 'ctrl_wavkan.m')
};

% EDIT this list to match the scenarios you've actually wired into your
% model (grid impedance switch, load-step timer, supraharmonic burst
% enable). Each row just needs a label; how you realize it in your model
% (mask parameters, Simulink.Parameter in base workspace, etc.) is up to
% you -- set them in the loop below before calling sim().
scenarios = {'steady_harmonics', 'load_step', 'supraharmonic_burst', 'weak_grid'};

if ~bdIsLoaded(modelName)
    open_system(modelName);
end
set_param(modelName, 'StopTime', num2str(stopTime));

results = struct('controller', {}, 'scenario', {}, 'thd_pct', {}, ...
                  'vdc_mean', {}, 'vdc_ripple_pct', {});

for ci = 1:size(controllers, 1)
    cname = controllers{ci, 1};
    cfile = controllers{ci, 2};
    fprintf('\n=== Controller: %s ===\n', cname);
    insertControllerScript(modelName, controllerBlockPath, cfile);

    for si = 1:numel(scenarios)
        sname = scenarios{si};
        fprintf('  scenario: %-22s ... ', sname);

        % ---- EDIT: apply scenario-specific parameter overrides here ----
        % Example (uncomment / adapt to your actual block names -- these
        % differ between R2021a-style Specialized Power Systems models
        % and R2026a-style native Simscape Electrical models; see
        % SIMULINK_2026A_GUIDE.md if you're on R2026a):
        % switch sname
        %     case 'weak_grid'
        %         set_param([modelName '/<your source-impedance block>'], 'L', '2e-3');
        %     otherwise
        %         set_param([modelName '/<your source-impedance block>'], 'L', '0.1e-3');
        % end

        simOut = sim(modelName);

        % ---- pull logged signals (Timeseries "To Workspace" outputs) ----
        iSrc = simOut.get('logIsrc');   % Nx3 (or 3 separate ts) -- adapt if
        vdc  = simOut.get('logVdc');    % your logging differs
        tA = iSrc.Time; xA = iSrc.Data(:, 1);

        % use the last ~10 fundamental cycles for a steady-state-ish THD
        cyc = round(fs_log / f0);
        nUse = min(numel(xA), 10 * cyc);
        thd = computeTHD(xA(end - nUse + 1:end), fs_log, f0, 40);

        vdcData = vdc.Data;
        vdcMean = mean(vdcData(end - nUse + 1:end));
        vdcRipplePct = 100 * (max(vdcData(end - nUse + 1:end)) - ...
                               min(vdcData(end - nUse + 1:end))) / vdcMean;

        results(end + 1) = struct('controller', cname, 'scenario', sname, ...
            'thd_pct', thd, 'vdc_mean', vdcMean, 'vdc_ripple_pct', vdcRipplePct); %#ok<AGROW>
        fprintf('THD=%.2f%%  Vdc_ripple=%.2f%%\n', thd, vdcRipplePct);
    end
end

%% ---- export ----
outDir = fullfile(here, '../results');
if ~exist(outDir, 'dir'), mkdir(outDir); end

T = struct2table(results);
writetable(T, fullfile(outDir, 'simulink_results.csv'));
save(fullfile(outDir, 'simulink_results.mat'), 'results');

fprintf('\nSaved results/simulink_results.csv and .mat\n');
fprintf('Upload simulink_results.csv back into the chat and I will turn it into\n');
fprintf('the comparison plots/table for the paper.\n');
end
