# Comparison with Published ML/Neural-Network Approaches for SAPF (Octave-Native)

This extends the Octave-native closed-loop study (`VERIFICATION_REPORT.md`,
`latex_octave/manuscript_octave.tex`) with real, published machine-learning
techniques used for SAPF reference-current generation, run through the
identical closed-loop plant and scenario matrix as the rest of this
project -- entirely in Octave/MATLAB, no Python anywhere in this phase.

## 1. What's actually published (literature survey)

| Approach | Representative paper(s) | What it does |
|---|---|---|
| **ADALINE** (adaptive linear neuron, LMS) | Janpong, Areerak & Areerak, *"Harmonic Detection for Shunt Active Power Filter Using ADALINE Neural Network,"* Energies 14(14):4351, 2021, doi:10.3390/en14144351 (HIL-validated on a TMS320F28335 DSP). Hasan et al., *"Online harmonic extraction and synchronization algorithm... for unified power quality conditioner,"* Energy Reports 8:962-971, 2022. Also a well-cited *"Optimal current harmonic extractor based on unified ADALINEs for shunt active power filters,"* IEEE Trans. Power Electronics, using PSO to tune the LMS learning rate. | A single linear neuron with a Fourier/harmonic basis, weights adapted online via least-mean-squares (Widrow-Hoff). By far the most common real ML technique for this exact task. |
| **RBFNN** (radial basis function network) | Tah, Panda & Panigrahi, *"Shunt Active Filter Based on Radial Basis Function Neural Network and p-q Power Theory,"* Int. J. Power Electronics and Drive Systems 8(2):667-676, 2017, doi:10.11591/ijpeds.v8.i2.pp667-676 ("RBFNN-PQ"). Also used for sliding-mode current-tracking control (a different task) in *"Adaptive Neural Sliding Mode Control of Active Power Filter,"* J. Applied Mathematics, 2013, doi:10.1155/2013/341831. | Fixed or randomly-selected Gaussian-kernel centers, linear output layer, often trained by closed-form methods rather than backpropagation. Second most common real technique for this task. |
| **ANFIS** (adaptive neuro-fuzzy) | Multiple papers combine fuzzy rule bases with gradient-based tuning, typically for DC-link PI gain scheduling or peak-current-reference generation rather than as a drop-in $\bar p$-extractor. | Not implemented here -- its fuzzy-rule structure doesn't map onto the windowed-extractor interface used throughout this study without a substantially different architecture. Included for completeness, not compared quantitatively. |
| MLP | Krismanto, Lomi & Hartungi, *"Artificial neural network-based harmonics extraction algorithm for shunt active power filter control,"* Int. J. Power Electronics 4(3), 2012 -- compares MLP vs RBF directly; reports RBF converges faster but MLP generalizes across a wider harmonic range. | Not separately implemented; an MLP without the wavelet/KAN edge structure is architecturally already covered by the FixedWNN family in this study. |

**What's verified vs. what's cited:** the citations above were checked against their abstracts/metadata (titles, authors, venues, DOIs where available) during this work, but the papers' own reported numbers were not reproduced -- different papers use different loads, hardware, and test conditions, so quoting their THD/settling numbers next to ours would compare different experiments, not run a fair comparison. That is exactly why Section 2 below implements ADALINE and RBFNN ourselves, in our own Octave plant, so the comparison is actually fair.

## 2. Fair, executed comparison (same Octave plant, same scenarios, same metrics)

Implemented in `plant_octave/adalineStepGeneric.m` and
`plant_octave/rbfnnFit.m` / `rbfnnStepGeneric.m` / `rbfnnBasis.m`, run
through `plant_octave/litBaselinesStudy.m` using the identical closed-loop
plant (`runClosedLoopGeneric.m`) and scenario matrix as
`multiSeedStudy.m`.

**ADALINE**: Fourier-basis LMS, exactly as in the cited papers -- models
$p(t)$ as DC + known ripple harmonics (300/600/900/1200 Hz), weights
adapt via Widrow-Hoff LMS. Unlike every other learned extractor in this
study, **ADALINE is not pretrained** -- consistent with how it's actually
deployed in the literature, it starts from zero weights and adapts online
during the closed-loop run itself.

