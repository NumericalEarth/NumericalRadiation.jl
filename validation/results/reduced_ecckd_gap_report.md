# Reduced ecCKD Gap Report

Status: **reduced_shortwave_passed**

Reference scope: clean official ecCKD tropical and RCEMIP-style cloudless/no-aerosol cases.

Hard forcing threshold: `0.3` W m^-2.

| Category | Method | Passed | TOA forcing error | Surface forcing error |
|---|---|---:|---:|---:|
| full shortwave | official ecCKD 32x32 baseline without shortwave reduction | true | 0.00806408713606 W m^-2 | 0.0140335470378 W m^-2 |
| reduced shortwave | official ecCKD 32x31 leave-one-out g23 support with exact boundary-polished quadrature weights | true | 0.299826700215 W m^-2 | 0.278191612233 W m^-2 |
| reduced shortwave | evenly selected official ecCKD g-points with renormalized weights | false | 15.148939416 W m^-2 | 66.5675113805 W m^-2 |
| reduced shortwave | greedy searched 16 shortwave g-point subset with official weights renormalized | false | 7.17718646856 W m^-2 | 6.84298667546 W m^-2 |
| reduced shortwave | greedy searched 16 shortwave g-point subset with least-squares fitted shortwave weights | false | 31.0262219594 W m^-2 | 66.6731185186 W m^-2 |
| reduced shortwave | greedy searched 16 shortwave g-point subset with projected boundary-weighted fitted shortwave weights | false | 5.55763254463 W m^-2 | 2.74834035515 W m^-2 |
| reduced shortwave | weighted greedy 16 shortwave g-point subset with projected simplex weights | false | 5.52030576048 W m^-2 | 3.17852209835 W m^-2 |
| reduced shortwave | weighted greedy 16 shortwave g-point subset with projected hard-gate max-norm weights | false | 5.51884380351 W m^-2 | 3.18861438431 W m^-2 |
| reduced shortwave | weighted greedy 16 shortwave g-point subset with diagnostic fitted coefficient scales | false | 5.88171009786 W m^-2 | 5.77898204224 W m^-2 |
| reduced shortwave | weighted greedy 16 shortwave g-point subset with latest preflight-optimized weights and coefficient scales | false | 2.58865294431 W m^-2 | 2.56622140734 W m^-2 |
| reduced shortwave | weighted greedy 16 shortwave g-point subset with latest preflight-optimized weights, coefficient scales, and pressure-band table moves | false | 2.31170988514 W m^-2 | 2.75790205932 W m^-2 |
| reduced shortwave | weighted greedy 16 shortwave g-point subset with latest preflight table moves and reduced incoming shortwave spectral weights | false | 2.31170988514 W m^-2 | 2.75790205932 W m^-2 |
| reduced shortwave | weighted greedy 16 shortwave g-point subset with boundary-aware post-constrained weight refit | false | 2.32587243275 W m^-2 | 2.75109439529 W m^-2 |
| reduced shortwave | weighted greedy 16 shortwave g-point subset with boundary-aware table, component, structural, objective-probe, surface-probe, capped table, continuation, post-capped weight, post-weight surface-table, bounded weight, four current component-scale refits, selected current gas-pressure component scan refit, gas-pressure continuation refit, weighted gas-pressure continuation refit, and high-weight gas-pressure continuation refit | false | 2.07524167121 W m^-2 | 2.02695668832 W m^-2 |
| reduced shortwave | evenly selected official ecCKD g-points with least-squares fitted shortwave weights | false | 56.8890709074 W m^-2 | 118.958235969 W m^-2 |
| reduced shortwave | evenly selected official ecCKD g-points with renormalized weights | false | 92.3557392308 W m^-2 | 171.674844598 W m^-2 |
| reduced shortwave | adjacent official ecCKD g-point bins with spectral-weighted coefficient averages | false | 66.0484885039 W m^-2 | 164.983235003 W m^-2 |
| reduced shortwave | adjacent official ecCKD g-point bins with spectral-weighted coefficient averages | false | 79.9785618291 W m^-2 | 156.746283354 W m^-2 |
| reduced shortwave | cumulative spectral-weight bins with coefficient averages | false | 81.055508224 W m^-2 | 215.161432856 W m^-2 |
| reduced shortwave | cumulative spectral-weight bins with coefficient averages | false | 94.9855815493 W m^-2 | 206.599801603 W m^-2 |
| reduced shortwave | non-adjacent coefficient-similarity shortwave g-point pairs with spectral-weighted coefficient averages | false | 26.2279763918 W m^-2 | 73.6097384692 W m^-2 |
| reduced shortwave | weighted-greedy anchor g-points plus nearest-neighbor coefficient-similarity bins | false | 40.3200732112 W m^-2 | 123.040442676 W m^-2 |
| reduced shortwave | weighted-greedy anchor g-points plus nearest spectral-order Voronoi bins | false | 40.3601966211 W m^-2 | 125.54176579 W m^-2 |

## Conclusion

At least one reduced shortwave strategy passes the hard forcing threshold.

## Optimization Preflight

- present: true
- acceptance gap status: `far_above_objective_target`
- final objective / target: 8.605003990705882
- best local block: `weights`
- topology scan status: `all_32x16_topologies_fail_forcing_gate`
- topology candidates: 18
- best topology forcing lower bound: 6.91747223736229
- best topology method: weighted greedy 16 shortwave g-point subset with boundary-aware table, component, structural, objective-probe, surface-probe, capped table, continuation, post-capped weight, post-weight surface-table, bounded weight, four current component-scale refits, selected current gas-pressure component scan refit, gas-pressure continuation refit, weighted gas-pressure continuation refit, and high-weight gas-pressure continuation refit
- final worst case: `ecckd_clear_sky_tropical_column`
- final worst metric: `toa_forcing_max_abs`
- final worst value: 2.5815011972117645
- final worst threshold: 0.3
- targeted worst-metric candidates: 96
- targeted worst-metric objective: 8.593242597543547
- targeted move accepted: false
- separated-component candidates: 64
- separated-component target objective: 8.620175149198891
- separated-component move accepted: false
- next optimizer required absolute reduction: 2.2815011972117647
- next optimizer required relative reduction: 0.8837885489559235
- next optimizer parameterization: nonnegative shortwave coefficient-table or quadrature-bin optimizer with objective terms for TOA forcing, surface forcing, flux profiles, and heating rates
- warm-start topology candidates: 2
- warm-start topology best objective: 8.628843147703455
- warm-start topology improved: false
- finite-difference coefficient-gradient candidates: 68
- finite-difference coefficient-gradient best objective: 14.43220297365618
- finite-difference coefficient-gradient improved: false

## Coefficient Continuation

- present: true
- status: `coefficient_continuation_above_target`
- initial objective: 214.26452989359106
- final objective: 8.628843147703455
- final objective / target: 8.628843147703455
- best start label: `preflight_post_coefficient_weight_refinement`
- best start objective: 8.628843147703455
- greedy checkpoint used: true
- saved states evaluated: 5
- worst case: `ecckd_rcemip_style_column_subset`
- worst metric: `toa_forcing_max_abs`
- worst value: 2.588652944311036
- worst threshold: 0.3

## Subset Search Artifact

- present: true
- status: `failed_threshold`
- weighted selected shortwave g-points: `1, 3, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 30, 31`
- pruned full-fit selected shortwave g-points: `1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16`
- hard-gate max-norm selected shortwave g-points: `1, 3, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 30, 31`
- fitted weights present: true

## Optical-Depth Fit Preflight

