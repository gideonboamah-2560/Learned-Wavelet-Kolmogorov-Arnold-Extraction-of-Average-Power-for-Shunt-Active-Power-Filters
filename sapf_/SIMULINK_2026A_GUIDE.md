# Building This SAPF in Simulink R2026a

## The situation, stated plainly

MathWorks removed the **Specialized Power Systems (SPS)** library from
Simscape Electrical starting in **R2026a**. Everything in the earlier
`README.md` (block paths under `powerlib`/`sps_lib`: `Three-Phase
Source`, `Universal Bridge`, `Three-Phase Series RLC Branch`, etc.) was
written for R2021a and **will not work** on R2026a — those blocks are
gone, not renamed.

MathWorks' own automated migration tool, `spsConversionAssistant`, exists
to help convert old SPS-based models, but as of a MathWorks Answers
thread from November 2025, a user reported it "turned \[SPS] blocks into
subsystems therefore losing all their corresponding block
functionalities" — i.e. don't treat it as a one-click fix, especially not
for the power-electronics blocks (Universal Bridge) that this project
needs.

**What I'm giving you instead:** the native Simscape Electrical block set
that replaces SPS, with library paths and the specific architectural
changes you need to know about. This is based on MathWorks documentation
and community discussion, not on something I could execute myself (no
MATLAB/Simulink in my environment) — so treat block paths as "start
here, verify against your Library Browser" rather than copy-paste
guaranteed, especially for anything I've marked lower-confidence below.

## The one big architectural difference: physical networks, not signal flow

SPS blocks connected with ordinary-looking lines that were secretly a
specialized electrical signal domain, but the *inputs and outputs of
your controller* (a MATLAB Function block) were always plain Simulink
signals, so wiring them in was direct.

Native Simscape Electrical is different: its blocks connect via
**physical conserving ports** (real electrical nodes, not signals), and
every physical network needs:
- Exactly one **Solver Configuration** block (`Simscape > Utilities`) —
  new requirement, SPS never needed this (it used `powergui` instead).
- An **Electrical Reference** block per network (`Simscape > Foundation
  Library > Electrical > Electrical Elements`) — establishes ground.

Because our `ctrl_*.m` MATLAB Function block outputs (`icRefA`,
`icRefB`, `icRefC`) and inputs (`vA`, `vB`, `vC`, `iLA`, ...) are plain
Simulink signals, you need conversion blocks at every interface:
- **Simulink-PS Converter** (`Simscape > Utilities`) — Simulink signal →
  physical signal, used to feed the controller's `icRef` output into a
  physical current source.
- **PS-Simulink Converter** (`Simscape > Utilities`) — physical signal →
  Simulink signal, used to bring a Simscape voltage/current sensor's
  reading back into the MATLAB Function block as a plain number.

This is standard Simscape practice (not specific to this project), and
these two converter blocks are stable, long-documented blocks — high
confidence these exist and work as described.

## Native block set (replaces the R2021a `powerlib` list)