**RBFNN**: random-subset-of-training-windows centers (Broomhead-Lowe),
fixed width (nearest-neighbor heuristic), linear output layer trained by
closed-form ridge regression (`rbfnnFit.m`, a single `A\b` solve, no
gradient descent, no epochs) -- matching how real RBFN-SAPF papers train
them. 4 seeds (center-selection randomness).

### Results (`results/octave_litbaselines.csv`)

| Controller | Steady THD (%) | Load-step settle (ms) | Peak $V_{dc}$ dev. (V) |
|---|---|---|---|
| Classical LPF-25Hz | 4.24 | 34.2 | 13.72 |
| **ADALINE** (mu=0.08, literature-typical) | 4.24 | **34.3** | 11.70 |
| **RBFNN** (4 seeds) | 4.19 $\pm$ 0.08 | **7.1 $\pm$ 0.0** | 5.00 $\pm$ 0.01 |
| FixedWNN (4 seeds) | 3.64 $\pm$ 0.17 | 7.1 $\pm$ 0.0 | 4.75 $\pm$ 0.14 |
| GRU (4 seeds) | 3.88 $\pm$ 0.10 | 7.1 $\pm$ 0.0 | 4.82 $\pm$ 0.05 |
| WavKAN (4 seeds) | 3.14 $\pm$ 0.04 | 7.3 $\pm$ 0.2 | 3.89 $\pm$ 0.89 |

Welch's t-test (implemented from `betainc`, no toolbox), WavKAN vs RBFNN
steady THD: **p < 0.0001** (highly significant).

![All 6 approaches](latex_octave/plots/fig_all6_octave.png)

## 3. The actual finding: it's not "neural vs. classical," it's architecture family

This is the most important result of this comparison, and it would have
been invisible without implementing ADALINE and RBFNN fairly rather than
citing their papers:

**Settling time splits into exactly two groups, and the split is NOT
"classical vs. neural":**
- **Slow ($\approx$34 ms): classical LPF *and* ADALINE.** Despite being a
  "neural network" by name, ADALINE's transient response is governed by
  its LMS adaptation time constant, which -- at the learning rate
  (mu=0.08) typical of the cited literature -- is just as slow as a fixed
  low-pass filter. ADALINE is a *recursively adapting* filter, conceptually
  much closer to the classical LPF than to the short-window extractors,
  regardless of the "neural network" label.
- **Fast ($\approx$7 ms): RBFNN *and* FixedWNN, GRU, WavKAN.** What these
  four share is not "being a neural network" -- ADALINE is also one -- but
  operating on a **short sliding window** (32 samples / 3.2 ms) and
  producing a direct, non-recursive estimate each control cycle, rather
  than slowly adapting internal state toward a new operating point.

**A follow-up check (`results/octave_adaline_musweep.csv`) confirms this
is a tunable property of ADALINE, not an inherent limit:**

| mu | Steady THD (%) | Load-step settle (ms) | Supraharmonic THD (%) |
|---|---|---|---|
| 0.02 | 4.24 | 44.5 | 4.77 |
| 0.08 | 4.24 | 34.3 | 4.76 |
| 0.30 | 4.24 | 14.0 | 4.75 |
| 0.50 | 4.24 | 7.0 | 4.73 |
| 0.80 | 4.24 | 6.8 | 4.70 |

Sweeping the learning rate from mu=0.02 to mu=0.8 took settling time from
44.5 ms down to 6.8 ms, with **no measurable THD penalty** in this
noise-free simulation. In a real deployment this would be surprising --
classical LMS theory predicts a speed/misadjustment tradeoff -- and the
likely explanation is that our synthetic ripple exactly matches ADALINE's
modeled harmonic basis (no model mismatch) and that the dominant
THD-limiting factor here is the current loop, not the extractor
(established in the main Octave study). **This is flagged as a real
limitation**: real hardware noise, unmodeled harmonics, and measurement
imperfections -- none of which this simulation includes beyond the
explicitly modeled supraharmonic bursts -- would likely punish an
aggressively-tuned ADALINE more than this clean test shows. The
literature's typically conservative learning-rate choices may reflect
exactly this real-world caution, which this simulation cannot fully
validate either way.