- present: true
- status: `optical_depth_refit_target_ready`
- baseline RMSE: 0.3664883638868358
- per-g fitted RMSE: 0.19724155725275747
- component-fitted RMSE: 0.16519290474879328
- component relative RMSE reduction: 0.5492547075797433
- baseline flux objective: 214.26452989361144
- per-g scaled flux objective: 1062.4526906196147
- component-scaled flux objective: 1182.4597819306232
- per-g scaled flux improved: false
- component-scaled flux improved: false
- coefficient-table raw LS optical-depth RMSE: 0.0035778590813959925
- coefficient-table clipped-model optical-depth RMSE: 2.727799953052386
- physical projected table optical-depth RMSE: 3.1876209655501285e-17
- physical projected table flux objective: 549.9441166764261
- coefficient-table fit flux objective: 1395.5012798871628
- coefficient-table fit flux improved: false
- coefficient-table fit passed hard thresholds: false

## Size Weight Refit

- present: true
- status: `refit_still_failed`
- any passed: false
- best method: even_select
- best ng_sw: 30
- best refit objective: 44.77028807133745
- best TOA forcing error: 6.662571785589762
- best surface forcing error: 13.431086421401233

## Leave-One-Out Scan

- present: true
- status: `all_leave_one_out_failed`
- candidates: 32
- passes: 0
- best omitted g-point: 23
- best objective: 1.645092128254022
- best TOA forcing error: 0.0536563611829024
- best surface forcing error: 0.07520428660029665
- worst omitted g-point: 10
- worst objective: 141.6540772252957
- worst TOA forcing error: 21.01219647565449
- worst surface forcing error: 42.49622316758871

## Leave-One-Out Weight Refit

- present: true
- status: `all_leave_one_out_refits_failed`
- candidates: 32
- passes: 0
- best omitted g-point: 23
- best initial objective: 1.645092128254022
- best refit objective: 1.624423143786563
- best objective reduction: 0.020668984467459017
- best refit TOA forcing error: 0.05361437946237402
- best refit surface forcing error: 0.07513920044664246
- worst omitted g-point: 10
- worst refit objective: 141.65400805358635
- worst refit TOA forcing error: 21.012191230480312
- worst refit surface forcing error: 42.4962024160759

## Importance-Guided Group Scan

- present: true
- status: `all_importance_groups_failed`
- importance source: `validation/results/reduced_ecckd_leave_one_out_scan.json`
- grouping rule: critical_singleton_kN keeps the N largest leave-one-out objective g-points as singleton bins, then splits all remaining g-points into 16 - N spectral-order groups; criticalN_redundantM also keeps the M smallest leave-one-out objective g-points as singleton bins before splitting the rest.
- candidates: 9
- passes: 0
- best label: `critical_singleton_k12`
- best refit objective: 278.219694550495
- best TOA forcing error: 30.65572714095174
- best surface forcing error: 83.4659083651485

## Support-Swap Scan

- present: true
- status: `failed_threshold`
- seed count: 2
- exact candidates per seed: 12
- best objective: 26.84729671457178
- best removed g-point: 31
- best added g-point: 8
- best selected shortwave g-points: `2, 4, 7, 8, 10, 11, 12, 14, 16, 18, 21, 22, 27, 28, 30, 32`
- passed hard thresholds: false

## Support-Swap Continuation Scan

- present: true
- status: `failed_threshold`
- exact candidates: 16
- seed objective: 26.84729671457178
- best objective: 25.009745933903808
- best objective reduction: 1.8375507806679714
- best removed g-point: 22
- best added g-point: 25
- best selected shortwave g-points: `2, 4, 7, 8, 10, 11, 12, 14, 16, 18, 21, 25, 27, 28, 30, 32`
- passed hard thresholds: false

## Support Expansion Scan

- present: true
- status: `failed_threshold`
- seed count: 2
- exact candidates per seed: 16
- best objective: 50.228511564342256
- best shortwave g-point count: 18
- best added g-points: `3, 6`
- best selected shortwave g-points: `2, 3, 4, 6, 7, 10, 11, 12, 14, 16, 18, 21, 22, 27, 28, 30, 31, 32`
- passed hard thresholds: false

## Support Expansion Refit Scan

- present: true
- status: `failed_threshold`
- iterations: 4000
- p-norm: 16
- candidates: 5
- starts per candidate: 4
- best label: `subset_hardgate_plus_3_6`
- best objective: 50.34545301641151
- best start: `official_normalized`
- best shortwave g-point count: 18
- best added g-points: `3, 6`
- best selected shortwave g-points: `2, 3, 4, 6, 7, 10, 11, 12, 14, 16, 18, 21, 22, 27, 28, 30, 31, 32`
- passed hard thresholds: false

## Random Support Search

- present: true
- status: `failed_threshold`
- RNG seed: 1729
- random seed count: 256
- candidates: 258
- exact candidates: 32
- iterations: 800
- p-norm: 16
- best label: `random_support_10`
- best objective: 57.899821879771025
- best selected shortwave g-points: `1, 6, 9, 10, 11, 12, 14, 19, 20, 21, 23, 24, 25, 26, 29, 31`
- best TOA forcing error: 17.171568538871043
- best surface forcing error: 17.369946563931308
- best heating RMSE: 2.5590696275371565
- canonical seed objective: 137.26298428229296
- subset-search hardgate seed objective: 69.26093277143721
- passed hard thresholds: false

## Current Metric Breakdown

- present: true
- status: `failed_threshold`
- hard objective: 6.91747223736229
- worst case: `ecckd_rcemip_style_column_subset`
- worst variable: `boundary`
- worst metric: `toa_forcing_max_abs`
- worst value: 2.075241671208687
- worst threshold: 0.3
- second case: `ecckd_clear_sky_tropical_column`
- second variable: `heating_rate`
- second metric: `rmse`
- second value: 0.3431161518590576
- second threshold: 0.05
- second normalized: 6.862323037181151

## Reduced Acceptance Decision

- present: true
- status: `decision_required`
- blocker: `reduced_16g_hard_threshold`
- objective target: 1.0
- current hard objective: 6.91747223736229
- worst case: `ecckd_rcemip_style_column_subset`
- worst metric: `toa_forcing_max_abs`
- worst value: 2.075241671208687
- worst threshold: 0.3
- second case: `ecckd_clear_sky_tropical_column`
- second metric: `rmse`
- second normalized: 6.862323037181151
- local support searches rejected: true
- current chain required for best row: true
- random-support best objective: 57.899821879771025
- bare canonical support objective: 137.26298428229296
- recommended next decision: choose between revising the reduced-model acceptance target or allowing a different reduced basis
- remaining options: revise the hard reduced 16-g acceptance target or split it from the validated 32-g production acceptance target; allow a different reduced basis, such as more shortwave g-points or a non-subset coefficient table, for the Breeze/RRTMG-compatible reduced path

## Pressure-Band Table Refinement Preflight

- present: true
- status: `pressure_band_move_improved`
- current objective: 8.628843147703455
- target case: `ecckd_rcemip_style_column_subset`
- target metric: `toa_forcing_max_abs`
- target metric objective: 8.628843147703455
- candidates: 16
- best target-metric objective: 8.626352305698694
- best full objective: 9.432645885058891
- accepted: false
- iterative accepted moves: 2
- iterative final objective: 8.615297908051314
- iterative objective reduction: 0.013545239652140495
- iterative improved: true

## Targeted Active-Entry Refinement

