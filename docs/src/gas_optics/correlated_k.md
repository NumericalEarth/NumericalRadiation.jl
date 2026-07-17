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

The quadrature nodes ``k_{b,i}`` and weights ``w_{b,i}`` are the g points.
The "correlated" assumption is that the sorted absorption ordering remains
usable as pressure, temperature, and gas composition vary across the column.

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
[`LongwaveOpticalProperties`](@ref) and [`ShortwaveOpticalProperties`](@ref).

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
