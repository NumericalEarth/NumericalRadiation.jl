# RadiativeHeating.jl / Breeze.jl Radiation Project Plan

**Prepared:** 2026-05-12  
**Intended use:** paste into Codex with `/goal`, or use as a project brief for staged implementation.  
**Current working package name:** `NumericalRadiation.jl`  
**Target package name:** `RadiativeHeating.jl`  
**Target Breeze integration location:** `Breeze.jl/ext/BreezeRadiativeHeatingExt.jl`

**Rename decision for this active `/goal`:** defer the package rename until
after the three acceptance gates are complete. The current implementation and
artifacts may keep the `NumericalRadiation.jl` module/repository name while
building the RadiativeHeating APIs, validation gates, and Breeze-owned
extension. A final rename to `RadiativeHeating.jl` remains a release/staging
task, but it is not a blocker for the current accuracy/performance gates unless
the `/goal` is explicitly revised.

---

## 0. One-sentence goal

Build `RadiativeHeating.jl` as a standalone, high-quality, GPU-capable, differentiable radiation and gas-optics package that implements an ecRad-style radiative transfer pipeline, ingests ecCKD gas-optics models, later reproduces ecCKD model generation through a differentiable Julia workflow using Reactant.jl and Enzyme.jl, and integrates into Breeze.jl through a Breeze-owned extension that can outperform the existing RRTMGP.jl path.

Completion of this `/goal` is defined by three required gates:

1. Pass a hard cloudless/no-aerosol ecRad accuracy gate using official ecCKD
   inputs. This isolates gas optics, clear-sky solvers, source terms, and
   surface-boundary conventions.
2. Use the validated official ecCKD 32-g gas-optics model as the production
   target, freeze the 16-g reduced model as diagnostic evidence, keep the
   Reactant.jl and Enzyme.jl optimization/training path demonstrated, and emit
   direct RRTMGP comparison metrics on the same column ensemble.
3. Pass the current IFS all-sky gate by implementing cloud and aerosol optical
   properties, scattering, overlap, and McICA/Tripleclouds-style solver
   semantics, then demonstrate the >= 4x H100 speedup over RRTMGP in the
   dedicated Breeze extension on a realistic RCEMIP-style workload.

The implementation order for the active `/goal` is the same three-step
sequence:

1. **Step 1: clean ecCKD cloudless gate.** First make the official
   cloudless/no-aerosol ecRad case pass hard thresholds. Treat failures here as
   gas-optics, clear-solver, source-term, or surface-boundary bugs, not as
   all-sky physics work.
2. **Step 2: 32-g production gas optics.** Then replace proxy coefficients
   with the validated official ecCKD 32-g gas-optics path, retain the 16-g
   reduced work as a frozen diagnostic, and compare the 32-g production output
   directly to RRTMGP on the same column ensemble.
3. **Step 3: all-sky plus production Breeze.** Finally close the current IFS
   all-sky cloud/aerosol/scattering/overlap solver gap and keep the H100
   Breeze/RRTMGP comparison on a realistic RCEMIP-style workload as the
   production performance gate.

Current audit state for these three steps. The Step 2 row keeps historical
optimizer context for the frozen 16-g diagnostic, but the active acceptance
target is now the 32-g production path plus direct RRTMGP comparison.

| Step | Status | Required next evidence |
|---|---|---|
| Step 1: clean ecCKD cloudless gate | passed | Keep `validation/results/ecrad_accuracy_gate.*` passing on the official ecCKD hard-gate cases. |
| Step 2: 32-g production gas optics | passed | The recorded user decision (archived working log, ref `audit-trail-2026-07-17`) changes the Step 2 acceptance target: the 16-g canonical model is frozen as a diagnostic at hard objective `7.00640773953`, and production uses the validated official ecCKD 32-g gas-optics path. `validation/results/reduced_ecckd_accuracy.*` records the official 32x32 baseline passing the hard ecRad/ecCKD thresholds with TOA forcing error `0.00806408713606` W m^-2 and surface forcing error `0.0140335470378` W m^-2. `validation/results/reduced_ecckd_32g_rrtmgp_comparison.*` now emits the direct RRTMGP comparison on the same tropical, RCEMIP-style, and all-sky-clear-projection column ensemble; it records `Status: passed`, `official_32g_ecckd_hard_gate_passed = true`, and finite RRTMGP compatibility metrics. The 16-g reduced artifacts remain as diagnostic history rather than completion blockers. |
| Step 3: all-sky plus production Breeze | passed | `validation/results/ecrad_all_sky_ifs_gate.*` records `Status: passed`: official ecCKD all-sky hard gate passed, cloud scattering tables passed, the best cloud/aerosol/overlap sweep passed with value `0.387294188553`, and the reference-optics Tripleclouds solver matched with TOA error `1.42029895187e-05` and surface error `2.57961164607e-05`. The Breeze benchmark now has a `RADIATIVE_HEATING_GAS_MODEL_SOURCE=validated_ecCKD` path and records explicit trace-gas defaults (`co2`, `ch4`, `n2o`, `cfc11`, `cfc12`, and `o3`) instead of silently using a `co2`-only state. Breeze converts tabulated ecCKD host-model state to column molar amounts on the CPU path and now has KernelAbstractions device-preparation kernels for official multi-gas column amounts, pressure/temperature/H2O interpolation state, tabulated absorption optical depths with gas-reference subtraction, shortwave Rayleigh optical depths, longwave source-table interpolation, and an integrated tabulated optical-properties kernel that fills these optics in one launch. The latest environment artifact in the dedicated Breeze checkout was written from Slurm job `864` on `gpu-prod-st-gpu-prod-1` and reports `ready_for_h100_nsight_gate`: H100 detected, `CUDA.functional=true`, `nvidia-smi` works, and both `nsys` and `ncu` are available from the CUDA 13 path. The H100 support preflight now passes for `validated_ecCKD`: `gas_model_device_support_status = supported`, missing requirements are empty, and the reason cites recorded CPU/GPU parity evidence. The parity artifact passes on H100 for official tabulated ecCKD 32/32 with a 2 x 2 x 8 smoke grid; field max errors are roundoff-scale (`~1e-13` W m^-2 for downwelling shortwave and `~6e-17` for flux divergence). The support checklist is owned by `BreezeRadiativeHeatingExt.radiative_heating_device_support`, and the benchmark/preflight artifacts record `gas_model_device_support_source = "BreezeRadiativeHeatingExt"` so H100 readiness is tied to extension capabilities rather than duplicated benchmark metadata. The RCEMIP-style H100 production benchmark passes the >=4x RRTMGP comparison: `/shared/home/greg/Projects/BreezeRadiativeHeatingDev/Breeze.jl/benchmarking/results/rcemip_h100_32x32x64/radiative_heating_rcemip_latest.json` records `final_4x_claim_supported = true`, speedup `31.3348246298x`, RadiativeHeating median update `7.785843` ms, RRTMGP median update `243.968025` ms, grid `32 x 32 x 64`, official ecCKD 32/32 gas optics, and both profiler reports (`.../nsight/radiative_heating_rcemip_nsys.nsys-rep` and `.../nsight/radiative_heating_rcemip_ncu.ncu-rep`). |

## 0.1 Next Goal: ecCKD Recovery and New Band Counts

The next differentiable-training goal is to make the in-house Reactant.jl and
Enzyme.jl pipeline reproduce published ecCKD models before using it to fill
missing band-count gaps. This is a stricter target than matching broadband
fluxes alone. The recovery experiment must keep the ecCKD problem definition
fixed and vary only the Julia optimizer stack.

Current active recovery `/goal`, updated 2026-05-20:

1. Demonstrate parity with ecRad for full-accuracy ecCKD models and reduced
   ecCKD models, including 16-, 32-, and other available band counts.
2. Demonstrate that reduced models meet the hard accuracy criteria when
   compared to RRTMGP on representative atmosphere states, including a
   realistic RCEMIP-style column ensemble rather than a trivial single-column
   smoke case.
3. Demonstrate that the new radiation models can be integrated dynamically into
   Breeze simulations without numerical blow-up, and preserve the H100
   production evidence against RRTMGP.
4. Reimplement the ecCKD training pipeline with Reactant.jl and Enzyme.jl,
   recover at least one published ecCKD model while keeping the published
   problem definition fixed and changing only the optimizer stack/settings,
   then use the same pipeline to fill band-count gaps and plot accuracy versus
   band count.

The active recovery goal is **not complete**. The refreshed
`validation/results/recovery_goal_audit.*` report records one passed
requirement, two partial requirements, and one blocked requirement. Public
CKDMIP input data is present at the dedicated data root, but exact
published-objective recovery is blocked until the locally derived ecCKD
`5gas-*` and `rel-*` training flux products are generated from the CKDMIP
spectra. Slurm job `1077` is currently running that derived-flux generation
directly into `$RH_CKDMIP_DATA_PATH/evaluation1/{lw,sw}_fluxes` after removing
the unsupported LW namelist key and using the rebuilt CKDMIP binary without
`-ffpe-trap=invalid,zero,overflow`. The repository launcher also now reuses
completed raw chunks after restart and installs final derived products into
the same CKDMIP tree.

Fixed inputs:

- official ecCKD/ecRad model data resolved from `Artifacts.toml`, an explicit
  environment override, or the local validation checkout;
- official ecCKD source resolved from `Artifacts.toml`, `RH_ECCKD_SOURCE_PATH`,
  or `validation/external/ecckd`, including the original `optimize_lut`,
  Adept-based cost-function, and training shell scripts;
- the same LBL/reference target data, atmospheric training profiles, gases,
  pressure/temperature grids, spectral intervals, solar/Planck weighting,
  g-point topology, coefficient parameterization, regularization, constraints,
  normalization, and loss function used by the published model;
- published ecCKD NetCDF definitions used as coefficient-level and
  radiative-output references.

Variable component:

- optimizer implementation and execution stack only: Reactant-compiled losses,
  Enzyme gradients, Optim.jl or custom projected-gradient/LBFGS/trust-region
  methods, and optimizer settings.

Primary recovery metrics for a fixed-topology published model:

| Metric | Acceptance threshold |
|---|---:|
| log-coefficient RMSE, `rmse(log(k_recovered + eps) - log(k_published + eps))` | `< 1e-3` |
| median relative coefficient error | `< 1e-3` |
| 99th-percentile relative coefficient error | `< 1e-2` |
| g-point weight absolute error | `< 1e-6` |
| band-integrated weight absolute error | `< 1e-8` |

Objective recovery metrics:

| Metric | Acceptance threshold |
|---|---:|
| recovered objective / published objective, if original objective is reconstructed | `<= 1.01` |
| held-out validation objective / published validation objective | `<= 1.02` |
| normalized gradient norm at recovered solution | `< 1e-5` |
| teacher-student training loss reduction, if original LBL objective cannot be fully reconstructed | `> 100x` |
| teacher-student held-out loss, if used | `< 2e-4` |

Current objective-reconstruction status: the official ecCKD source and
published CKD-definition files are now artifact-backed and locally verifiable.
`validation/results/ecckd_published_training_manifest.*` captures the fixed
official source files, `evaluation1`/`evaluation2` dataset choices, training
modes, gases, and selected `optimize_lut` common options that must stay fixed.
`validation/results/ckdmip_training_data_preflight.*` checks a mounted
`RH_CKDMIP_DATA_PATH` against the public upstream CKDMIP inputs and separately
inventories the derived ecCKD `5gas-*` and `rel-*` training flux products
referenced by those scripts, while
`validation/results/ckdmip_training_data_download_plan.*` provides the opt-in
download plan.
`validation/results/ecckd_objective_reconstruction_check.*` still blocks exact
published-objective recovery on missing upstream CKDMIP data or on missing
derived ecCKD training flux products. The upstream data is too large for
ordinary CI and must be acquired or mounted as a dedicated data artifact; the
derived products must then be generated locally from the spectra before the
Reactant/Enzyme optimizer can replace only the optimizer settings.

Active recovery-goal audit, 2026-05-19: this next goal is **not complete**.
`validation/results/ecckd_published_training_manifest.*` passes and fixes the
official source/script/objective contract, and
`validation/results/ecckd_teacher_student_recovery_scan.*` passes coefficient
teacher-student recovery for all six published ecCKD definitions. However,
`validation/results/ckdmip_training_data_preflight.*` reports whether the
upstream data root is missing, incomplete, ready for derived flux generation, or
ready for original-objective reconstruction, and
`validation/results/ecckd_objective_reconstruction_check.*` reports
`blocked_missing_original_training_assets` until both the public upstream
CKDMIP inputs and the derived ecCKD training flux products are present. Until
that preflight reaches `ready_for_original_ecckd_objective`, the
Reactant/Enzyme pipeline is verified only as a fixed-topology teacher-student
recovery and not as a reproduction of the original published ecCKD optimization
objective.
`validation/recovery_goal_audit.jl` is the current prompt-to-artifact audit for
the four latest recovery deliverables; it writes
`validation/results/recovery_goal_audit.*` and currently records the Breeze
integration evidence as passed, the full/reduced parity and reduced/RRTMGP
requirements as partial, and exact original-objective recovery as blocked on
the missing CKDMIP training tree.

Radiative-output recovery metrics on held-out atmosphere columns:

| Metric | Acceptance threshold |
|---|---:|
| broadband flux RMSE | `< 0.3 W m^-2` |
| broadband flux max error | `< 2 W m^-2` |
| TOA net-flux error | `< 0.3 W m^-2` |
| surface net-flux error | `< 0.3 W m^-2` |
| heating-rate RMSE | `< 0.03 K day^-1` |
| heating-rate max error | `< 0.3 K day^-1` |

Once at least one published model is recovered under these criteria, extend the
same pipeline to published 32-, 64-, and 96-g ecCKD definitions where available,
then train intermediate models such as 16, 24, 48, and 80 g-points. The required
summary artifact is an accuracy/performance-versus-band-count Pareto plot that
includes published ecCKD points, recovered versions of those points, newly
trained intermediate points, and RRTMGP as a reference. At minimum, the plot
must report TOA forcing error, surface forcing error, flux RMSE, heating-rate
RMSE, runtime, memory/workspace size, and H100 throughput.

Latest Step 2 audit note, 2026-05-19: `validation/results/goal_audit_check.*`
marks the goal `complete` under the updated criterion: production uses the
validated official ecCKD 32-g model, and
`validation/results/reduced_ecckd_32g_rrtmgp_comparison.*` provides the direct
RRTMGP comparison axis. The frozen 16-g diagnostic remains documented because
it explains why the reduced target changed. The full RRTMGP-target
Reactant/Enzyme calibration
artifact now exists and passes its AD-specific gate:
`validation/results/rrtmgp_target_16g_ad_calibration.*` records Reactant
compilation of the same 6-layer RRTMGP-target loss that Enzyme differentiates,
and Enzyme reverse-mode gradient descent reduces the 16-g calibration loss
from `34711.9494945` to `34703.9349766`. This demonstrates the requested AD
calibration path, but it does not close the reduced hard-accuracy gate: the
post-training package metrics remain far from production accuracy
(`flux_rmse = 277.987326399` W m^-2, TOA forcing error
`569.42820632` W m^-2, and surface forcing error `630.794993633` W m^-2).
The current reduced
accuracy artifact reports the current 32x16 retained capped-table,
post-capped-weight, post-weight surface-table, bounded post-weight weight,
current component-scale, selected gas-pressure component, and weighted/high-weight
gas-pressure continuation rows at TOA `2.07524167121` W m^-2 and surface
`2.02695668832` W m^-2. The metric breakdown reports hard objective
`6.91747223736`, with the active blocker split between RCEMIP-style TOA forcing
and tropical heating-rate RMSE. Bounded support-swap, support-expansion,
multi-start expansion-refit, and 256-sample random 16-g support diagnostics now
reject; the bare deterministic canonical support objective is `137.262984282`,
which confirms that the current best row depends on the composed
table/component/gas-pressure refit chain rather than support choice alone.
`validation/results/reduced_ecckd_gap_report.*` now emits a
`Reduced Acceptance Decision` section with status `decision_required`. The
remaining reduced 16-g work is diagnostic rather than a production blocker. A bounded
radius-2 support-plus-refit search now rejects after prefiltering `8 / 33`
neighbors and fully refitting `2 / 33`: the best selected alternative has hard
objective `45.0350379919`, much worse than the current composed canonical
state. A nonlocal support-plus-refit search then fully evaluates the best saved
supports from the random, swap, continuation, and hardgate subset searches
(`4 / 4` candidates) and also rejects: the best is again
`hardgate_subset_best` at objective `45.0350379919`, while the other saved
supports blow up to objectives `1375.13330949`, `70366.6855162`, and
`79316.6222921`, all with zero accepted refit moves. The structured decision
state therefore narrows the remaining options to revising/splitting the hard
16-g reduced acceptance target or allowing a different reduced basis.
A current-base component-scale diagnostic found one remaining cap-safe
component direction on the fully composed base. With the smaller
`0.001953125` log-scale trust region, it accepts a ridge row that lowers the
hard objective from `6.97212754254` to `6.96933451127`, TOA forcing from
`2.09163826276` to `2.09080035338` W m^-2, and worst heating-rate RMSE from
`0.348575997036` to `0.347361493009` K day^-1 while keeping surface forcing at
`2.01498794456` W m^-2 under the `2.03` W m^-2 regression cap. This accepted
move is now composed into the canonical reduced row, but it is still far from
the `0.3` W m^-2 hard threshold.
A second current-base component-scale diagnostic composes that first accepted
move and then finds another cap-safe low-rank direction with a tighter
`0.0009765625` log-scale trust region. It lowers the hard objective from
`6.96933451127` to `6.96730155579`, TOA forcing from `2.09080035338` to
`2.09019046674` W m^-2, surface forcing from `2.01498794456` to
`2.01348577884` W m^-2, and worst heating-rate RMSE from
`0.347361493009` to `0.346742121541` K day^-1. This second accepted move is
also composed into the canonical reduced row, but the row remains far from the
`0.3` W m^-2 hard threshold.
A third current-base component-scale diagnostic composes the first two
accepted moves and then finds another cap-safe low-rank direction with a
tighter `0.00048828125` log-scale trust region. It lowers the hard objective
from `6.96730155579` to `6.96625146691`, TOA forcing from `2.09019046674` to
`2.08987544007` W m^-2, and worst heating-rate RMSE from `0.346742121541` to
`0.346419533777` K day^-1 while keeping surface forcing at
`2.01423282621` W m^-2 under the `2.03` W m^-2 cap. This third accepted move
is also composed into the canonical reduced row, but the row remains far from
the `0.3` W m^-2 hard threshold.
A fourth current-base component-scale diagnostic composes the first three
accepted moves and then finds a still smaller cap-safe low-rank direction with
a tighter `0.000244140625` log-scale trust region. It lowers the hard
objective from `6.96625146691` to `6.96570561645`, TOA forcing from
`2.08987544007` to `2.08971168493` W m^-2, and worst heating-rate RMSE from
`0.346419533777` to `0.346248776779` K day^-1 while keeping surface forcing at
`2.01462006099` W m^-2 under the `2.03` W m^-2 cap. This fourth accepted move
is also composed into the canonical reduced row, but the row remains far from
the `0.3` W m^-2 hard threshold and shows the whole-component halving path is
near diminishing returns.
A current-base pressure-component diagnostic composes the four accepted
whole-component moves and then solves a richer 128-column pressure-band
static/H2O component-scale basis against the coupled heating-profile and
boundary residual. It accepts a ridge row that lowers the hard objective from
`6.96570561645` to `6.9558996605`, TOA forcing from `2.08971168493` to
`2.08676989815` W m^-2, surface forcing from `2.01462006099` to
`2.01383542392` W m^-2, and worst heating-rate RMSE from `0.346248776779` to
`0.343997633773` K day^-1. This move is now composed into the canonical
reduced row; it is a larger improvement than another whole-component halving
step, but the row remains far from the `0.3` W m^-2 hard threshold.
A leave-one-out scan of the official 32-g shortwave path now shows that every
31-g single-omission candidate fails the full hard gate. The best omission,
g-point `23`, has small boundary errors (TOA `0.0536563611829` W m^-2 and
surface `0.0752042866003` W m^-2) but still fails through the full flux/RMSE
objective at `1.64509212825`. A matching nonnegative 31-weight refit also
fails every single-omission support; the best refitted omission remains
g-point `23` with objective `1.62442314379`. This rules out naive official
weights as the reason the near-full leave-one-out models fail and strengthens
the conclusion that the remaining reduced-gas-optics blocker needs a richer
bounded-frontier flux/heating residual or quadrature-bin parameterization, not
more local 16-g support or weight-only tweaks. An importance-guided 16-bin
coefficient-averaging scan that preserves high-impact leave-one-out g-points
as singleton bins and refits nonnegative group weights was also rejected; its
best candidate, `critical_singleton_k12`, has objective `278.21969455`, TOA
forcing error `30.655727141` W m^-2, and surface forcing error
`83.4659083651` W m^-2. This is far worse than the current retained subset, so
hard-gate importance ranking is useful diagnostic information but not a direct
recipe for coefficient-averaged 16-bin construction.
The current retained 32x16 metric breakdown is now recorded in
`validation/results/reduced_ecckd_current_metric_breakdown.*`. It shows the
hard objective is not a single isolated boundary outlier: the worst row is
`ecckd_rcemip_style_column_subset` TOA forcing at normalized objective
`6.9558996605`, immediately followed by `ecckd_clear_sky_tropical_column`
heating-rate RMSE at normalized objective `6.87995267546`, with the RCEMIP
surface forcing row also above `6.71x` threshold. Future reduced optimizers therefore
need to optimize coupled boundary fluxes and heating-rate residuals together;
a one-metric TOA-only fix is likely to regress another active gate.