- present: true
- final objective: 8.613037683455408
- objective reduction: 0.00012625968935253695
- accepted moves: 2
- targeted candidates: 1155
- iterations requested: 2

## Global Active-Entry Refinement

- present: true
- final objective: 8.55821829320007
- objective reduction: 0.0004777973219916021
- accepted moves in latest window: 7
- cumulative active moves: 21
- ranked candidates: 22000
- candidate limit: 256
- candidate offset: 3328
- iterations requested: 1

## Global Block Active-Entry Refinement

- present: true
- final objective: 8.55304192199147
- objective reduction: 0.0032006851424171145
- accepted grouped moves: 10
- cumulative active moves: 33
- group limit: 16
- iterations requested: 2

## Global Block Linearized Active-Entry Refit

- present: true
- basis count: 48
- best ridge lambda: 0.01
- base objective: 8.391873243830332
- candidate objective: 8.394675247235076
- final objective: 8.391873243830332
- objective reduction: -0.0028020034047440134
- accepted: false
- accepted moves: 0
- cumulative active moves: 405

## Linearized Active-Entry Refit

- present: true
- fitted candidates: 64
- best ridge lambda: 1.0e-6
- base objective: 8.61316394314476
- candidate objective: 8.61303778872563
- objective reduction: 0.00012615441912977587
- accepted: true

## Global Linearized Active-Entry Refit

- present: true
- fitted candidates: 24
- best ridge lambda: 1.0e-6
- base objective: 8.572600151493742
- candidate objective: 8.572600151493742
- objective reduction: 0.0
- accepted: false

## Topology Slot Refit

- present: true
- radius: 2
- candidates: 33
- base objective: 8.613037683455408
- best objective: 11.184787077747268
- best improvement: -2.57174939429186
- improved: false
- best move: g16 -> g18

## Post-Table Weight Refit

- present: true
- iterations: 2000
- base objective: 8.409684785990143
- refit objective: 8.410126091845314
- objective reduction: -0.0004413058551708815
- accepted: false

## Exact Weight Refit

- present: true
- iterations completed: 1
- initial objective: 8.321909904054035
- final objective: 8.321909904054035
- objective reduction: 0.0
- accepted: false

## Joint Weight/Block Refit

- present: true
- residual mode: worst_metric
- basis count: 8
- best ridge lambda: 100.0
- best direction: fitted
- base objective: 8.321909904054035
- candidate objective: 9.31858911278288
- final objective: 8.321909904054035
- objective reduction: -0.9966792087288443
- accepted: false
- accepted moves: 0
- cumulative active moves: 405

## Boundary-Column Refinement

- present: true
- target case: ecckd_rcemip_style_column_subset
- target metric: toa_forcing_max_abs
- target column: 6
- target residual: -2.496456640341094
- evaluated candidates: 128
- evaluated trials: 1024
- base objective: 8.321522134470314
- candidate objective: 8.32148401919767
- final objective: 8.32148401919767
- objective reduction: 3.8115272644745346e-5
- accepted: true
- accepted moves: 1
- cumulative active moves: 409

## Slot-Blend Refinement

- present: true
- radius: 31
- candidates: 256
- evaluated trials: 1024
- base objective: 7.478367127241938
- candidate objective: 9.188143165676669
- final objective: 7.478367127241938
- objective reduction: 0.0
- accepted: false
- accepted blends: 0
- best move: g21 -> g18
- best alpha: 0.25

## Pair Slot-Blend Refinement

- present: true
- base blends: 7
- ranked singles: 12
- evaluated pairs: 48
- base objective: 7.478367127241938
- best single objective: 8.397179355430353
- best pair objective: 9.105660444944306
- final objective: 7.478367127241938
- objective reduction: 0.0
- accepted: false
- accepted blends: 0
- total blends: 7

## Slot-Blend Linearized Refit

- present: true
- status: `slot_blend_linearized_rejected`
- base blends: 7
- candidates: 32
- single trials: 1024
- probe alpha: 0.0009765625
- max alpha: 0.0078125
- base objective: 7.478367127241938
- best exact objective: 10.827264184143814
- best objective reduction: -3.348897056901876
- best positive deltas: 18
- best TOA forcing: 2.786455062393543
- best surface forcing: 3.2481792552431443
- accepted: false
- accepted blends: 0
- total blends: 7

## Post-Slot Weight Refit

- present: true
- status: `post_slot_weight_refit_improved`
- base blends: 7
- iterations completed: 3
- initial objective: 7.470718745420584
- final objective: 7.44913935346555
- objective reduction: 0.021579391955033778
- accepted: true
- initial TOA forcing: 2.241215623626175
- initial surface forcing: 2.1292754603217645
- final TOA forcing: 2.234741806039665
- final surface forcing: 2.107931501308258

## Boundary-Column Block Refinement

- present: true
- target case: ecckd_rcemip_style_column_subset
- target metric: toa_forcing_max_abs
- target column: 6
- evaluated trials: 288
- base objective: 8.321428259962195
- candidate objective: 8.3213311545353
- final objective: 8.3213311545353
- objective reduction: 9.710542689411739e-5
- accepted: true
- accepted moves: 4
- cumulative active moves: 417
- best component: static_absorption
- best block size: 4

## Gas Pressure-Band Refinement

- present: true
- target case: ecckd_rcemip_style_column_subset
- target metric: toa_forcing_max_abs
- target column: 6
- pressure-band count: 8
- evaluated candidates: 96
- evaluated trials: 768
- base objective: 8.320799140737165
- candidate objective: 8.32070420145783
- final objective: 8.32070420145783
- objective reduction: 9.493927933590385e-5
- accepted: true
- accepted moves: 1
- best component: static_absorption
- best g-point: 4
- best gas index: 1

## Gas Pressure-Band Linearized Refit

- present: true
- fitted candidates: 24
- best ridge lambda: 1.0
- best direction: fitted
- base objective: 8.32070420145783
- candidate objective: 8.320729132221535
- final objective: 8.32070420145783
- objective reduction: -2.4930763705910408e-5
- accepted: false
- accepted moves: 0

## Flux-Pair Bins

- present: true
- status: `failed_threshold`
- objective: 25.969838836562076
- worst TOA forcing: 2.922190381918057
- worst surface forcing: 7.790951650968623
- passed hard thresholds: false

## Grouped Quadrature Search

- present: true
- status: `failed_threshold`
- candidates: 10
- best label: `weight_descending_flux0.1_heat1.0_boundary10.0`
- best objective: 16.010669152898345
- best TOA forcing: 2.4338689611814743
- best surface forcing: 4.803200745869503
- passed hard thresholds: false

## Grouped Quadrature Weight Refit

- present: true
- status: `weight_refit_improved`
- candidates: 10
- iterations: 3000
- best label: `weight_descending_flux0.1_heat1.0_boundary10.0`
- best base objective: 16.010669152898345
- best refit objective: 15.53274663527759
- best objective reduction: 0.47792251762075466
- best TOA forcing: 2.4447358176058174
- best surface forcing: 4.659823990583277
- passed hard thresholds: false

## Weight Max-Norm Refit

- present: true
- status: `weight_refit_rejected`
- base exact objective: 8.32070420145783
- base linear objective: 8.32212002776123
- best candidate: projected p=64 hard-gate weights
- best exact objective: 8.321198347306431
- best approximate objective: 8.516045400946389
- best TOA forcing: 2.496359504191929
- best surface forcing: 2.376821869603191
- max absolute weight delta: 8.753591389243365e-7
- accepted: false

## Constrained Table Optimizer

