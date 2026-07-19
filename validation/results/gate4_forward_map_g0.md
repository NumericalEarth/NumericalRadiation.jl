# Gate-4 forward map G0 (stage3_objective_completion_plumbing)

Status: **stage3_gates_passed**

no objective-value, floor, or recovery claims; synthetic shapes and published tables only; stages 1-3 cover interpolation, RT recurrences, the Enzyme chain gradient, and the prior/negative-OD objective-completion terms.

| Gate | Result |
|---|---|
| gate1_interpolation_nodes | passed |
| gate2_lw_analytic | passed |
| gate3_sw_analytic | passed |
| gate4_published_table_load | passed |
| gate5_enzyme_chain_fd | passed |
| gate6_prior_term | passed |
| gate7_negative_od_penalty | passed |

SW heating convention: downwelling-only divergence (design Appendix A, high-risk parity requirement).

Top-edge interpolation nodes follow the upstream index clamp (fractional index <= n-1.0001) and are verified against the analytically clamped value.

Provenance: branch `glw/gate4-recovery`, generated_from_head `3739b68` (artifact generated from the working tree before its own commit), checklist Appendix B; published SW32 load: loaded.
