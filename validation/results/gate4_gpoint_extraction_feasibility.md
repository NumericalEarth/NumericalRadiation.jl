# Gate-4 g-point extraction feasibility (negative result)

Status: **extraction_infeasibility_proven**

published definitions contain NO standalone g_point variable (inventory recorded), and gpoint_fraction is a fractional overlap/projection on the coarse definition grid, not a one-hot assignment; the real per-wavenumber g_point vector required by create_look_up_table cannot be recovered from it; argmax extraction is invalid

| Target | size | max | fractional entries | colsum range |
|---|---|---|---|---|
| lw32 | [326, 32] | 0.4488372206687927 | 2537 | [0.999999985244358, 1.0000000151339918] |
| sw32 | [995, 32] | 0.46638116240501404 | 2066 | [0.9999985096692399, 1.0000000305299181] |

| Gate | Result |
|---|---|
| argmax_extraction_ruled_out | passed |
| create_lut_requires_g_point_vector | passed |
| gpoint_fraction_is_fractional | passed |
| no_computation_beyond_file_stats | passed |
| no_g_point_variable_in_published | passed |

Remaining options: A1 locate released find_g_points outputs; A2 rerun find_g_points as fixed-input problem-definition reconstruction (acceptance only if the reconstructed structure exactly reproduces the published gpoint_fraction/band arrays, else requires an explicit rule change); A3 alternative init source from upstream release history.

Provenance: branch `glw/gate4-recovery`, generated_from_head `2cebde3` (pre-own-commit).