- present: true
- status: `constrained_table_optimizer_rejected`
- candidate scope: `all_global_residual_probe`
- include Rayleigh candidates: true
- candidates: 96
- probe step: 0.001953125
- max log scale: 0.015625
- base objective: 7.139850295341148
- best ridge lambda: 1.0e6
- best exact objective: 7.2287893662750475
- best objective reduction: -0.08893907093389952
- best TOA forcing: 2.16652518013521
- best surface forcing: 2.168636809882514
- accepted: false

## Topology Constrained Optimizer

- present: true
- status: `failed_threshold`
- topologies: 3
- candidates per topology: 64
- max log scale: 0.25
- best topology: subset_search_boundary_weight_30
- best exact objective: 23.30159499024944
- best TOA forcing: 6.990478497074832
- best surface forcing: 6.848470430293219

## Post-Constrained Weight Refit

- present: true
- status: `weight_refit_improved`
- initial objective: 7.424090865585337
- final objective: 7.409795080920295
- objective reduction: 0.014295784665042
- accepted: true
- initial TOA forcing: 2.227227259675601
- initial surface forcing: 2.0185419128694804
- final TOA forcing: 2.2229385242760884
- final surface forcing: 2.1024910021599226

## Post-Constrained Boundary Weight Refit

- present: true
- status: `boundary_weight_refit_improved`
- initial boundary objective: 7.297431753704113
- final boundary objective: 7.297425585382674
- boundary objective reduction: 6.168321438515534e-6
- initial full objective: 7.297431753704113
- final full objective: 7.297425585382674
- accepted: true
- initial TOA forcing: 2.189229526111234
- initial surface forcing: 2.189199276342265
- final TOA forcing: 2.189227174740836
- final surface forcing: 2.189227675614802

## Hard-Gate Sparse Subset Search

- present: true
- status: `failed_threshold`
- selected shortwave g-points: `1, 2, 9, 10, 12, 13, 14, 16, 21, 22, 25, 27, 28, 30, 31, 32`
- exact objective: 89.13382507888798
- approximate objective: 59.38385044339999
- worst TOA forcing: 7.399853448492422
- worst surface forcing: 16.53609643502125
- passed hard thresholds: false

## Boundary-Table Topology Replacement

- present: true
- status: `topology_replacement_rejected`
- radius: 2
- evaluated candidates: 33
- base objective: 7.139850295341148
- best objective: 8.911432433220337
- best improvement: -1.7715821378791894
- best replacement: g16 -> g18

## Boundary-Table Topology Weight Refit

- present: true
- status: `topology_weight_refit_rejected`
- radius: 2
- weight iterations: 800
- evaluated candidates: 12
- base objective: 8.769329833298798
- best objective: 43.59538029980665
- best improvement: -34.82605046650785
- best replacement: g4 -> g2

## Boundary-Table Coordinate Scan

- present: true
- status: `coordinate_scan_improved`
- candidates: 48
- trials: 384
- base objective: 7.297423915802787
- best objective: 7.296013195030659
- best objective reduction: 0.0014107207721281156
- best TOA forcing: 2.1888039585091974
- best surface forcing: 2.1822991632745925
- accepted: true

## Boundary-Table Pair Coordinate Scan

- present: true
- status: `pair_coordinate_scan_improved`
- single trials: 384
- selected singles: 16
- pair trials: 120
- base objective: 7.296013195030659
- best objective: 7.295875814987388
- best objective reduction: 0.000137380043270241
- best TOA forcing: 2.1887627444962163
- best surface forcing: 2.182298567528619
- accepted: true

## Boundary-Table Coordinate Descent

- present: true
- status: `coordinate_descent_improved`
- candidates: 48
- iteration limit: 6
- completed iterations: 6
- baseline objective: 7.295875814987388
- final objective: 7.2958592955110175
- final objective reduction: 1.6519476370824293e-5
- final TOA forcing: 2.188757788653305
- final surface forcing: 2.182241639983431
- accepted: true

## Boundary-Table Continuation Optimizer

- present: true
- status: `constrained_table_optimizer_improved`
- base mode: `boundary_table_post_descent`
- candidate scope: `all_global_objective_probe`
- residual mode: `toa`
- include Rayleigh candidates: true
- candidates: 64
- probe step: 0.00390625
- max log scale: 0.125
- base objective: 7.2958592955110175
- best exact objective: 7.295859130116848
- best objective reduction: 1.6539416947125574e-7
- best TOA forcing: 2.1887577390350543
- best surface forcing: 2.182241639983431
- accepted: true

## Component-Scale Refit

- present: true
- status: `component_scale_refit_improved`
- base mode: `boundary_table_post_descent_plus_continuation`
- parameter count: 48
- coordinate iterations: 12 / 12
- base objective: 7.295859130116848
- coordinate final objective: 7.139886570250553
- final objective: 7.139886570250553
- objective reduction: 0.15597255986629488
- final TOA forcing: 2.141965971075166
- final surface forcing: 2.1414964367791214
- accepted moves: 12
- accepted: true

## Pressure-Component Scale Refit

- present: true
- status: `pressure_component_scale_refit_improved`
- base mode: `component_scale_refit`
- pressure bands: 8
- candidates: 112
- iterations: 2 / 2
- base objective: 7.139886570250553
- final objective: 7.139854746386429
- objective reduction: 3.182386412436955e-5
- final TOA forcing: 2.1419564239159286
- final surface forcing: 2.141511341968304
- accepted moves: 2
- accepted: true

## Temperature-Component Scale Refit

- present: true
- status: `temperature_component_scale_refit_improved`
- base mode: `pressure_component_scale_refit`
- temperature bands: 8
- candidates: 32
- iterations: 2 / 2
- base objective: 7.139854746386429
- final objective: 7.1398503135238425
- objective reduction: 4.432862586334352e-6
- final TOA forcing: 2.1419550940571526
- final surface forcing: 2.1415175039060728
- accepted moves: 2
- accepted: true

## H2O-Component Scale Refit

- present: true
- status: `h2o_component_scale_refit_improved`
- base mode: `temperature_component_scale_refit`
- H2O bands: 8
- candidates: 16
- iterations: 1 / 1
- base objective: 7.1398503135238425
- final objective: 7.139850295588607
- objective reduction: 1.7935235518962145e-8
- final TOA forcing: 2.141955088676582
- final surface forcing: 2.14151611110789
- accepted moves: 1
- accepted: true

## Gas-Component Scale Refit

- present: true
- status: `gas_component_scale_refit_improved`
- base mode: `h2o_component_scale_refit`
- candidates: 16
- iterations: 1 / 1
- base objective: 7.139850295588607
- final objective: 7.139850295341148
- objective reduction: 2.474589422263307e-10
- final TOA forcing: 2.1419550886023444
- final surface forcing: 2.1415160508908
- accepted moves: 1
- accepted: true

## Pressure-Temperature Component Scale Refit

- present: true
- status: `pressure_temperature_component_scale_refit_improved`
- base mode: `gas_component_scale_refit`
- objective mode: `full`
- candidates: 64
- iterations: 4 / 4
- base objective: 8.769329833298798
- final objective: 7.5100949758291335
- objective reduction: 1.2592348574696643
- final TOA forcing: 2.25302849274874
- final surface forcing: 2.1179710745639113
- accepted moves: 4
- accepted: true

## Gas Pressure-Temperature Component Scale Refit

