# Gate-4 forward map G0 (Stage 1)

Status: **stage1_gates_passed**

no objective-value or recovery claims; synthetic shapes and published tables only; Stage 1 covers interpolation and RT recurrences with analytic fixtures.

| Gate | Result |
|---|---|
| gate1_interpolation_nodes | passed |
| gate2_lw_analytic | passed |
| gate3_sw_analytic | passed |
| gate4_published_table_load | passed |

SW heating convention: downwelling-only divergence (design Appendix A, high-risk parity requirement).

Top-edge interpolation nodes follow the upstream index clamp (fractional index <= n-1.0001) and are verified against the analytically clamped value.

Provenance: branch `glw/gate4-recovery`, HEAD `5bf8310`, checklist Appendix B; published SW32 load: loaded.
