# Wav-KAN Shunt Active Power Filter — Simulink Implementation Guide (R2021a)

This package gives you everything to build the closed-loop three-phase
three-wire SAPF in Simulink using **Simscape Electrical / Specialized
Power Systems** (confirmed present up through your R2021a; MathWorks has
announced it will be removed in R2026a, so this is a safe target for now
but worth knowing if you ever upgrade), with the four reference-current-
generation controllers (classical p-q+PI, fixed-wavelet WNN, GRU, and the
proposed Wav-KAN) dropped in as **MATLAB Function blocks**.

## Changelog (bugs found and fixed during closed-loop validation)

Building an executable closed-loop model exposed three bugs in an earlier
version of this package. They are fixed here and confirmed fixed by the
Octave closed-loop checks in `plant_octave/` (see `VERIFICATION_REPORT.md`).
If you generated `simulink/ctrl_*.m` before now, **regenerate them** with
`scripts/trainControllers.m` then `scripts/exportControllerCode.m`
(already done in this delivered copy):

1. **Wrong ripple-frequency physics in the training data** (`scripts/genDataset.m`).
   A 6-pulse rectifier's 5th/7th/11th/13th current harmonics produce
   instantaneous-power ripple at the 6th/12th/18th/24th harmonic of the
   fundamental (300/600/900/1200 Hz @ 50 Hz) -- not 100/200/300/400 Hz as
   originally coded. Before this fix, all three learned controllers
   performed *worse* than the classical filter in closed loop despite
   better open-loop accuracy.
2. **Sign error in the inverse p-q transform** (`sharedSubfunctions.m`).
   With q = va*ib - vb*ia, the correct inverse is icA = (va*pc - vb*qc)/|v|^2,
   icB = (vb*pc + va*qc)/|v|^2 -- the signs on the qc terms were flipped,
   which compensates harmonics with the wrong sequence and leaves a large
   residual.
3. **DC-link PI gains were arbitrary** (Kp=0.6, Ki=8) rather than derived
   from the linearized energy-balance model. Now set from a standard
   second-order design (wn=2*pi*8 rad/s, zeta=0.7): Kp=2*zeta*wn*C*Vref=112.6
   W/V, Ki=wn^2*C*Vref=4043 W/(V*s).

The closed-loop validation these fixes came from is `plant_octave/` and
`VERIFICATION_REPORT.md`; it covers everything except Simulink block
diagrams themselves (see below).

## Important: how I validated this, and what I didn't

I don't have MATLAB or Simulink in the environment I built this in — only
GNU Octave, which has no Simulink at all. So there are two different
confidence levels in this package:

- **Fully tested (via Octave), high confidence:** every controller's math
  (`simulink/ctrl_*.m`), the training pipeline, and `computeTHD.m` — I ran
  all of these against synthetic signals and confirmed correct behavior.
- **Not executable-tested, best effort:** anything that touches actual
  Simulink block wiring (`resolveLibBlock.m`, `insertControllerScript.m`,
  `runAndExportResults.m`). The `insertControllerScript.m` API call is
  taken directly from MathWorks' own documented example for scripting
  MATLAB Function blocks, so I'm confident in its correctness; the parts
  I'm least sure about are exact block/parameter names in Specialized
  Power Systems, which have shifted across releases (I found evidence of
  both `powerlib` and `sps_lib` naming the same library at different
  points — `resolveLibBlock.m` tries both).

**Because of that, I'm not shipping a from-scratch power-circuit builder
script** — hand-scripting a block diagram (source, rectifier, VSI, DC
bus, all the port-level wiring) with zero ability to catch a wrong port
name would be more likely to waste your time than save it. Instead:

## Recommended path: start from a known-working base model

MATLAB File Exchange already has validated Simulink SAPF models that are
compatible with any release, including R2021a:
- **"Shunt Active Power Filter"** by Jawad Iqbal, File Exchange ID 42627
  — pq-theory based, same 400 V three-phase-three-wire topology we
  designed around, reports THD reduced from 30.56% to 4.45%.
- **"Three Phase Shunt Active Power Filter using pq theory"** — similar,
  alternative implementation if you want to compare structures.

Download one of these from Add-On Explorer or the File Exchange website,
open it in R2021a, and:

1. Find its reference-current-generation subsystem (the block(s) that
   take load current + PCC voltage and output the compensating current
   reference — usually visibly labeled something like "p-q theory" or
   "Reference Current Generation").
2. Delete that subsystem's internals (keep the power circuit, inner
   current controller, and PWM generator exactly as they are).
3. Drop in an empty **MATLAB Function** block in its place, named e.g.
   `SAPF_Controller`, with inputs `(vA,vB,vC,iLA,iLB,iLC,Vdc,VdcRef,Ts)`
   and outputs `(icRefA,icRefB,icRefC)` wired exactly where the old
   subsystem's ports were.
4. Use `simulink_automation/insertControllerScript.m` (see below) to load
   any of the 4 trained controllers into that block without copy-pasting.

This means the circuit you're using is one that's already known to work,
and the only new thing is the reference-generation stage — which is
exactly our research contribution anyway.

---