- present: true
- status: `gas_pressure_temperature_component_scale_refit_improved`
- base mode: `pressure_temperature_component_scale_refit`
- candidates: 32
- iterations: 4 / 4
- base objective: 7.5100949758291335
- final objective: 7.412298820428684
- objective reduction: 0.09779615540044961
- final TOA forcing: 2.223689646128605
- final surface forcing: 2.1179872821336403
- accepted moves: 4
- accepted: true

## H2O Pressure-Temperature Component Scale Refit

- present: true
- status: `h2o_pressure_temperature_component_scale_refit_improved`
- base mode: `gas_pressure_temperature_component_scale_refit`
- candidates: 8
- iterations: 8 / 8
- base objective: 7.412298820428684
- final objective: 7.410291144465949
- objective reduction: 0.0020076759627345453
- final TOA forcing: 2.2230873433397846
- final surface forcing: 2.219764548065541
- accepted moves: 8
- accepted: true

## Mixed Pressure-Temperature Component Refit

- present: true
- status: `mixed_pressure_temperature_component_refit_improved`
- base mode: `h2o_pressure_temperature_component_scale_refit`
- candidates: 12
- iterations: 4 / 4
- base objective: 7.410291144465949
- final objective: 7.400574072257011
- objective reduction: 0.009717072208938582
- final TOA forcing: 2.220172221677103
- final surface forcing: 2.2197591448673393
- accepted moves: 4
- accepted: true

## Retained Mixed Component Pareto Scan

- present: true
- status: `retained_mixed_component_scan_improved`
- acceptance rule: `bounded_frontier_surface_cap`
- forcing-error tolerance: 0.01
- surface cap: 2.03
- candidates: 12
- trials: 144
- base objective: 7.193524184543065
- final objective: 7.054523065216548
- objective reduction: 0.13900111932651704
- best exact objective: 7.03955734014509
- best objective reduction: 0.15396684439797514
- final TOA forcing: 2.1163569195649643
- final surface forcing: 2.029781059196388
- best TOA forcing: 2.111867202043527
- best surface forcing: 2.037489042826728
- any strict Pareto-safe: true
- any surface-cap-safe: true
- any tolerance Pareto-safe: true
- accepted: true

## Retained Topology Neighbor Scan

- present: true
- status: `retained_topology_neighbor_rejected`
- radius: 2
- candidates: 33
- pair candidates: 21
- base objective: 7.193524184543065
- best objective: 8.8090400284532
- best objective reduction: -1.615515843910135
- base TOA forcing: 2.1580572553629196
- base surface forcing: 2.0279297458791916
- best TOA forcing: 2.2166149703335947
- best surface forcing: 2.3572053866221268
- best replacement: slot 0, g0 -> g0
- Pareto safe: false
- passed hard thresholds: false

## Retained Topology Constrained Optimizer

- present: true
- status: `constrained_table_optimizer_rejected`
- candidate scope: `all_global_residual_probe`
- residual mode: `boundary`
- candidates: 16
- base objective: 8.8090400284532
- best exact objective: 9.499400883386215
- best objective reduction: -0.6903608549330151
- best TOA forcing: 2.273599785577076
- best surface forcing: 2.8498202650158646
- Pareto safe: false
- proposed moves: 112
- accepted: false

## Structural Optimizer Sweep

- present: true
- status: `structural_optimizer_sweep_improved`
- configurations: 2
- best label: `retained_all_shortwave_residual_probe`
- best base objective: 7.400574072257011
- best exact objective: 7.258849459427571
- best objective reduction: 0.1417246128294396
- best TOA forcing: 2.177654837828271
- best surface forcing: 1.984029499150786

## Retained Structural Optimizer

- present: true
- status: `constrained_table_optimizer_improved`
- base mode: `boundary_table_continuation`
- candidate scope: `all_global_residual_probe`
- residual mode: `all_shortwave`
- include Rayleigh candidates: true
- candidates: 12
- probe step: 0.001953125
- max log scale: 0.03125
- base objective: 7.400574072257011
- best exact objective: 7.258849459427571
- best objective reduction: 0.1417246128294396
- best TOA forcing: 2.177654837828271
- best surface forcing: 1.984029499150786
- accepted moves: 12
- accepted: true

## Retained Structural Continuation

- present: true
- status: `constrained_table_optimizer_improved`
- base mode: `boundary_table_continuation`
- candidate scope: `all_global_residual_probe`
- residual mode: `all_shortwave`
- include Rayleigh candidates: true
- candidates: 12
- probe step: 0.0009765625
- max log scale: 0.0078125
- base objective: 7.258849459427571
- best exact objective: 7.22363619224808
- best objective reduction: 0.03521326717949158
- best TOA forcing: 2.167090857674424
- best surface forcing: 1.975674675997702
- accepted moves: 12
- accepted: true

## Retained Structural Continuation 2

- present: true
- status: `constrained_table_optimizer_improved`
- base mode: `boundary_table_continuation`
- candidate scope: `all_global_residual_probe`
- residual mode: `all_shortwave`
- include Rayleigh candidates: true
- candidates: 12
- probe step: 0.00048828125
- max log scale: 0.00390625
- base objective: 7.22363619224808
- best exact objective: 7.206402766842928
- best objective reduction: 0.017233425405152047
- best TOA forcing: 2.1619208300528783
- best surface forcing: 1.99434663304055
- accepted moves: 12
- accepted: true

## Retained Structural Continuation 3

- present: true
- status: `constrained_table_optimizer_improved`
- base mode: `boundary_table_continuation`
- candidate scope: `all_global_residual_probe`
- residual mode: `all_shortwave`
- include Rayleigh candidates: true
- candidates: 12
- probe step: 0.000244140625
- max log scale: 0.001953125
- base objective: 7.206402766842928
- best exact objective: 7.197812620308923
- best objective reduction: 0.008590146534004361
- best TOA forcing: 2.159343786092677
- best surface forcing: 2.016706065913695
- accepted moves: 12
- accepted: true

## Retained Structural Continuation 4

- present: true
- status: `constrained_table_optimizer_improved`
- base mode: `boundary_table_continuation`
- candidate scope: `all_global_residual_probe`
- residual mode: `all_shortwave`
- include Rayleigh candidates: true
- candidates: 12
- probe step: 0.0001220703125
- max log scale: 0.0009765625
- base objective: 7.197812620308923
- best exact objective: 7.193524184543065
- best objective reduction: 0.004288435765857912
- best TOA forcing: 2.1580572553629196
- best surface forcing: 2.0279297458791916
- accepted moves: 12
- accepted: true

## Retained Structural Pareto Probe

- present: true
- status: `pareto_probe_rejected`
- configurations: 2
- best label: `current_residual_tiny_no_rayleigh`
- best exact objective: 7.193524184543065
- best objective reduction: 0.0
- best TOA forcing: 2.1580572553629196
- best surface forcing: 2.028383871322717
- any accepted: false
- any Pareto-safe accepted: false

## Retained Quadrature Pareto Scan

- present: true
- status: `quadrature_pareto_scan_rejected`
- candidates: 128
- base objective: 7.193524184543065
- best objective: 7.841462640249499
- best objective reduction: -0.6479384557064334
- best TOA forcing: 2.341262851028091
- best surface forcing: 2.3524387920748495
- best move: g14 positive 0.03125
- best TOA regressed: true
- best surface regressed: true
- any Pareto-safe: false
- best Pareto-safe objective: 7.193524184543065

## Retained Quadrature Pair Pareto Scan