2026-05-16 reduced-gas-optics update: the latest wider integrated
pressure-band table pass evaluated the full simple 512-candidate
component/g-point/band/sign move set for four iterations. It accepted four
moves and reduced the main preflight objective only from `8.61439354943` to
`8.61316394314`; the final blocker moved to `toa_forcing_max_abs` in
`ecckd_rcemip_style_column_subset`, with value `2.58394918294` W m^-2 against
the `0.3` W m^-2 threshold. The regenerated reduced-accuracy artifact now
reports the table-refined 32x16 candidate at worst TOA forcing error
`2.58394918294` W m^-2 and worst surface forcing error `2.4639442291` W m^-2.
An incoming-shortwave-weighted variant of the same table-refined candidate was
also evaluated and produced identical boundary-forcing errors, so reduced
incoming spectrum weighting is not a useful escape path. A 28-iteration greedy
coefficient checkpoint was preserved as
`validation/results/reduced_ecckd_optimization_preflight.regressed_28iter.*`;
it lowered the scalar greedy objective but worsened the final hard-gate
objective to about `8.71329`, so longer scalar coefficient descent is not
currently acceptance-aligned.

Follow-up active table-entry refinement promoted the fine-grained table-entry
scan into the main preflight and reduced-accuracy path. With the same four
accepted pressure-band moves, two accepted active coefficient-entry moves
originally reduced the main preflight objective from `8.61316394314` to
`8.61311643949`; a later completed coefficient/topology exploration preflight
with the expensive active table-entry loop disabled records a slightly lower
table-refined objective of `8.60500733608`.
The regenerated reduced-accuracy artifact and Breeze reduced-accuracy copy now
select the lower-objective targeted/global active-entry move set when it is
available. They report the official table-refined 32x16 candidate at worst TOA
forcing error `2.49657297122` W m^-2 and worst surface forcing error
`2.38029831045` W m^-2 after the latest accepted grouped linearized
active-entry table diagnostic and exact shortwave-weight coordinate refit are
included.
This is real movement in the right direction, but it is negligible relative to
the required reduction to the `0.3` W m^-2 boundary-forcing threshold; active
entry-level scaling of the accepted pressure bands is therefore not sufficient
by itself.

The dedicated Breeze benchmark constructor for
`RADIATIVE_HEATING_GAS_MODEL_SOURCE=validated_ecCKD_reduced_preflight_table_refined`
now applies the same active table-entry moves after the pressure-band moves, so
runtime smoke tests and reduced-accuracy/Pareto artifacts no longer refer to
different reduced models. A CPU RCEMIP-style smoke artifact in the dedicated
Breeze checkout,
`benchmarking/results/reduced_preflight_table_refined_cpu_active_smoke/radiative_heating_rcemip_latest.json`,
records `preflight_pressure_move_count = 4`,
`preflight_active_table_entry_move_count = 2`, `gas_model_device_support_status
= supported`, and `gas_model_accuracy_status = failed_threshold`. This is
constructor/runtime consistency evidence only; it does not replace the existing
H100 performance evidence or unblock the reduced accuracy gate.

A radius-2 topology-neighbor preflight was also run with bounded coefficient
refit (`RH_REDUCED_TOPOLOGY_REFINEMENT_RADIUS=2`). The warm-started pass checked
4 of 33 candidates and the ranked pass refined the best 8 of 33 candidates.
Neither improved the `8.61488084949` post-joint objective before table
refinement, and the final table/active-entry objective remains
`8.60500733608` in the latest completed preflight. This rules out the currently bounded one-g-point radius-2
topology replacement as an immediate fix; the remaining reduced-accuracy work
needs a structurally stronger constrained table/quadrature optimizer rather
than more local neighbor swaps.

A smooth-objective diagnostic was added in response to the running review's
concern that the max-norm hard gate may be too nonsmooth for local search. The
diagnostic uses a log-sum-exp objective with beta `8`; the best smooth value was
`14.5755388982`, but the associated hard objective remained
`8.61488084949`, so the move was not accepted into the reduced model. This
rules out the current 48-parameter smooth scalar path as an immediate fix, but
it remains useful as a diagnostic for future table/quadrature optimizers.

The active table-entry search has also been made less brute-force. It now builds
an ordered candidate list from the current worst case by tracing the
pressure/temperature/H2O interpolation stencil touched by the accepted
pressure-band moves and ranking entries by interpolation weight and gas amount.
A helper-level verification generated `1155` targeted candidates for the
`ecckd_rcemip_style_column_subset` blocker and, with a 32-candidate cap,
accepted one full-objective-improving move. The objective change was only
`8.61316394314476` to `8.613163943139266`, so this is a useful implementation
and profiling improvement, not a scientific unlock for the hard threshold.
A dedicated narrow artifact now records this path:
`validation/results/reduced_ecckd_targeted_entry_refinement.*`. With a
256-candidate cap and two active-entry iterations it found two targeted
entry moves, improving the pressure-refined objective to `8.61303768346`
(`1.26259689353e-4` absolute improvement). A later full diagnostic run with the
active table-entry loop enabled exceeded the interactive runtime window inside
that expensive stage. The canonical
`validation/results/reduced_ecckd_optimization_preflight.*` artifacts were
therefore regenerated with `RH_REDUCED_ACTIVE_TABLE_ENTRY_ITERATIONS=0`, and
now show a completed table-refined objective of `8.60500733608`.
An expanded 512-candidate targeted-entry run was also checked with progress
reporting and a wall-time cap. It reached `8.6130383086`, slightly worse than
the 256-candidate two-move artifact, so the targeted active-entry cap is not
the reason this path stalls. The active-entry validation loop now has opt-in
`RH_REDUCED_ACTIVE_TABLE_ENTRY_PROGRESS` and
`RH_REDUCED_ACTIVE_TABLE_ENTRY_MAX_SECONDS` controls for wider sweeps.

The pressure-band-local active-entry limit was then relaxed in
`validation/results/reduced_ecckd_global_entry_refinement.*`. This artifact
ranks all table entries touched by the current worst-case interpolation stencil
across all 16 reduced shortwave slots, not just entries inside the accepted
pressure-band moves. The first 256 perturbations found only a tiny improvement
(`8.61303768346` to `8.61302520165`), but adding an offset control exposed more
useful later ranked windows. Offsets 256, 512, 768, 1024, 1280, 1792, and 2048
each accepted one move, while offset 1536 did not. The search now has a
repeatable offset-window sweep mode with configurable stride, window count, and
no-improvement stopping. A four-window automated sweep from offset 2304 accepted
four more moves, bringing the cumulative active-entry count to 14 and the
objective to `8.55869609052`. A later eight-window sweep from offset 3328
accepted seven more moves but improved only to `8.5582182932`, and the
regenerated reduced-accuracy artifact moved only to TOA `2.56746548796` W m^-2
and surface `2.45017530966` W m^-2. A first grouped active-entry block
diagnostic accepted two coherent table-entry moves, and a bounded wider pass
accepted ten more grouped moves. A grouped linearized active-entry refit then
made the only material local-table improvement, reaching a retained objective
of `8.39187324383` with `405` cumulative active-entry moves. The regenerated
reduced-accuracy artifact reports TOA `2.51756197315` W m^-2 and surface
`2.50542662493` W m^-2. Follow-up grouped linearized trust-region attempts were
rejected (`8.39467524724` candidate objective at max log-scale `0.03125`), and
a post-table weight refit also worsened the exact objective (`8.40968478599` to
`8.41012609185`). This remains far above the `<= 1.0` target and now shows
diminishing returns from greedy scalar windows, small grouped blocks, grouped
linearized local table-entry bases, and post-table weight refits. The next
useful step is a proper constrained multi-parameter table optimizer or a
different reduced quadrature parameterization.

An exact post-table shortwave-weight coordinate refit is recorded in
`validation/results/reduced_ecckd_exact_weight_refit.*`. Unlike the surrogate
post-table weight refit, it evaluates every proposed softmax-logit move against
the exact clean ecCKD hard objective. It improved the retained table-refined
state to objective `8.32190990405`, with regenerated reduced-accuracy errors
TOA `2.49657297122` W m^-2 and surface `2.38029831045` W m^-2. A smaller-step
continuation found no further exact-weight improvement, so weight-only tuning
is also at a local limit and still far from the `0.3` W m^-2 threshold.

A coupled post-table diagnostic is recorded in
`validation/results/reduced_ecckd_joint_weight_block_refit.*`. It fits grouped
active-entry table amplitudes and shortwave weight logits in one linearized
system, with the residual focused on the current worst hard-gate metric, then
accepts only after a full nonlinear hard-objective evaluation. The first
trust-region run was rejected: it kept the retained objective at
`8.32190990405`, while the best candidate worsened to `9.31858911278`. This
rules out the immediate "co-adjust weights while making another local grouped
table move" escape route and reinforces that the next reduced-shortwave work
needs a constrained table/quadrature optimizer rather than more local scaling
around the current 16-point topology.

A boundary-column local scan is recorded in
`validation/results/reduced_ecckd_boundary_column_refinement.*`. It identifies
the column producing the current worst boundary forcing error, scans active
coefficient-table entries used by that column, and accepts only moves that
reduce the full normalized hard objective. Three bounded continuation passes
accepted one move each, and a wider fourth pass accepted one additional tiny
move, raising the cumulative active-entry move count to 409
and reducing the retained objective from `8.32190990405` to
`8.3214840192`. The regenerated reduced-accuracy artifact moved only
slightly, to TOA `2.49644520576` W m^-2 and surface `2.37992030034` W m^-2.
This is a real accepted improvement, but it is far too small to close the
`0.3` W m^-2 hard threshold and further supports moving to a constrained
multi-parameter table/quadrature optimizer.

A slot-blend table/quadrature diagnostic is recorded in
`validation/results/reduced_ecckd_slot_blend_refinement.*`. It convexly blends
one optimized reduced shortwave slot toward a nearby full official ecCKD
g-point table and accepts only after a nonlinear hard-gate evaluation. Earlier
local continuations around g25 produced only `O(1e-5)` objective improvements.
After the constrained-table and post-constrained-weight state was propagated,
a wider aligned scan with radius `31` and blend alphas
`0.00390625,0.0078125,0.015625,0.03125` accepted one blend from g12 toward
g26 at alpha `0.03125`, reducing the objective from `8.05252179968` to
`8.02746921371`. Six additional accepted continuations brought the total
accepted blend count to seven and reduced the objective to `7.47836712724`;
the regenerated reduced-accuracy artifact now reports TOA `2.24351013817`
W m^-2 and surface `2.10248332807` W m^-2 before the later post-slot weight
refit. This remains far outside the `0.3` W m^-2 hard boundary thresholds.
Follow-up
small-alpha single-slot and ranked pair-slot diagnostics were rejected from the
seven-blend state: the best single candidate worsened the objective to
`8.39717935543`, and the best pair candidate worsened it to `9.10566044494`.
A coordinated 32-direction nonnegative linearized slot-blend refit was also
rejected, worsening the objective to `10.8272641841` with TOA `2.78645506239`
W m^-2 and surface `3.24817925524` W m^-2. This rules out the current local
one-slot, two-slot, and linearized multi-slot blend neighborhoods as an
immediate path to the hard gate. A post-slot exact shortwave-weight coordinate
refit was accepted, reducing the objective from `7.47836712724` to
`7.45725553248`; it slightly improved TOA to `2.23717665974` W m^-2 while
raising surface to `2.13957282121` W m^-2. Later post-weight constrained-table
continuations accepted multiple small additional moves. The latest accepted
all-case active-entry continuation reduced the exact objective from
`7.42495140942` to `7.42405122402`, and propagation moved the canonical row to
TOA `2.2256780832` W m^-2 and surface `2.03691157366` W m^-2. This remains far
above the hard boundary thresholds.

A boundary-column block scan is recorded in
`validation/results/reduced_ecckd_boundary_column_block_refinement.*`. It
groups entries used by the current worst boundary column and applies one
coherent nonnegative scale to a block of table entries, accepting only if the
full hard objective improves. Two continuation passes accepted four-entry
static-absorption blocks, raising the cumulative active-entry move count to
417 and reducing the retained objective to `8.32133115454`. The regenerated
reduced-accuracy artifact reports TOA `2.49639587668` W m^-2 and surface
`2.37933472152` W m^-2. This is larger than the single-entry and slot-blend
tails, but still only changes the boundary error by `O(1e-4)` W m^-2, so local
entry/block scaling is not a practical route to the `0.3` W m^-2 hard gate.

A gas-specific pressure-band scan is recorded in
`validation/results/reduced_ecckd_gas_pressure_band_refinement.*`. It applies
one nonnegative scale to a selected gas/slot/pressure-band block in the current
reduced shortwave table and accepts only full-hard-objective improvements. Two
4-band passes plus two finer 8-band passes accepted dynamic-H2O and
static-absorption band moves, reducing the retained objective to
`8.32070420146`. The regenerated reduced-accuracy artifact reports TOA
`2.49621126044` W m^-2 and surface `2.37899445235` W m^-2. This is the
strongest of the recent local table
diagnostics, but the improvement is still `O(1e-4)` in normalized objective per
accepted move and does not change the conclusion: the remaining gap requires a
larger constrained table/quadrature optimizer.

A joint linearized gas-pressure-band refit is recorded in
`validation/results/reduced_ecckd_gas_pressure_band_linearized_refit.*`. It
finite-differences the top gas/slot/pressure-band bases for the current worst
boundary residual and solves a ridge-regularized update before evaluating the
nonlinear hard objective. A normal trust region overshot badly, and a much
smaller trust region still worsened the objective from `8.32070420146` to
`8.32072913222`; no joint gas-band move was accepted. This rules out a simple
linearized combination of the recent gas-band directions.

A flux-profile-paired 16-bin topology diagnostic is recorded in
`validation/results/reduced_ecckd_flux_pair_bins.*`. It pairs official
shortwave g-points by similarity of their single-gpoint flux, heating-rate,
and boundary-flux profiles on the reduced validation cases, then evaluates a
16-bin spectral-weighted coefficient average. This topology failed with
objective `25.9698388366`, TOA `2.92219038192` W m^-2, and surface
`7.79095165097` W m^-2, worse than the current optimized weighted-greedy
topology. This rules out simple flux-profile pairing as the missing 16-bin
quadrature construction.

A fixed-topology simplex-weight diagnostic is recorded in
`validation/results/reduced_ecckd_weight_maxnorm_refit.*`. It keeps the
current table-refined 16-g shortwave optical properties fixed and tries
projected p-norm (`p = 16, 32, 64`) and direct max-norm weight refits against
hard-gate-scaled flux, heating-rate, and boundary residuals. The best exact
candidate is the `p = 64` refit, but it worsens the accepted hard objective
from `8.32070420146` to `8.32119834731` despite a tiny weight perturbation
(`max |delta w| = 8.75359138924e-7`). The direct max-norm candidate improves
the linearized residual surface but worsens the nonlinear exact objective.
This rules out another fixed-topology shortwave weight solve as the missing
step; the remaining gap still points to a constrained coefficient-table or
quadrature-bin optimizer.

