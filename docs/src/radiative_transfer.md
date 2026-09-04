# Radiative Transfer

Radiation schemes in this package solve a one-dimensional column problem. The
column assumption is the plane-parallel approximation: thermodynamic and
composition fields vary in height, while each layer is horizontally uniform
over the radiation column. Three-dimensional host models call the column solver
for many independent columns.

## Continuous Equation

For monochromatic intensity ``I_\nu`` at wavenumber ``\nu`` and direction
cosine ``\mu``, the plane-parallel radiative transfer equation can be written
in optical-depth coordinates as

```math
\mu \frac{\partial I_\nu(\tau_\nu, \mu)}{\partial \tau_\nu}
  = I_\nu(\tau_\nu, \mu) - S_\nu(\tau_\nu, \mu).
```

Here ``\tau_\nu`` increases along the absorbing path and ``S_\nu`` is the
source function. In clear-sky thermal longwave transfer without scattering,

```math
S_\nu = B_\nu(T),
```

where ``B_\nu`` is the Planck function. In shortwave transfer, the source is
solar illumination plus scattering terms. The solvers exposed here currently
use staged optical properties: gas optics, cloud optics, and aerosol optics
produce optical depth and scattering fields, then a radiative-transfer solver
integrates the fluxes.

## Fluxes and Heating

The hemispheric fluxes are angular moments of intensity,

```math
F_\nu^+ = 2\pi \int_0^1 \mu I_\nu(\mu)\,d\mu,
\qquad
F_\nu^- = 2\pi \int_0^1 \mu I_\nu(-\mu)\,d\mu.
```

After integrating over spectral interval, the net downward flux is

```math
F_\mathrm{net} = F^\downarrow - F^\uparrow.
```

Layer heating follows from pressure-coordinate flux convergence:

```math
\frac{\partial T}{\partial t}
  = -\frac{g}{c_p}\frac{\partial F_\mathrm{net}}{\partial p}.
```

For layer ``k`` bounded by interfaces ``k`` and ``k+1``, the discrete form used
by the staged column API is

```math
\left(\frac{\partial T}{\partial t}\right)_k
  \approx \frac{g}{c_p}
          \frac{F_{\mathrm{net}, k} - F_{\mathrm{net}, k+1}}
               {p_{k+1} - p_k}.
```

This convention assumes interface pressure increases from top of atmosphere to
surface, matching [`ColumnAtmosphere`](@ref).

## Discrete Optical Depth

For a gas ``m`` with layer path amount ``u_{m,k}``, a tabulated absorption
coefficient ``\kappa_{\nu,m}`` gives layer optical depth

```math
\Delta \tau_{\nu,k} = \sum_m \kappa_{\nu,m}(p_k, T_k, q_k) u_{m,k}.
```

The ecCKD runtime replaces the monochromatic index ``\nu`` with a finite set of
spectral bands and g points. The package keeps that replacement explicit:
[`optical_properties!`](@ref) fills caller-owned arrays, then
[`radiative_fluxes!`](@ref) consumes those arrays. This separation is the main
reason the same gas-optics model can be used in single-column examples,
validation scripts, and host-model integrations.

## Cloud Overlap

Cloudy layers require an additional approximation because the vertical overlap
of cloudy regions is not known from layer cloud fraction alone. The staged
all-sky solvers keep cloud-region optical properties separate from
`cloud_fraction` and `overlap_parameter` so the overlap rule is explicit.

[`CloudOverlapShortwave`](@ref) supports six overlap modes:

- `:maximum`: adjacent cloudy regions overlap as much as possible.
- `:average`: interface cloud fraction is the arithmetic mean of neighboring
  layer fractions.
- `:adding`: clear/cloudy layer reflectance and transmittance are mixed before
  the shortwave adding pass.
- `:matrix_maximum`: clear and cloudy region fluxes are propagated with a
  two-region maximum-overlap matrix.
- `:matrix_alpha`: the two-region matrix uses the supplied ecRad-style alpha
  overlap parameter between adjacent layers.
- `:tripleclouds_alpha`: cloudy regions are split into optically thinner and
  thicker Tripleclouds regions, with alpha overlap applied to the matrix pass.

[`CloudOverlapLongwave`](@ref) currently supports two overlap modes:

- `:adding`: clear/cloudy longwave reflectance, transmittance, and source terms
  are mixed before the scalar adding pass.
- `:tripleclouds_alpha`: cloudy longwave regions use the same alpha-overlap
  Tripleclouds split as the shortwave all-sky path.
