# Reduced ecCKD Optimization Preflight

Status: **preflight_ready**

| Field | Value |
|---|---:|
| Trainable shortwave g-points | 16 |
| Parameter count | 48 |
| Initial normalized objective | 214.264529894 |
| Directional derivative | -47.9336647894 |
| Best trial objective | 213.785388667 |
| Best trial step | 0.01 |
| Optimization smoke final objective | 213.785388667 |
| Optimization smoke reduction | 0.47914122634 |
| Directional search final objective | 213.306642558 |
| Directional search reduction | 0.957887335617 |
| Best parameter block | weights |
| Best block trial objective | 213.496613388 |
| Coefficient coordinate candidates | 64 |
| Best coefficient coordinate | absorption g25 negative step 1.0 |
| Best coefficient coordinate objective | 93.9257170886 |
| Greedy coefficient descent iterations | 18 |
| Greedy coefficient descent final objective | 9.01318970914 |
| Greedy coefficient descent source | cached checkpoint |
| Joint coefficient direction candidates | 12 |
| Best joint coefficient direction | nonzero_absorption_scales |
| Best joint coefficient objective | 8.94544944983 |
| Post-joint refinement iterations | 2 |
| Post-joint refinement final objective | 8.6288431477 |
| Post-coefficient weight refinement iterations | 1 |
| Post-coefficient weight refinement final objective | 8.6288431477 |
| Finite-difference coefficient-gradient candidates | 68 |
| Finite-difference coefficient-gradient norm | 37.030639719 |
| Finite-difference coefficient-gradient best objective | 14.4322029737 |
| Finite-difference coefficient-gradient improved | false |
| Smooth objective beta | 8 |
| Smooth objective best smooth value | 14.6343222614 |
| Smooth objective hard candidate | 8.6288431477 |
| Smooth objective accepted | false |
| Topology-neighbor candidates | 8 / 16 |
| Best topology-neighbor move | g9 -> g8 |
| Best topology-neighbor objective | 52.5845357307 |
| Topology scan status | all_32x16_topologies_fail_forcing_gate |
| Topology candidates | 18 |
| Best topology forcing lower bound | 6.91747223736 |
| Subset-search scan status | all_subset_topologies_fail_forcing_gate |
| Subset-search candidates | 4 |
| Best subset-search forcing lower bound | 279.014517783 |
| Hard threshold objective target | 1.0 |
| Final objective / target | 8.60500399071 |
| Final worst case | ecckd_clear_sky_tropical_column |
| Final worst metric | toa_forcing_max_abs |
| Final worst metric value | 2.58150119721 |
| Final worst metric threshold | 0.3 |
| Targeted worst-metric candidates | 96 |
| Targeted worst-metric objective | 8.59324259754 |
| Targeted full-objective candidate | 10.1463124654 |
| Targeted move accepted | false |
| Separated-component parameter count | 64 |
| Separated-component candidates | 64 |
| Separated-component target objective | 8.6201751492 |
| Separated-component full-objective candidate | 8.67410459714 |
| Separated-component move accepted | false |
| Table-refinement iterations | 2 |
| Table-refinement accepted moves | 2 |
| Table-refinement final objective | 8.60500733608 |
| Table-refinement improved | true |
| Active table-entry iterations | 2 |
| Active table-entry accepted moves | 2 |
| Active table-entry targeted candidates | 584 |
| Active table-entry final objective | 8.60500399071 |
| Active table-entry improved | true |
| Next optimizer target case | ecckd_clear_sky_tropical_column |
| Next optimizer target metric | toa_forcing_max_abs |
| Required absolute reduction | 2.28150119721 |
| Required relative reduction | 0.883789 |
| Warm-start topology radius | 1 |
| Warm-start topology candidates | 2 / 16 |
| Warm-start topology best move | g4 -> g3 |
| Warm-start topology best objective | 8.6288431477 |
| Warm-start topology improved | false |
| Ranked topology radius | 1 |
| Ranked topology candidates | 4 / 16 |
| Ranked topology best move | g21 -> g20 |
| Ranked topology best initial objective | 12.2502218635 |
| Ranked topology best refined objective | 8.6288431477 |
| Ranked topology improved | false |

The parameterization optimizes 16 shortwave spectral weights, 16 absorption coefficient scales, and 16 Rayleigh coefficient scales on the official ecCKD reduced hard-gate cases.

The topology scan ranks the existing official 32x16 reduced-accuracy candidates by the forcing-error lower bound implied by their TOA and surface forcing errors. This keeps the next optimizer tied to measured official-case evidence instead of only the current weighted-greedy topology.

Next required work: Move beyond bounded pressure-band table scales: run a stronger joint coefficient/table optimizer against flux and heating residuals or jointly optimize the reduced quadrature definition; the current table-refined 48-parameter path remains far above the hard-gate target.

Reactant status: `available`

Reactant surrogate check: `passed`

Enzyme status: `available`

Enzyme surrogate check: `passed`
