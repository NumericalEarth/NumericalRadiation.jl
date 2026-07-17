# Reduced ecCKD Pressure-Band Refinement Preflight

Status: **pressure_band_move_improved**

| Field | Value |
|---|---:|
| Current full objective | 8.6288431477 |
| Target case | ecckd_rcemip_style_column_subset |
| Target metric | toa_forcing_max_abs |
| Target metric objective | 8.6288431477 |
| Pressure bands | 4 |
| Candidates | 16 |
| Best target-metric band | 1 |
| Best target-metric scale | 1.28403 |
| Best target-metric objective | 8.6263523057 |
| Best full-objective band | 1 |
| Best full-objective scale | 0.882497 |
| Best full objective | 9.43264588506 |
| Global pressure-band accepted | false |
| Per-g pressure-band candidates | 64 |
| Best per-g target g-point | 9 |
| Best per-g target band | 4 |
| Best per-g target objective | 8.60906253001 |
| Best per-g full g-point | 10 |
| Best per-g full band | 3 |
| Best per-g full objective | 8.61698624162 |
| Per-g pressure-band accepted | true |
| Component per-g candidates | 64 |
| Best component per-g full component | static_absorption |
| Best component per-g full g-point | 4 |
| Best component per-g full band | 4 |
| Best component per-g full objective | 8.60669545574 |
| Component per-g pressure-band accepted | true |
| Iterative component per-g iterations completed | 2 |
| Iterative component per-g accepted moves | 2 |
| Iterative component per-g final objective | 8.60500733608 |
| Active table-entry candidates | 64 |
| Active table-entry component | static_absorption |
| Active table-entry g-point | 4 |
| Best active table-entry full objective | 8.62833129034 |
| Active table-entry accepted | true |
| Iterative active table-entry iterations completed | 2 |
| Iterative active table-entry accepted moves | 2 |
| Iterative active table-entry final objective | 8.6276741494 |
| Pairwise per-g candidates | 14 |
| Pairwise selected single candidates | 6 |
| Best pairwise full objective | 8.61198581335 |
| Pairwise pressure-band accepted | true |
| Iterative per-g iterations requested | 2 |
| Iterative per-g iterations completed | 2 |
| Iterative per-g accepted moves | 2 |
| Iterative per-g final objective | 8.61529790805 |
| Iterative per-g objective reduction | 0.0135452396521 |

Next required work: The accepted iterative component pressure-band moves are already promoted into the main reduced optimizer and reduced-accuracy artifact; move beyond bounded pressure-band table scales to a constrained multi-parameter coefficient-table or quadrature-bin optimizer against flux and heating residuals.
