# Wav-KAN Shunt Active Power Filter -- Project Index

**Octave/MATLAB is the ground-truth implementation.** Every result,
figure, and statistic in the manuscript is produced by the code in this
package, executed in GNU Octave. A separate Python package exists only as
an optional alternative (see the end of this file); nothing here depends
on it.

## Layout

```
models/, scripts/          Training pipeline: Wav-KAN, FixedWNN, GRU, classical LPF
                           (hand-derived backprop, Adam, best-checkpoint selection)
simulink/ctrl_*.m          Self-contained controllers with trained weights embedded,
                           ready to paste into Simulink MATLAB Function blocks
plant_octave/              Closed-loop plant + all studies (no Simulink needed):
    verifyInOctave.m         deployed ctrl_*.m files in closed loop, 4 scenarios
    multiSeedStudy.m         4 seeds x {FixedWNN, GRU, Wav-KAN} + classical, 4 scenarios
    litBaselinesStudy.m      ADALINE and RBFNN (published SAPF techniques), mu sweep
    buildOctaveDigest.m      mean/std + significance tests (Welch, one-sample)
    welchTTest.m, oneSampleTTest.m   from betainc -- no statistics toolbox
    makeResultFigures.m      ALL manuscript figures -> vector PDF at final printed size
    draw*.m                  architecture diagrams (called by makeResultFigures.m)
simulink_automation/       Helpers for when Simulink is available (R2021a / R2026a)
latex_octave/              THE MANUSCRIPT: manuscript_octave.tex / .pdf (IEEEtran)
results/                   All CSV/MAT outputs of the studies
VERIFICATION_REPORT.md     What was verified in Octave and how
RELATED_WORK_OCTAVE.md     ADALINE / RBFNN comparison and literature table
SIMULINK_2026A_GUIDE.md    Native Simscape Electrical build notes for R2026a
README.md                  Simulink build guide for R2021a (legacy SPS blocks)
```

## Reproduce everything (about 40 minutes, dominated by training)

```
octave plant_octave/multiSeedStudy.m      # 4-seed study       -> results/octave_*.csv
octave plant_octave/litBaselinesStudy.m   # ADALINE / RBFNN    -> results/octave_litbaselines.csv
octave plant_octave/buildOctaveDigest.m   # statistics         -> results/octave_digest.mat
octave plant_octave/verifyInOctave.m      # deployed-code check
octave plant_octave/makeResultFigures.m   # figures (vector PDF) -> latex_octave/plots/
cd latex_octave && pdflatex manuscript_octave.tex   # (x3 for references)
```

The manuscript is written directly in LaTeX; its numbers were taken from
the CSVs above and checked against them.

## Headline findings (all from the Octave studies)

1. **Transient speed splits by architecture family, not "neural vs.
   classical".** Classical LPF and ADALINE settle a load step in about
   34 ms; RBFNN, FixedWNN, GRU and Wav-KAN in about 7 ms. What the fast
   group shares is a short-window direct estimate; ADALINE is a recursive
   adaptive filter. ADALINE's slowness is a learning-rate choice
   (44.5 ms at mu=0.02 down to 6.8 ms at mu=0.8), with no THD penalty in
   this noise-free simulation -- a limitation of what the simulation can
   show about real hardware.
2. **Steady-state THD:** Wav-KAN 3.14 +/- 0.04 %, vs. FixedWNN 3.64, GRU
   3.88, RBFNN 4.19, classical/ADALINE 4.24. Wav-KAN vs. FixedWNN
   p = 0.008, vs. GRU p = 0.0002, vs. RBFNN p = 8e-6.
3. **Wav-KAN training instability:** one of four seeds gives 7.02 %
   weak-grid THD against 4.07-5.33 % for the others; FixedWNN and GRU show
   no comparable spread. Reported with the full per-seed breakdown.
4. **The current loop, not the extractor, dominates steady-state THD**
   (classical filter: 8.55 / 4.24 / 2.61 % at 0.7 / 1.5 / 2.5 kHz loop
   bandwidth) -- extractors must be compared with the loop held fixed.

## What to trust how much

| Claim | Confidence | Basis |
|---|---|---|
| Octave closed-loop results, statistics, manuscript numbers | High | Executed here; 4 seeds; tests implemented and sanity-checked |
| Deployed `ctrl_*.m` match the study harness | High | Max difference 3.8e-7 A / 2.5e-7 V |
| Simulink block layouts (R2021a / R2026a) | Low-Medium | Documentation-based; not executed (no Simulink available) |
| Hardware behaviour, noise robustness | Not tested | Simulation only; no hardware or HIL |

## Optional alternative

`sapf_python_project.zip` is an independent re-implementation of the same
study in Python, kept as an optional cross-check. It is not required,
not used as evidence in the manuscript, and its trained weights and
numbers differ from the Octave ones (training is seed-sensitive).