- present: true
- status: `quadrature_pair_pareto_scan_rejected`
- pairs: 120
- candidates: 480
- base objective: 7.193524184543065
- best objective: 7.793782609045745
- best objective reduction: -0.6002584245026794
- best TOA forcing: 2.336998958566369
- best surface forcing: 2.3381347827137233
- best move: g14 up, g25 down, 0.03125
- best TOA regressed: true
- best surface regressed: true
- any Pareto-safe: false
- best Pareto-safe objective: 7.193524184543065

## Retained Quadrature Linearized Optimizer

- present: true
- status: `quadrature_linearized_optimizer_rejected`
- residual mode: `all_shortwave`
- basis count: 15
- base objective: 7.054523065216548
- best exact objective: 8.92989013811454
- best objective reduction: -1.8753670728979923
- best TOA forcing: 2.201854566570944
- best surface forcing: 2.678967041434362
- any Pareto-safe: false
- accepted: false

## Retained Current Quadrature Linearized Optimizer

- present: true
- status: `current_quadrature_linearized_optimizer_rejected`
- residual mode: `all_shortwave`
- basis count: 15
- surface cap: 2.03
- TOA tolerance: 0.0
- base objective: 6.97212754254385
- base TOA forcing: 2.091638262763155
- base surface forcing: 2.0069430717148435
- best exact objective: 9.747571100255831
- best objective reduction: -2.7754435577119807
- best TOA forcing: 2.28122103579949
- best surface forcing: 2.924271330076749
- accepted objective: 6.97212754254385
- accepted TOA forcing: 2.091638262763155
- accepted surface forcing: 2.0069430717148435
- accepted: false

## Retained Current Bounded Table Optimizer

- present: true
- status: `current_bounded_table_optimizer_rejected`
- residual mode: `surface`
- candidates: 16
- surface cap: 2.03
- TOA tolerance: 0.0
- minimum objective reduction: 0.001
- base objective: 6.97212754254385
- base TOA forcing: 2.091638262763155
- base surface forcing: 2.0069430717148435
- best exact objective: 9.889130808038166
- best objective reduction: -2.9170032654943157
- best TOA forcing: 2.380309873076385
- best surface forcing: 2.9667392424114496
- accepted objective: 6.97212754254385
- accepted objective reduction: 0.0
- accepted TOA forcing: 2.091638262763155
- accepted surface forcing: 2.0069430717148435
- accepted moves: 0
- accepted: false

## Retained Current Heating-Profile Optimizer

- present: true
- status: `current_heating_profile_optimizer_rejected`
- residual mode: `heating_profile_boundary`
- candidates: 8
- surface cap: 2.03
- TOA tolerance: 0.0
- minimum objective reduction: 0.001
- base objective: 6.97212754254385
- base TOA forcing: 2.091638262763155
- base surface forcing: 2.0069430717148435
- base heating RMSE: 0.34857599703590136
- best exact objective: 9.89161448599172
- best objective reduction: -2.91948694344787
- best TOA forcing: 2.379879680626459
- best surface forcing: 2.9674843457975157
- best heating RMSE: 0.34485215702987443
- accepted objective: 6.97212754254385
- accepted objective reduction: 0.0
- accepted TOA forcing: 2.091638262763155
- accepted surface forcing: 2.0069430717148435
- accepted heating RMSE: 0.34857599703590136
- accepted moves: 0
- accepted: false

## Retained Current Joint Heating Optimizer

- present: true
- status: `current_joint_heating_optimizer_rejected`
- residual mode: `heating_profile_boundary`
- basis: `quadrature_logits_plus_active_table_entries`
- logit basis count: 15
- table candidates: 8
- basis count: 23
- surface cap: 2.03
- TOA tolerance: 0.0
- minimum objective reduction: 0.001
- base objective: 6.97212754254385
- base TOA forcing: 2.091638262763155
- base surface forcing: 2.0069430717148435
- base heating RMSE: 0.34857599703590136
- best exact objective: 8.517983399567584
- best objective reduction: -1.5458558570237333
- best TOA forcing: 2.498407254608196
- best surface forcing: 2.555395019870275
- best heating RMSE: 0.34039942362275777
- accepted objective: 6.97212754254385
- accepted objective reduction: 0.0
- accepted TOA forcing: 2.091638262763155
- accepted surface forcing: 2.0069430717148435
- accepted heating RMSE: 0.34857599703590136
- accepted table moves: 0
- accepted: false

## Retained Current Component-Scale Optimizer

- present: true
- status: `current_component_scale_optimizer_improved`
- residual mode: `heating_profile_boundary`
- basis: `per_gpoint_static_h2o_rayleigh_component_scales`
- basis count: 48
- surface cap: 2.03
- TOA tolerance: 0.0
- minimum objective reduction: 0.001
- base objective: 6.97212754254385
- base TOA forcing: 2.091638262763155
- base surface forcing: 2.0069430717148435
- base heating RMSE: 0.34857599703590136
- best exact objective: 6.969334511271181
- best objective reduction: 0.0027930312726693884
- best TOA forcing: 2.090800353381354
- best surface forcing: 2.0149879445638135
- best heating RMSE: 0.3473614930085476
- accepted objective: 6.969334511271181
- accepted objective reduction: 0.0027930312726693884
- accepted TOA forcing: 2.090800353381354
- accepted surface forcing: 2.0149879445638135
- accepted heating RMSE: 0.3473614930085476
- accepted: true

## Retained Current Component-Scale Optimizer 2

- present: true
- status: `current_component_scale_optimizer2_improved`
- residual mode: `heating_profile_boundary`
- basis: `second_pass_per_gpoint_static_h2o_rayleigh_component_scales`
- basis count: 48
- surface cap: 2.03
- TOA tolerance: 0.0
- minimum objective reduction: 0.0005
- base objective: 6.969334511271181
- base TOA forcing: 2.090800353381354
- base surface forcing: 2.0149879445638135
- base heating RMSE: 0.3473614930085476
- best exact objective: 6.967301555794165
- best objective reduction: 0.002032955477015541
- best TOA forcing: 2.0901904667382496
- best surface forcing: 2.0134857788435454
- best heating RMSE: 0.34674212154136674
- accepted objective: 6.967301555794165
- accepted objective reduction: 0.002032955477015541
- accepted TOA forcing: 2.0901904667382496
- accepted surface forcing: 2.0134857788435454
- accepted heating RMSE: 0.34674212154136674
- accepted: true

## Retained Current Component-Scale Optimizer 3

- present: true
- status: `current_component_scale_optimizer3_improved`
- residual mode: `heating_profile_boundary`
- basis: `third_pass_per_gpoint_static_h2o_rayleigh_component_scales`
- basis count: 48
- surface cap: 2.03
- TOA tolerance: 0.0
- minimum objective reduction: 0.00025
- base objective: 6.967301555794165
- base TOA forcing: 2.0901904667382496
- base surface forcing: 2.0134857788435454
- base heating RMSE: 0.34674212154136674
- best exact objective: 6.966251466909105
- best objective reduction: 0.0010500888850604184
- best TOA forcing: 2.0898754400727313
- best surface forcing: 2.014232826211469
- best heating RMSE: 0.3464195337771146
- accepted objective: 6.966251466909105
- accepted objective reduction: 0.0010500888850604184
- accepted TOA forcing: 2.0898754400727313
- accepted surface forcing: 2.014232826211469
- accepted heating RMSE: 0.3464195337771146
- accepted: true

## Retained Current Component-Scale Optimizer 4

