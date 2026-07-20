# Gate-4 R2 finding: SSI resolved, drift version-independent

Status: **r2_ssi_resolved_drift_version_independent**

Finding record only; no floor, objective, acceptance, init-generation, or
recovery computation; no promotion.

## Headline

The v1.4 (`23adaca`) build **emits `solar_spectral_irradiance` and it is
elementwise EXACT** vs the published SW32 file (995 fine-grid values
bit-identical). The SSI-absence finding is **resolved as version skew**,
confirming R1 experimentally. The residual drift is **version-independent**:
identical mismatch counts and max diffs at v1.2 and v1.4.

## Run record (job 4096, rc=0)

Attempts: 4094 failed (upstream adept.m4 link-order bug, latent at v1.2);
4095 failed (LIBS applied before any -L path); 4096 green with
`LDFLAGS='-L<adept>/lib -Wl,-rpath,<adept>/lib' LIBS=-ladept`. Build:
gcc 13.3.0, commit verified, `create_look_up_table` sha256 `1c79dfa3…5412d3`.
Input: hash-pinned 4082 SW candidate (find_g_points unchanged in
v1.2..23adaca). Output `ecckd-1.4_sw_raw-…rgb-tol0.047.nc` sha256
`99333fb5…532c26`, log-echo match. 50 averaging warnings (SW-only; recorded).

## Comparisons (run twice, deterministic)

| Field | Result |
|---|---|
| g_count, band bounds, band_number, fine wavenumber grids | EXACT |
| **solar_spectral_irradiance** | **PRESENT + EXACT** |
| gpoint_fraction | 60/31840 mismatched, max 1.60e-5 |
| solar_irradiance | 2/32, max 2.05e-5 |
| rayleigh_molar_scattering_coeff | 2/32, max 9.6e-16 |

The three mismatch sets are numerically identical to the v1.2 proof (4091)
— same counts, same max diffs. SSI bit-exactness also proves the local SSI
input and wavenumber grid match upstream's build inputs.

## Attribution state

- Resolved: SW structural absence = version skew (closed by experiment).
- Unresolved: the small drift — version-independent across v1.2/v1.4, so
  attributable to input-data or build-config provenance of the original
  published build, not the testable code-version delta.
- LW-1.0 mapping ambiguity unchanged.

## Decision input for Greg

Option B (structural-exact + storage-precision tolerance) is now strongly
supported: everything structural including the newly emitted SSI is
bit-exact; residual drift ≤2.1e-5, confined to three arrays, provably not a
function of code version in the testable range. Option A (strict) leaves
the campaign without an acceptance init source. Promotion remains NOT
automatic pending Greg's explicit rule decision.