The first bounded multi-parameter constrained table optimizer is recorded in
`validation/results/reduced_ecckd_constrained_table_optimizer.*`. It builds a
linearized residual system for the current hard-gate-scaled shortwave flux,
heating-rate, and boundary errors with respect to active nonnegative
table-entry log-scale parameters, solves ridge-regularized bounded updates, and
accepts only after evaluating the nonlinear full hard objective. The initial
8-candidate run was accepted but only reduced the objective by `2.187806178e-6`.
A 24-candidate continuation improved the objective to `8.32069451307`; a
64-candidate continuation found a stronger accepted ridge-`100` update,
reducing the exact objective from `8.32069616378` to `8.32048206811`. A
256-candidate continuation also accepted, with standalone optimizer objective
`8.32031491548`, but the propagated reduced-accuracy artifact only moved to
TOA `2.49615084763` W m^-2 and surface `2.37799777619` W m^-2. A follow-up
`global_active` 64-basis run ranked active entries across the selected
shortwave g-points rather than only around prior pressure-band moves. It
accepted a ridge-`1` update and reduced the standalone exact objective from
`8.32050284039` to `8.32033427487`, with standalone TOA and surface errors
`2.49610028246` W m^-2 and `2.32927322341` W m^-2. After propagation through
`validation/results/reduced_ecckd_accuracy.*`, the retained 32x16
table-refined candidate reports TOA `2.49620320659` W m^-2 and surface
`2.33025155795` W m^-2. A wider `global_active` 128-basis continuation accepted
a ridge-`100` update, lowering the standalone exact objective from
`8.3206773553` to `8.30478534412`; after propagation, the retained 32x16 row
improved to TOA `2.49279961294` W m^-2 and surface `2.30609754397` W m^-2.
The constrained optimizer artifact now records cumulative active moves, and
the reduced-accuracy reader consumes those cumulative moves; this fixes the
previous continuation bookkeeping issue where a later continuation could
overwrite earlier accepted constrained moves. Two additional cumulative
absorption-only continuations reduced the standalone exact objective to
`8.25126395105`; after propagation, the retained 32x16 row reports TOA
`2.47084600351` W m^-2 and surface `2.29705580933` W m^-2. A forced Rayleigh
basis experiment was rejected by the exact hard objective: it reduced TOA but
worsened the surface error enough to raise the full objective. Two larger
trust-region continuations with `max_log_scale = 0.25` and `0.5` were accepted,
followed by a wider 256-candidate global-active constrained continuation. The
latest constrained artifact has standalone exact objective `8.05252310077`. The
current propagated constrained-only hard-objective row is TOA
`2.41575693023` W m^-2 and surface `2.34200627002` W m^-2. A later accepted
slot-blend continuation followed by accepted post-slot weight refit improves
the canonical propagated row to TOA `2.23717665974` W m^-2 and surface
`2.13957282121` W m^-2. A post-weight
global-active constrained-table pass with 256 candidates, probe step
`0.0078125`, max log scale `0.015625`, and Rayleigh excluded was accepted:
it reduced the exact objective from `7.45725553248` to `7.45473084843`.
Repeating the same trust region was rejected by `9.17287271029e-7`, but a
512-candidate continuation with probe step `0.00390625` and max log scale
`0.0078125` was accepted, reducing the exact objective to `7.45311736945`.
A second continuation with the same settings was also accepted against the
tropical-column TOA blocker, reducing the exact objective from `7.45315620432`
to `7.44992897999` and propagating the canonical row to TOA
`2.23497889836` W m^-2 and surface `2.11026354956` W m^-2. A third continuation
accepted another smaller ridge-`0.01` move, reducing the exact objective from
`7.44992966121` to `7.44905450492`. After a canonical-neutral post-slot weight
refit, a ridge-`10000` constrained-table continuation reduced the exact
objective from `7.44913935347` to `7.44758604447`, and a further ridge-`100`
continuation reduced it from `7.44758531552` to `7.44579427719`. Another
ridge-`10000` continuation against the tropical-column TOA blocker reduced the
exact objective from `7.44583261873` to `7.44293542812`. Another accepted
ridge-`10000` continuation reduced it from `7.44293607757` to
`7.44185065131`. A further ridge-`100` continuation against the RCEMIP-style
TOA blocker reduced it from `7.44184995142` to `7.4399830226`. A later
ridge-`10000` continuation against the tropical-column TOA blocker reduced it
from `7.44002111377` to `7.437447312`. Another ridge-`10000` continuation
reduced it from `7.43744793535` to `7.43567711556`. A further ridge-`100`
continuation reduced it from `7.43567644299` to `7.43484277744`; a later
ridge-`10000` continuation reduced it from `7.43488064123` to `7.432585338`;
another ridge-`10000` continuation reduced it from `7.43258593814` to
`7.43042476955`. Another ridge-`0.01` continuation reduced it from
`7.43042536082` to `7.42956116297`; a later ridge-`10000` continuation
reduced it from `7.42964657597` to `7.42818441105`. Propagation moved the
canonical row to TOA `2.22845513068` W m^-2 and surface `2.02225151834`
W m^-2. A further ridge-`100` continuation reduced the hard objective from
`7.42818376892` to `7.42746289838` and moved the canonical row to TOA
`2.22825008823` W m^-2 and surface `2.02258910414` W m^-2. The first
all-case active-entry candidate scope then reduced the hard objective from
`7.42750029409` to `7.42580418685` and moved the canonical row to TOA
`2.22776343615` W m^-2 and surface `2.01695534197` W m^-2. A second all-case
continuation reduced it from `7.42587812049` to `7.42495844869` and moved the
canonical row to TOA `2.22748542282` W m^-2 and surface `2.01450427629`
W m^-2. A third all-case continuation reduced it from `7.42495140942` to
`7.42405122402` and moved the canonical row to TOA `2.22722725968` W m^-2 and
surface `2.01854191287` W m^-2. A further all-case continuation reduced the
scalar hard objective from `7.42409086559` to `7.42387283421`, improving TOA
to `2.22717371848` W m^-2 while worsening surface to `2.02275441801` W m^-2
after propagation. The constrained-table optimizer now also exposes an
`all_global_residual_probe` candidate scope that ranks the global active-entry
pool by direct residual reduction from small positive/negative probes before
the ridge solve. The accepted 32-candidate residual-probe continuation reduced
the scalar hard objective from `7.42391239493` to `7.42257406679`; propagation
moved the canonical row to TOA `2.22677737752` W m^-2 and surface
`2.01973131819` W m^-2. A wider 64-candidate residual-probe continuation then
reduced the scalar hard objective from `7.4225912584` to `7.42094851978` and
propagated to TOA `2.22628464061` W m^-2 and surface `2.01728018333` W m^-2.
The follow-up smaller-trust-region residual-probe continuation reduced the
scalar hard objective only from `7.42094880204` to `7.42093181466`, propagating
to TOA `2.22627954518` W m^-2 and surface `2.01725576134` W m^-2; this tiny
gain indicates the local non-Rayleigh residual-probe basis is nearly exhausted.
A Rayleigh-inclusive residual-probe continuation then reduced the scalar hard
objective from `7.42093181726` to `7.41977527859`. Propagation improved TOA to
`2.2256780832` W m^-2 but worsened surface to `2.03691157366` W m^-2, so this
is scalar-objective progress rather than a Pareto improvement of both boundary
metrics. A direct hard-objective probe scope was added for future experiments,
but its first 16-candidate Rayleigh-inclusive no-write smoke was rejected
(`7.418926943997235` to `7.466967894987515`), so it should not replace the
current residual-probe evidence without a different acceptance strategy.
The boundary-aware post-constrained weight refit reduced the max normalized
TOA/surface boundary objective from `7.418926943997235` to `7.355912280200036`
and is surfaced as a main reduced-accuracy candidate row. A smaller-step
continuation from the latest accepted boundary weights reduced the reported
boundary objective to `7.311608077751165`; a half-step continuation reduced it
to `7.297431753704113`; and a final quarter-step continuation only reduced it
to `7.297425585382674`, with TOA `2.18922717474` W m^-2 and surface
`2.18922767561` W m^-2. This is useful diagnostic progress but remains far
outside the hard boundary thresholds, and the tiny final improvement indicates
that the weight-only boundary refit is now near its local limit.
The constrained-table optimizer now has an explicit `boundary_weight_refit`
base mode so future experiments can linearize from this boundary-aware
candidate instead of implicitly falling back to the canonical table-refined
base. Two no-write smoke checks from that base were rejected: the
Rayleigh-inclusive residual-probe scope moved from base objective
`8.1744100491` to `8.40832544635`, and the Rayleigh-inclusive hard-objective
probe scope moved from `8.1744100491` to `8.40817407863`. This confirms the
base-mode plumbing but does not provide a new accepted reduced-accuracy row.
Rayleigh-inclusive probe ranking was also changed so Rayleigh entries are
selected by signed probe response instead of sign-blind scattering magnitude.
A no-write canonical residual-probe smoke with this ranking was still rejected
(`7.60536000232` to `7.82401039417`), so the Rayleigh path remains diagnostic
rather than accepted evidence.
After the final boundary-weight continuation, a constrained-table continuation
from `base_mode = boundary_weight_refit` found only a tiny absorption-only
descent direction (`7.297425585382674` to `7.297423915802787`, surface
`2.18230029605` W m^-2 while TOA remained `2.18922717474` W m^-2). It was
promoted into a separate boundary-base continuation artifact,
`validation/results/reduced_ecckd_boundary_base_constrained_table_optimizer.*`,
and is now surfaced as a reduced-accuracy row. It is useful provenance for the
current best diagnostic row, but the improvement is far too small to change the
Step 2 acceptance status.
The prior post-blend
constrained-table pass had been
rejected by only `6.75368454495e-7`, so the basis is not dead, but the accepted
movement remains small. This is still far
above the `0.3` W m^-2 hard
threshold. The executable parameterization is now working, but the current
active-entry basis is flattening. A useful next version needs a richer
constrained table/quadrature basis, not just active entries around the current
16-point topology.
The constrained-table residual/objective probe loop now has opt-in progress
and a wall-clock cap via `RH_REDUCED_CONSTRAINED_TABLE_PROGRESS` and
`RH_REDUCED_CONSTRAINED_TABLE_MAX_PROBE_SECONDS`, so wider candidate-pool
experiments can be run without silent long hangs. A 64-candidate boundary-base
no-write residual-probe smoke with an eightfold probe pool and a 180-second
probe cap evaluated 188 of 512 probe candidates and was rejected: it worsened
the exact objective from `7.297425585382674` to `7.300004150630836`, with TOA
`2.18985710886` W m^-2 and surface `2.19000124519` W m^-2. This confirms that
simply widening the same residual-probe active-entry basis is not enough.
The constrained-table optimizer also has
`RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE=boundary`, which fits only
TOA/surface boundary residuals in the linearized system while retaining exact
full hard-objective acceptance. A bounded no-write boundary-mode smoke with 32
final candidates, an eightfold probe pool, and a 180-second probe cap was also
rejected: it worsened the exact objective from `7.297425585382674` to
`7.2992044158165`; surface improved to `2.18694644467` W m^-2, but TOA
worsened to `2.18976132474` W m^-2. This confirms that focusing the same
active-entry basis on boundary residuals alone is still not enough.
The retained boundary-base artifact now uses the narrower
`RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE=toa` path. It improves the
nonlimiting surface error to `2.18230029605` W m^-2 while leaving the limiting
TOA error unchanged at `2.18922717474` W m^-2, so it improves provenance but
does not change the failed Step 2 status.
A Rayleigh-inclusive direct exact coordinate scan from the boundary-base table
state is recorded in
`validation/results/reduced_ecckd_boundary_table_coordinate_scan.*`. It
evaluated 48 active-entry candidates, including all 16 Rayleigh slots, and 384
signed scale trials against the full hard objective. It was accepted: the best
objective improved from `7.2974239158` to `7.29601319503`, TOA improved from
`2.18922717474` to `2.18880395851` W m^-2, and surface moved to
`2.18229916327` W m^-2. This is real progress, but it remains far above the
`0.3` W m^-2 threshold.
A paired exact coordinate scan is recorded in
`validation/results/reduced_ecckd_boundary_table_pair_coordinate_scan.*`. It
ranked 384 single-coordinate trials, retained the best 16, and evaluated
120 exact move pairs. It was accepted but only made a marginal Rayleigh
adjustment: the best pair improved objective from `7.29601319503` to
`7.29587581499`, TOA from `2.18880395851` to `2.1887627445` W m^-2, and
surface from `2.18229916327` to `2.18229856753` W m^-2. This keeps the best
retained row current, but rules out simple pairwise active-entry coordinate
search as sufficient around the retained state.
A bounded exact coordinate-descent continuation is recorded in
`validation/results/reduced_ecckd_boundary_table_coordinate_descent.*`. It
starts from the retained non-recursive boundary-table state, including the
accepted single and pair Rayleigh moves, and accepts only full-hard-objective
improvements. With six iterations it accepted additional static-absorption
and Rayleigh moves; objective moved from `7.29587581499` to `7.29585929551`,
TOA from `2.1887627445` to `2.18875778865` W m^-2, and surface from
`2.18229856753` to `2.18224163998` W m^-2. This is retained in
`validation/results/reduced_ecckd_accuracy.*`, but it confirms that local
active-entry coordinate descent is now producing only marginal changes.
An exact top-16 triple-coordinate scan is recorded in
`validation/results/reduced_ecckd_boundary_table_triple_coordinate_scan.*`.
After correcting the base to include the retained coordinate-descent moves, it
improved the normalized objective by only `6.53993037503e-09` and TOA by only
`1.96197991156e-09` W m^-2. This is numerical-noise scale relative to the
`0.3` W m^-2 threshold and is not promoted into the retained model; it is
evidence that the current local active-entry basis is exhausted.
A grouped-quadrature search is recorded in
`validation/results/reduced_ecckd_grouped_quadrature_search.*`. It generates
deterministic 16-bin pairings from flux, heating-rate, and boundary-flux
feature scalings and exact-evaluates each grouped spectral-weighted coefficient
table. The best grouped candidate still fails with normalized objective
`16.0106691529`, TOA forcing `2.43386896118` W m^-2, and surface forcing
`4.80320074587` W m^-2. This rules out the tested simple grouped-pair
quadrature definitions as a replacement for the retained table-entry path.
A wider constrained continuation with exact-objective candidate probing is
recorded in
`validation/results/reduced_ecckd_boundary_table_continuation_optimizer.*`.
It starts from the retained boundary-table state, evaluates 690 of 784
objective-probe candidates under the bounded probe cap, keeps 64 directions
with Rayleigh enabled, and allows `0.125` log-scale moves.
It was re-run from the explicit non-recursive `boundary_table_post_descent`
base after fixing the composition order, and only improved the normalized objective from
`7.29585929551` to `7.29585913012`, with TOA moving from `2.18875778865` to
`2.18875773904` W m^-2 and surface unchanged at `2.18224163998` W m^-2. This
also confirms diminishing returns in the current active-entry parameterization.

A whole-component scale refit is recorded in
`validation/results/reduced_ecckd_component_scale_refit.*`. It starts from the
explicit non-recursive post-descent-plus-continuation base and exact-coordinate
descends 48 per-g-point component scales: static absorption, H2O absorption, and
Rayleigh scattering. The retained 12-move run improves the normalized objective
from `7.29585913012` to `7.13988657025`, with TOA moving from
`2.18875773904` to `2.14196597108` W m^-2 and surface from
`2.18224163998` to `2.14149643678` W m^-2. This is promoted into
`validation/results/reduced_ecckd_accuracy.*`, but still fails the `0.3`
W m^-2 hard boundary thresholds by about a factor of seven.

A pressure-band component scale refit is recorded in
`validation/results/reduced_ecckd_pressure_component_scale_refit.*`. It starts
from the retained whole-component scale-refit model and scans 8 pressure bands
for static and H2O absorption on the component-refit-selected g-points. The
two accepted moves reduce the normalized objective only from `7.13988657025`
to `7.13985474639`, with TOA moving from `2.14196597108` to
`2.14195642392` W m^-2 and surface moving slightly upward from
`2.14149643678` to `2.14151134197` W m^-2. This is retained because the hard
max objective improves, but it shows pressure-band component scaling is a
marginal local refinement rather than a route to the hard threshold.

A temperature-band component scale refit is recorded in
`validation/results/reduced_ecckd_temperature_component_scale_refit.*`. It
starts from the retained pressure-component model and exact-coordinate scans 8
temperature bands for static and H2O absorption on the g-points touched by the
previous component refits. The two accepted moves reduce the normalized
objective only from `7.13985474639` to `7.13985031352`, with TOA moving from
`2.14195642392` to `2.14195509406` W m^-2 and surface moving slightly upward
from `2.14151134197` to `2.14151750391` W m^-2. This is promoted into the
retained 32x16 row, but the tiny gain reinforces that pressure/temperature
component scaling is now saturated.

An H2O-bin component scale refit is recorded in
`validation/results/reduced_ecckd_h2o_component_scale_refit.*`. It starts from
the retained temperature-component model and scans the dynamic shortwave H2O
table along the tabulated H2O dimension. One accepted move reduces the
normalized objective only from `7.13985031352` to `7.13985029559`, with TOA
moving from `2.14195509406` to `2.14195508868` W m^-2 and surface from
`2.14151750391` to `2.14151611111` W m^-2. This is retained for consistency,
but it effectively rules out simple per-axis component scaling as the next
path to the hard reduced threshold.

A gas-specific component scale refit is recorded in
`validation/results/reduced_ecckd_gas_component_scale_refit.*`. It starts from
the retained H2O-component model and exact-coordinate scans static shortwave
absorption scales by gas on the g-points selected by the whole-component refit.
One accepted move reduces the normalized objective only from `7.13985029559`
to `7.13985029534`, with TOA moving from `2.14195508868` to
`2.1419550886` W m^-2 and surface from `2.14151611111` to
`2.14151605089` W m^-2. This effectively rules out gas-specific scalar
component scaling as a material route to the hard reduced threshold.

A coupled pressure-temperature component scale refit is recorded in
`validation/results/reduced_ecckd_pressure_temperature_component_scale_refit.*`.
It starts from the current gas-component model and scans coherent pressure-
temperature blocks rather than pressure-only or temperature-only axes. One H2O
block moves on local g-point 2 reduce the diagnostic full objective from
`8.7693298333` to `7.51009497583`, improving surface forcing from
`2.63079894999` to `2.11797107456` W m^-2 while leaving TOA as the dominant
error at `2.25302849275` W m^-2. These moves are retained in the current artifact
because it improves the current exact objective, but it remains far above the
`0.3` W m^-2 hard threshold and does not change the conclusion that a richer
table/quadrature optimizer is required.

The follow-on pressure-temperature component refinements are recorded in
`validation/results/reduced_ecckd_gas_pressure_temperature_component_scale_refit.*`,
`validation/results/reduced_ecckd_h2o_pressure_temperature_component_scale_refit.*`,
and `validation/results/reduced_ecckd_mixed_pressure_temperature_component_refit.*`.
Gas-specific static absorption moves on local g-point 14, H2O
pressure-temperature-humidity moves on local g-point 2, and a mixed scan over
those two families reduce the retained row to TOA `2.22017222168` W m^-2 and
surface `2.21975914487` W m^-2. This is a retained improvement, but it also
shows the local block-scaling plateau: both boundary errors remain roughly
7.4 times the `0.3` W m^-2 hard threshold. The next reduced-accuracy attempt
should therefore change parameterization to a non-local coefficient-table,
flux/heating-residual, or quadrature-bin optimizer rather than continuing
single-family local block scans.

A retained all-shortwave residual structural optimizer is recorded in
`validation/results/reduced_ecckd_retained_structural_optimizer.*` and is now
consumed by the canonical reduced accuracy path after the pressure-temperature
retained chain. It starts from the mixed pressure-temperature retained model,
probes all globally active table entries with shortwave flux/heating/boundary
residuals, accepts 12 constrained nonnegative table moves, and improves the
retained objective from `7.40057407226` to `7.25884945943`. The regenerated
32x16 reduced row improves to TOA `2.17765483783` W m^-2 and surface
`1.98402949915` W m^-2. A smaller-trust-region retained structural continuation
is recorded in
`validation/results/reduced_ecckd_retained_structural_continuation.*`; it
starts from the retained structural model, accepts 12 additional constrained
table moves, and improves the row again to TOA `2.16709085767` W m^-2 and
surface `1.975674676` W m^-2. A second smaller-trust-region retained structural
continuation is recorded in
`validation/results/reduced_ecckd_retained_structural_continuation2.*`; it
accepts 12 more constrained table moves and improves the scalar retained
objective to `7.20640276684`, with TOA `2.16192083005` W m^-2 and surface
`1.99434663304` W m^-2. A third smaller-trust-region continuation is recorded
in `validation/results/reduced_ecckd_retained_structural_continuation3.*`; it
accepts 12 more constrained table moves and improves the scalar retained
objective to `7.19781262031`, with TOA `2.15934378609` W m^-2 and surface
`2.01670606591` W m^-2. A fourth smaller-trust-region continuation is recorded
in `validation/results/reduced_ecckd_retained_structural_continuation4.*`; it
accepts 12 more constrained table moves and improves the scalar retained
objective to `7.19352418454`, with TOA `2.15805725536` W m^-2 and surface
`2.02792974588` W m^-2. These are the first material non-local improvements
after the local block/topology plateau, but the retained reduced row remains
far outside the `0.3` W m^-2 hard threshold and is now clearly trading surface
error upward for small TOA/scalar-objective gains.

Four expanded retained objective-probe table updates are recorded in
`validation/results/reduced_ecckd_retained_objective_probe_expansion*.{json,md}`.
They use exact hard-objective single-coordinate probes to select
table/Rayleigh candidates, then solve bounded multi-parameter residual updates.
The accepted moves improve the retained objective from `7.19352418454` to
`7.17183877799`, with TOA `2.1515516334` W m^-2 and surface
`2.12090329129` W m^-2. A follow-on surface-residual table update in
`validation/results/reduced_ecckd_retained_surface_probe_expansion.*`
improves the retained objective to `7.15275906225`, with TOA
`2.14582771868` W m^-2 and surface `2.07301164631` W m^-2. A second
surface-residual update in
`validation/results/reduced_ecckd_retained_surface_probe_expansion2.*`
improves the retained objective to `7.14881462481`, with TOA
`2.14464438744` W m^-2 and surface `2.06161728409` W m^-2. A third
surface-residual update in
`validation/results/reduced_ecckd_retained_surface_probe_expansion3.*`
improves the retained objective to `7.14795534014`, with TOA
`2.14438660204` W m^-2 and surface `2.05760969562` W m^-2. A TOA-residual
diagnostic in `validation/results/reduced_ecckd_retained_toa_probe_expansion.*`
improves the scalar objective to `7.13146967612`, with TOA
`2.13944090284` W m^-2 but regresses surface to `2.07939172665` W m^-2; it is
therefore retained as diagnostic evidence and is not promoted into the
canonical reduced-accuracy row. The canonical moves are promoted with
`RH_REDUCED_IGNORE_RETAINED_OBJECTIVE_PROBE_EXPANSION{,2,3,4}=true` guarding the
objective-probe optimizer artifacts and
`RH_REDUCED_IGNORE_RETAINED_SURFACE_PROBE_EXPANSION{,2,3}=true` guarding the
surface-probe optimizer artifacts against self-dependency when they are rerun.

The boundary-table topology replacement diagnostic was rerun after promoting
the component/axis/gas refits into the retained model. The current-base radius-2
single-slot replacement artifact,
`validation/results/reduced_ecckd_boundary_topology_replacement.*`, now starts
from objective `7.13985029534`; all 33 candidates are worse, with the best
replacement `g16 -> g18` at objective `8.91143243322`. This rules out a simple
neighboring one-slot replacement around the fully retained local model.

A boundary-table topology-plus-weight-refit diagnostic is recorded in
`validation/results/reduced_ecckd_boundary_topology_weight_refit.*`. It replaces
one radius-2 neighboring shortwave slot in the retained boundary-aware model,
then refits the 16 shortwave weights with the hard-gate max-norm weight solver
before exact evaluation. The first 12 candidates were all rejected; the best
candidate worsened the full hard objective from `8.7693298333` to
`43.5953802998`. This rules out the cheap fairer variant of one-slot topology
replacement plus weight refit.

A grouped-quadrature weight refit is recorded in
`validation/results/reduced_ecckd_grouped_quadrature_weight_refit.*`. It keeps
each deterministic 16-bin grouped-quadrature coefficient table fixed but refits
its nonnegative shortwave weights against the hard-gate-scaled shortwave flux,
heating-rate, and boundary residual basis before exact evaluation. The best
grouped candidate improves from objective `16.0106691529` to
`15.5327466353`, with TOA forcing error `2.44473581761` W m^-2 and surface
forcing error `4.65982399058` W m^-2. This is far worse than the retained
component/axis/gas-refined 32x16 row, so deterministic pair grouping plus
weight refit is not the reduced-threshold path.

A sparse hard-gate flux-basis support diagnostic is now recorded in
`validation/results/reduced_ecckd_hardgate_subset_search.*`. It searches
nonnegative 16-term supports over the full 32 official shortwave g-point flux
responses and exact-checks the selected support through the normal tabulated
model path. The bounded smoke improved its raw-start exact objective but still
failed badly: exact objective `89.1338250789`, TOA forcing error
`7.39985344849` W m^-2, and surface forcing error `16.536096435` W m^-2. This
does not compete with the current table-refined boundary-aware row; it is kept
as a negative feasibility diagnostic showing that raw sparse flux-basis support
search is not a useful promotion path without the stronger coefficient-table
optimization layer.

A current-boundary-model topology replacement diagnostic is recorded in
`validation/results/reduced_ecckd_boundary_topology_replacement.*`. It starts
from the boundary-aware table-continuation model and replaces one shortwave
slot at a time with the raw official table for a radius-2 neighboring g-point.
All 33 candidates were rejected; the best replacement (`g16 -> g18`) worsened
the normalized objective from `7.2974239158` to `8.89421612255`. This rules out
the simplest "swap one current optimized slot to a nearby official g-point"
escape route.

A current-state Rayleigh-inclusive constrained continuation was rejected. With
Rayleigh candidates enabled, 384 candidates, `max_log_scale = 0.0625`, and high
ridge regularization, the best exact candidate worsened the objective from
`8.05252310077` to `8.67034447233`; TOA rose to `2.45447725796` W m^-2 and
surface rose to `2.6011033417` W m^-2. This rules out simply adding Rayleigh
active entries to the current local basis as an immediate reduced-accuracy fix.

A retained-base constrained table refit was also rerun from the fully promoted
boundary-table-continuation plus component/axis/gas-refit model. With 96
residual-probed candidates, Rayleigh enabled, boundary residuals, probe step
`0.001953125`, and `max_log_scale = 0.015625`, the best ridge candidate
worsened the exact objective from `7.13985029534` to `7.22878936628`. This
records that the current linearized active-entry basis is exhausted at the
latest retained state.

A separate alternate-topology constrained diagnostic is recorded in
`validation/results/reduced_ecckd_topology_constrained_optimizer.*`. It applies
the same exact-acceptance constrained active-entry optimizer to three 16-g
topologies from the subset-search artifact without overwriting the canonical
reduced model. All three are worse than the canonical topology: the best,
`subset_search_boundary_weight_30`, still has objective `23.3015949902`, TOA
`6.99047849707` W m^-2, and surface `6.84847043029` W m^-2. This rules out
the currently known subset-search alternate topologies as an immediate route;
the next structural attempt should build a new quadrature/table
parameterization rather than reuse those fixed subsets.

