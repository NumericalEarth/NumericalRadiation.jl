# Gate-4 matched-state OD evaluator (aggregation-independent)

Status: **matched_state_od_evaluator_passed**

aggregation-independent matched-state OD evaluator library + self-tests; parity vs pinned run_ckd smoke references through the stacked-axis scenario contract; no Gate-2 dataset choice, no aggregation choice, no thresholds-4/5 semantics, no optimizer/floor/recovery claims.

| Gate | Verdict |
|---|---|
| gas_axis_permutation_invariance | passed |
| lw_clamp_field_separate | passed |
| lw_od_parity | passed |
| lw_pressure_grid_consistent | passed |
| negativity_findings_unclamped | passed |
| refuse_active_n2 | passed |
| refuse_active_rayleigh | passed |
| refuse_constituent_count_mismatch | passed |
| refuse_definition_gas_set_mismatch | passed |
| refuse_definition_gcount_drift | passed |
| refuse_duplicate_active_gas | passed |
| refuse_empty_active_list | passed |
| refuse_gas_not_in_definition | passed |
| refuse_missing_conc_dependent_gas | passed |
| refuse_missing_reference_surface_mf | passed |
| refuse_negative_active_vmr | passed |
| refuse_negative_reference_surface_mf | passed |
| refuse_nonfinite_temperature | passed |
| refuse_nonmonotone_pressure | passed |
| refuse_parity_stats_shape_mismatch | passed |
| refuse_unknown_scenario_axis_id | passed |
| refuse_wrong_dim_order | passed |
| sw_clamp_field_separate | passed |
| sw_od_parity | passed |
| sw_pressure_grid_consistent | passed |

Parity (Float32-storage tolerances: abs floor 1.0e-9, rel 1.0e-6):

| Term | max_abs | max_rel (above floor) | signed bias |
|---|---|---|---|
| lw_od_cfc11 | 2.884306920906965e-11 | 0.0 | -0.0018181818181818182 |
| lw_od_cfc12 | 1.455136873626181e-11 | 0.0 | 0.002108262108262108 |
| lw_od_ch4 | 3.7093903365592595e-9 | 5.808530289395586e-8 | 0.002215999025934494 |
| lw_od_co2 | 7.5982707699040475e-6 | 5.931739946656874e-8 | -0.0005095541401273885 |
| lw_od_composite | 4.764991974326449e-7 | 5.9199810344545984e-8 | 0.001574074074074074 |
| lw_od_h2o | 1.4010364736805059e-5 | 5.923122202435551e-8 | 0.0008796296296296296 |
| lw_od_n2o | 5.81878469019248e-11 | 0.0 | -0.005396732788798133 |
| lw_od_o3 | 1.1829560353504576e-7 | 5.7952849428986206e-8 | 0.0003935185185185185 |
| lw_od_total_raw | 1.4008329458192748e-5 | 1.4899122797653175e-7 | 0.0011574074074074073 |
| sw_od_ch4 | 3.63748617272959e-12 | 0.0 | 0.0039673278879813305 |
| sw_od_co2 | 2.383849997400489e-7 | 5.883617470808254e-8 | 0.009333333333333334 |
| sw_od_composite | 1.4817620130891385e-8 | 5.668876750666911e-8 | 0.007824074074074074 |
| sw_od_h2o | 4.7568398287012315e-7 | 5.8662862409280235e-8 | -0.002835249042145594 |
| sw_od_n2o | 2.903624075119987e-11 | 0.0 | -0.004717078295260263 |
| sw_od_o3 | 1.1910219344102302e-7 | 5.733067860628769e-8 | 0.003111111111111111 |
| sw_od_total_raw | 4.778716728992549e-7 | 5.876539197068577e-8 | 0.002962962962962963 |

Provenance: branch `glw/gate4-recovery`, head `0255fe7` (pre-own-commit).