## 1. Folder contents

```
models/        Plain-MATLAB reference implementation + trainer (numpy-free,
               pure MATLAB) of all 4 controllers — use this for offline
               retraining if you change the load/scenario distribution.
scripts/       genDataset.m, trainControllers.m, exportControllerCode.m
simulink/      *** THE FILES YOU NEED FOR SIMULINK ***
               ctrl_pq_pi.m, ctrl_fixed_wnn.m, ctrl_gru.m, ctrl_wavkan.m
               Each is a SELF-CONTAINED function (trained weights baked
               in as literals) ready to paste into a MATLAB Function block.
results/       trainedControllers.mat + training/validation logs
```

If you ever change the synthetic training scenarios (different load
profile, different supraharmonic band, etc.), re-run
`scripts/trainControllers.m` then `scripts/exportControllerCode.m` to
regenerate the four `simulink/ctrl_*.m` files with new embedded weights.

---

## 2. Top-level model topology

```
 [Three-Phase Source] --Rs,Ls-- [PCC] ----------------- [Nonlinear Load]
   (grid, 50 Hz, 400V L-L)         |                    (6-pulse rectifier
                                   |                      + RL DC load)
                                   |
                                   |------------------- [Supraharmonic
                                   |                      injection source]
                                   |
                              [Lf, Rf]  (APF coupling filter)
                                   |
                         [Universal Bridge #2]  (2-level VSI, IGBT)
                                   |
                              [DC bus, C]
                                   |
                    (gate signals from PWM Generator,
                     driven by inner current PI,
                     driven by ic_ref_abc from the
                     MATLAB Function controller block)
```

## 3. Block-by-block setup (Specialized Power Systems)

### 3.1 Grid source
- **Three-Phase Source** block.
  - Phase-to-phase RMS voltage: 400 V, Frequency: 50 Hz.
  - Internal R = 0.1 Ω, L = 0.1 mH for a "stiff grid" baseline run.
  - For the weak-grid test scenario, change L to 2 mH (keep R at 0.1 Ω)
    and re-run — this is the scenario that stresses the extraction
    filters most, since PCC voltage distortion feeds back into p, q.

### 3.2 Nonlinear + supraharmonic load
- **Universal Bridge** (3-arm, diode) configured as an uncontrolled
  6-pulse rectifier, DC side loaded with a series R-L (e.g. R=8 Ω,
  L=15 mH) to ground a realistic 5th/7th/11th/13th harmonic profile
  (~28–30% current THD).
- Add a **Controlled Current Source** (or three, one per phase) in
  parallel at the PCC, driven by a **Sine Wave** block at a variable
  frequency in the 2–9 kHz band (this is your "supraharmonic emission"
  stand-in for an EV charger / PV inverter). Use a **Signal Builder** or
  a simple gain-scheduled Sine Wave to turn the burst on/off at a chosen
  time, matching the synthetic-training-data assumption.
- To test the transient-response scenario, step the rectifier's DC-side
  load resistance (or add a second load switched in via a **Breaker**
  block) partway through the run.

### 3.3 Shunt APF power stage
- **Series RLC Branch** as the coupling filter: Lf = 3 mH, Rf = 0.05 Ω,
  one per phase, between the PCC and the VSI AC terminals.
- **Universal Bridge** (3-arm, IGBT/Diode) as the 2-level VSI.
- DC bus: a shunt **Capacitor** (C = 2000 µF) across the bridge's DC
  terminals, with **Voltage Measurement** across it (this is your `Vdc`
  signal into the controller).
- `VdcRef` = 800 V (must be > peak line-to-line PCC voltage for full
  controllability; 800 V gives comfortable margin for a 400 V system).

### 3.4 Measurements
- **Three-Phase V-I Measurement** at the PCC (gives you `vA,vB,vC` and,
  separately, one on the load branch for `iLA,iLB,iLC`).
- A second **Three-Phase V-I Measurement** on the source branch, for
  computing THD of the *source* current after compensation — this is
  your headline result.

### 3.5 Controller (MATLAB Function block)
Add one **MATLAB Function** block, name it e.g. `SAPF_Controller`.
Double-click it and paste in the full contents of **one** of:
```
simulink/ctrl_pq_pi.m
simulink/ctrl_fixed_wnn.m
simulink/ctrl_gru.m
simulink/ctrl_wavkan.m
```
- Inputs (in order): `vA,vB,vC,iLA,iLB,iLC,Vdc,VdcRef,Ts`
- Outputs: `icRefA,icRefB,icRefC`
- Set the block's **Sample Time** to `1e-4` (10 kHz controller rate) via
  the block's Simulink function block parameters, or wrap it in a
  **Rate Transition** fed from a 10 kHz trigger if your plant is running
  a faster fixed-step solver. Feed a constant `Ts = 1e-4` into the last
  input.
- To compare controllers, keep four copies of this block (one per
  variant) in the model and use a **Manual Switch** or run four separate
  simulations swapping which one feeds the current loop — four separate
  runs is simplest and avoids interaction effects between controllers.

