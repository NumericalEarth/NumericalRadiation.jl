# ecRad Cloud Scattering Tables Check

Status: **passed**

This check verifies that the package can ingest the official ecRad cloud scattering NetCDF tables and map them to the official ecCKD g-point grids needed for the all-sky SOCRATES/Fu optical-property path. It does not yet prove that the mapped properties are used by the all-sky solver.

| Kind | Status | Medium | Wavenumbers | Effective radii | Shape OK | Bounded | Path |
|---|---|---|---:|---:|---:|---:|---|
| liquid | passed | `liquid-water` | 396 | 50 | true | true | `validation/external/ecrad/data/mie_droplet_scattering.nc` |
| ice | passed | `ice` | 445 | 23 | true | true | `validation/external/ecrad/data/baum-general-habit-mixture_ice_scattering.nc` |

## ecCKD G-Point Mapping

| Kind | Status | Intervals | G-points | Shape OK | Fractions nonnegative | Liquid max extinction | Ice max extinction |
|---|---|---:|---:|---:|---:|---:|---:|
| shortwave | passed | 995 | 32 | true | true | 184.35586677556356 | 56.10563625683885 |
| longwave | passed | 326 | 64 | true | true | 204.32733732722625 | 62.64665824313908 |

Next implementation step: use these mapped g-point scattering properties in cloudy-region optical-depth construction and then carry cloud fraction/overlap through the all-sky solver instead of tuning broadband cloud coefficients.