| Old SPS block | Native replacement | Library path (verify in Browser) | Confidence |
|---|---|---|---|
| Three-Phase Source | **Voltage Source (Three-Phase)** (ideal) + separate **RLC (Three-Phase)** in series for $R_s,L_s$ | `Simscape/Electrical/Sources`; `Simscape/Electrical/Passive/RLC Assemblies` | High — both are long-standing native blocks |
| Controlled Current Source (for the APF's compensating current $i_c$) | **Controlled Current Source (Three-Phase)** | `Simscape/Electrical/Sources` | High — documented since R2018b, physical-signal input port matches our use case exactly |
| Three-Phase Series RLC Branch (coupling filter $L_f,R_f$) | **RLC (Three-Phase)** | `Simscape/Electrical/Passive/RLC Assemblies` | High |
| Universal Bridge (rectifier load AND the VSI) | **Universal Bridge** (native version exists under Simscape Electrical, confirmed by MathWorks staff on the Answers forum as "a direct replacement for the SPS Universal Bridge block") | Somewhere under `Simscape/Electrical/Power Electronics` or `Semiconductor & Converters` — exact submenu unconfirmed | **Medium** — block's existence and name confirmed, exact path not; use the name-search approach below rather than a hardcoded path |
| Three-Phase V-I Measurement | **Voltage Sensor** + **Current Sensor** (native), each + a PS-Simulink Converter | `Simscape/Electrical/Sensors & Transducers` (or `Foundation Library > Electrical > Electrical Sensors`) | High |
| PWM Generator (2-Level) | **PWM Generator (Three-phase, Two-level)** — native block, MathWorks example "Three-Phase Two-Level PWM Generator" uses it | Under `Simscape/Electrical/...` control/pulse-generator sublibrary — exact submenu unconfirmed | Medium |
| powergui | **Solver Configuration** (`Simscape/Utilities`) + ordinary Simulink solver settings (a variable-step solver like `ode23t`/`ode15s` is typically recommended for Simscape) | `Simscape/Utilities` | High for Solver Configuration; solver choice is a general Simscape recommendation, not this-project-specific |
| Discrete PI Controller (inner current loop) | Unchanged — this was always a plain Simulink block, not SPS | `Simulink/Continuous` or `Discrete` library | High |

## Recommended build sequence

1. Start from `ssc_new` (a MATLAB command that creates a new model
   prepopulated with a Solver Configuration and Electrical Reference
   block) rather than a blank model — this avoids forgetting the two
   required blocks.
2. Build the power stage: Voltage Source (Three-Phase) + series RLC
   (Three-Phase) for the grid; Universal Bridge (diode-configured) + RLC
   for the rectifier load; RLC (Three-Phase) coupling filter + Universal
   Bridge (IGBT-configured) + a Simscape capacitor for the APF.
3. Insert Voltage/Current Sensors at the PCC and on the APF branch, each
   followed by a PS-Simulink Converter, feeding your `ctrl_*.m` MATLAB
   Function block (paste in the contents of one of
   `simulink/ctrl_pq_pi.m`, `ctrl_fixed_wnn.m`, `ctrl_gru.m`,
   `ctrl_wavkan.m` exactly as before — this part is completely unchanged
   from the R2021a guide, since MATLAB Function blocks are not
   SPS-dependent).
4. Feed the controller's `icRefA/B/C` outputs through a Simulink-PS
   Converter into a Controlled Current Source (Three-Phase), OR (more
   realistically, to actually see switching behavior) into the same inner
   PI + PWM Generator + Universal Bridge (IGBT) chain as before — the
   `icRef` signal is still just a Simulink reference current, so the
   inner current loop design from the R2021a guide (`Kp,i = ωc·Lf`,
   `Ki,i = ωc·Rf`) carries over unchanged.
5. Set the Solver Configuration's settings and the model's Simulink
   solver (Model Settings) per Simscape's general guidance for stiff
   switched circuits — expect to need a variable-step solver with a small
   max step size, or a fixed-step local solver via the Solver
   Configuration block's "Use local solver" option.

## What to do right now, concretely

Given the genuine uncertainty in exact block paths above, the fastest
reliable path is:
1. Open the Simulink Library Browser, expand `Simscape > Electrical`,
   and manually locate `Universal Bridge` and the PWM generator block —
   hover to read the exact path, exactly as `resolveLibBlock.m`
   (updated below) would try to do programmatically.
2. If you have an existing SPS-based model (e.g. the File Exchange
   "Shunt Active Power Filter" #42627 I recommended earlier), try
   `spsConversionAssistant` on a **copy** of it first — even if it only
   partially works, it may save you time on the parts it does convert
   correctly (sources, RLC branches), leaving you to manually rebuild
   just the Universal Bridge stages.
3. Either way, budget real time for this — you are migrating across a
   library removal that MathWorks' own user base was still actively
   discussing as of late 2025, not following a mature, well-trodden path.

## Updated automation scripts

- `simulink_automation/resolveLibBlock.m` has been updated (see below)
  to search native Simscape libraries by block name instead of assuming
  `sps_lib`/`powerlib` exist.
- `simulink_automation/insertControllerScript.m` and
  `runAndExportResults.m` are **unchanged and still correct** — they
  never referenced SPS blocks by name; they work with any MATLAB
  Function block and any model, regardless of R2026a's library changes.
