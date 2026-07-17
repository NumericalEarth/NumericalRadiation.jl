# Radiative Heating Goal Audit Check

Status: **not_complete**

| Artifact | Status | Completion blocker |
|---|---|---:|
| old ABR Breeze extension removed | verified | false |
| dedicated BreezeRadiativeHeatingExt present | missing_or_unexpected | false |
| Breeze tabulated ecCKD column amount conversion | missing_or_unexpected | false |
| ecRad reference manifest | verified | false |
| upstream ecRad checkout | verified | false |
| ecRad hard-threshold accuracy gate | verified | false |
| ecRad cloudless/no-aerosol first hard gate | missing_or_unexpected | false |
| ecRad accuracy diagnostics | verified | false |
| ecRad all-sky cloud-effect diagnostics | verified | false |
| ecRad all-sky cloud parameter sweep | verified | false |
| ecRad all-sky IFS gate | verified | false |
| ecRad all-sky optics gap diagnostic | verified | false |
| ecRad reference-optics solver gap diagnostic | verified | false |
| ecRad cloud scattering table ingestion | verified | false |
| ecRad convention gap report | verified | false |
| ecRad candidate schema preflight | verified | false |
| official ecCKD definition files recognized | verified | false |
| toy ecCKD training | verified | false |
| toy ecCKD Enzyme check | verified | false |
| toy ecCKD Reactant check | verified | false |
| official/reduced ecCKD gas-optics training | verified | true |
| full Reactant/Enzyme RRTMGP-target 16-g calibration | verified | false |
| toy cloud validation | verified | false |
| host-model access points | verified | false |
| package-native RRTMGP comparison extension | verified | false |
| package-native RRTMGP comparison test | verified | false |
| Breeze RCEMIP H100 4x acceptance | verified | false |
| Breeze RCEMIP realistic problem size | verified | false |
| Breeze RCEMIP gas model metadata | verified | false |
| Breeze validated ecCKD CPU smoke | verified | false |
| Breeze validated ecCKD accuracy metadata smoke | verified | false |
| Breeze validated ecCKD CPU device-support metadata | verified | false |
| Breeze validated ecCKD trace-gas metadata | verified | false |
| Breeze tabulated ecCKD device column amount kernel | missing_or_unexpected | false |
| Breeze tabulated ecCKD interpolation state kernel | missing_or_unexpected | false |
| Breeze tabulated ecCKD absorption optical-depth kernel | missing_or_unexpected | false |
| Breeze tabulated ecCKD Rayleigh optical-depth kernel | missing_or_unexpected | false |
| Breeze tabulated ecCKD longwave source kernel | missing_or_unexpected | false |
| Breeze tabulated ecCKD integrated optical-properties kernel | missing_or_unexpected | false |
| Breeze tabulated ecCKD flux-divergence kernel | missing_or_unexpected | false |
| Breeze tabulated ecCKD device workspace | missing_or_unexpected | false |
| Breeze tabulated ecCKD device update path | missing_or_unexpected | false |
| Breeze validated ecCKD H100 support preflight | verified | false |
| Breeze validated ecCKD H100 support source | verified | false |
| Breeze validated ecCKD H100 next implementation | verified | false |
| Breeze validated ecCKD H100 missing kernel checklist | verified | false |
| Breeze validated ecCKD H100 parity requirement | verified | false |
| Breeze RCEMIP Nsight Systems report | verified | false |
| Breeze RCEMIP Nsight Compute report | verified | false |
| Breeze RCEMIP H100 smoke | verified | false |
| Breeze reduced Pareto scaffold | verified | false |
| Breeze reduced 32x16 proxy timing | verified | false |
| Breeze reduced accuracy scaffold | verified | false |
| Breeze reduced 32x16 proxy accuracy | verified | false |
| reduced ecCKD size scan | verified | false |
| official ecCKD 32b baseline | verified | false |
| 32-g ecCKD/RRTMGP comparison | verified | false |
| reduced ecCKD gap report | verified | false |
| reduced ecCKD acceptance decision | verified | false |
| reduced 16-g diagnostic hard-threshold record | verified | false |
| reduced ecCKD subset search | verified | false |
| reduced ecCKD subset search threshold status | verified | false |
| reduced ecCKD optimization preflight | verified | false |
| reduced ecCKD optimization gap status | verified | false |
| reduced 16-g diagnostic optimization objective record | verified | false |
| reduced ecCKD optimization block scan | verified | false |
| reduced ecCKD coefficient coordinate scan | verified | false |
| reduced ecCKD topology candidate scan | verified | false |
| reduced ecCKD subset-search topology scan | verified | false |
| official reduced optimization Reactant dependency | verified | false |
| official reduced optimization Reactant check | verified | false |
| official reduced optimization Enzyme dependency | verified | false |
| official reduced optimization Enzyme check | verified | false |
| Breeze GPU environment check | verified | false |
| Breeze H100 acceptance runbook | verified | false |
| Breeze H100 acceptance local preflight | verified | false |
| toy ecCKD training RMSE improvement | verified | false |