**On steady-state THD**, WavKAN's advantage is large and highly
significant here: 3.14% vs. RBFNN's 4.19% (p<0.0001), consistent with
(and in this run, even more pronounced than) its significant advantage
over FixedWNN and GRU already reported in the main Octave study.

## 4. What this changes about the overall story

- The "learned extractors settle faster than classical" claim from the
  main study should be **refined**: it is not learned-vs-classical, it is
  **short-window batch extraction vs. recursively-adapting filtering**
  (whether that filter is a fixed LPF or an adaptive ADALINE). This is a
  more precise and more defensible claim than the original framing.
- ADALINE -- the dominant real technique in the literature -- is not a
  strawman: with retuning it matches the fast settling of every other
  extractor here, in this simulation. Papers reporting slow ADALINE
  convergence very likely use conservative learning rates for real-world
  noise robustness, a tradeoff this clean simulation cannot fully probe.
- RBFNN, a real literature-standard technique requiring far less
  implementation effort than WavKAN, GRU, or FixedWNN (one closed-form
  solve, no backpropagation, no training epochs), achieves the *same*
  fast settling as those more complex architectures. Any claim for the
  value of the more complex architectures needs to rest on the THD
  difference specifically, which is where WavKAN's advantage is largest
  and most consistent.

## Files
- `plant_octave/adalineStepGeneric.m` -- ADALINE LMS step function
- `plant_octave/rbfnnFit.m`, `rbfnnBasis.m`, `rbfnnStepGeneric.m` -- RBFNN
- `plant_octave/litBaselinesStudy.m` -- the experiment driver
- `results/octave_litbaselines.csv`, `results/octave_adaline_musweep.csv`
- `latex_octave/plots/fig_all6_octave.png`

## Additional references added to the manuscript (all checked against publisher/repository records)

The manuscript now cites 28 works, numbered in order of first citation, and
every entry is cited in the text. The 17 added in the latest pass, and what
each one supports:

| Topic | Reference | Used for |
|---|---|---|
| SAPF background | Akagi, IEEE Trans. Ind. Appl. 32(6):1312-1322, 1996 | SAPF as standard solution |
| p-q theory | Akagi/Watanabe/Aredes book, Wiley-IEEE 2007; Peng & Lai, IEEE Trans. Instrum. Meas. 45(1):293-297, 1996; Czarnecki, IEEE Trans. Power Del. 21(1):362-367, 2006 | standard definition, generalized definitions, and the debate over interpretation |
| Supraharmonics | Ronnberg et al., Electr. Power Syst. Res. 150:1-10, 2017 | context for the 2-150 kHz scenario |
| SAPF harmonic detection | Maurya/Gupta/Maurya, Ain Shams Eng. J. 9(4):2833-2839, 2018 (wavelet); Chen et al., Energy Rep. 7:98-104, 2021 (conventional) | prior wavelet and conventional detectors |
| ESN in active filters | Dai et al., IEEE ECCE 2010; Tao et al., IET Power Electron. 16(14):2301-2310, 2023 | reservoir-computing SAPF control / harmonic prediction |
| KAN in power | Shuai & Li, arXiv:2408.06650; Novak et al., IEEE ECCE 2025 | closest KAN work in power systems / power electronics |
| Baseline methods | Widrow & Hoff 1960; Widrow & Stearns 1985; Broomhead & Lowe, Complex Syst. 2:321-355, 1988; Jang, IEEE Trans. SMC 23(3):665-685, 1993 | LMS (ADALINE), RBF networks, ANFIS (not implemented) |
| Methodology | Bouthillier et al., MLSys 2021; Scaman & Virmaux, NeurIPS 2018; Welch, Biometrika 34:28-35, 1947 | seed variance, Lipschitz-bound looseness, the significance test |

Three entries that were previously listed but never cited in the text
(Adam, IEEE Std 519, the Tao et al. ESN paper) are now cited where relevant.

Verification level: titles, authors, venues, volumes, pages and DOIs were
checked against search results (publisher pages, repositories, or other
papers' reference lists), not by reading each paper's full text. The claims
attached to each citation are consistent with the abstracts. Two details
came only from page headers or citing papers: the initials of the Shuai &
Li authors (H., F.) and the author list of the Akagi/Watanabe/Aredes book.
