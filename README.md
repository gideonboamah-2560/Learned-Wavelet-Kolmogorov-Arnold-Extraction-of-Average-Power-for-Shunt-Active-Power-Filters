# Research data and code -- reproduction guide

Companion to "Average-power extraction for shunt active power filters: a controlled
closed-loop comparison of classical, adaptive and learned extractors, including a
wavelet Kolmogorov--Arnold network". Everything is GNU Octave 8.4.0 code in
MATLAB-compatible syntax; **no toolboxes are required**. Deposit this folder (e.g. on
Mendeley Data, Zenodo or Figshare), then put the DOI in the manuscript's *Data
availability* statement and in the cover letter.

## Layout
- `code/sapf_matlab/` -- the project exactly as used for the study (training, closed-loop plant, all study drivers, statistics, deployable `simulink/ctrl_*.m`, all result files in `results/`).
- `code/submission_artifacts/` -- small scripts that produced the journal figures, the unified six-extractor tables, the graphical abstract and the harness-consistency check. They read `code/sapf_matlab/` and never modify it. Keep the two folders side by side.

## Which script produces which manuscript item
| Manuscript item | Script | Output |
|---|---|---|
| Sec. 6.1 open-loop RMSE; Sec. 3 boundedness numbers; Sec. 2.3 current-loop sensitivity; 4-seed study of FixedWNN / GRU / Wav-KAN and the classical filter | `sapf_matlab/plant_octave/multiSeedStudy.m` | `results/octave_extraction.csv`, `octave_cert.csv`, `octave_wc_sensitivity.csv`, `octave_multiseed.csv` |
| ADALINE, RBFNN (published SAPF techniques); Table 3 (ADALINE learning-rate sweep) | `sapf_matlab/plant_octave/litBaselinesStudy.m` | `results/octave_litbaselines.csv`, `octave_adaline_musweep.csv` |
| All p-values (Welch, one-sample; implemented from `betainc`) | `sapf_matlab/plant_octave/buildOctaveDigest.m` | `results/octave_digest.mat` |
| Tables 2 and 4 (unified six-extractor summaries), Table 5 (per-seed values) | `submission_artifacts/sixExtractorTables.m` (Table 5 is read directly from the two CSVs above) | `submission_artifacts/results/octave_six_extractor_summary.csv` |
| Figures 1-5 | `submission_artifacts/makeJournalFigures.m` (run with `FIG_LAYOUT='elsevier'`; retrains one Wav-KAN for Fig. 3) | `submission_artifacts/figures/*.pdf` |
| Graphical abstract | `submission_artifacts/makeGraphicalAbstract.m` | `Graphical_Abstract.pdf` |
| Study harness vs deployed controller (3.8e-7 A, 2.5e-7 V) | `submission_artifacts/checkHarnessConsistency.m` | printed |
| Deployed controllers in closed loop | `sapf_matlab/plant_octave/verifyInOctave.m` | `results/octave_verification.csv` |

## Reproducing (from `code/`)
```
octave sapf_matlab/plant_octave/multiSeedStudy.m      % ~30 min, dominated by training
octave sapf_matlab/plant_octave/litBaselinesStudy.m   % a few minutes
octave sapf_matlab/plant_octave/buildOctaveDigest.m
octave submission_artifacts/sixExtractorTables.m
octave --eval "FIG_LAYOUT='elsevier'; run('submission_artifacts/makeJournalFigures.m')"
```
Training is deterministic for a given Octave version (re-running reproduced earlier per-seed values exactly). Other Octave versions or random-number generators may give different per-seed numbers, including which seed misbehaves; the qualitative conclusions should be robust, individual seed values need not be.

## Known limitations of the data
Simulation only; synthetic training data; four seeds per learned model.