A post-constrained shortwave weight refit is recorded in
`validation/results/reduced_ecckd_post_constrained_weight_refit.*`. It refits
only the 16 quadrature weights after applying the cumulative constrained table
moves. The exact hard objective improves from `8.19724182888` to
`8.18337001211` in the first accepted run, then from `8.10742845726` to
`8.08563208793` after a later constrained continuation. The latest conservative
high-ridge constrained continuation improved the standalone objective to
`8.05252310077`; a follow-up weight refit was neutral, so the current
post-weight row remains far outside the hard gate: TOA `2.41575693023` W m^-2
and surface `2.34200627002` W m^-2 against `0.3` W m^-2 thresholds. The
canonical reduced-accuracy artifact then applies the accepted slot-blend
continuations, post-slot weight refit, and the accepted post-weight
constrained-table continuations described above, yielding TOA `2.2256780832`
W m^-2 and surface `2.03691157366` W m^-2.
This is useful diagnostic evidence, but it should not replace the canonical
reduced-accuracy row unless the acceptance policy changes from hard boundary
thresholds to scalar objective reduction.

A larger-size shortwave diagnostic is recorded in
`validation/results/reduced_ecckd_size_weight_refit.*`. It refits only the
shortwave weights for simple 16/20/24/28/30-term `even_select` and
`weighted_bins` candidates using the hard-gate-normalized weight objective.
Every candidate still fails. The best refit is the 30-term `even_select`
candidate with objective `44.7702880713`, worst TOA forcing error
`6.66257178559` W m^-2, and worst surface forcing error `13.4310864214`
W m^-2. This rules out naive larger reduced subsets with refit weights as an
intermediate acceptance route; the full 32-term official shortwave remains the
only passing simple size-scan row.

A stronger joint active-entry experiment is recorded in
`validation/results/reduced_ecckd_targeted_entry_linearized_refit.*`. It builds
a normalized shortwave flux/heating/boundary residual vector, finite-differences
the highest-priority targeted table entries, and solves a ridge-regularized
linearized update before evaluating the nonlinear hard objective. With 64 fitted
entries the best accepted candidate reached `8.61303778873`, slightly worse
than the two-step greedy targeted artifact. This suggests the current local
active-entry subspace is exhausted; the next useful reduced-model work should
change the reduced quadrature/table parameterization rather than keep adding
local active-entry scaling variants.

The same linearized idea was then applied to the global all-slot candidate set
from the current best pressure plus three-active-entry state in
`validation/results/reduced_ecckd_global_entry_linearized_refit.*`. With 24
fitted entries, the best ridge candidate worsened the hard objective from
`8.61302520165` to `8.61557365818`, so it was rejected. This rules out the
obvious coordinated linearized all-slot active-entry update as an immediate
escape from the reduced shortwave blocker.

An anchored spectral-order Voronoi bin reduction was added to
`validation/results/reduced_ecckd_accuracy.*` as another structural 32-to-16
quadrature candidate. It keeps the weighted-greedy 16 anchors but assigns every
omitted official shortwave g-point to the nearest anchor in spectral order and
forms spectral-weighted coefficient averages. This also fails badly: worst TOA
forcing error `40.3601966211` W m^-2 and worst surface forcing error
`125.54176579` W m^-2. Together with the adjacent, cumulative-weight,
coefficient-similarity, and anchored-similarity bin failures, this rules out
simple coefficient-averaging bins as the missing reduced-model ingredient.

A topology slot-inheritance diagnostic is recorded in
`validation/results/reduced_ecckd_topology_slot_refit.*`. It evaluates all 33
radius-2 one-g-point neighbors of the weighted-greedy topology while keeping the
optimized local parameter slots, accepted pressure-band moves, and targeted
active-entry moves attached to their local slots. No neighbor improves the
current optimized state: base objective `8.61303768346`, best neighbor
`11.1847870777` (`g16 -> g18`). This rules out nearby one-g-point topology
swaps as an immediate fix, even when they inherit the current optimized
coefficient/table state.

A post-table shortwave-weight refit is recorded in
`validation/results/reduced_ecckd_post_table_weight_refit.*`. It refits only the
16 shortwave weights after applying the current coefficient scales,
pressure-band table moves, and best targeted active-entry moves. The exact hard
objective worsened from `8.61303768346` to `8.61321133639`, with worst TOA
forcing error increasing from `2.58391130504` to `2.58396340092` W m^-2 and
worst surface forcing error increasing from `2.46402531871` to
`2.46450389804` W m^-2. This rules out a post-table weight-only refit as an
acceptance path.

---

## 1. Executive summary

The project should proceed in measured stages. Each stage must have:

1. Passing tests.
2. Documentation.
3. Performance benchmarks.
4. Comparisons with existing/reference codes.
5. Working examples with quantitative success criteria.

The core design should separate:

```text
atmospheric state
    ↓
gas/cloud/aerosol optics
    ↓
optical properties
    ↓
radiative transfer solver
    ↓
fluxes
    ↓
heating rates
```

`RadiativeHeating.jl` should own radiation science, gas optics, solvers, file ingestion, validation, and offline ecCKD model generation. `Breeze.jl` should own the extension that couples RadiativeHeating to Breeze fields, grids, tendencies, scheduling, examples, and application benchmarks.

This division is a design requirement:

```text
RadiativeHeating.jl
    standalone radiation and gas-optics library
    no dependency on Breeze

Breeze.jl/ext/BreezeRadiativeHeatingExt.jl
    Breeze-specific adapter and examples
    weak dependency on RadiativeHeating
```

The main performance ambition is two-tiered:

| Target | Meaning | Goal |
|---|---|---:|
| Similar gas-optics complexity | RRTMGP-like amount of gas-optics work, same column state, same vertical grid, same device, same precision | >= 4x faster than RRTMGP.jl on GPU |
| Reduced ecCKD models | ecCKD 64/32/16-term models, explicitly trading accuracy for speed | much larger speedups, reported as an accuracy/runtime Pareto curve |

The 4x claim must be defended by an apples-to-apples benchmark suite. Reduced-model speedups must be reported together with flux, heating-rate, and forcing errors.

---

## 2. External references and source map

These are the main external sources the implementation should use or compare against.

### 2.1 ecRad

- Repository: https://github.com/ecmwf-ifs/ecrad
- Documentation landing page: https://confluence.ecmwf.int/display/ECRAD
- Key purpose: ECMWF atmospheric radiation scheme.
- Relevant properties:
  - Modular radiation scheme.
  - Supports multiple solver families.
  - Supports gas optics including RRTM-G and ecCKD.
  - Main scientific reference for solver behavior and validation cases.

The ecRad repository points to the Hogan and Bozzo ecRad publications and the ecCKD gas-optics paper. Treat ecRad as the primary reference implementation for solver and gas-optics agreement.

### 2.2 ecCKD

- Repository: https://github.com/ecmwf-ifs/ecckd
- Documentation landing page: https://confluence.ecmwf.int/display/ECRAD/ECMWF+gas+optics+tool%3A+ecCKD
- Key purpose: tool for generating fast k-distribution gas-optics models suitable for ecRad.
- Relevant properties:
  - Generates CKD-definition NetCDF files.
  - Uses correlated-k and optionally full-spectrum correlated-k methods.
  - Requires NetCDF, Adept, CKDMIP software, and CKDMIP spectral absorption database for generation workflows.
  - The CKDMIP spectral absorption database is approximately 700 GB, so CKDMIP-scale tests are heavy/manual, not ordinary CI.

Treat ecCKD first as a producer of files that `RadiativeHeating.jl` can ingest. Only later reimplement model generation.

### 2.3 RRTMGP.jl and RTE+RRTMGP

- RRTMGP.jl docs: https://clima.github.io/RRTMGP.jl/latest/
- RRTMGP.jl repository: https://github.com/CliMA/RRTMGP.jl
- RTE+RRTMGP docs: https://earth-system-radiation.github.io/rte-rrtmgp/
- Key design fact:
  - RRTMGP is naturally split into `Optics`, which computes optical properties and source functions, and `RTE`, which computes radiative fluxes from optical properties.

Use RRTMGP.jl as the main performance baseline in Breeze and as the comparison target for the 4x speedup goal. Do not copy its implementation style; use it as a benchmark and integration reference.

`RadiativeHeating.jl` should also provide an optional RRTMGP extension for
standalone scientific comparisons. When `RRTMGP.jl`, `ClimaComms.jl`, and
`NCDatasets.jl` are loaded, the extension should compute RRTMGP fluxes through
this package's built-in `ColumnAtmosphere` and `RadiativeFluxes` abstractions.
This gives validation code a direct way to compare RadiativeHeating and RRTMGP
on identical package-native single-column or batched-column inputs without
going through Breeze.

Current status: `NumericalRadiationRRTMGPExt` computes RRTMGP clear-sky
fluxes from a `ColumnAtmosphere` into caller-owned `RadiativeFluxes`, and
`radiative_flux_error_metrics` compares RadiativeHeating and RRTMGP fluxes
through all LW/SW up/down components plus flux-divergence heating rates and
net TOA/surface forcing errors.

### 2.4 Breeze.jl

- Repository: https://github.com/NumericalEarth/Breeze.jl
- Documentation: https://numericalearth.github.io/BreezeDocumentation/dev
- Agent rules: https://github.com/NumericalEarth/Breeze.jl/blob/main/AGENTS.md
- Relevant properties:
  - Breeze is a CPU/GPU atmospheric flow package built on Oceananigans.
  - Breeze extends Oceananigans with atmospheric dynamics, thermodynamics, microphysics, and radiation.
  - Breeze already uses package extensions for large optional integrations.
  - Breeze agent rules emphasize KernelAbstractions.jl kernels, type stability, allocation-free kernels, no scalar GPU fallbacks, and concrete typed structs.

The RadiativeHeating extension belongs in Breeze because Breeze is the bigger/end application that owns its model state, fields, tendencies, time stepping, examples, and user-facing radiation components.

### 2.5 Benchmarking and GPU profiling

- CUDA.jl profiling docs: https://cuda.juliagpu.org/stable/development/profiling/
- BenchmarkTools.jl manual: https://juliaci.github.io/BenchmarkTools.jl/stable/manual/
- NVIDIA Nsight Systems / Nsight Compute documentation: https://developer.nvidia.com/nsight-systems and https://developer.nvidia.com/nsight-compute

Benchmark GPU code with synchronized timings and GPU-specific profiling. Do not trust unsynchronized wall-clock measurements. Use `BenchmarkTools` for CPU and controlled timings; use CUDA synchronization, `CUDA.@profile`, Nsight Systems for timeline and launch-overhead analysis, and Nsight Compute for kernel-level occupancy, register, shared-memory, and memory-throughput analysis.

The primary optimization target is NVIDIA H100. Other CUDA GPUs may be used for development and portability checks, but headline speedup claims and frozen GPU performance milestones should be measured on H100 unless the plan is explicitly revised.

Profiling should be used extensively, not only at the end. Nsight Systems and Nsight Compute reports are expected for GPU optimization PRs, frozen regression benchmarks, and final performance claims. Smoke tests and CPU-only runs may omit Nsight artifacts.

---

## 3. Non-negotiable architectural decisions

### 3.1 `RadiativeHeating.jl` must be standalone

`RadiativeHeating.jl` must not depend on Breeze. It should support:

- Single-column tests.
- Batched-column tests.
- CPU and GPU execution.
- ecRad comparison.
- ecCKD file ingestion.
- ecCKD gas-optics models.
- Radiative transfer solvers.
- Offline ecCKD model generation and optimization.
- Differentiable workflows using Enzyme.jl and Reactant.jl.

This allows fast radiation development without loading Breeze or Oceananigans.

### 3.2 The Breeze extension must live in Breeze

The extension should be placed in:

```text
Breeze.jl/ext/BreezeRadiativeHeatingExt.jl
```

not in `RadiativeHeating.jl/ext`.

Rationale:

- Breeze owns its grid layout, field conventions, tendencies, schedules, and examples.
- Breeze is the larger application.
- `RadiativeHeating.jl` should not know about Breeze models.
- The extension surface may need to evolve as Breeze evolves.
- This mirrors the principle that end applications own adapters to libraries.

`RadiativeHeating.jl` should expose stable, standalone APIs that Breeze can call.

### 3.3 Runtime and offline model generation must be separated

There are two distinct paths:

```text
Runtime path:
    fast, typed, allocation-free, GPU-capable, no I/O, Breeze-compatible

Offline generation path:
    data-heavy, CKDMIP-aware, optimization-heavy, may allocate, may perform I/O
```

Breeze should only use the runtime path. It should never know about CKDMIP-scale ecCKD model generation.

### 3.4 Solver must not know where optics came from

The radiative transfer solvers should accept optical properties and source terms independent of whether they came from:

- Analytic bands.
- ecCKD.
- A benchmark-only RRTMGP-compatible model.
- Future gas optics models.

The gas optics and radiative transfer solver layers must remain separate.

### 3.5 Host-model integration must be lightweight and multi-level

`RadiativeHeating.jl` should be easier to couple to host models than RRTMGP-style workflows that require many temporary arrays or a single fixed end-to-end call path. The runtime API must support multiple integration levels:

```text
high-level path:
    atmosphere + optics model + solver -> fluxes/heating rates

mid-level path:
    atmosphere + optics model -> optical properties/source terms
    host model owns solver, vertical integral, or tendency insertion

low-level path:
    preallocated arrays/views + interpolation metadata -> optimized kernels
    host model owns memory layout and scheduling
```

This is required for:

- Breeze, which should be able to inherit highly optimized RadiativeHeating kernels without paying unnecessary packing or temporary-array costs.
- SpeedyWeather and similar models, which may want to use gas optics, source terms, or optical properties while implementing their own solvers, vertical integrals, flux divergence, or tendencies.
- Offline validation tools, which need access to intermediate optical properties and source terms.

The design should expose stable access points at each layer:

```text
state access / column views
gas optical properties
cloud and aerosol optical properties
source terms
radiative transfer solvers
flux accumulation
flux divergence / heating-rate conversion
diagnostics and validation summaries
```

The optional RRTMGP comparison extension should expose the same layered style:

```text
ColumnAtmosphere -> RRTMGP-compatible atmospheric state/workspace
RRTMGP lookup tables + boundary conditions -> RadiativeFluxes
RadiativeFluxes -> RadiationErrorMetrics against RadiativeHeating fluxes
```

It should preallocate RRTMGP state and flux arrays, document any required
top-down/bottom-up convention conversion, and support tests that compute both
models from the same `ColumnAtmosphere`.

Temporary arrays are allowed during setup/materialization, but the runtime path should be written so host integrations can provide preallocated outputs, views, or fused kernels. Any unavoidable temporary array in a hot path must be benchmarked, documented, and justified.

### 3.6 Performance claims must include metadata

Every benchmark report must include:

```text
git SHA / version of RadiativeHeating.jl
git SHA / version of Breeze.jl
git SHA / version of RRTMGP.jl
git SHA / version of ecRad reference if used
Julia version
CUDA version
GPU model
CPU model
precision
number of columns
number of layers
LW band count
LW g/k-term count
SW band count
SW g/k-term count
radiation configuration
cloud/aerosol configuration
compiler flags / environment where relevant
```

Do not hard-code assumptions about RRTMGP or ecCKD spectral counts. Read and report them from the loaded model files.

### 3.7 Metric definitions

Use these definitions unless a later section explicitly says otherwise.

| Metric | Definition |
|---|---|
| `runtime_ms_minimum` | Minimum elapsed time across benchmark samples, excluding setup and file I/O unless the case is explicitly an I/O benchmark. |
| `runtime_ms_median` | Median elapsed time across benchmark samples. This is the default runtime for speedup claims. |
| `runtime_ms_p90` | 90th percentile elapsed time across benchmark samples. |
| `speedup_vs_rrtmgp` | `runtime_ms_median(RRTMGP.jl baseline) / runtime_ms_median(RadiativeHeating.jl case)` for the same device, precision, column count, layer count, radiation configuration, and comparable spectral complexity. |
| coefficient of variation | `std(runtime_ms) / mean(runtime_ms)` over repeated benchmark samples. |
| hot-path allocations | Allocations reported inside the timed kernel/function body after all setup, object construction, file loading, and first-call compilation are excluded. |
| GPU allocations | Device allocations reported inside the synchronized timed region after setup. |
| temporary-array footprint | Bytes and array count of persistent and per-call temporary arrays required by the runtime path. Per-call hot-path temporary arrays should be zero unless explicitly justified. |
| scalar GPU indexing warnings | Any CUDA scalar-indexing warnings or host scalar fallback observed during tests or benchmarks. Target is zero. |
| RMSE | `sqrt(mean((model - reference)^2))` over the stated case set, levels/interfaces, columns, and flux component. |
| max error | Maximum absolute error over the stated case set, levels/interfaces, columns, and component. |
| forcing error | Error in the flux or heating-rate change caused by a stated gas perturbation, measured as `(perturbed - baseline)` in RadiativeHeating minus the same reference-code difference. |
| energy-closure residual | Net column flux divergence minus column-integrated heating in consistent units, with sign convention stated in the test or report. |
| memory footprint | Model data plus persistent working arrays required for the timed runtime path; report host and device memory separately where applicable. |

Every metric report must state the case set. For validation metrics, the case set must identify the atmospheric columns, vertical grid, gas concentrations, cloud/aerosol state, surface properties, and solar/geometry inputs.

---

## 4. Proposed package layout

### 4.1 `RadiativeHeating.jl`

```text
RadiativeHeating.jl
├── Project.toml
├── README.md
├── src/
│   ├── RadiativeHeating.jl
│   ├── States/
│   │   ├── column_atmosphere.jl
│   │   ├── gases.jl
│   │   ├── surface.jl
│   │   ├── geometry.jl
│   │   └── units.jl
│   ├── Fluxes/
│   │   ├── fluxes.jl
│   │   └── heating_rates.jl
│   ├── GasOptics/
│   │   ├── gas_optics.jl
│   │   ├── analytic_band.jl
│   │   └── EcCKD/
│   │       ├── ecckd_model.jl
│   │       ├── ecckd_definition.jl
│   │       ├── interpolation.jl
│   │       ├── concentration_dependence.jl
│   │       ├── planck_sources.jl
│   │       ├── rayleigh.jl
│   │       └── validation.jl
│   ├── CloudOptics/
│   │   ├── cloud_optics.jl
│   │   ├── liquid.jl
│   │   ├── ice.jl
│   │   └── overlap.jl
│   ├── AerosolOptics/
│   │   └── aerosol_optics.jl
│   ├── Solvers/
│   │   ├── solver_interface.jl
│   │   ├── cloudless.jl
│   │   ├── homogeneous.jl
│   │   ├── two_stream.jl
│   │   ├── mcica.jl
│   │   ├── tripleclouds.jl
│   │   └── spartacus.jl
│   ├── IO/
│   │   ├── artifacts.jl
│   │   ├── ecckd_netcdf.jl
│   │   ├── ecrad_cases.jl
│   │   ├── rrtmgp_compat.jl
│   │   └── schema_summary.jl
│   ├── Benchmarks/
│   │   ├── benchmark_cases.jl
│   │   ├── benchmark_metadata.jl
│   │   └── benchmark_report.jl
│   ├── Optimization/
│   │   └── EcCKDGeneration/
│   │       ├── spectra.jl
│   │       ├── g_point_partitioning.jl
│   │       ├── lut_creation.jl
│   │       ├── objective.jl
│   │       ├── optimize_lut.jl
│   │       └── evaluation.jl
│   └── Differentiation/
│       ├── enzyme.jl
│       └── reactant.jl
├── ext/
│   ├── RadiativeHeatingNCDatasetsExt.jl
│   ├── RadiativeHeatingCUDAExt.jl
│   ├── RadiativeHeatingReactantExt.jl
│   └── RadiativeHeatingEnzymeExt.jl
├── test/
│   ├── runtests.jl
│   ├── unit/
│   ├── integration/
│   ├── reference_ecrad/
│   ├── reference_ecckd/
│   ├── gpu/
│   ├── ad/
│   └── benchmarks/
├── benchmark/
│   ├── Project.toml
│   ├── benchmark_suite.jl
│   ├── cases/
│   ├── reference/
│   └── results/
├── examples/
│   ├── analytic_column.jl
│   ├── ecckd_file_summary.jl
│   ├── ecckd_clear_sky_fluxes.jl
│   ├── compare_ecckd_to_ecrad.jl
│   ├── compare_to_rrtmgp.jl
│   └── optimize_ecckd_toy_model.jl
└── docs/
    ├── make.jl
    └── src/
        ├── index.md
        ├── architecture.md
        ├── gas_optics/
        ├── solvers/
        ├── benchmarks.md
        ├── validation.md
        ├── ecckd_generation.md
        └── api.md
```

### 4.2 `Breeze.jl` extension layout

```text
Breeze.jl
├── ext/
│   └── BreezeRadiativeHeatingExt/
│       ├── BreezeRadiativeHeatingExt.jl
│       ├── radiation_models.jl
│       ├── column_extraction.jl
│       ├── heating_tendencies.jl
│       ├── scheduling.jl
│       ├── gpu_kernels.jl
│       └── diagnostics.jl
├── test/
│   └── extensions/
│       └── radiative_heating/
├── examples/
│   └── radiation/
│       ├── radiative_heating_clear_sky.jl
│       ├── radiative_heating_cloudy.jl
│       └── compare_radiative_heating_rrtmgp.jl
└── docs/
    └── src/
        └── radiation/
            └── radiative_heating.md
```