### 3.6 Inner current controller + PWM
- Three **Discrete PI Controller** blocks (or a single vectorized one),
  one per phase, tracking `icRefA/B/C` against the *measured* APF branch
  current (`Three-Phase V-I Measurement` on the Lf/Rf branch). This loop
  is identical across all four controller variants — keep its gains
  fixed across your comparison runs so any differences you see are
  attributable to the reference-generation stage, not the inner loop.
- Feed the PI output (a per-phase modulation signal, saturate to
  [-1, 1]) into a **PWM Generator (2-Level)** block (carrier frequency
  ~10 kHz) to produce the 6 gate signals for the Universal Bridge VSI.

### 3.7 Solver / powergui
- Add a **powergui** block, **Discrete** mode, sample time `Ts_power =
  1e-6` (1 µs) — fine enough to resolve the 10 kHz PWM carrier and give
  genuine switching ripple (this is a real advantage of doing this in
  Simscape rather than my earlier averaged-model prototype: you get
  authentic switching-induced high-frequency content for the
  supraharmonic study, not just an injected disturbance).
- Use powergui's built-in **FFT Analysis Tool** (Powergui → Tools → FFT
  Analysis) on the source current to get THD directly, or add a
  **Discrete Fourier** block for online monitoring.

---

## 4. Recommended experiment matrix

Run each of the 4 controllers through the same 4 scenarios (16 runs
total), logging source-current THD, DC-link ripple, and transient
settling time:

1. **Steady multi-harmonic load** (baseline 6-pulse rectifier, no step).
2. **Load step** (step the DC-side load ~50%→100% partway through).
3. **Supraharmonic burst** (2–9 kHz injection on for a sub-interval).
4. **Weak grid** (Ls = 2 mH instead of 0.1 mH).

---

## 4b. Automation scripts (`simulink_automation/`)

- **`resolveLibBlock.m`** — finds a Specialized Power Systems block by
  name (tries both `sps_lib` and `powerlib` as the underlying library
  system name, since this has changed across releases) rather than a
  hardcoded full path. Use if you want to script additions to your model
  (e.g. `resolveLibBlock('Universal Bridge')`).
- **`insertControllerScript.m`** — loads one of the four `ctrl_*.m` files
  into your `SAPF_Controller` MATLAB Function block programmatically, so
  switching controllers for a comparison run is one function call instead
  of copy-paste:
  ```matlab
  insertControllerScript('your_model_name', 'your_model_name/SAPF_Controller', ...
                          'simulink/ctrl_wavkan.m')
  ```
- **`computeTHD.m`** — FFT-based THD of any logged current waveform.
  Already validated: on a synthetic 20% THD test signal it returned
  20.96% (expected ~20.96%).
- **`runAndExportResults.m`** — orchestrates all 4 controllers through
  your scenario list, calls `sim()`, computes THD/DC-ripple from logged
  signals, and writes `results/simulink_results.csv` + `.mat`. **You need
  to edit two things at the top of this file** before running it: the
  exact block path of your `SAPF_Controller` block, and (if your scenario
  parameters live on named blocks) the parameter-override lines inside
  the scenario loop. It expects three "To Workspace" blocks in your
  model, Save format = Timeseries, named exactly `logIsrc`, `logVdc`,
  `logIload`.

## 5. The loop for getting results into the paper

Since I can't run MATLAB myself, here's the intended workflow:

1. You build/adapt the model per section 3 above (start from the File
   Exchange base + swap in the controller block).
2. Run `simulink_automation/runAndExportResults.m` — it sweeps all 4
   controllers and produces `results/simulink_results.csv`.
3. **Upload `simulink_results.csv` (and/or `.mat`) back into our chat.**
   I'll read it, compute any derived statistics, generate the comparison
   plots/tables, and draft the Results section text around the real
   numbers.
4. If a run looks wrong (e.g. THD is absurdly high, DC bus diverges),
   tell me what you're seeing and I'll help debug the likely cause from
   the controller/plant-model logic side, even without seeing the model
   directly — a lot of SAPF bugs (sign errors in the p-q inverse
   transform, PI saturation limits, Vdc reference too low) are diagnosable
   from symptoms alone.

## 6. Known limitations to state in the paper

- The controllers were trained **offline** on synthetic p̄-extraction
  data (known load steps, harmonic ripple, supraharmonic bursts) rather
  than online in closed loop; this is standard practice for this class
  of paper, but the manuscript should say so explicitly and describe it
  as a train/deploy split, with online fine-tuning left as future work.
- Per-step compute cost differs a lot across controllers (in our
  MATLAB/Octave benchmark, GRU was ~8x slower per step than the
  fixed-wavelet WNN, and Wav-KAN ~2x slower) — worth reporting as a
  table, since real-time deployability at a 10 kHz control rate is a
  real constraint for a TPEL reviewer to care about, not just accuracy.
- Wav-KAN training was noticeably more sensitive to learning rate than
  FixedWNN (it destabilizes with too-high LR since scale/translation are
  themselves being learned) — this is a legitimate discussion point,
  not something to hide: it motivates a "training stability" ablation
  in the paper (LR sweep, and/or a two-stage training schedule: freeze
  a,b initially and only learn c, then unfreeze).
