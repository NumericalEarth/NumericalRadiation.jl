# Correlated-k Method

Line-by-line radiation resolves absorption at very fine spectral spacing. That
is accurate but too expensive for most weather and climate simulations. A
correlated-k model compresses each spectral band into a small quadrature over
sorted absorption strength.

## From Wavenumber to g Space

Within a spectral band ``b``, define the cumulative distribution of absorption
coefficients by

```math
g(k) = \frac{1}{\Delta \nu_b}
       \int_{\nu \in b} \mathbf{1}\left(\kappa_\nu \le k\right)\,d\nu.
```

The band-integrated transmissivity can then be approximated as

```math
\bar{T}_b(u)
  = \frac{1}{\Delta \nu_b}\int_{\nu \in b} e^{-\kappa_\nu u}\,d\nu
  \approx \sum_{i=1}^{n_g} w_{b,i}
          \exp\left(-k_{b,i} u\right).
```

The nodes ``k_{b,i}`` and weights ``w_{b,i}`` are the g points. The
"correlated" assumption is that the sorted absorption ordering remains usable
as pressure, temperature, and gas composition vary across the column.

## How ecCKD Chooses g Points

ecCKD is not an ordinary per-band Gaussian quadrature over the cumulative
distribution above. The construction, described by Hogan & Matricardi (2022)
and in the tool documentation (`doc/ecckd_documentation.tex` in the
[upstream ecCKD repository](https://github.com/ecmwf-ifs/ecckd), pinned here
as the `ecckd_source` artifact), proceeds in distinct steps:

1. **Reorder each gas once, on a fixed reference profile.** Wavenumbers are
   ranked within each band on the median present-day profile of the CKDMIP
   *MMM* dataset — in the longwave by the height of the peak cooling rate
   (Hogan, 2010), in the shortwave by the height at which the zenith optical
   depth reaches 0.25 from the top of atmosphere. The result is a *unique*
   mapping from wavenumber to g space (the `gpoint_fraction` variable in the
   CKD-definition files), unlike CKD implementations that reorder
   independently at each pressure level.
2. **Partition each gas's g space against an error tolerance.** For each gas
   and band, the ordered spectrum is partitioned into g points such that a
   penalty function — heating-rate error plus a weighted flux error of a
   quasi-monochromatic calculation against line-by-line truth — stays below a
   configured heating-rate tolerance in K day⁻¹. Fewer g points are needed at
   looser tolerance.
3. **Merge gases with the full-spectrum hypercube partition.** The
   single-gas partitions are overlapped using the hypercube-partition method
   of Hogan (2010), which sets the combined number of g points per band to
   ``1 - n_\mathrm{gas} + \sum_i n_{g,i}`` rather than the product of
   single-gas counts.

References: Hogan (2010), *J. Atmos. Sci.*, 67, 2086–2100,
doi:10.1175/2010JAS3202.1; Hogan & Matricardi (2020), *Geosci. Model Dev.*,
13, 6501–6521, doi:10.5194/gmd-13-6501-2020 (CKDMIP); Hogan & Matricardi
(2022), *J. Adv. Model. Earth Syst.*, DOI 10.1029/2022MS003033 (the ecCKD
tool).

## What ecCKD Stores

An ecCKD CKD-definition file stores tabulated gas absorption and supporting
spectral data. NumericalRadiation loads these files into
[`EcCKDTabulatedGasOpticsModel`](@ref), which holds:

- longwave and shortwave absorption tables,
- pressure and temperature interpolation grids,
- gas names and optional water-vapor dependent tables,
- longwave and shortwave quadrature weights,
- shortwave Rayleigh scattering data when available.

At runtime, [`optical_properties!`](@ref) interpolates the tables to each
layer, multiplies by gas path amounts, and fills
[`LongwaveOptics`](@ref) and [`ShortwaveOptics`](@ref).

## Accuracy and Cost

Increasing the number of g points improves the quadrature approximation but
also increases the cost of optical-property evaluation and column transport.
The published ecCKD pairs exposed by this package are:

| selector | longwave g points | shortwave g points |
| --- | ---: | ---: |
| `"32x32"` | 32 | 32 |
| `"32x64"` | 32 | 64 |
| `"32x96"` | 32 | 96 |
| `"64x32"` | 64 | 32 |
| `"64x64"` | 64 | 64 |
| `"64x96"` | 64 | 96 |

The validation workflow compares these reduced models against ecRad and
RRTMGP-style references, then reports flux and heating errors as a function of
g-point count. New reduced models should be judged by the same metrics before
being used in prognostic simulations.