- present: true
- status: `current_component_scale_optimizer4_improved`
- residual mode: `heating_profile_boundary`
- basis: `fourth_pass_per_gpoint_static_h2o_rayleigh_component_scales`
- basis count: 48
- surface cap: 2.03
- TOA tolerance: 0.0
- minimum objective reduction: 0.000125
- base objective: 6.966251466909105
- base TOA forcing: 2.0898754400727313
- base surface forcing: 2.014232826211469
- base heating RMSE: 0.3464195337771146
- best exact objective: 6.965705616445254
- best objective reduction: 0.0005458504638511386
- best TOA forcing: 2.089711684933576
- best surface forcing: 2.014620060988314
- best heating RMSE: 0.3462487767792485
- accepted objective: 6.965705616445254
- accepted objective reduction: 0.0005458504638511386
- accepted TOA forcing: 2.089711684933576
- accepted surface forcing: 2.014620060988314
- accepted heating RMSE: 0.3462487767792485
- accepted: true

## Retained Current Pressure-Component Optimizer

- present: true
- status: `current_pressure_component_optimizer_improved`
- residual mode: `heating_profile_boundary`
- basis: `per_gpoint_pressure_band_static_h2o_component_scales`
- basis count: 128
- pressure-band count: 4
- surface cap: 2.03
- TOA tolerance: 0.0
- minimum objective reduction: 0.001
- base objective: 6.965705616445254
- base TOA forcing: 2.089711684933576
- base surface forcing: 2.014620060988314
- base heating RMSE: 0.3462487767792485
- best exact objective: 6.955899660495106
- best objective reduction: 0.009805955950147549
- best TOA forcing: 2.086769898148532
- best surface forcing: 2.013835423916582
- best heating RMSE: 0.34399763377316
- accepted objective: 6.955899660495106
- accepted objective reduction: 0.009805955950147549
- accepted TOA forcing: 2.086769898148532
- accepted surface forcing: 2.013835423916582
- accepted heating RMSE: 0.34399763377316
- accepted: true

## Retained Current Pressure-Component Scan

- present: true
- status: `current_pressure_component_scan_improved`
- residual mode: `heating_profile_boundary`
- basis: `per_gpoint_pressure_band_static_h2o_component_scales`
- include Rayleigh: false
- static gas split: false
- selected partition: `log_pressure`
- selected pressure-band count: 8
- selected basis count: 256
- selected accepted moves: 238
- surface cap: 2.03
- TOA tolerance: 0.0
- minimum objective reduction: 0.001
- base objective: 6.965705616445254
- base TOA forcing: 2.089711684933576
- base surface forcing: 2.014620060988314
- base heating RMSE: 0.3462487767792485
- selected objective: 6.934406309441196
- selected TOA forcing: 2.080321892832359
- selected surface forcing: 2.0231421127480047
- selected heating RMSE: 0.34553657661892073
- accepted: true

## Retained Current Pressure-Component Rayleigh Scan

- present: true
- status: `current_pressure_component_scan_improved`
- residual mode: `heating_profile_boundary`
- basis: `per_gpoint_pressure_band_static_h2o_component_scales_plus_rayleigh`
- include Rayleigh: true
- static gas split: false
- selected partition: `index`
- selected pressure-band count: 4
- selected basis count: 144
- selected accepted moves: 135
- surface cap: 2.03
- selected objective: 6.956078733661997
- selected TOA forcing: 2.086823620098599
- selected surface forcing: 2.0204840025069117
- selected heating RMSE: 0.3441380066108824
- accepted: true

## Retained Current Pressure-Component Surface-Guard Scan

- present: true
- status: `current_pressure_component_scan_improved`
- residual mode: `heating_profile_boundary`
- basis: `per_gpoint_pressure_band_static_h2o_component_scales`
- include Rayleigh: false
- static gas split: false
- selected partition: `log_pressure`
- selected pressure-band count: 4
- selected basis count: 128
- selected accepted moves: 119
- surface cap: 2.02
- selected objective: 6.954300434068443
- selected TOA forcing: 2.086290130220533
- selected surface forcing: 2.0145221241717266
- selected heating RMSE: 0.3439955488691842
- accepted: true

## Retained Current Gas-Pressure Component Scan

- present: true
- status: `current_pressure_component_scan_improved`
- residual mode: `heating_profile_boundary`
- basis: `per_gpoint_pressure_band_static_gas_h2o_component_scales`
- include Rayleigh: false
- static gas split: true
- selected partition: `log_pressure`
- selected pressure-band count: 4
- selected basis count: 576
- selected accepted moves: 312
- surface cap: 2.03
- selected objective: 6.9289635819132895
- selected TOA forcing: 2.0786890745739868
- selected surface forcing: 2.024535501958894
- selected heating RMSE: 0.34403925398554575
- accepted: true

## Retained Current Gas-Pressure Component Continuation Scan

- present: true
- status: `current_pressure_component_scan_improved`
- residual mode: `heating_profile_boundary`
- basis: `per_gpoint_pressure_band_static_gas_h2o_component_scales`
- include Rayleigh: false
- static gas split: true
- selected partition: `log_pressure`
- selected pressure-band count: 4
- selected basis count: 576
- selected accepted moves: 312
- surface cap: 2.028
- selected objective: 6.919764945999324
- selected TOA forcing: 2.075929483799797
- selected surface forcing: 2.0270181578559345
- selected heating RMSE: 0.34349224387457794
- accepted: true

## Retained Current Weighted Gas-Pressure Component Continuation Scan

- present: true
- status: `current_pressure_component_scan_improved`
- residual mode: `heating_profile_boundary`
- basis: `per_gpoint_pressure_band_static_gas_h2o_component_scales`
- include Rayleigh: false
- static gas split: true
- heating residual weight: 4.0
- boundary residual weight: 1.0
- selected partition: `log_pressure`
- selected pressure-band count: 4
- selected basis count: 576
- selected accepted moves: 313
- surface cap: 2.02702
- selected objective: 6.918020507423156
- selected TOA forcing: 2.0754061522269467
- selected surface forcing: 2.0270141541137363
- selected heating RMSE: 0.3432374882916219
- accepted: true

## Retained Current High-Weight Gas-Pressure Component Continuation Scan

- present: true
- status: `current_pressure_component_scan_improved`
- residual mode: `heating_profile_boundary`
- basis: `per_gpoint_pressure_band_static_gas_h2o_component_scales`
- include Rayleigh: false
- static gas split: true
- heating residual weight: 8.0
- boundary residual weight: 1.0
- selected partition: `log_pressure`
- selected pressure-band count: 4
- selected basis count: 576
- selected accepted moves: 313
- surface cap: 2.0270142
- selected objective: 6.91747223736229
- selected TOA forcing: 2.075241671208687
- selected surface forcing: 2.026956688318073
- selected heating RMSE: 0.3431161518590576
- accepted: true

## Broader Support-Plus-Refit Search

- present: true
- status: `support_refit_rejected`
- objective target: 1.0
- current objective: 7.0064077395265185
- best objective: 45.03503799193671
- best objective reduction: -38.028630252410196
- radius: 2
- prefilter candidates: 8 / 33
- refit candidates: 2 / 33
- best move: g4 -> g2
- passed hard objective: false

## Nonlocal Support-Plus-Refit Search

- present: true
- status: `nonlocal_support_refit_rejected`
- objective target: 1.0
- current objective: 7.0064077395265185
- best objective: 45.03503799193671
- best objective reduction: -38.028630252410196
- candidates: 4 / 4
- best label: `hardgate_subset_best`
- passed hard objective: false

## Retained Capped Table Optimizer