---

## 5. Core API sketch

### 5.1 Abstract interfaces

```julia
abstract type AbstractAtmosphericState end
abstract type AbstractGasOpticsModel end
abstract type AbstractCloudOpticsModel end
abstract type AbstractAerosolOpticsModel end
abstract type AbstractRadiativeTransferSolver end
abstract type AbstractRadiationBackend end
```

### 5.2 Main functions

```julia
optical_properties!(optics, gas_model, atmosphere)
cloud_optical_properties!(optics, cloud_model, atmosphere)
aerosol_optical_properties!(optics, aerosol_model, atmosphere)
radiative_fluxes!(fluxes, solver, optics, atmosphere, boundary_conditions)
heating_rates!(heating, fluxes, atmosphere)
radiative_heating!(heating, fluxes, optics, model, atmosphere)
```

These functions should be composable rather than only available through `radiative_heating!`. Host models must be able to stop after gas optics, replace the solver, replace the vertical integral, or write heating tendencies into their own arrays.

### 5.3 Integration access levels

Provide three API layers:

| Layer | Intended users | API shape | Allocation expectation |
|---|---|---|---|
| High-level radiation call | examples, simple column models, quick validation | `radiative_heating!(...)` orchestrates optics, solver, fluxes, and heating rates | zero allocations after setup |
| Component calls | SpeedyWeather-style integrations and validation tools | `optical_properties!`, `source_terms!`, `radiative_fluxes!`, `heating_rates!` callable independently | caller may provide all work arrays |
| Kernel/workspace calls | Breeze-style optimized integrations | explicit workspaces, views, interpolation metadata, and backend-specific kernels | no per-call temporaries; host model can own memory and scheduling |

The package should provide workspace constructors, but not require host models to use package-owned storage:

```julia
workspace = radiation_workspace(model, atmosphere; backend)
prepare_radiation!(workspace, model, atmosphere)
optical_properties!(workspace.optics, model.gas_optics, atmosphere, workspace)
radiative_fluxes!(workspace.fluxes, model.solver, workspace.optics, atmosphere, boundary_conditions, workspace)
```

Equivalent methods should accept host-owned arrays or array views where practical, so Breeze can avoid redundant column packing and SpeedyWeather can use its own solver or vertical-integral machinery.

### 5.4 Suggested data objects

```julia
struct ColumnAtmosphere{FT, A, G, S, Geo}
    pressure_layers::A
    pressure_interfaces::A
    temperature_layers::A
    temperature_interfaces::A
    gases::G
    surface::S
    geometry::Geo
end
```

```julia
struct OpticalProperties{FT, A}
    optical_depth::A
    single_scattering_albedo::A
    asymmetry_factor::A
    source::A
end
```

Preferred layout for optical properties:

```julia
τ[k, z, column]
ω₀[k, z, column]
gₐ[k, z, column]
source[k, z, column]
```

---

## 6. Stage quality gates

### 6.1 Tests

Each stage must add tests scaled to its risk:

| Test category | Success criterion |
|---|---|
| Unit tests | cover new public APIs and numerical kernels |
| Integration tests | cover at least one end-to-end path introduced by the stage |
| Reference comparisons | compare against ecRad, RRTMGP.jl, analytic solutions, or stored fixtures where applicable |
| Allocation tests | hot paths allocate zero objects after setup |
| Performance smoke tests | benchmark suite runs without errors or performance regressions |
| NaN/stress tests | no NaNs or nonphysical values on randomized physical columns |
| AD tests | gradient checks pass for differentiable paths |

### 6.2 Documentation

Each stage must add or update:

- Public docs page.
- API docstrings.
- Example script.
- Benchmark notes.
- Known limitations.

### 6.3 Examples

Examples must be runnable scripts, not just snippets.

Each example should print a concise metrics block, for example:

```text
Model: ecCKD climate-32b
Columns: 65536
Layers: 128
Precision: Float32
Device: NVIDIA H100
LW flux RMSE vs ecRad: ... W m^-2
SW flux RMSE vs ecRad: ... W m^-2
Heating-rate RMSE vs ecRad: ... K day^-1
Runtime: ... ms
Speedup vs RRTMGP.jl: ... x
```

### 6.4 Performance

Hot-path requirements:

- No CPU allocations after setup.
- No GPU allocations after setup.
- No per-call temporary arrays in the runtime path unless explicitly justified by a benchmark.
- No scalar indexing on GPU.
- Type-stable kernels.
- Benchmark reports include metadata.
- GPU timings are synchronized.
- Kernel count, memory footprint, temporary-array footprint, and Nsight-derived profiling summaries are reported for optimized GPU cases.

### 6.5 Code quality

- Use concrete typed structs in hot paths.
- Use solver types, not symbol flags.
- Keep I/O outside kernels and differentiated functions.
- Keep setup/materialization separate from execution.
- Keep storage ownership explicit: package-owned workspace, caller-owned arrays, or host-model views.
- Expose intermediate products instead of forcing host models through one monolithic radiation update.
- Make vertical conventions explicit: `layers` versus `interfaces`.
- Make flux sign conventions explicit and consistent.
- Prefer small kernels and composable types over giant monolithic routines.

---

## 7. Benchmarking strategy

### 7.1 Benchmark decomposition

Every radiation benchmark should report the following components separately:

```text
1. Breeze state access / column extraction / packing
2. gas optics
3. cloud optics
4. aerosol optics
5. longwave solver
6. shortwave solver
7. flux-to-heating conversion
8. Breeze tendency insertion
9. full radiation update
```

This prevents misleading full-call conclusions.

Benchmarks should also report whether each component used package-owned workspaces, caller-owned arrays, or host-model views. If a component materializes temporary arrays, report their count, size, lifetime, and whether they are avoidable with a lower-level API.

### 7.2 Required benchmark cases

```text
benchmark/cases/
├── single_column_clear_sky.toml
├── single_column_cloudy.toml
├── era5_slice_clear_sky.toml
├── era5_slice_cloudy.toml
├── gpu_scaling_clear_sky.toml
├── gpu_scaling_cloudy.toml
├── rrtmgp_like_complexity.toml
├── ecckd_64_term.toml
├── ecckd_32_term.toml
├── ecckd_16_term.toml
└── breeze_radiation_step.toml
```

### 7.3 Required benchmark outputs

```text
benchmark/results/latest.json
benchmark/results/latest.md
benchmark/results/history/*.json
benchmark/results/plots/runtime_vs_columns.png
benchmark/results/plots/speedup_vs_terms.png
benchmark/results/plots/error_vs_runtime.png
```

### 7.4 Benchmark metadata schema

Each JSON record should include:

```json
{
  "case": "clear_sky_batch",
  "date": "2026-05-12",
  "radiative_heating_sha": "...",
  "breeze_sha": "...",
  "rrtmgp_sha": "...",
  "julia_version": "...",
  "cuda_version": "...",
  "device": "...",
  "precision": "Float32",
  "columns": 65536,
  "layers": 128,
  "lw_bands": 16,
  "lw_gpoints": 32,
  "sw_bands": 16,
  "sw_gpoints": 32,
  "clouds": "none",
  "aerosols": "none",
  "backend": "CUDA",
  "runtime_ms_median": 1.23,
  "runtime_ms_minimum": 1.18,
  "runtime_ms_p90": 1.31,
  "allocations": 0,
  "gpu_allocations": 0,
  "temporary_arrays": 0,
  "temporary_bytes": 0,
  "workspace_bytes_host": 1048576,
  "workspace_bytes_device": 8388608,
  "kernel_launches": 4,
  "nsight_systems_report": "benchmark/results/profiles/clear_sky_batch.nsys-rep",
  "nsight_compute_report": "benchmark/results/profiles/clear_sky_batch.ncu-rep",
  "achieved_occupancy": 0.62,
  "dram_throughput_gb_s": 820.0,
  "registers_per_thread": 64,
  "shared_memory_bytes_per_block": 8192,
  "speedup_vs_rrtmgp": 5.6
}
```

The Nsight fields may be `null` for smoke tests, CPU-only runs, or machines without Nsight installed. They are required for GPU optimization PRs, frozen regression benchmarks, milestone GPU reports, and any final performance claim.

Primary GPU target:

```text
NVIDIA H100
```

Development benchmarks on other GPUs are useful, but they should not replace the H100 benchmark for headline targets.

### 7.5 Performance targets

| Configuration | Minimum target | Stretch target |
|---|---:|---:|
| Similar-complexity gas optics versus RRTMGP.jl | 4x | 6x |
| Similar-complexity full clear-sky call versus RRTMGP.jl | 4x | 6x |
| ecCKD 64-term clear-sky versus RRTMGP.jl | 2x | 4x |
| ecCKD 32-term clear-sky versus RRTMGP.jl | 5x | 8x |
| ecCKD 16-term clear-sky versus RRTMGP.jl | 8x | 15x |
| ecCKD 32-term Breeze radiation update versus Breeze+RRTMGP | 5x | 8x |
| ecCKD 16-term Breeze radiation update versus Breeze+RRTMGP | 8x | 15x |

Headline targets are H100 targets. Other GPU results should be reported as portability/scaling data unless explicitly promoted to a target platform.

These targets must be revisited after the first careful RRTMGP.jl baseline benchmark. If the baseline is dominated by non-radiation overhead or a known bug, adjust the benchmark to isolate the real radiation workload.

### 7.6 Accuracy/performance Pareto reporting

For reduced ecCKD models, never report speed alone. Always report:

```text
runtime
speedup
memory footprint
LW TOA flux RMSE
LW surface flux RMSE
SW surface flux RMSE
heating-rate RMSE
max heating-rate error
forcing error for CO2/CH4/N2O/O3 perturbations where available
```

---

## 8. Stage-by-stage implementation plan

Each stage below includes goals, deliverables, metrics, docs, examples, and exit criteria.

---

# Stage 0 — Benchmark and validation harness first

## Goal

Create the measurement framework before major implementation work. This ensures that every later change can be tested, compared, and timed.

## Tasks

1. Create `benchmark/Project.toml`.
2. Create benchmark case configuration files.
3. Implement benchmark metadata collection.
4. Implement CPU benchmark runner using BenchmarkTools.
5. Implement GPU benchmark runner with explicit synchronization.
6. Implement Markdown and JSON result writers.
7. Implement plotting scripts for benchmark summaries.
8. Create placeholder benchmark cases for current analytic-band code and RRTMGP.jl.

## Metrics

| Metric | Success criterion |
|---|---|
| Benchmark suite runs | `julia --project=benchmark benchmark/benchmark_suite.jl --case smoke` exits successfully |
| JSON report generated | `benchmark/results/latest.json` exists and validates against the benchmark schema |
| Markdown report generated | `benchmark/results/latest.md` exists and includes the same cases as JSON |
| Metadata complete | all required schema fields are present, with unavailable optional dependencies recorded as `null` and explained |
| CPU timings include min/median/p90 | JSON contains `runtime_ms_minimum`, `runtime_ms_median`, and `runtime_ms_p90` for each CPU case |
| GPU timings synchronized | benchmark code uses `CUDA.@sync` or equivalent synchronization inside the timed region |
| Plots generated | at least runtime vs columns |

## Tests

- Unit tests for metadata serialization.
- Unit tests for benchmark result schema.
- Smoke test that benchmark suite runs one small case.

## Docs

Add:

```text
docs/src/benchmarks.md
```

Include:

- How to run benchmarks.
- How GPU synchronization is handled.
- How to interpret speedup.
- Why reduced models require error/runtime reporting.

## Example

```text
examples/run_minimal_benchmark.jl
```

## Exit criteria

```text
benchmark suite runs
benchmark reports generated
metadata present
one CPU case measured
one GPU smoke case measured if CUDA available
docs build
```

---

# Stage 1 — Rename and API scaffold

## Goal

Rename `NumericalRadiation.jl` to `RadiativeHeating.jl` while preserving existing functionality under the new interface.

## Tasks

1. Rename package.
2. Add abstract types for state, gas optics, cloud optics, aerosol optics, solvers.
3. Move current analytic-band implementation into `GasOptics/analytic_band.jl` or equivalent.
4. Implement `ColumnAtmosphere` and `RadiativeFluxes` structs.
5. Implement `heating_rates!` with explicit flux sign convention.
6. Ensure existing analytic-band tests pass through the new API.

## Metrics

| Metric | Success criterion |
|---|---|
| Existing tests pass | 100% |
| Analytic-band backend works through new API | yes |
| Hot-path CPU allocations | zero after setup |
| Component API works | gas optics, solver, and heating-rate conversion can be called independently |
| Workspace API works | caller can reuse preallocated workspace for repeated calls |
| Type stability | selected hot calls pass `@code_warntype` inspection |
| Docs | architecture page exists |
| Example | analytic column example runs |

## Tests

- Existing analytic-band tests.
- New interface tests.
- Component access tests.
- Workspace reuse tests.
- Heating-rate sign convention tests.
- Energy-closure tests for simple cases.

## Docs

Add:

```text
docs/src/architecture.md
docs/src/api.md
```

## Example

```text
examples/analytic_column.jl
```

The example must print:

```text
surface flux
TOA flux
column-integrated heating
energy closure residual
runtime
```

## Exit criteria

```text
all tests pass
docs build
analytic example runs
benchmark harness measures analytic backend
zero hot-path allocations after setup
component and workspace APIs demonstrated
```

---

# Stage 2 — RRTMGP.jl baseline benchmarks

## Goal

Establish a reliable, reproducible RRTMGP.jl baseline before optimizing RadiativeHeating.

## Tasks

1. Add RRTMGP.jl benchmark dependency.
2. Benchmark RRTMGP.jl gas optics separately from RTE.
3. Benchmark full RRTMGP.jl clear-sky radiation.
4. Benchmark full RRTMGP.jl cloudy radiation if available/used in Breeze.
5. Benchmark current Breeze + RRTMGP radiation update.
6. Add `NumericalRadiationRRTMGPExt` or an equivalent optional extension
   for direct `ColumnAtmosphere` / `RadiativeFluxes` comparisons.
7. Add tests that compute RadiativeHeating and RRTMGP fluxes from identical
   package-native column inputs and emit flux/heating metrics.
8. Report actual spectral dimensions read from loaded lookup tables.
9. Store baseline results.

Current implementation note: items 6 and 7 have package-level smoke coverage in
`test/test_rrtmgp_ext.jl`; benchmark timing and spectral-dimension artifact
work remain open.

## Benchmark cases

```text
rrtmgp_clear_sky_lw
rrtmgp_clear_sky_sw
rrtmgp_clear_sky_lw_sw
rrtmgp_cloudy_no_aerosol
rrtmgp_cloudy_aerosol
breeze_rrtmgp_radiation_step
```

## Metrics

| Metric | Success criterion |
|---|---|
| RRTMGP.jl gas optics benchmark works | median synchronized runtime reported for gas optics only |
| RRTMGP.jl RTE benchmark works | median synchronized runtime reported for RTE only |
| RRTMGP.jl full-call benchmark works | median synchronized runtime reported for gas optics plus RTE |
| Breeze+RRTMGP benchmark works | median synchronized runtime reported for the Breeze radiation update |
| RRTMGP comparison extension works | RRTMGP fluxes can be computed from `ColumnAtmosphere` into `RadiativeFluxes` |
| Direct model comparison works | RadiativeHeating and RRTMGP flux/heating metrics are reported for the same package-native column |
| Actual bands/g-points reported | metadata includes LW/SW band and g-point counts read from loaded files |
| Median runtime coefficient of variation | < 5% for large GPU cases |
| Benchmark JSON/Markdown generated | `benchmark/results/latest.json` and `benchmark/results/latest.md` are produced for baseline cases |
| H100 baseline available | H100 benchmark recorded for headline comparison, unless explicitly marked unavailable |
| Nsight baseline profiles | Nsight Systems and Nsight Compute profiles attached for large H100 GPU baseline cases |

## Tests

- Smoke tests only; avoid making RRTMGP.jl a hard test dependency unless appropriate.
- Validate that benchmark metadata includes spectral counts.

## Docs

Add a section:

```text
docs/src/benchmarks.md#rrtmgp-baseline
```

## Exit criteria

```text
RRTMGP.jl baseline exists
Breeze+RRTMGP baseline exists
spectral dimensions reported from files
a reproducible benchmark report is stored
```

---

# Stage 3 — ecRad and ecCKD ingestion

## Goal

Read ecCKD CKD-definition files and summarize/validate their schema. Establish ecRad/ecCKD reference workflows.

## Tasks

1. Implement artifact or user-specified file loading for ecCKD definitions.
2. Implement NetCDF reader extension using NCDatasets.jl or equivalent.
3. Implement `EcCKDDefinition` data structure.
4. Implement schema summary.
5. Implement schema validation.
6. Build or document ecRad reference workflow.
7. Add test fixtures for small/representative ecCKD files.

## Suggested API

```julia
definition = read_ecckd_definition(path)
summary = summarize_ecckd_definition(definition)
validate_ecckd_definition(definition)
```

## Metrics

| Metric | Success criterion |
|---|---|
| Official ecCKD files load | 100% for files included in test/artifact set |
| Dimensions validated | validator checks required NetCDF dimensions and fails on missing or inconsistent dimensions |
| Gas names validated | validator maps file gas names to canonical package gas identifiers and reports unknown names |
| Band metadata validated | validator checks band bounds, ordering, and LW/SW classification |
| Pressure/temperature grids validated | validator checks monotonicity, units, and expected interpolation axes |
| LUT dimensions validated | validator checks lookup-table shapes against gas, band, g-point, pressure, and temperature dimensions |
| Summary table generated | `summarize_ecckd_definition` prints model, version, gases, bands, g-points, grid sizes, and source/scattering table availability |
| Docs page | `docs/src/gas_optics/ecckd_files.md` exists and is linked from the docs index |
| File-summary example | `examples/ecckd_file_summary.jl` runs on at least one fixture or artifact |

## Tests

- Schema tests.
- Missing variable tests.
- Unit conversion tests if needed.
- File summary snapshot tests.

## Docs

Add:

```text
docs/src/gas_optics/ecckd_files.md
```

## Example

```text
examples/ecckd_file_summary.jl
```

Expected output:

```text
model name
version
LW/SW
number of bands
number of g/k terms
gases
pressure grid size
temperature grid size
source tables present
rayleigh tables present
```

## Exit criteria

```text
every selected ecCKD file loads
schema validation passes
summary example runs
docs build
```

---

# Stage 4 — ecCKD forward gas optics, CPU first

## Goal

Implement ecCKD gas optics as a consumer of ecCKD files. This means computing optical depth, source terms, and scattering-related quantities from atmospheric columns.

## Tasks

1. Implement pressure/temperature interpolation.
2. Implement gas concentration handling.
3. Implement concentration-dependence models.
4. Implement longwave source/Planck terms.
5. Implement shortwave solar and Rayleigh terms.
6. Accumulate gas optical depths over gases.
7. Validate against ecRad optical properties before solving radiative transfer.

## Suggested API

```julia
model = EcCKDGasOptics(definition)
optics = similar_optical_properties(model, atmosphere)
optical_properties!(optics, model, atmosphere)
```

## Correctness metrics

| Quantity | Threshold |
|---|---:|
| Optical depth versus ecRad, Float64 | max relative error <= 1e-6 initially where reference optical depth > 1e-12; max absolute error <= 1e-12 otherwise |
| Optical depth versus ecRad, Float32 | max relative error <= 1e-4 initially where reference optical depth > 1e-8; max absolute error <= 1e-8 otherwise |
| LW source terms versus ecRad, Float64 | max relative error <= 1e-6 initially where reference magnitude > 1e-12; max absolute error <= 1e-12 otherwise |
| LW source terms versus ecRad, Float32 | max relative error <= 1e-4 initially where reference magnitude > 1e-8; max absolute error <= 1e-8 otherwise |
| SW Rayleigh/scattering terms versus ecRad | same tolerance family as optical depth |
| Interpolation at table nodes | roundoff-level error |
| Negative optical depths | none |
| NaNs | none |

Tolerances may need adjustment after direct comparison with ecRad due to exact interpolation conventions, but all adjustments must be documented.

## Performance metrics

| Benchmark | Initial success criterion |
|---|---:|
| CPU ecCKD gas optics, 64-term | reported |
| CPU ecCKD gas optics, 32-term | reported |
| CPU ecCKD gas optics, 16-term | reported |
| Hot-path allocations | zero after setup |
| Type stability | clean selected kernels |

## Tests

- Interpolation unit tests.
- Table-node exactness tests.
- Concentration-dependence unit tests.
- Gas accumulation unit tests.
- ecRad optical-property comparison tests.

## Docs

Add:

```text
docs/src/gas_optics/ecckd_forward.md
```

## Examples

```text
examples/ecckd_clear_sky_optical_depths.jl
examples/compare_ecckd_optics_to_ecrad.jl
```

## Exit criteria

```text
gas optical properties agree with ecRad reference columns
CPU benchmark reported
no hot-path allocations
docs and examples complete
```

---

# Stage 5 — ecCKD gas optics on GPU

## Goal

Move ecCKD gas optics onto GPU and begin optimizing memory layout and spectral specialization.

## Tasks

1. Implement GPU-compatible optical-property kernels.
2. Ensure no scalar indexing.
3. Ensure no host fallback.
4. Specialize on spectral sizes where useful.
5. Benchmark 16/32/64-term models.
6. Compare GPU output to CPU output and ecRad references.

