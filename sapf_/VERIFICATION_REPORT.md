# Octave Closed-Loop Verification Report

Octave/MATLAB is the ground-truth platform for this project. This report
documents what was verified, and how, entirely within it.

## What is verified

Everything here runs the **real, delivered** `simulink/ctrl_*.m` controller
files -- the exact code meant for the Simulink MATLAB Function blocks --
inside a closed-loop plant written in plain Octave (`plant_octave/`), so
no Simulink is needed to exercise them end to end. The plant is the
reduced-order SAPF model of the manuscript: the PCC algebraic constraint
$i_s+i_c=i_L$ is eliminated analytically to give one explicit ODE for the
APF current, with an averaged two-level VSI, a DC-link capacitor, and an
inner PI current loop (1.5 kHz) shared by every controller.

Run it yourself: `octave plant_octave/verifyInOctave.m` (about 100 s).

## 1. The two harnesses are numerically identical

`runClosedLoopMATLAB.m` calls the deployed `ctrl_wavkan.m` directly.
`runClosedLoopGeneric.m` (used for the multi-seed studies) reproduces the
same reference-generation algorithm from the shared `clarkeAndPower.m` /
`dcRegAndInvClarke.m`, so that 4 seeds x 3 models need not each be
exported to a `.m` file. Run on the same trained Wav-KAN weights over
0.05 s, the two differ by at most **3.8e-7 A** in source current and
**2.5e-7 V** in DC-link voltage -- floating-point round-off. So the
multi-seed results describe the same algorithm that ships to Simulink.

## 2. Deployed-controller results (seed 0; `results/octave_verification.csv`)

| Controller | Scenario | THD (%) | Vdc p-p (V) | Vdc mean (V) | Load-step settle (ms) |
|---|---|---|---|---|---|
| pq_pi | steady | 4.24 | 1.88 | 800.0 | - |
| pq_pi | load_step | 4.27 | 2.34 | 800.0 | 34.2 |
| pq_pi | supraharmonic | 4.76 | 1.94 | 800.0 | - |
| pq_pi | weak_grid | 5.30 | 2.02 | 800.0 | - |
| fixed_wnn | steady | 3.71 | 1.84 | 800.0 | - |
| fixed_wnn | load_step | 3.73 | 2.30 | 800.0 | 7.1 |
| fixed_wnn | supraharmonic | 4.25 | 1.91 | 800.0 | - |
| fixed_wnn | weak_grid | 4.70 | 1.98 | 800.0 | - |
| gru | steady | 3.81 | 1.84 | 800.0 | - |
| gru | load_step | 3.84 | 2.30 | 800.0 | 7.1 |
| gru | supraharmonic | 4.29 | 1.89 | 800.0 | - |
| gru | weak_grid | 4.82 | 1.98 | 800.0 | - |
| wavkan | steady | 3.23 | 1.81 | 800.0 | - |
| wavkan | load_step | 3.25 | 2.27 | 800.0 | 7.2 |
| wavkan | supraharmonic | 3.67 | 1.83 | 800.0 | - |
| wavkan | weak_grid | 4.29 | 1.94 | 800.0 | - |

Self-consistency checks built into the script, all passing: the DC link
regulates to 800.0 V in every run; every THD lies in a plausible range
(0.5-30 %); and the learned extractors settle a load step far faster
(7.1-7.2 ms) than the classical filter (34.2 ms).

This is one training seed. The statistically meaningful numbers -- four
seeds per learned model, Welch/one-sample tests, the per-seed Wav-KAN
instability -- are in `plant_octave/multiSeedStudy.m` and the manuscript.
Where the single-seed numbers above differ from the four-seed means in
the manuscript (e.g. Wav-KAN steady THD 3.23 % here vs. 3.14 +/- 0.04 %),
the manuscript's are the ones to quote.

## 3. Bugs this verification guards against

Three defects were found and fixed during development; the closed-loop
checks above would expose any of them if reintroduced:

1. **Ripple-frequency physics in the training data.** A 6-pulse rectifier's
   5th/7th/11th/13th current harmonics give power ripple at the
   6th/12th/18th/24th harmonic (300/600/900/1200 Hz at 50 Hz), not
   100-400 Hz. With the wrong spectrum the learned extractors do *worse*
   than the classical filter in closed loop despite better open-loop
   accuracy.
2. **Sign of the inverse p-q transform.** With $q=v_\alpha i_\beta-v_\beta
   i_\alpha$ the inverse is $i_\alpha=(v_\alpha p_c-v_\beta q_c)/|v|^2$,
   $i_\beta=(v_\beta p_c+v_\alpha q_c)/|v|^2$. Flipped signs compensate the
   wrong harmonic sequence and leave a large residual.
3. **DC-link PI gains.** Derived from the linearised energy-balance model
   ($\omega_n=2\pi\cdot8$ rad/s, $\zeta=0.7$): $K_p=112.6$ W/V,
   $K_i=4043$ W/(V$\cdot$s), rather than arbitrary values.

## 4. Further Octave-native results

- `RELATED_WORK_OCTAVE.md` -- ADALINE and RBFNN (published SAPF
  techniques) against the other extractors, plus the ADALINE learning-rate
  sweep.
- `latex_octave/manuscript_octave.pdf` -- the manuscript, hand-written in
  LaTeX, with every number and figure from the Octave studies.

## Optional alternative implementation

An independent re-implementation of the same study in another language
exists as an optional extra package. It is not used as evidence anywhere
in the manuscript or in this report. For completeness: it agrees with the
Octave results on the transient-speed finding (learned extractors about
7 ms, classical filters 21-41 ms) but not on the THD ranking among the
learned extractors, which is seed-sensitive -- one more reason the
manuscript reports four-seed statistics and the Wav-KAN instability
rather than any single run.