- present: true
- status: `retained_capped_table_optimizer_improved`
- candidate scope: `all_global_residual_probe`
- residual mode: `surface`
- surface cap: 2.03
- TOA tolerance: 0.0
- candidates: 48
- base objective: 7.054523065216548
- base TOA forcing: 2.1163569195649643
- base surface forcing: 2.029781059196388
- cap-safe row present: true
- best cap-safe objective: 7.001340598221807
- best cap-safe TOA forcing: 2.100402179466542
- best cap-safe surface forcing: 2.013975838620567
- best overall objective: 7.001340598221807
- best overall TOA forcing: 2.100402179466542
- best overall surface forcing: 2.013975838620567
- best unsafe objective: 7.158656695435942
- best unsafe TOA forcing: 2.130143039847624
- best unsafe surface forcing: 2.1475970086307825
- accepted: true
- accepted moves: 48

## Retained Capped Table Continuation

- present: true
- status: `retained_capped_table_continuation_improved`
- candidate scope: `all_global_residual_probe`
- residual mode: `surface`
- surface cap: 2.03
- TOA tolerance: 0.0
- base capped moves: 48
- candidates: 48
- base objective: 7.001340598221807
- base TOA forcing: 2.100402179466542
- base surface forcing: 2.013975838620567
- cap-safe row present: true
- best cap-safe objective: 6.98655990974778
- best cap-safe TOA forcing: 2.0924515443667673
- best cap-safe surface forcing: 2.013449998462079
- best overall objective: 6.98655990974778
- best overall TOA forcing: 2.0924515443667673
- best overall surface forcing: 2.013449998462079
- best unsafe objective: 7.0089335237769985
- best unsafe TOA forcing: 2.1026800571330995
- best unsafe surface forcing: 2.0160198535356955
- accepted: true
- accepted moves: 48

## Retained Post-Capped Weight Refit

- present: true
- status: `retained_post_capped_weight_refit_improved`
- iterations: 25000
- base objective: 6.98655990974778
- refit objective: 6.979264309835722
- objective reduction: 0.00729559991205786
- base TOA forcing: 2.0924515443667673
- base surface forcing: 2.013449998462079
- refit TOA forcing: 2.092063121393437
- refit surface forcing: 2.0064903601304067
- accepted: true
- max abs weight delta: 2.8150644069691033e-6

## Retained Post-Weight Surface Table Refit

- present: true
- status: `retained_post_weight_surface_table_refit_rejected`
- residual mode: `surface`
- candidates: 16
- base objective: 6.979264309835722
- best objective: 6.979238075476291
- best objective reduction: 2.6234359431498433e-5
- best TOA forcing: 2.092063121393437
- best surface forcing: 2.0064903601304067
- accepted: false
- accepted moves: 0

## Retained Post-Weight Bounded Weight Refit

- present: true
- status: `retained_post_weight_bounded_weight_refit_improved`
- iterations: 50000
- surface cap: 2.03
- base objective: 6.979264309835722
- refit objective: 6.97212754254385
- objective reduction: 0.007136767291871848
- base TOA forcing: 2.092063121393437
- base surface forcing: 2.0064903601304067
- refit TOA forcing: 2.091638262763155
- refit surface forcing: 2.0069430717148435
- accepted: true
- max abs weight delta: 3.427650503928792e-6

## Retained Table Coordinate Pareto Scan

- present: true
- status: `table_coordinate_pareto_scan_rejected`
- candidates: 64
- trials: 640
- base objective: 7.193524184543065
- best objective: 7.193524184543065
- best objective reduction: 0.0
- best TOA forcing: 2.1580572553629196
- best surface forcing: 2.027929745271422
- best component: `static_absorption`
- best move: g30 negative 0.0001220703125
- best TOA regressed: false
- best surface regressed: false
- any Pareto-safe: false
- best Pareto-safe objective: 7.193524184543065

## Retained Objective-Probe Expansion

- present: true
- status: `objective_probe_expansion_rejected`
- configurations: 2
- best label: `objective_probe_24_medium_tiny`
- best exact objective: 7.1479553401358
- best objective reduction: 0.005350185250989625
- best TOA forcing: 2.14438660204074
- best surface forcing: 2.057609695615838
- any accepted: false

## Retained Objective-Probe Expansion 2

- present: true
- status: `objective_probe_expansion2_rejected`
- configurations: 2
- best label: `objective_probe2_24_medium_tiny`
- best exact objective: 7.153305525386884
- best objective reduction: 0.005365928912985041
- best TOA forcing: 2.145991657616065
- best surface forcing: 2.034156464009129
- any accepted: false

## Retained Objective-Probe Expansion 3

- present: true
- status: `objective_probe_expansion3_rejected`
- configurations: 2
- best label: `objective_probe3_24_medium_tiny`
- best exact objective: 7.158671454299963
- best objective reduction: 0.00538167743277107
- best TOA forcing: 2.147601436289989
- best surface forcing: 2.0108178569705615
- any accepted: false

## Retained Objective-Probe Expansion 4

- present: true
- status: `objective_probe_expansion4_rejected`
- configurations: 2
- best label: `objective_probe4_32_medium_tiny`
- best exact objective: 7.164053131732734
- best objective reduction: 0.005723801443385135
- best TOA forcing: 2.14921593951982
- best surface forcing: 1.9875938542755875
- any accepted: false

## Retained Surface-Probe Expansion

- present: true
- status: `surface_probe_expansion_rejected`
- configurations: 2
- best label: `surface_probe_32_small_tiny`
- best exact objective: 7.188843817861729
- best objective reduction: -5.744261253948224e-5
- best TOA forcing: 2.1566531453585185
- best surface forcing: 2.0122889742841608
- any accepted: false

## Retained Surface-Probe Expansion 2

- present: true
- status: `surface_probe_expansion2_rejected`
- configurations: 2
- best label: `surface_probe2_32_small_tiny`
- best exact objective: 7.19271692514288
- best objective reduction: -4.571520586704736e-5
- best TOA forcing: 2.157815077542864
- best surface forcing: 2.0237684915168757
- any accepted: false

## Retained Surface-Probe Expansion 3

- present: true
- status: `surface_probe_expansion3_rejected`
- configurations: 2
- best label: `surface_probe3_32_small_tiny`
- best exact objective: 7.193567264739093
- best objective reduction: -4.308019602738966e-5
- best TOA forcing: 2.1580701794217276
- best surface forcing: 2.0280040109353195
- any accepted: false

## Retained Boundary-Probe Expansion

- present: true
- status: `boundary_probe_expansion_rejected`
- configurations: 3
- best label: `boundary_probe_32_small_tiny`
- best exact objective: 7.194506563887444
- best objective reduction: -0.0009823793443786144
- best TOA forcing: 2.158351969166233
- best surface forcing: 2.029818713168652
- any accepted: false

## Retained TOA-Probe Expansion

- present: true
- status: `toa_probe_expansion_rejected`
- configurations: 2
- best label: `toa_probe_32_medium_tiny`
- best exact objective: 7.131469676120048
- best objective reduction: 0.01648566401570406
- best TOA forcing: 2.1394409028360144
- best surface forcing: 2.079391726648055
- any Pareto-safe: false
- any accepted: false

## Boundary-Table Triple Coordinate Scan

- present: true
- status: `triple_coordinate_scan_improved`
- single trials: 384
- selected singles: 16
- triple trials: 560
- base objective: 7.2958592955110175
- best objective: 7.295859288971087
- best objective reduction: 6.53993037502687e-9
- best TOA forcing: 2.188757786691326
- best surface forcing: 2.182241639983431
- accepted: true

## Next Required Work

Promote the passing reduced model into the Breeze Pareto and H100 production benchmark path.