## GPU design notes

Explore:

- `τ[k, z, column]` layout.
- Fixed spectral type parameters: `EcCKDGasOptics{FT, NG_LW, NG_SW}`.
- Shared memory for reusable LUT fragments.
- Read-only/cache-friendly access for lookup tables.
- Precomputed interpolation indices/fractions.
- Separate kernels for 16, 32, 64, and RRTMGP-like spectral sizes.

## Correctness metrics

| Quantity | Threshold |
|---|---:|
| GPU versus CPU optical depth | Float32 relative error <= 1e-5 initially |
| GPU versus CPU source terms | Float32 relative error <= 1e-5 initially |
| GPU NaN stress tests | zero failures |
| GPU scalar indexing warnings | zero |

## Performance metrics

| Benchmark | Initial target |
|---|---:|
| GPU ecCKD gas optics, 64-term versus RRTMGP.jl gas optics | >= 2x by end of stage |
| GPU ecCKD gas optics, 32-term versus RRTMGP.jl gas optics | >= 4x by end of stage |
| GPU ecCKD gas optics, 16-term versus RRTMGP.jl gas optics | >= 6x by end of stage |
| Hot-path GPU allocations | zero |
| Kernel launches | reported |
| Memory throughput | reported from Nsight Compute for optimized cases |
| Timeline profile | Nsight Systems report attached for optimized cases |
| Kernel profile | Nsight Compute report attached for optimized cases |

## Tests

- CPU/GPU agreement tests.
- GPU smoke test.
- GPU stress test for randomized physical columns.

## Docs

Add:

```text
docs/src/gpu.md
```

## Exit criteria

```text
GPU gas optics pass correctness tests
GPU benchmark table exists
no scalar indexing
no GPU allocations in hot path
```

---

# Stage 6 — Minimal ecRad-style clear-sky solver

## Goal

Implement clear-sky longwave and shortwave solvers that consume optical properties and produce fluxes and heating rates.

## Solver targets

```julia
CloudlessLongwave()
CloudlessShortwave()
HomogeneousLongwave()
HomogeneousShortwave()
```

## Tasks

1. Implement solver interface.
2. Implement longwave clear-sky solver.
3. Implement shortwave clear-sky solver.
4. Implement boundary conditions.
5. Implement flux accumulation over spectral dimension.
6. Implement heating-rate calculation.
7. Compare fluxes/heating rates to ecRad for same optics.

## Correctness metrics

| Quantity | Threshold |
|---|---:|
| LW up/down flux RMSE versus ecRad | <= 0.05 W m^-2 for same optics |
| SW up/down/direct/diffuse flux RMSE versus ecRad | <= 0.05 W m^-2 for same optics |
| Heating-rate RMSE versus ecRad | <= 0.005 K day^-1 for same optics |
| Energy conservation | <= 1e-10 relative Float64, <= 1e-5 Float32 |
| No-atmosphere test | analytic agreement |
| Single-layer pure absorber | analytic agreement |

Tolerances may need adjustment after confirming exact ecRad conventions. Any adjustments must be justified and documented.

## Performance metrics

| Benchmark | Target |
|---|---:|
| GPU clear-sky full call, 64-term ecCKD | >= 2x faster than RRTMGP.jl full clear-sky call |
| GPU clear-sky full call, 32-term ecCKD | >= 5x faster than RRTMGP.jl full clear-sky call |
| GPU clear-sky full call, 16-term ecCKD | >= 8x faster than RRTMGP.jl full clear-sky call |
| Hot-path allocations | zero |
| Kernel launches | reported |
| Nsight Systems timeline | attached for optimized GPU benchmark cases |
| Nsight Compute kernel report | attached for optimized GPU benchmark cases |

## Tests

- Analytical no-atmosphere test.
- Analytical single-layer tests.
- Energy-closure tests.
- ecRad comparison tests.
- CPU/GPU agreement tests.

Current solver-limit coverage includes `test/test_cloudless_longwave_solver.jl`,
`test/test_cloudless_shortwave_solver.jl`, and `test/test_runtime_interfaces.jl`.
These cover no-atmosphere limits, single-layer absorber limits, a two-layer
closed-form pure-absorber Schwarzschild longwave solution with nonzero TOA and
surface boundaries, ecRad-style interface longwave sources, conservative
single-layer shortwave scattering at `mu0 = 1`, and column energy closure. Keep
these focused solver tests separate from artifact/gate tests so solver
regressions are caught before ecCKD and Breeze validation runs.

## Docs

Add:

```text
docs/src/solvers/clear_sky.md
```

## Examples

```text
examples/ecckd_clear_sky_fluxes.jl
examples/ecckd_heating_rates.jl
examples/compare_clear_sky_to_ecrad.jl
```

## Exit criteria

```text
clear-sky fluxes and heating rates match ecRad within tolerances
clear-sky benchmarks report speedup
docs and examples complete
```

---

# Stage 7 — First GPU optimization milestone

## Goal

Turn prototype GPU support into a serious performance path.

## Tasks

1. Profile gas optics and solver kernels.
2. Identify memory-bound versus compute-bound regions.
3. Reduce kernel launches where useful.
4. Use shared memory or cached LUT staging where profiling supports it.
5. Specialize kernels for 16/32/64-term spectral models.
6. Precompute interpolation metadata where useful.
7. Freeze the first speedup regression benchmarks.

## Candidate optimization techniques

- Fixed spectral dimensions in types.
- Specialized kernels for small spectral counts.
- Shared memory staging for LUT fragments.
- Kernel fusion for gas-optics accumulation and solver setup.
- Avoid temporary optical-property arrays where fusion preserves clarity and correctness.
- Use structure-of-arrays layout for gas fields if it improves memory coalescing.
- Benchmark direct field views versus packed column arrays.

## Metrics

| Metric | Target |
|---|---:|
| ecCKD 64-term clear-sky full call | >= 2x RRTMGP.jl |
| ecCKD 32-term clear-sky full call | >= 5x RRTMGP.jl |
| ecCKD 16-term clear-sky full call | >= 8x RRTMGP.jl |
| Nsight Systems profile attached to benchmark report | yes |
| Nsight Compute profile attached to benchmark report | yes |
| Accuracy regression | none |
| Hot-path allocations | zero |
| GPU scalar indexing | zero |

## Docs

Update:

```text
docs/src/benchmarks.md
docs/src/gpu.md
```

## Exit criteria

```text
first GPU speed milestones achieved or documented blockers identified
benchmark report includes Nsight timeline and kernel-level information
performance regression guard established
```

---

# Stage 8 — RRTMGP-like benchmark milestone

## Goal
Defend the primary 4x claim by comparing against RRTMGP.jl for a similar amount of gas-optics work.

## Tasks

1. Define an apples-to-apples RRTMGP-like benchmark.
2. Either:
   - implement a benchmark-only `RRTMGPCompatibleGasOptics`, or
   - use an ecCKD model with comparable spectral and table complexity.
3. Match columns, layers, precision, device, cloud configuration, and boundary conditions.
4. Benchmark gas optics, RTE, and full call separately.
5. Freeze a regression case once target is met.

## Metrics

| Metric | Target |
|---|---:|
| Similar-complexity gas optics speedup | >= 4x |
| Similar-complexity full clear-sky call speedup | >= 4x |
| Temporary-array footprint versus RRTMGP.jl | RadiativeHeating reports fewer or zero per-call temporaries for equivalent benchmark components |
| Accuracy difference | flux and heating-rate RMSE reported, with differences attributed to optics, solver, or convention choices |
| Benchmark reproducibility | median coefficient of variation < 5% |
| Target GPU | H100 result recorded for headline claim |
| Benchmark metadata | complete |
| Nsight profiles | attached for the selected GPU case |

## Exit criteria

```text
an agreed similar-complexity benchmark exists
RadiativeHeating achieves >= 4x speedup on selected GPU case, or blockers are documented with profiles
temporary-array footprint is reported against the RRTMGP.jl baseline
benchmark result is frozen as a regression guard
```

---

# Stage 9 — Breeze.jl extension

## Goal

Add a Breeze-owned extension that uses RadiativeHeating as a radiation backend.

This stage requires development in Breeze.jl as well as RadiativeHeating.jl. Use a dedicated Breeze checkout for this project, for example:

```text
../BreezeRadiativeHeatingDev/Breeze.jl
```

Do not edit any other local Breeze checkout on this system. If a suitable dedicated checkout does not exist, create one intentionally and record its path in the benchmark metadata and PR notes.

Current dedicated checkout:

```text
/shared/home/greg/Projects/BreezeRadiativeHeatingDev/Breeze.jl
```

It was freshly cloned from `https://github.com/NumericalEarth/Breeze.jl` at
commit `05c8fafbb0522e9c7cbc72dc89d0523083cd6810`. The old
`NumericalRadiationBreezeExt` extension in this package has been removed;
Breeze integration work belongs in `BreezeRadiativeHeatingExt` inside the
dedicated Breeze checkout.

Current implementation status: the dedicated Breeze checkout now contains a
`BreezeRadiativeHeatingExt` weak extension with a `RadiativeHeatingOptics()`
constructor that allocates Breeze-owned flux fields, stores an
`NumericalRadiation.AbstractGasOpticsModel`, and runs a first CPU runtime
path for both `EcCKDGasOpticsModel` and `EcCKDTabulatedGasOpticsModel`. That
path extracts Breeze temperature,
reference pressure, and water vapor into caller-owned column buffers, calls the
NumericalRadiation optical-property APIs, optionally composes cloud and
aerosol optical depth, calls the cloudless flux APIs, and writes flux
divergence back to Breeze. The targeted Breeze test
`julia --project=test test/runtests.jl radiative_heating_extension` passes
with 52 assertions, including typed `NamedTuple` gas-column storage, tabulated
ecCKD runtime evaluation, optional aerosol optics, direct final-4x benchmark
acceptance checks, and equality
of Breeze-owned flux fields and flux
divergence against a standalone NumericalRadiation column calculation. The
test now also verifies Breeze thermodynamic tendency coupling in zero-motion CPU
cases: `Gρe` receives the RadiativeHeating flux divergence for
`:StaticEnergy`, and `:LiquidIcePotentialTemperature` produces a nonzero
radiative tendency while the same no-radiation state remains zero. GPU kernels,
device-compatible low-temporary-array kernels, production cloud coupling, and
the final RCEMIP-style RRTMGP comparison remain open tasks. The dedicated Breeze checkout
also contains a scaffold benchmark,
`benchmarking/radiative_heating_rcemip_benchmark.jl`, verified on the default
16 x 16 x 64 CPU workload with one sample. The optional CPU RRTMGP baseline
path also runs on the same default workload with `--rrtmgp=true` and reports
both timings. The scaffold writes
`benchmarking/results/radiative_heating_rcemip_latest.json` and `.md`, but the
script and artifacts are explicitly marked as not final 4x evidence because
they lack H100/Nsight profiling, full Breeze timestep integration, and a
production gas-optics equivalence claim. The artifacts now record isolated
`update_radiation!` timing and Breeze `update_state!` timing, which includes
radiation plus Breeze tendency computation, along with Julia version, Breeze
and NumericalRadiation checkout paths and git SHAs, dirty-worktree flags,
command-line arguments, and Nsight Systems / Nsight Compute command templates
for rerunning the same case under NVIDIA profilers.
The regenerated default fixed-coefficient 32/32 CPU scaffold artifact with
`--rrtmgp=true` reports `17.317874` ms for isolated `update_radiation!` and
`20.685182` ms for Breeze `update_state!`; the same CPU smoke run reports
RRTMGP baseline medians of `1261.201124` ms for `update_radiation!` and
`1236.463213` ms for `update_state!`, for scaffold-only speedups of `72.827x`
and `59.775x`.
The CPU allocation measurements in the same artifact report `0` bytes for the
RadiativeHeating `update_radiation!` hot path, `638224` bytes for
RadiativeHeating `update_state!`, `35184` bytes for RRTMGP `update_radiation!`,
and `673408` bytes for RRTMGP `update_state!`. These numbers are explicitly
not final 4x evidence because they are CPU toy-gas scaffold timings, not
H100/Nsight production evidence. The artifact now computes
`final_4x_claim_supported` from explicit acceptance criteria and records
`final_4x_blocking_reason`; the current CPU scaffold is blocked because the
backend is CPU, H100/Nsight evidence is false, and Nsight report paths are
missing.
The benchmark now accepts `--ng_lw` and `--ng_sw` so reduced toy gas-optics
smoke runs can record their spectral complexity explicitly. A 16/16 CPU smoke
run has been written to
`/shared/home/greg/Projects/BreezeRadiativeHeatingDev/Breeze.jl/benchmarking/results/reduced_16x16_smoke/`;
it reports `18.190728` ms for the isolated radiation update and `22.217260` ms
for Breeze `update_state!`. This is useful as reduced-model scaffold evidence,
not as a final 16-term accuracy or H100 performance claim.
The same benchmark now also accepts `--gas_model=fixed|tabulated`. A tabulated
32/32 CPU smoke artifact in the dedicated Breeze checkout under
`benchmarking/results/tabulated_smoke/` exercises the
`EcCKDTabulatedGasOpticsModel` lookup path on the same RCEMIP-style state. It
reports `38.044391` ms for isolated radiation and `45.373956` ms for
`update_state!`, with `0` hot-path temporary arrays. This remains scaffold
evidence, not ecRad/ecCKD reference validation.
The dedicated Breeze checkout also contains
`benchmarking/radiative_heating_reduced_pareto.jl`, which runs multiple toy
g-point counts and writes a combined CPU Pareto scaffold report. The latest
16/16, 32x16, and 32/32 report is in
`benchmarking/results/reduced_pareto/radiative_heating_reduced_pareto_latest.md`;
it records isolated radiation timing, Breeze `update_state!` timing, gas-optics
host memory, workspace host memory, and hot-path temporary array counts for
16/16, 32x16, and 32/32 toy cases. With typed `NamedTuple` gas columns in the
Breeze extension, the latest fixed-gas-model one-sample CPU medians are
`9.913615` ms, `13.202653` ms, and `16.774407` ms for isolated radiation,
respectively, with zero hot-path temporary arrays. The 32x16 case is only a
32b-like scaffold proxy until a real ecCKD 32b model is available. This is not
final reduced-model evidence because ecRad/ecCKD accuracy, hard Breeze
threshold pass/fail, H100 device memory/timing, Nsight profiles, and production
RRTMGP comparison remain open.
The matching reduced accuracy scaffold,
`benchmarking/radiative_heating_reduced_accuracy.jl`, compares reduced toy
g-point counts against the toy 32/32 case on the same RCEMIP-style Breeze state
and writes `benchmarking/results/reduced_accuracy/radiative_heating_reduced_accuracy_latest.md`.
The current 16/16-vs-32/32 toy report records flux-divergence RMSE
`4.75381805359e-05` and max absolute error `0.000277839124546`, flux RMSE
`0.195566875303`, TOA flux RMSE `0.260161495052`, and surface flux RMSE
`0.3725245635`. The 32x16 toy proxy has flux RMSE `0.0839111097546` and
surface flux RMSE `0.506458113391` against the toy 32/32 reference. The report
includes a toy threshold pass/fail gate and the current 16/16 and 32x16 reduced
cases pass that toy gate. This is explicitly not ecRad/ecCKD reference
validation and does not replace the hard Breeze threshold gate.

The dedicated Breeze checkout also contains
`benchmarking/radiative_heating_gpu_environment_check.jl`, which writes
`benchmarking/results/gpu_environment/radiative_heating_gpu_environment_latest.md`.
The login-shell report is blocked because it is outside a GPU allocation, but
the Slurm H100 job-step report at
`benchmarking/results/gpu_environment_h100_job764_with_nsight/radiative_heating_gpu_environment_latest.md`
marks the H100/Nsight preflight ready: H100 detected `true`, `nvidia-smi`
available `true`, CUDA.jl functional `true`, `nsys` available `true`, and
`ncu` available `true`.
For H100 execution, the dedicated Breeze checkout now has
`benchmarking/radiative_heating_h100_acceptance.sh`. It runs the GPU preflight,
the RCEMIP-style RadiativeHeating/RRTMGP comparison, and Nsight Systems /
Nsight Compute collection. The final accepted H100 artifact is still missing:
`benchmarking/results/rcemip_h100_32x32x64/radiative_heating_rcemip_latest.json`
must support `final_4x_claim_supported = true`, use
`gas_model_source = validated_ecCKD`, and retain the 1024-column
RCEMIP-style workload with Nsight Systems and Nsight Compute reports. Existing
H100/Nsight scaffold artifacts are useful preflight evidence, but they are not
the final validated-ecCKD production comparison.

Host-model access-point artifact: `validation/access_points_check.jl` writes
`validation/results/access_points_check.json` and `.md`. It verifies the staged
runtime symbols are exported and that gas optical properties, cloud optical
properties, longwave/shortwave solvers, and heating-rate conversion are callable
as separate component steps. The current report passes and confirms a host model
can stop after gas optics or replace the solver/vertical integral path.

Current differentiable-training scaffold: `validation/toy_ecckd_training.jl`
runs a deterministic fixed-topology toy ecCKD training problem, writes
`validation/results/toy_ecckd_training.json` and `.md`, and verifies that loss
drops from `0.0113011861681` to `6.62185338745e-05` with finite-difference
gradient relative difference `6.24261421237e-10` against a `1e-4` threshold.
The report now also records reproducible configuration metadata and shows
improved toy forward metrics: flux RMSE drops from `0.106306902776` to
`0.00813742167428` W m^-2, and heating-rate RMSE drops from
`0.00169086417626` to `0.000300394647974` K day^-1. When run under the Breeze
test environment where Enzyme and Reactant are available, the same report
records an Enzyme gradient check for a smooth two-stream radiative loss with
relative error `4.27732803781e-10` and a passing Reactant toy loss compilation
check. The full RRTMGP-target 16-g calibration artifact now exercises a pure,
unrolled package-equivalent shortwave loss with Reactant compilation and Enzyme
reverse-mode training, while the mutating radiative-transfer pipeline remains a
future differentiability target. This toy fixture is not enough to close the
end-to-end gas-optics training deliverable: the audit now requires a separate
`validation/results/official_ecckd_training.json` production/reduced ecCKD
training artifact before this requirement can be marked complete. That
artifact now exists and demonstrates a deterministic two-iteration
official/reduced ecCKD training path: the normalized reduced hard-gate
objective decreases from about `214.26` to `213.31`, with Reactant and Enzyme
checks passing. It records `hard_accuracy_target_met = false`, so it satisfies
the training-path evidence but does not close the reduced-accuracy blocker.

Official reduced AD evidence is now separated from the expensive flux
optimizer. `validation/reduced_ecckd_official_ad_checks.jl` writes
`validation/results/reduced_ecckd_official_ad_checks.*` and verifies the
official reduced 32x16 surrogate parameter path with both AD backends:
Reactant is available and compiles the surrogate, and Enzyme is available with
finite-difference gradient relative error `4.19599644067e-11` against the
`1e-4` threshold. Together with the RRTMGP-target 16-g calibration artifact,
the goal audit now marks the Reactant/Enzyme optimization path as satisfied.
The remaining Step 2 blocker is strictly the reduced shortwave hard-gate
accuracy decision.

Current all-sky/cloud scaffold: `src/solvers/cloud_optics.jl` defines
`CloudOpticalProperties`, `LayerCloudOpticsModel`,
`LayerLiquidIceCloudOpticsModel`, and `add_cloud_optical_depths!` so layer
cloud optical depth can be evaluated independently from gas optics and added
to precomputed longwave/shortwave optical properties. The liquid/ice model
keeps liquid water path, ice water path, cloud fraction, shortwave
single-scattering albedo, and shortwave scattering asymmetry as separate
access points for host models and the ecRad candidate writer. Cloud shortwave
extinction is now split into absorption and scattering channels before
composition with gas optics, and scattering asymmetry is combined by optical
depth. This gives the staged runtime interface an initial all-sky composition
path while keeping gas optics, cloud optics, and solvers separately testable.
`test/test_cloud_optics.jl` covers cloud optical-depth evaluation,
phase-separated liquid/ice/cloud-fraction evaluation, cloud scattering
composition including asymmetry, gas+cloud optical-depth combination, and a
shortwave all-sky smoke case where cloud absorption reduces surface flux.
The same absorption/scattering/asymmetry partition is available for staged
layer aerosol optics. `validation/ecrad_all_sky_ifs_gate.jl` now summarizes the
current IFS all-sky evidence and passes: the official ecCKD all-sky hard gate
passes, the best cloud/aerosol/overlap sweep has worst threshold ratio about
`0.387`, the reference-optics Tripleclouds solver agrees to about `1e-5`
W m^-2 at the boundaries, and cloud scattering table ingestion passes.