## Goal Steps

| Step | Status | Definition |
|---|---|---|
| cloudless official ecCKD ecRad accuracy | `passed` | Pass hard cloudless/no-aerosol ecRad thresholds with official ecCKD inputs. |
| 32-g ecCKD/RRTMGP-compatible gas optics | `passed_32g_target` | Use the validated official ecCKD 32-g production model, freeze the 16-g model as a diagnostic, and emit direct RRTMGP comparison metrics on the same column ensemble. |
| all-sky IFS conventions plus Breeze H100 4x | `passed` | Pass current IFS all-sky cloud/aerosol/scattering/overlap solver thresholds and demonstrate >=4x H100 Breeze speedup over RRTMGP on a realistic RCEMIP-style workload. |

## Prompt-to-Artifact Checklist

| Requirement | Status | Completion criteria | Evidence |
|---|---|---|---|
| Plan reviewed and concrete three-step /goal captured | `satisfied` | The project plan and audit list the three concrete goal gates with current status. | ecRad convention gap report (`verified`)<br>ecRad hard-threshold accuracy gate (`verified`)<br>reduced ecCKD gap report (`verified`) |
| Hard cloudless/no-aerosol official ecCKD accuracy thresholds | `uncovered` | Official ecCKD clear/cloudless hard-gate artifacts pass. | ecRad hard-threshold accuracy gate (`verified`)<br>ecRad cloudless/no-aerosol first hard gate (`missing_or_unexpected`) |
| NetCDF/ecRad/ecCKD references discovered and usable | `satisfied` | Reference manifest, upstream ecRad checkout, candidate schema, and official ecCKD files are present and valid. | ecRad reference manifest (`verified`)<br>upstream ecRad checkout (`verified`)<br>ecRad candidate schema preflight (`verified`)<br>official ecCKD definition files recognized (`verified`) |
| Direct RRTMGP comparison through ColumnAtmosphere/RadiativeFluxes | `satisfied` | The package-native RRTMGP extension and direct comparison test are implemented. | package-native RRTMGP comparison extension (`verified`)<br>package-native RRTMGP comparison test (`verified`) |
| Fresh dedicated Breeze checkout and Breeze-owned extension | `uncovered` | Old ABR Breeze extension is absent and the fresh Breeze checkout owns BreezeRadiativeHeatingExt. | old ABR Breeze extension removed (`verified`)<br>dedicated BreezeRadiativeHeatingExt present (`missing_or_unexpected`)<br>Breeze tabulated ecCKD column amount conversion (`missing_or_unexpected`) |
| Host-model access points for external solvers and vertical integrals | `satisfied` | Access-point validation passes without unexported required APIs. | host-model access points (`verified`) |
| 32-g ecCKD/RRTMGP-compatible production gas optics | `satisfied` | The official ecCKD 32-g production path passes ecRad/ecCKD hard thresholds, the 16-g model is frozen as diagnostic evidence, and direct RRTMGP comparison metrics are emitted on the same column ensemble. | official ecCKD 32b baseline (`verified`)<br>32-g ecCKD/RRTMGP comparison (`verified`)<br>reduced ecCKD gap report (`verified`)<br>reduced ecCKD acceptance decision (`verified`)<br>reduced 16-g diagnostic hard-threshold record (`verified`)<br>reduced ecCKD subset search (`verified`)<br>reduced ecCKD subset search threshold status (`verified`)<br>reduced ecCKD optimization preflight (`verified`)<br>reduced ecCKD optimization gap status (`verified`)<br>reduced 16-g diagnostic optimization objective record (`verified`)<br>reduced ecCKD optimization block scan (`verified`)<br>reduced ecCKD coefficient coordinate scan (`verified`)<br>reduced ecCKD topology candidate scan (`verified`)<br>reduced ecCKD subset-search topology scan (`verified`) |
| Reactant and Enzyme optimization path | `satisfied` | Toy and official reduced optimization checks show Reactant and Enzyme availability, and full 16-g calibration against the RRTMGP/package reference is demonstrated. | toy ecCKD Reactant check (`verified`)<br>toy ecCKD Enzyme check (`verified`)<br>official reduced optimization Reactant dependency (`verified`)<br>official reduced optimization Reactant check (`verified`)<br>official reduced optimization Enzyme dependency (`verified`)<br>official reduced optimization Enzyme check (`verified`)<br>full Reactant/Enzyme RRTMGP-target 16-g calibration (`verified`) |
| End-to-end gas-optics training demonstration | `blocked` | Toy training passes, and an official/reduced ecCKD gas-optics training artifact demonstrates the production path. | toy ecCKD training (`verified`)<br>toy ecCKD training RMSE improvement (`verified`)<br>official/reduced ecCKD gas-optics training (`verified`, blocker) |
| Current IFS all-sky cloud/aerosol/scattering/overlap semantics | `satisfied` | Cloud/scattering diagnostics, final IFS all-sky gate, and all-sky solver/reference-optics evidence pass. | ecRad all-sky IFS gate (`verified`)<br>toy cloud validation (`verified`)<br>ecRad all-sky cloud-effect diagnostics (`verified`)<br>ecRad all-sky cloud parameter sweep (`verified`)<br>ecRad all-sky optics gap diagnostic (`verified`)<br>ecRad reference-optics solver gap diagnostic (`verified`)<br>ecRad cloud scattering table ingestion (`verified`) |
| Validated ecCKD Breeze CPU and H100 support path | `uncovered` | Validated ecCKD metadata flows through Breeze, CPU support is verified, and H100 tabulated multi-gas support is no longer blocked. | Breeze validated ecCKD CPU smoke (`verified`)<br>Breeze validated ecCKD accuracy metadata smoke (`verified`)<br>Breeze validated ecCKD CPU device-support metadata (`verified`)<br>Breeze validated ecCKD trace-gas metadata (`verified`)<br>Breeze tabulated ecCKD device column amount kernel (`missing_or_unexpected`)<br>Breeze tabulated ecCKD interpolation state kernel (`missing_or_unexpected`)<br>Breeze tabulated ecCKD absorption optical-depth kernel (`missing_or_unexpected`)<br>Breeze tabulated ecCKD Rayleigh optical-depth kernel (`missing_or_unexpected`)<br>Breeze tabulated ecCKD longwave source kernel (`missing_or_unexpected`)<br>Breeze tabulated ecCKD integrated optical-properties kernel (`missing_or_unexpected`)<br>Breeze tabulated ecCKD flux-divergence kernel (`missing_or_unexpected`)<br>Breeze tabulated ecCKD device workspace (`missing_or_unexpected`)<br>Breeze tabulated ecCKD device update path (`missing_or_unexpected`)<br>Breeze validated ecCKD H100 support preflight (`verified`)<br>Breeze validated ecCKD H100 support source (`verified`)<br>Breeze validated ecCKD H100 next implementation (`verified`) |
| Realistic RCEMIP-style H100 4x RRTMGP comparison with Nsight profiling | `satisfied` | Final 1024-column RCEMIP-style H100 artifact supports >=4x over RRTMGP with validated ecCKD and Nsight Systems/Compute reports. | Breeze RCEMIP H100 4x acceptance (`verified`)<br>Breeze RCEMIP realistic problem size (`verified`)<br>Breeze RCEMIP gas model metadata (`verified`)<br>Breeze RCEMIP Nsight Systems report (`verified`)<br>Breeze RCEMIP Nsight Compute report (`verified`)<br>Breeze GPU environment check (`verified`)<br>Breeze H100 acceptance runbook (`verified`)<br>Breeze H100 acceptance local preflight (`verified`) |

## Dedicated Breeze Checkout

| Field | Value |
|---|---|
| Path | `/shared/home/greg/Projects/BreezeRadiativeHeatingDev/Breeze.jl` |
| HEAD SHA | `2772a8bbdab14c3fc4c6fd5e255dac9ba22d744f` |
| Fresh-clone SHA matches | false |
| Origin remote | `https://github.com/NumericalEarth/Breeze.jl` |
| Origin remote matches | true |
| Dirty worktree | true |

Blocking reasons:

- official/reduced ecCKD gas-optics training: production official/reduced ecCKD training improves the objective but has not quantitatively recovered a published model