Current reduced-model accuracy evidence: `validation/reduced_ecckd_accuracy.jl`
evaluates 32x16 and 16x16 reduced ecCKD variants against the clean ecCKD
tropical and RCEMIP-style cloudless/no-aerosol references. It writes both
`validation/results/reduced_ecckd_accuracy.*` and the dedicated Breeze
checkout's
`benchmarking/results/reduced_accuracy/radiative_heating_reduced_accuracy_latest.*`.
`validation/ecckd_32b_baseline_check.jl` now records the 32b baseline
explicitly: the default official ecCKD path loads
`ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc` and
`ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc`, yielding 32 longwave and 32
shortwave g-points with normalized weights, and ties that baseline to the
passing full 32x32 reduced-accuracy anchor.
The first real downselection, weighted-bin, and subset-search trials fail hard
thresholds. The reduced validation path now preserves reduced g-point surface
albedo and incoming shortwave spectral weights instead of falling back to
broadband boundary conditions. With that corrected bookkeeping, the official
32x32 ecCKD baseline passes the same clean references with worst TOA/surface
forcing errors of about `0.008` and `0.014` W m^-2. The best current 32x16
accuracy-table trial remains the weighted greedy shortwave subset
(`1, 4, 9, 10, 12, 13, 14, 16, 21, 22, 25, 27, 28, 30, 31, 32`) with projected
simplex weights; it reduces worst TOA/surface forcing errors to about `5.52`
and `3.18` W m^-2. That is still well outside the hard `0.3` W m^-2 forcing
thresholds. Extended projected max-norm weight optimization did not materially
improve this subset, and the size scan still finds that only the full 32-g
shortwave path passes. This replaces the earlier placeholder "blocked by ecRad
gate" reduced-accuracy artifact with concrete evidence, but the reduced Pareto
remains scientifically blocked until a real reduced shortwave optimization
method, not simple g-point selection, meets the hard thresholds.
The reduced evaluator now treats registered reduced models differently from the
full official ecCKD model: full official ecCKD still uses the materialized
ecRad incoming shortwave spectrum, while reduced models use their own reduced
quadrature weights. `test/test_reduced_ecckd_metadata.jl` covers this metadata
and boundary-array mapping behavior.
An exploratory separate absorption/Rayleigh scaling probe for the weighted
greedy 32x16 subset did not improve the current best model: it ended around
`10.35` W m^-2 TOA and `7.12` W m^-2 surface forcing error, worse than the
projected-weight subset. This supports the current conclusion that the 16-g
shortwave goal needs a real reduction/optimization workflow rather than scalar
post-hoc tuning of selected official g-points.
`validation/reduced_ecckd_gap_report.jl` now writes
`validation/results/reduced_ecckd_gap_report.*` as the canonical blocker
summary. It states which simple 16-g strategies have been ruled out and points
the next implementation step at reduced shortwave k-distribution
optimization/generation rather than additional subset tuning.
`validation/reduced_ecckd_subset_search.jl` is the executable subset-search
artifact behind that conclusion. It now scans boundary weights `1`, `3`, `10`,
and `30` for projected-weight subset searches. The best approximate trial uses
boundary weight `30`, selects
`1, 4, 6, 9, 10, 12, 13, 14, 16, 18, 21, 22, 25, 27, 28, 30`, and still fails
with worst TOA/surface forcing errors of about `6.40` and `3.63` W m^-2. The
companion optimization preflight also records a topology-candidate scan from
the official reduced-accuracy artifact: 11 measured 32x16 topologies all fail
the forcing gate, and the best current topology is the weighted-greedy
projected hard-gate/max-norm subset with a forcing-objective lower bound of
about `18.4` relative to the target `1.0`.

The dedicated Breeze extension also accepts optional
`NumericalRadiation.AbstractCloudOpticsModel` through the `cloud_optics`
keyword. Its CPU runtime path evaluates cloud optical properties, adds them to
gas optical depths, and then calls the same longwave/shortwave solver path.
It also accepts optional `NumericalRadiation.AbstractAerosolOpticsModel`
through the `aerosol_optics` keyword and composes aerosol optical depth in the
same staged path.
`julia --project=test test/runtests.jl radiative_heating_extension` in the
dedicated Breeze checkout now passes with 52 assertions, including cloudy and
aerosol column cases where additional shortwave absorption reduces surface
downwelling shortwave flux relative to the clear column.

Cloud validation artifact: `validation/toy_cloud_validation.jl` writes
`validation/results/toy_cloud_validation.json` and `.md`, validates the
absorptive cloud scaffold against stored deterministic cloudy flux/heating
references, and checks that cloudy surface shortwave flux is lower than the
clear fixture. This remains a toy fixture, not ecRad all-sky validation.

ecRad reference manifest: `validation/ecrad_reference_manifest.jl` writes
`validation/results/ecrad_reference_manifest.json` and `.md`. It defines the
first required external reference files:
`validation/reference/ecrad/clear_sky_tropical_column.nc`,
`validation/reference/ecrad/all_sky_tropical_column.nc`, and
`validation/reference/ecrad/rcemip_style_column_subset.nc`, along with initial
hard thresholds for flux, heating-rate, TOA forcing, and surface forcing
errors. When NCDatasets is available in the active Julia environment and the
files exist, the manifest also checks that required NetCDF variables are
present. A shallow upstream ecRad checkout has been materialized under
`validation/external/ecrad`, and `validation/materialize_ecrad_references.jl`
now writes the three expected reference files from ecRad `test/ifs` inputs and
reference outputs. The current manifest status is
`references_present_schema_valid`. `validation/write_ecrad_candidates.jl` now
writes first-pass `radiative_heating_*` variables using the current staged
ABR gas-optics/solver path, and `validation/ecrad_candidate_schema.jl` reports
`passed`. The full hard accuracy gate now reaches numerical comparison and
still reports `failed_threshold` because the all-sky reference cases require
cloud, aerosol, scattering, overlap, and solver conventions that are not yet
implemented. The focused clean ecCKD cloudless/no-aerosol hard gate now passes
for both tropical and RCEMIP-style subsets. `validation/ecrad_accuracy_diagnostics.jl` now writes
`validation/results/ecrad_accuracy_diagnostics.json` and `.md`, ranking the
largest threshold exceedances; the current worst misses are all-sky TOA and
surface forcing, followed by all-sky shortwave and heating-rate errors.
Reference-file placement and schema expectations are summarized in
`validation/reference/ecrad/README.md`.

The official ecCKD reader now also ingests the shortwave Rayleigh coefficient
table and exposes it through `ShortwaveOpticalProperties.rayleigh_optical_depth`
with ecRad-compatible pressure scaling. The refreshed
`validation/ecckd_official_files_check.jl` artifact reports a maximum Rayleigh
optical depth of about `1.0099` for the smoke column, replacing the earlier
unit-inflated value. `CloudlessShortwave` now uses Rayleigh optical depth in a
conservative layered scattering approximation. That moved the clear-sky
tropical shortwave mean biases from roughly `-27.8` to `+1.6` W m^-2 for
`sw_up` and from roughly `+21.2` to `+3.4` W m^-2 for `sw_down`; later
ecRad-style direct/diffuse adding and gas-optics convention fixes closed the
focused clean ecCKD cloudless/no-aerosol gate.
The materialized ecRad reference files now preserve the input
`cos_solar_zenith_angle` and `solar_irradiance`, and use ecRad's
pressure-weighted full-level temperature convention for `temperature_layer`.
The candidate writer passes `cos_zenith` through `ColumnAtmosphere.geometry`,
while `CloudlessShortwave` scales optical depth by `1 / cos_zenith` when that
field is present. These convention fixes improved the RCEMIP-style surface
forcing miss from about `72.8` W m^-2 to about `61.4` W m^-2 and formed part
of the final focused cloudless-gate fix.
`CloudlessLongwave` now supports both scalar and spectral surface longwave
boundary fluxes. For official ecCKD candidates, the writer distributes the
prescribed broadband surface longwave flux across g-points using the ecCKD
Planck table, then uses the ecRad no-scattering interface-source path by
default. This reduced the cloudless tropical longwave RMSEs to about `3.34`
W m^-2 for `lw_up` and `1.98` W m^-2 for `lw_down`, and reduced the tropical
heating-rate RMSE to about `1.26` K day^-1.
The official ecCKD candidate now includes the relevant gases from the official
LW/SW tables and the ecRad IFS reference input: H2O, O3, CO2, CH4, N2O,
CFC11, and CFC12, plus the ecCKD composite background-gas absorption term per
mole of air. Missing shortwave CFC coefficients are represented as zero
shortwave absorption so the shared runtime gas set can still carry longwave
CFC absorption.
The official ecCKD runtime reader now also preserves the H2O mole-fraction
dimension in the official coefficient files and interpolates it per layer from
the column H2O amount and pressure thickness instead of sampling one fixed H2O
slice for the whole atmosphere. It also applies official relative-linear
reference mole fractions, so CH4 and N2O use the ecRad-compatible
`(vmr - reference_vmr)` contribution. With dynamic H2O interpolation, Rayleigh
scattering, the composite background-gas term, CFCs, relative-linear gas
handling, ecRad-style shortwave direct/diffuse adding, spectral boundary
fixtures, and interface Planck sources enabled, the clean ecCKD cloudless gate
passes. The latest clean ecCKD tropical case has TOA/surface mean biases of
about `-0.028` and `-0.010` W m^-2; the clean ecCKD RCEMIP-style subset has
about `-0.027` and `-0.0045` W m^-2.
`validation/ecrad_flux_bias_diagnostics.jl` now writes signed
candidate-minus-reference bias artifacts. The latest cloudless diagnostics show
the focused clean ecCKD gate is now within the hard flux, heating-rate, TOA,
and surface thresholds. The current IFS all-sky gate is now captured by
`validation/ecrad_all_sky_ifs_gate.jl` and passes; the remaining ecRad-side
blocker is reduced-model accuracy evidence, not the first cloudless gate.
The upstream ecRad checkout includes ecCKD Tripleclouds/McICA reference output
files, but the bundled clear fluxes from those files are not a clean
cloudless/no-aerosol reference because they come from the ecCKD all-sky
configuration context with aerosol settings. A local `bin/ecrad` driver has
now been built in `validation/external/ecrad` using locally extracted NetCDF
and HDF5 libraries, and it generated
`test/ifs/ecrad_meridian_ecckd_cloudless_noaer_out.nc` from an
`ECCKD + Cloudless + no aerosol` namelist. The materializer now writes clean
ecCKD cloudless/no-aerosol reference files from that output, and the focused
hard gate includes the clean ecCKD tropical/RCEMIP-style cases.

Current completion audit: `validation/results/goal_audit_check.*` maps the full
`/goal` deliverables to implemented evidence and remaining blockers. It
currently marks the goal as not complete because the reduced 16-g ecCKD/RRTMG
accuracy threshold and optimization target still fail. The official ecCKD hard
gate, all-sky ecRad accuracy diagnostics, package-native RRTMGP comparison
extension, Reactant/Enzyme path, end-to-end gas-optics training, dedicated Breeze
extension, H100 environment check, Nsight reports, and realistic RCEMIP-style
H100 >=4x RRTMGP benchmark are present. The remaining audit blockers are
downstream of the reduced-model hard-threshold failure and are summarized by the
`decision_required` reduced acceptance artifact.
The executable audit command
`julia --project=. validation/goal_audit_check.jl` writes
`validation/results/goal_audit_check.json` and `.md`, verifies the current
scaffold artifacts, and currently reports status `not_complete`.

The remaining ecRad work must proceed through three concrete implementation
steps:

1. Pass a focused cloudless/no-aerosol ecRad gate first, using
   `validation/ecrad_cloudless_accuracy_gate.jl`, so gas optics and clear-sky
   solver conventions are debugged before all-sky physics is added. This step
   now passes for the clean ecCKD tropical and RCEMIP-style references.
2. Replace the current fixed toy coefficients with real ecCKD/RRTMG-compatible
   gas optics, including reduced 32/32b/16-term models that can support the
   Breeze accuracy/runtime Pareto reports.
3. Keep the current IFS all-sky conventions passing: cloud liquid/ice optics,
   aerosols, scattering, overlap, and solver semantics are summarized by
   `validation/ecrad_all_sky_ifs_gate.jl`, which currently passes against the
   full ecRad evidence stack.

## Location

```text
Breeze.jl/ext/BreezeRadiativeHeatingExt.jl
```

## Tasks

1. Create or select the dedicated Breeze checkout for this project and record its path.
2. Add weak dependency from Breeze to RadiativeHeating in the dedicated checkout.
3. Define Breeze-facing radiation type, for example:

   ```julia
   RadiativeHeatingRadiation(...)
   ```

4. Convert Breeze model fields into RadiativeHeating column/batch states.
5. Call `RadiativeHeating.radiative_fluxes!` or high-level runtime API.
6. Convert flux divergence into Breeze heating tendencies.
7. Respect Breeze scheduling for intermittent radiation updates.
8. Avoid unnecessary column packing where possible.
9. Prefer direct views or fused extraction kernels when they reduce temporary arrays.
10. Benchmark packing/extraction separately from radiation.
11. Add Breeze docs and examples.

## Breeze extension responsibilities

```text
Breeze model state
    ↓
Breeze extension column/batch view, fused extraction kernel, or packed state
    ↓
RadiativeHeating component or runtime call
    ↓
flux divergence
    ↓
Breeze heating tendency
```

The extension must not contain ecCKD parser logic or solver mathematics.
It may own Breeze-specific storage, scheduling, direct field views, and fused kernels that call RadiativeHeating low-level kernels.

## Metrics

| Metric | Success criterion |
|---|---|
| Breeze accepts RadiativeHeating radiation object | a Breeze model can be constructed with `RadiativeHeatingRadiation(...)` or the final chosen API |
| Dedicated Breeze checkout used | benchmark metadata and PR notes identify the dedicated Breeze checkout path; unrelated local Breeze checkouts are untouched |
| Single-column Breeze result equals standalone RadiativeHeating | max absolute heating-rate difference <= 1e-10 K day^-1 for Float64 and <= 1e-5 K day^-1 for Float32, unless the test documents a looser convention-related tolerance |
| Breeze clear-sky GPU example runs | example completes on CUDA when available and reports flux/heating metrics |
| Breeze cloudy GPU example runs when cloudy stage exists | example completes on CUDA when available and reports flux/heating metrics |
| Column extraction time reported | Breeze benchmark JSON includes `column_extraction_runtime_ms_median` |
| Radiation call time reported | Breeze benchmark JSON includes `radiation_core_runtime_ms_median` |
| Heating insertion time reported | Breeze benchmark JSON includes `heating_insertion_runtime_ms_median` |
| Temporary-array footprint reported | Breeze benchmark JSON includes temporary array count/bytes for extraction, radiation core, and insertion |
| Direct-view or packed-state choice documented | benchmark report states whether the case uses direct views, fused extraction, or packed columns |
| No scalar indexing | zero CUDA scalar-indexing warnings in tests and benchmark smoke runs |
| Hot-path allocations | zero |
| Docs page in Breeze | `docs/src/radiation/radiative_heating.md` exists, is linked from the Breeze docs index, and documents benchmark interpretation |

## Breeze benchmark targets

| Configuration | Target |
|---|---:|
| RRTMGP-like complexity radiation update | >= 4x faster than Breeze+RRTMGP |
| ecCKD 32-term radiation update | >= 5x to 8x faster than Breeze+RRTMGP |
| ecCKD 16-term radiation update | >= 8x to 15x faster than Breeze+RRTMGP |
| Whole timestep impact | reported honestly |

Whole-timestep speedup may be lower than radiation speedup if radiation is not the dominant cost. Report both.

## Tests

- Single-column Breeze/RadiativeHeating equality test.
- Small 2D Breeze clear-sky test.
- Small 3D Breeze clear-sky test if feasible.
- GPU smoke test.
- Heating tendency sign convention test.
- Radiation update scheduling test.

## Docs

Add in Breeze docs:

```text
docs/src/radiation/radiative_heating.md
```

## Examples

```text
Breeze.jl/examples/radiation/radiative_heating_clear_sky.jl
Breeze.jl/examples/radiation/radiative_heating_cloudy.jl
Breeze.jl/examples/radiation/compare_radiative_heating_rrtmgp.jl
```

## Exit criteria

```text
Breeze extension works
Breeze tests pass
Breeze docs build
Breeze examples run
Breeze benchmark compares RadiativeHeating and RRTMGP.jl
dedicated Breeze checkout path recorded; other local Breeze checkouts untouched
```

---

# Stage 10 — Clouds, aerosols, and all-sky solvers

## Goal

Expand from clear-sky to all-sky radiation while preserving testability and benchmark decomposition.

## Suggested order

```text
1. homogeneous clouds
2. cloud overlap model
3. Tripleclouds
4. McICA
5. SPARTACUS later
```

Start with deterministic solvers before stochastic McICA.

## Tasks

1. Implement liquid cloud optical properties.
2. Implement ice cloud optical properties.
3. Implement homogeneous all-sky solver.
4. Implement cloud fraction edge cases.
5. Implement cloud overlap model.
6. Implement Tripleclouds.
7. Implement McICA with explicit reproducible RNG.
8. Compare all-sky cases to ecRad.

## Correctness metrics

| Quantity | Threshold |
|---|---:|
| Homogeneous cloudy flux RMSE versus ecRad | <= 0.1 W m^-2 initially |
| Heating-rate RMSE versus ecRad | <= 0.01 K day^-1 initially |
| Cloud fraction = 0 | exact clear-sky behavior |
| Cloud fraction = 1 | exact full-cloud behavior |
| McICA with fixed RNG | reproducible |
| Randomized physical columns | no NaNs |

## Performance metrics

| Benchmark | Target |
|---|---:|
| Homogeneous cloudy 32-term ecCKD versus RRTMGP.jl all-sky | >= 4x |
| Homogeneous cloudy 16-term ecCKD versus RRTMGP.jl all-sky | >= 8x |
| Cloud optics overhead | reported |
| Solver overhead | reported |
| McICA overhead | reported |

## Docs

Add:

```text
docs/src/clouds.md
docs/src/solvers/all_sky.md
```

## Examples

```text
examples/ecckd_cloudy_fluxes.jl
examples/compare_all_sky_to_ecrad.jl
```

## Exit criteria

```text
homogeneous all-sky cases validated against ecRad
cloudy benchmarks reported
Breeze cloudy example works
```

---

# Stage 11 — Reduced-model accuracy/speed Pareto suite

## Goal

Quantify the speed/accuracy tradeoff across ecCKD 64/32/16-term models and make reduced optics a defensible scientific choice.

## Required model set

Where available:

```text
LW 16-term
LW 32-term
LW 32b-term
LW 64-term reference
SW 16-term
SW 32-term
SW 32b-term
SW 64/96 specialized reference where applicable
```

## Metrics

| Metric | Meaning |
|---|---|
| `RMSE(F_lw_up_TOA)` | LW top-of-atmosphere upwelling flux error in W m^-2 over the named validation case set |
| `RMSE(F_lw_down_surface)` | LW surface downwelling flux error in W m^-2 over the named validation case set |
| `RMSE(F_sw_down_surface)` | SW surface downwelling flux error in W m^-2 over the named validation case set |
| `RMSE(heating_rate)` | profile heating-rate error in K day^-1 over all selected layers and columns |
| `max_abs(heating_rate_error)` | catches localized stratospheric or surface outliers |
| forcing error | gas perturbation tests where data are available |
| runtime | median synchronized GPU runtime |
| memory footprint | model data + working arrays |
| speedup | relative to RRTMGP.jl and relative to ecCKD 64-term |

## Required output table

Generate a table like:

| Model | LW terms | SW terms | Flux RMSE | Heating RMSE | GPU speedup vs RRTMGP.jl |
|---|---:|---:|---:|---:|---:|
| ecCKD reference | 64 | 64 | ... | ... | ... |
| ecCKD climate-32b | 32 | 32 | ... | ... | ... |
| ecCKD climate-32 | 32 | 32 | ... | ... | ... |
| ecCKD climate-16 | 16 | 16 | ... | ... | ... |

## Plots

```text
error_vs_runtime.png
speedup_vs_terms.png
heating_rmse_vs_terms.png
memory_vs_terms.png
```

## Docs

Add:

```text
docs/src/gas_optics/ecckd_pareto.md
```

## Exit criteria

```text
accuracy/speed Pareto table generated
plots generated
docs explain which model to use when
Breeze examples allow selecting 16/32/64-term models
```

---

# Stage 12 — Differentiable ecCKD optimization workflow

## Goal

Reimplement the continuous optimization part of ecCKD model generation in a differentiable Julia workflow using Enzyme.jl and Reactant.jl.

## Important conceptual split

Do not try to differentiate the entire ecCKD generation process at first. Split it into:

```text
Discrete/topological stages:
    band definitions
    spectral grouping
    g/k-term partitioning
    model topology

Continuous stages:
    LUT coefficients
    scaling factors
    source-function parameters
    smooth correction factors
```

Reactant/Enzyme should first target the continuous stages.

## Tasks

1. Reproduce reference-compatible ecCKD generation workflow at a high level.
2. Implement toy spectral dataset generation.
3. Implement differentiable loss for flux and heating-rate error.
4. Implement Enzyme gradient checks against finite differences.
5. Implement Reactant-compatible toy optimization if feasible.
6. Optimize LUT coefficients for fixed spectral topology.
7. Compare generated toy model against reference toy model.
8. Scale up gradually toward CKDMIP-style data.

## Suggested API

```julia
struct EcCKDOptimizationProblem{F, D, M, W}
    forward_model::F
    dataset::D
    metric::M
    weights::W
end

loss(θ, problem::EcCKDOptimizationProblem) = ...
```

## Loss components

```julia
loss(θ) =
    w_flux      * flux_error(θ) +
    w_heating   * heating_rate_error(θ) +
    w_spectral  * spectral_boundary_error(θ) +
    w_prior     * prior_regularization(θ) +
    w_smooth    * smoothness_regularization(θ)
```

## Metrics

| Metric | Success criterion |
|---|---|
| Enzyme gradients versus finite differences | relative error <= 1e-4 initially |
| Reactant compilation of toy loss | passes if feasible |
| Toy optimization loss | final loss is lower than initial loss and either decreases monotonically for line-search methods or reaches a documented target for stochastic/accelerated methods |
| Optimized toy flux RMSE | improves over initial model |
| Optimized toy heating-rate RMSE | improves over initial model |
| Reproducibility | fixed seed/config reproduces result |
| Docs | complete toy workflow |
| Heavy CKDMIP workflow | documented, not ordinary CI |

## Docs

Add:

```text
docs/src/ecckd_generation.md
docs/src/differentiation.md
```

## Examples

```text
examples/optimize_ecckd_toy_model.jl
```

The toy example should run quickly, ideally in minutes or less, and print:

```text
initial loss
final loss
initial flux RMSE
final flux RMSE
initial heating-rate RMSE
final heating-rate RMSE
gradient check error
optimization wall time
number of trainable parameters
```

## Exit criteria

```text
toy differentiable optimization works
Enzyme gradient check passes
Reactant path tested or limitation documented
loss decreases
example and docs complete
```

---

## 9. Pull request sequence

The following PR sequence should keep the work reviewable and measurable.

### PR 1 — Rename and scaffold

Exit criteria:

```text
package renamed
old analytic-band functionality preserved
new abstract interfaces added
old tests pass
new architecture docs build
analytic-column example runs
benchmark harness can time analytic backend
```

### PR 2 — Benchmark harness and RRTMGP baseline

Exit criteria:

```text
benchmark suite writes JSON and Markdown
RRTMGP.jl gas optics benchmark works
RRTMGP.jl RTE benchmark works
RRTMGP.jl full radiation benchmark works
Breeze+RRTMGP baseline benchmark works
spectral dimensions reported from loaded files
```

### PR 3 — ecCKD reader

Exit criteria:

```text
ecCKD definition files load
schema validation passes
summary table generated
docs page added
file-summary example runs
```

### PR 4 — ecCKD gas optics, CPU

Exit criteria:

```text
pressure/temperature interpolation implemented
concentration dependence implemented
LW/SW optical properties computed
comparison against ecRad optical properties passes for selected columns
CPU benchmark recorded
no hot-path allocations after setup
```

### PR 5 — ecCKD gas optics, GPU

Exit criteria:

```text
GPU optical-property kernels implemented
CPU/GPU agreement passes
16/32/64-term GPU benchmarks recorded
no scalar indexing
no GPU allocations in hot path
```

### PR 6 — Clear-sky solvers

Exit criteria:

```text
LW clear-sky solver implemented
SW clear-sky solver implemented
heating-rate conversion implemented
flux and heating-rate comparisons against ecRad pass
clear-sky examples run
clear-sky benchmark reports speedup
```

### PR 7 — First GPU optimization milestone

Exit criteria:

```text
>= 2x speedup for 64-term ecCKD full clear-sky call
>= 5x speedup for 32-term ecCKD full clear-sky call
>= 8x speedup for 16-term ecCKD full clear-sky call
kernel profile included in benchmark report
no accuracy regression
```

### PR 8 — Similar-complexity 4x milestone

Exit criteria:

```text
RRTMGP-like complexity benchmark implemented
>= 4x speedup over RRTMGP.jl on agreed GPU case
benchmark frozen as regression guard
accuracy differences documented
```

### PR 9 — Breeze extension in Breeze.jl

Exit criteria:

```text
Breeze weak dependency added
BreezeRadiativeHeatingExt implemented
single-column Breeze result matches standalone RadiativeHeating
Breeze GPU example runs
Breeze+RadiativeHeating benchmark compares against Breeze+RRTMGP
Breeze docs page added
dedicated Breeze checkout path recorded; other local Breeze checkouts untouched
```

### PR 10 — Homogeneous cloudy/all-sky path

Exit criteria:

```text
cloud optical properties implemented
homogeneous all-sky solver implemented
cloud fraction edge cases pass
all-sky fluxes compared to ecRad
cloudy Breeze example runs
cloudy benchmark reports speedup
```

### PR 11 — Reduced ecCKD Pareto suite

Exit criteria:

```text
16/32/64-term accuracy-speed table generated
plots generated
docs explain model tradeoffs
Breeze examples can select reduced models
```

### PR 12 — Differentiable toy ecCKD optimization

Exit criteria:

```text
toy model-generation workflow implemented
Enzyme gradient check passes
Reactant compilation tested if feasible
optimization loss decreases
docs and example added
```

---

## 10. Detailed benchmark design

### 10.1 CPU benchmarking

Use `BenchmarkTools.@benchmark`, `@benchmarkable`, `tune!`, and `run` where appropriate.

Report:

```text
minimum
median
mean
p90
memory allocations
bytes allocated
GC time
```

Benchmark functions should separate setup from execution. Do not include file I/O unless intentionally measuring file I/O.

### 10.2 GPU benchmarking

GPU operations may be asynchronous, so benchmark bodies must synchronize.

Example pattern:

```julia
using CUDA, BenchmarkTools

trial = @benchmark begin
    CUDA.@sync radiative_fluxes!($fluxes, $solver, $optics, $atmosphere, $boundary_conditions)
end
```

For deeper profiling:

```julia
CUDA.@profile radiative_fluxes!(fluxes, solver, optics, atmosphere, boundary_conditions)
```

For milestone GPU reports, also run Nsight Systems and Nsight Compute on representative cases. Store the generated `.nsys-rep` and `.ncu-rep` files under `benchmark/results/profiles/` and link them from the JSON and Markdown reports.

For optimized kernels, collect:

```text
kernel launches
kernel time
memory throughput
register count
shared memory per block
occupancy estimate
host/device transfer count
GPU allocations
Nsight Systems report path
Nsight Compute report path
```

### 10.3 Benchmark sizes

Include at least:

```text
columns = 1, 32, 1024, 16384, 65536
layers = 32, 64, 128, 256
precision = Float32, Float64 where feasible
models = RRTMGP-like, ecCKD-64, ecCKD-32, ecCKD-16
clouds = none, homogeneous cloudy
```

### 10.4 Performance regression policy

A benchmark regression should be flagged when:

```text
runtime increases by > 10% for frozen benchmarks
or allocations become nonzero
or kernel launch count unexpectedly increases
or GPU scalar indexing appears
or accuracy degrades beyond tolerance
```

Performance regressions may be accepted only with a written explanation and updated target.

---

## 11. Validation strategy

### 11.1 Layered validation

Validate in this order:

```text
1. schema and file ingestion
2. table interpolation
3. gas optical properties
4. source terms
5. boundary conditions
6. no-atmosphere solver behavior
7. single-layer analytic cases
8. clear-sky multi-layer cases
9. ecRad clear-sky comparison
10. cloudy/all-sky ecRad comparison
11. Breeze single-column comparison
12. Breeze multi-column application comparison
13. CKDMIP heavy/manual evaluation
```

### 11.2 Reference-code comparisons

Use:

- ecRad for ecCKD gas optics and solver behavior.
- RRTMGP.jl for current Julia/Breeze performance baseline.
- CKDMIP/line-by-line data for heavy ecCKD model-generation evaluation.

### 11.3 Scientific metrics

Report:

```text
TOA LW upwelling flux
surface LW downwelling flux
TOA SW reflected flux
surface SW downwelling flux
net flux profiles
heating-rate profiles
column-integrated energy closure
forcing changes under gas perturbations
```

### 11.4 Numerical tolerances

Initial tolerances should be strict for controlled cases:

```text
interpolation at table node: roundoff-level
optical depth versus ecRad Float64: <= 1e-6 relative where well-conditioned
optical depth versus ecRad Float32: <= 1e-4 relative where well-conditioned
flux RMSE versus ecRad: <= 0.05 W m^-2 for same optics
heating-rate RMSE versus ecRad: <= 0.005 K day^-1 for same optics
```

If ecRad comparison reveals convention differences, update tolerances only after documenting the difference.

---

## 12. Breeze-specific implementation rules

Follow Breeze's style and GPU rules.

Key rules for Breeze extension work:

- Use KernelAbstractions.jl kernels where appropriate.
- Kernels must be type-stable and allocation-free.
- Use `@kernel`, `@index`, and `launch!` patterns.
- Avoid scalar indexing on GPU.
- Avoid looping over grid points outside kernels.
- Do not pass whole model objects into kernels.
- Use concrete typed structs.
- Keep construction/materialization separate from hot calls.
- Avoid hidden global state.
- Keep RNG explicit for stochastic solvers.
- Respect Breeze's tendency and scheduling APIs.

### 12.1 Breeze API sketch

In Breeze:

```julia
radiation = RadiativeHeatingRadiation(
    gas_optics = EcCKDGasOptics(:climate_32b),
    longwave_solver = HomogeneousLongwave(),
    shortwave_solver = HomogeneousShortwave(),
    update_interval = 10minutes,
)

model = AtmosphereModel(grid; radiation)
```

or another API consistent with current Breeze radiation design.

### 12.2 Breeze benchmark report

Each Breeze benchmark should print:

```text
grid size
number of columns
number of vertical levels
radiation update interval
RRTMGP.jl radiation time
RadiativeHeating radiation time
speedup
column extraction time
radiation core time
heating insertion time
total model step time before/after
fraction of model step spent in radiation before/after
max heating-rate difference
mean heating-rate difference
TOA flux difference
surface flux difference
```

---

## 13. Reduced optics success criteria

The reduced models are a central project goal. The project should explicitly demonstrate:

```text
accuracy thresholds stated for each Breeze use case
much faster radiation updates
smaller memory footprint
stable simulations
clear error/runtime tradeoff
```

### 13.1 Minimum reduced-model acceptance

A reduced model should be considered viable only if it passes:

- Standalone clear-sky tests.
- Standalone cloudy tests if used in all-sky simulations.
- ecRad comparison for selected columns.
- Breeze single-column comparison.
- Breeze small-domain stability test.
- Accuracy/runtime Pareto reporting.

The initial hard acceptance thresholds for Breeze use are:

| Model class | LW TOA flux RMSE | LW surface flux RMSE | SW surface flux RMSE | Heating-rate RMSE | Max heating-rate error | Forcing error |
|---|---:|---:|---:|---:|---:|---:|
| ecCKD 64-term reference path | <= 0.25 W m^-2 | <= 0.25 W m^-2 | <= 0.5 W m^-2 | <= 0.01 K day^-1 | <= 0.1 K day^-1 | <= 0.1 W m^-2 or <= 5%, whichever is larger |
| ecCKD 32/32b-term Breeze production candidate | <= 1.0 W m^-2 | <= 1.5 W m^-2 | <= 2.0 W m^-2 | <= 0.05 K day^-1 | <= 0.5 K day^-1 | <= 0.3 W m^-2 or <= 10%, whichever is larger |
| ecCKD 16-term Breeze reduced-speed candidate | <= 3.0 W m^-2 | <= 4.0 W m^-2 | <= 5.0 W m^-2 | <= 0.15 K day^-1 | <= 1.0 K day^-1 | <= 0.75 W m^-2 or <= 20%, whichever is larger |

These thresholds apply to the named validation case set used for the Breeze target application. A threshold may be changed only by documenting the case set, the failure mode, the scientific reason for the change, and the resulting effect on model stability and forcing diagnostics.

Minimum stability gate for Breeze examples:

```text
clear-sky and cloudy small-domain Breeze examples complete without NaNs
heating tendencies remain finite for every grid point and update
energy-closure diagnostics stay within the stage-specific tolerance
no systematic heating-rate sign error appears in column diagnostics
```

### 13.2 Do not overclaim

Use precise language:

Good:

```text
The 32-term ecCKD model is 7.8x faster than Breeze+RRTMGP on this H100 clear-sky benchmark, with LW TOA flux RMSE of 0.XX W m^-2 and heating-rate RMSE of 0.XX K day^-1 against ecRad for this case set.
```

Bad:

```text
RadiativeHeating is 8x faster and equally accurate.
```

---

## 14. Differentiability requirements

Differentiable functions must avoid:

- File I/O.
- Hidden global state.
- Non-deterministic RNG.
- Dynamic dispatch in hot paths.
- Type instability.
- Unsupported mutation/aliasing patterns.
- Non-smooth clamps unless explicitly handled.

Differentiate small, pure kernels first:

```text
LUT interpolation
optical-depth accumulation
clear-sky flux calculation
heating-rate loss
```

Then combine them into larger differentiable workflows.

### 14.1 Gradient checks

For each differentiable function, compare Enzyme gradients to finite differences on small cases:

```text
surface temperature
water vapor profile
CO2 concentration
selected LUT coefficients
cloud liquid path for smooth cloudy paths
```

Initial threshold:

```text
relative gradient error <= 1e-4
```

Adjust only if the function is poorly conditioned or nonsmooth, and document why.

---

## 15. Risks and mitigations

| Risk | Mitigation |
|---|---|
| ecRad/ecCKD conventions differ from our interpretation | validate optical properties before fluxes; build schema summaries; write convention docs |
| RRTMGP.jl baseline includes overhead unrelated to radiation | decompose benchmark into optics, RTE, and Breeze coupling |
| 4x target is not met for similar-complexity model | profile first; report bottleneck; optimize memory layout, shared LUT staging, and kernel launch count |
| Reduced models are fast but inaccurate for target cases | publish Pareto curve; choose model per application; do not hide errors |
| Breeze column packing dominates runtime | benchmark packing separately; implement direct field views or fused extraction kernels |
| GPU kernels become too generic | specialize on 16/32/64/RRTMGP-like spectral sizes |
| Differentiable ecCKD generation becomes too ambitious | start with fixed topology and continuous LUT optimization only |
| CKDMIP dataset too large for CI | keep CKDMIP workflows manual/heavy; use small fixtures and toy problems in CI |
| Stochastic McICA complicates testing and AD | keep RNG explicit; start with deterministic solvers |

---

## 16. Definition of done for the full project

The full project is successful when the following dashboard is green:

| Category | Required result |
|---|---|
| Package tests | all unit, integration, GPU smoke, AD smoke tests pass |
| Docs | architecture, ecCKD reader, solvers, benchmarking, Breeze integration, AD workflow complete |
| Examples | standalone clear sky, standalone cloudy sky, RRTMGP comparison, ecRad comparison, Breeze clear sky, Breeze cloudy, differentiable toy optimization |
| RRTMGP comparison | gas optics, RTE, full radiation, Breeze timestep benchmarks reported |
| ecRad comparison | optical properties, fluxes, and heating rates match selected references |
| CKDMIP comparison | heavy/manual model-generation evaluation workflow documented |
| Similar-complexity speed | >= 4x GPU speedup versus RRTMGP.jl on agreed benchmark |
| Reduced ecCKD speed | 32-term and 16-term models show larger speedups with documented accuracy |
| Breeze integration | extension lives in Breeze and has no reverse dependency from RadiativeHeating to Breeze |
| GPU quality | zero hot-path allocations, zero scalar indexing, profiled kernels |
| Differentiability | finite-difference-verified gradients for representative smooth losses |

---

## 17. Immediate Codex instructions

When implementing from this plan, do not attempt the whole project in one pass. Start with PR 1 unless the repository already has later-stage work.

### First task

```text
Rename/scaffold the package while preserving current functionality.
Add the core interfaces, a column-state abstraction, flux/heating-rate containers, and an analytic-band example.
Add a minimal benchmark harness that times the existing analytic-band path.
Make tests and docs pass.
```

### First task acceptance criteria

```text
1. Existing tests pass.
2. New interface tests pass.
3. Docs build.
4. `examples/analytic_column.jl` runs.
5. `benchmark/benchmark_suite.jl` runs at least one analytic-band case.
6. Hot-path analytic-band call allocates zero objects after setup.
7. No Breeze dependency is added to RadiativeHeating.jl.
```

### Coding style reminder

- Prefer Julia-native typed design over transliteration from Fortran/C++.
- Keep hot paths allocation-free.
- Keep I/O and setup outside kernels.
- Keep solver and optics interfaces separate.
- Make every stage measurable.

---

## 18. Short version for project tracking

```text
Project: RadiativeHeating.jl + BreezeRadiativeHeatingExt

Main goal:
    ecRad-style radiation + ecCKD gas optics in idiomatic Julia,
    with Breeze integration and GPU speedups over RRTMGP.jl.

Architecture:
    RadiativeHeating.jl standalone.
    Breeze extension lives in Breeze.jl.
    Runtime path separate from offline ecCKD generation path.

Performance targets:
    >= 4x faster than RRTMGP.jl for similar gas-optics complexity on GPU.
    >= 5-8x for ecCKD 32-term reduced models.
    >= 8-15x for ecCKD 16-term reduced models.

Every stage must include:
    tests, docs, benchmarks, reference-code comparisons, runnable examples.

First stages:
    1. Pass the cloudless/no-aerosol ecRad hard gate first.
    2. Replace toy/fixed coefficients with real ecCKD/RRTMG-compatible gas optics.
    3. Implement current IFS all-sky cloud, aerosol, scattering, overlap, and solver conventions.
    4. Rename/scaffold.
    5. Benchmark RRTMGP.jl baseline.
    6. Read ecCKD files.
    7. Implement ecCKD gas optics.
    8. Implement clear-sky solvers.
    9. Optimize GPU path.
    10. Add Breeze extension in Breeze.jl.
    11. Build reduced-model Pareto suite.
    12. Add differentiable ecCKD optimization toy workflow.
```

---

## 19. Full `/goal` wording

```text
Concrete objective: deliver RadiativeHeating.jl plus a dedicated-checkout
BreezeRadiativeHeatingExt as a standalone, GPU-capable, differentiable,
ecRad/ecCKD-compatible radiation system that integrates cleanly with Breeze and
SpeedyWeather-style host models, avoids unnecessary temporary arrays, supports
Enzyme/Reactant gas-optics optimization and training, and proves its accuracy
and at least 4x H100 production Breeze speedup over Breeze+RRTMGP on a
realistic RCEMIP-style workload with reproducible tests, benchmarks, profiles,
and reference comparisons. The implementation must proceed through three
ordered acceptance gates: first a focused cloudless/no-aerosol ecRad gate,
second real ecCKD/RRTMG-compatible gas optics and reduced-model evidence, and
third current IFS all-sky cloud/aerosol/scattering/overlap solver conventions
plus the production H100 Breeze/RRTMGP comparison.

Deliverables:

1. Step 1: pass a focused cloudless/no-aerosol ecRad hard accuracy gate using
   clean ecCKD references and package-native `ColumnAtmosphere` /
   `RadiativeFluxes` outputs. This gate must verify clear-sky gas optics,
   longwave source terms, shortwave direct/diffuse scattering, fluxes,
   heating rates, TOA forcing, and surface forcing before all-sky physics is
   treated as complete.
2. Step 2: replace toy/fixed coefficients with real ecCKD/RRTMG-compatible gas
   optics, including official ecCKD file ingestion, RRTMGP-compatible
   comparison support, reduced 32/32b/16-term model variants, and
   accuracy/runtime evidence suitable for the Breeze Pareto reports.
3. Step 3: implement current IFS all-sky conventions against the full ecRad
   reference case set, including cloud liquid/ice optics, aerosols, scattering,
   cloud overlap, and solver semantics.
4. ecRad-style clear-sky and all-sky radiative-transfer solvers that consume
   optical properties/source terms independently from gas optics.
5. ecCKD file ingestion and forward gas-optics evaluation validated against
   ecRad/ecCKD reference outputs.
6. A dedicated-checkout Breeze.jl integration in
   Breeze.jl/ext/BreezeRadiativeHeatingExt.jl that does not touch other local
   Breeze checkouts and can use RadiativeHeating's optimized kernels without
   unnecessary temporary arrays.
7. An H100-profiled production Breeze benchmark demonstrating at least 4x
   speedup over Breeze+RRTMGP for an agreed similar-complexity radiation
   update. The comparison must include a realistic RCEMIP-style case: it does
   not need to perform the full expensive spin-up, but it must run a
   non-trivial production-style workload with representative 3D grid size,
   vertical resolution, moist thermodynamic state, clouds where available,
   radiation update cadence, and Breeze timestep integration overhead. Report
   isolated radiation-update speedup and whole-timestep impact using the same
   state, precision, device, radiation schedule, and diagnostics for both
   paths, with decomposed timings, temporary-array footprint, Nsight Systems
   and Nsight Compute reports, and complete benchmark metadata.
8. Reduced ecCKD 32/32b-term and 16-term model demonstrations that meet hard
   Breeze accuracy thresholds while reporting flux errors, heating-rate errors,
   forcing errors, memory footprint, runtime, and speedup.
9. A differentiable ecCKD optimization workflow using Enzyme.jl and Reactant.jl
   for fixed-topology continuous gas-optics parameters, with finite-difference
   gradient checks.
10. An end-to-end gas-optics training demonstration that starts from an
   official/reduced ecCKD gas-optics model, trains LUT/source/scaling
   parameters, shows loss reduction, improves flux and heating-rate RMSE,
   records reproducible configuration/seed metadata, and documents the path
   toward CKDMIP-scale training as a heavy/manual workflow. Toy training is
   useful scaffolding only; it is not the final deliverable.

Definition of done: tests, docs, runnable examples, benchmark reports,
reference-code comparisons, GPU profiling artifacts, and training artifacts
exist for each relevant stage; no Breeze dependency is added to the standalone
RadiativeHeating package; and all performance and accuracy claims are backed by
stored, reproducible evidence.
```
