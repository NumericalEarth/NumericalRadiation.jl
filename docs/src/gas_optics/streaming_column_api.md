# Streaming column API for host kernels

The [staged runtime](../solvers.md) fills `(Ngpoints, nlayers)` optics arrays for a
whole column and then solves them. A host model that runs radiation inside its
own kernels — one thread per column, no allocation, no intermediate `(Ngpoints, nlayers)`
matrices — needs the same physics as scalar, per-layer, per-g-point functions.
This page documents that *streaming* form of the API: the loop a host kernel
runs, the conventions its arguments follow, and the guarantee that i₀ᵀ
reproduces the array path bit for bit. It is the layer the
`NumericalRadiation` extension of
[Breeze.jl](https://github.com/NumericalEarth/Breeze.jl) (in progress) is
built on.

## Conventions

The streaming functions share the package conventions of the array path:

- **Ordering.** Layers are indexed `k = 1:nlayers` from the top of the
  atmosphere down; interface arrays have `nlayers + 1` entries with index 1 at
  the top. A host whose own columns run bottom-up flips the index when i₀ᵀ
  stages the column.
- **Gases.** A layer's gas amounts are a `NamedTuple` of scalars in mol m⁻²
  keyed by the model's gas names ([`gas_names`](@ref)), plus `composite` (dry
  air) whenever the model applies the ecCKD relative-linear convention. The
  gas keys (`h2o`, `co2`, `o3`, `ch4`, `n2o`, `cfc11`, `cfc12`, `composite`)
  mirror the ecCKD NetCDF variable prefixes and are the one place the package
  abbreviates a species; every other identifier spells i₀ᵀ out
  (`water_vapor_mole_fraction`, [`water_vapor_table_optical_depth`](@ref)). The
  H₂O mole fraction handed to [`gas_optics_stencil`](@ref) is relative to dry
  air, `h2o / composite`. The ecCKD tables expect the *dry* column-amount
  convention: for a hydrostatic layer of pressure thickness `Δp`,
  `composite = Δp / (g mᵈ)` — the whole layer mass over the dry molar mass,
  so in a host model `composite = ρ Δz / mᵈ` with the *total* density — and
  every gas is `χ composite` (`h2o = χ composite`). This is how the ecCKD tool
  derived the molar absorption coefficients from the line-by-line optical
  depths and how ecRad applies them, so i₀ᵀ reproduces the ecRad/CKDMIP
  reference fluxes (`validation/ckdmip_evaluation1.jl`). The moist molar-mass
  convention `composite = Δp / (g (mᵈ + mᵛ χ))`, under which
  `mᵈ composite + mᵛ h2o == Δp / g`, is an alternative that under-counts every
  absorber by the factor `1 + χ mᵛ/mᵈ` (up to ~3 % in the humid boundary
  layer); on the CKDMIP profiles i₀ᵀ biases the surface downwelling longwave
  flux by about −0.2 W m⁻² and raises the surface shortwave RMSE by ~50 %.
- **Fluxes.** Longwave and shortwave fluxes are each positive in their own
  direction, in W m⁻²; the streaming solvers zero their output arrays before
  accumulating the weighted g points into them.
- **Shortwave geometry.** `toa_irradiance` is the downwelling flux through a
  horizontal surface at the top of the atmosphere, `S₀ μ₀`. A host passes
  `S₀ max(μ₀, 0)` so that night (`μ₀ ≤ 0`) yields exact zeros without a
  branch; the solver clamps `μ₀` to `√eps(FT)` internally, so there is no `NaN`.
- **Precision.** `FT` is threaded from the model type: a `Float32` model
  ([`read_reference_ecckd_gas_optics`](@ref)`(Float32, "32x32")`, or
  `Adapt.adapt(Array{Float32}, model)`) produces `Float32` stencils, optical
  depths and sources, and the solvers take `FT` from the flux arrays.
- **Device rules.** Every function on this page is `@inline`, allocation-free,
  never throws, branches on model structure (empty tables, `Nothing` phases)
  but not on data, and uses `ifelse` rather than data-dependent control flow.
  Scratch storage is caller-owned, so a kernel hands in views of its own
  device arrays.

## The loop

One column is three sweeps of scalar calls:

```text
per layer k:      s = gas_optics_stencil(model, p, T, χ)          # once per layer
                  b = source_table_bracket(model, T_interface)     # once per interface

per g point:      longwave_optical_depth(model, gpoint, gases, s)      # LW  τ
                  longwave_source(model, gpoint, T_interface, b)       # LW  B at each interface
                  shortwave_optical_depth(model, gpoint, gases, s)     # SW  τ_absorption
                  rayleigh_optical_depth(model, gpoint, air_moles)     # SW  τ_scattering
                  add_cloud_scattering_layer(…, cloud, gpoint, b, water_path)  # clouds, per phase

per column:       streaming_longwave_fluxes!(…)
                  streaming_shortwave_fluxes!(…)
```

### Per-layer state

[`gas_optics_stencil`](@ref) brackets one layer's pressure, temperature and
H₂O mole fraction on the coefficient tables of an
[`EcCKDTabulatedGasOpticsModel`](@ref) and returns an `isbits`
[`GasOpticsStencil`](@ref). The stencil depends only on the layer state, so a
kernel builds i₀ᵀ once per layer and reuses i₀ᵀ for every gas and g point. A
host that stages columns in a separate kernel stores the six scalars
`(i₀ᵖ, wᵖ, i₀ᵀ, wᵀ, i₀ᴴ, wᴴ)` per layer and rebuilds the stencil with
`GasOpticsStencil(i₀ᵖ, wᵖ, i₀ᵀ, wᵀ, i₀ᴴ, wᴴ)`. For a fixed-coefficient
[`EcCKDGasOpticsModel`](@ref) the stencil is `nothing`.

[`source_table_bracket`](@ref) does the same for the Planck source table at an
interface temperature; [`longwave_source`](@ref) then interpolates the source
of each g point. Without a source table the source is the gray
`longwave_source_scale[gpoint] σT⁴`.

### Per-g-point optics

[`longwave_optical_depth`](@ref) and [`shortwave_optical_depth`](@ref) return
the gas optical depth of one layer for one g point from the scalar gas
`NamedTuple` and the stencil, clamped at zero as a total (ecCKD's
relative-linear gases may contribute negative optical depth individually).
[`rayleigh_optical_depth`](@ref) is the model's molar Rayleigh coefficient
times the layer's molar amount of air. Clouds enter through
[`SpectralCloudOptics`](@ref): [`effective_radius_bracket`](@ref) once per
layer and phase, then [`cloud_layer_optics`](@ref) gives `(κ, ω, g)` per g
point, which [`add_scattering_layer`](@ref) folds into the layer's
`(τ_absorption, τ_scattering, asymmetry)` for the shortwave and
[`cloud_absorption_optical_depth`](@ref) adds as pure absorption for the
longwave; [`add_cloud_scattering_layer`](@ref) is the shortwave pair of calls
in one. A `Nothing` phase dispatches to no-ops in every one of these
functions (a zero-extinction `(κ, ω, g)`, an unchanged layer, zero
absorption), so the clear-sky and all-sky kernels are the same code.

The kernel packages these calls into two *layer-optics functors* the solvers
call back into, each `(gpoint, k)` returning the layer's tuple:

| Solver | `layer_optics(gpoint, k)` returns |
|:-------|:------------------------------|
| [`streaming_longwave_fluxes!`](@ref) | `(τ, B_top, B_bottom)` — optical depth and the Planck source at the layer's two interfaces |
| [`streaming_shortwave_fluxes!`](@ref) | `(τ_absorption, τ_scattering, asymmetry)` — the single-scattering albedo and total optical depth are formed inside the solver |

### Per-column solve

[`streaming_longwave_fluxes!`](@ref) is the no-scattering longwave of
[`CloudlessLongwave`](@ref) with g points streamed: the ecRad half-level
Planck path with diffusivity `D = 1.66`, swept down from `toa_down` and then up
from the surface, where `up = surface_emission[gpoint] + surface_albedo * down`.
The surface source is a [`TabulatedSurfaceEmission`](@ref), which brackets the
surface temperature once and evaluates `ε B(Tₛ)` lazily per g point. Two
caller-owned scratch vectors of length `nlayers` carry the layer transmittance
and upward source between the sweeps.

[`streaming_shortwave_fluxes!`](@ref) is the two-stream adding method of
[`CloudlessShortwave`](@ref) with g points streamed: every layer passes
through [`NumericalRadiation.shortwave_two_stream_layer`](@ref) (delta-Eddington
scaling inside), and the adding sweeps run on a
[`ShortwaveColumnScratch`](@ref) — five layer vectors and two interface
vectors that a kernel supplies as views of its own arrays. The direct and
diffuse surface albedos may be broadband numbers or per-g-point indexables.

## Agreement with the array path

The array methods are loops over these functions: `optical_properties!` calls
`gas_optics_stencil` and the `*_optical_depth` functions layer by layer,
`radiative_fluxes!(…, CloudlessLongwave(), …)` calls
`streaming_longwave_fluxes!` one g point at a time whenever interface Planck
sources are present, and `radiative_fluxes!(…, CloudlessShortwave(), …)` runs
the same adding step for every g point that scatters. So the streaming path
reproduces the array path bit for bit; `test/test_streaming.jl` pins this on
the reference `climate_32x32` tables, and `test/access_points_check.jl` on the
2-layer toy model below. The one deliberate exception is a shortwave g point
with no scattering at all, which the array solver routes through a closed-form
Beer–Lambert branch. Both paths give the same direct beam, but the closed form
sends the surface-reflected flux back up as a slant beam, `e^{-τ/μ₀}`, whereas
the adding method treats i₀ᵀ as diffuse and attenuates i₀ᵀ with the two-stream
diffusivity 2, `e^{-2τ}`; the reflected fluxes therefore differ for such a g
point except at `μ₀ = 1/2`, where the two attenuations coincide. Every g point
of the reference ecCKD tables has Rayleigh scattering, so this branch is not
reached with them.

## A two-layer column

The fixed-coefficient toy model of `test/access_points_check.jl` has two
longwave and one shortwave g point, so the whole loop fits in a few lines.
Layer state is kept in a `NamedTuple`; a kernel would read the same scalars
from its own column arrays.

```jldoctest streaming
julia> using NumericalRadiation

julia> model = EcCKDGasOpticsModel(names = (:h2o, :co2),
                                   longwave_absorption = [0.08 0.004; 0.03 0.002],
                                   shortwave_absorption = [0.010 0.0008],
                                   longwave_source_scale = [1.0, 1.05],
                                   longwave_weights = [0.55, 0.45],
                                   shortwave_weights = [1.0]);

julia> column = (pressure = [20_000.0, 70_000.0],
                 pressure_interfaces = [1_000.0, 45_000.0, 100_000.0],
                 temperature = [240.0, 285.0],
                 temperature_interfaces = [230.0, 260.0, 295.0],
                 h2o = [0.002, 0.014],
                 co2 = 420e-6,
                 constants = PhysicalConstants());
```

The column carries the host's physical constants; nothing on this path has a
constant of its own (the model's `stefan_boltzmann` is set at construction).

The longwave functor builds the stencil, the optical depth and the two
interface Planck sources of layer `k` for g point `gpoint`:

```jldoctest streaming
julia> struct LongwaveLayers{M, C}
           model :: M
           column :: C
       end

julia> function (layers::LongwaveLayers)(gpoint, k)
           (; model, column) = layers
           gases = (h2o = column.h2o[k], co2 = column.co2)
           stencil = gas_optics_stencil(model, column.pressure[k], column.temperature[k], 0.0)
           τ = longwave_optical_depth(model, gpoint, gases, stencil)
           T_top, T_bottom = column.temperature_interfaces[k], column.temperature_interfaces[k + 1]
           B_top = longwave_source(model, gpoint, T_top, source_table_bracket(model, T_top))
           B_bottom = longwave_source(model, gpoint, T_bottom, source_table_bracket(model, T_bottom))
           return τ, B_top, B_bottom
       end;

julia> nlayers = 2;

julia> surface = TabulatedSurfaceEmission(model, 295.0; emissivity = 0.98);

julia> longwave_up, longwave_down = zeros(nlayers + 1), zeros(nlayers + 1);

julia> streaming_longwave_fluxes!(longwave_up, longwave_down, LongwaveLayers(model, column),
                                  surface, 0.02, 0.0, model.longwave_weights, 2, nlayers,
                                  zeros(nlayers), zeros(nlayers));

julia> round.(longwave_up; digits = 2)
3-element Vector{Float64}:
 430.18
 430.22
 430.33
```

The shortwave functor returns the absorption optical depth, the Rayleigh
scattering optical depth from the layer's molar amount of air —
`hydrostatic_air_moles` with the column's gravity and dry-air molar mass, as
the array path computes i₀ᵀ — and the scattering asymmetry (zero for Rayleigh
scattering; clouds would raise i₀ᵀ through `add_scattering_layer`):

```jldoctest streaming
julia> struct ShortwaveLayers{M, C}
           model :: M
           column :: C
       end

julia> function (layers::ShortwaveLayers)(gpoint, k)
           (; model, column) = layers
           gases = (h2o = column.h2o[k], co2 = column.co2)
           stencil = gas_optics_stencil(model, column.pressure[k], column.temperature[k], 0.0)
           τ = shortwave_optical_depth(model, gpoint, gases, stencil)
           Δp = column.pressure_interfaces[k + 1] - column.pressure_interfaces[k]
           (; gravity, dry_air_molar_mass) = column.constants
           air_moles = hydrostatic_air_moles(Δp, gravity, dry_air_molar_mass)
           return τ, rayleigh_optical_depth(model, gpoint, air_moles), 0.0
       end;

julia> μ₀, S₀, albedo = 0.5, column.constants.solar_constant, 0.1;

julia> shortwave_up, shortwave_down = zeros(nlayers + 1), zeros(nlayers + 1);

julia> streaming_shortwave_fluxes!(shortwave_up, shortwave_down, ShortwaveLayers(model, column),
                                   μ₀, S₀ * max(μ₀, 0), albedo, albedo, model.shortwave_weights,
                                   1, nlayers, ShortwaveColumnScratch(Float64, nlayers));

julia> round.(shortwave_down; digits = 2)
3-element Vector{Float64}:
 680.5
 680.47
 680.28
```

The same column through the array path — `optical_properties!` into
`(Ngpoints, nlayers)` work arrays with interface Planck sources, then
`radiative_fluxes!` — gives the same longwave fluxes bit for bit, and at this
`μ₀ = 0.5` the same shortwave fluxes to rounding (this toy model has no
Rayleigh table, so its single shortwave g point takes the Beer–Lambert branch
of the array solver, which agrees with the adding method only at `μ₀ = 1/2`,
see [above](#Agreement-with-the-array-path); with scattering the two would be
bitwise equal at any `μ₀`):

```jldoctest streaming
julia> atmosphere = ColumnAtmosphere(pressure_layers = column.pressure,
                                     pressure_interfaces = column.pressure_interfaces,
                                     temperature_layers = column.temperature,
                                     temperature_interfaces = column.temperature_interfaces,
                                     gases = (; h2o = column.h2o, co2 = column.co2),
                                     surface = (; temperature = 295.0),
                                     geometry = (; cos_zenith = μ₀));

julia> longwave = LongwaveOptics(zeros(2, nlayers), zeros(2, nlayers);
                                 source_top = zeros(2, nlayers),
                                 source_bottom = zeros(2, nlayers),
                                 weights = zeros(2));

julia> shortwave = ShortwaveOptics(zeros(1, nlayers); weights = zeros(1));

julia> optical_properties!(longwave, shortwave, model, atmosphere);

julia> fluxes = RadiativeFluxes(longwave_up = zeros(nlayers + 1),
                                longwave_down = zeros(nlayers + 1),
                                shortwave_up = zeros(nlayers + 1),
                                shortwave_down = zeros(nlayers + 1));

julia> radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, atmosphere,
                         LongwaveBoundaryConditions(surface_longwave_up = surface,
                                                    surface_albedo = 0.02));

julia> radiative_fluxes!(fluxes, CloudlessShortwave(), shortwave, atmosphere,
                         ShortwaveBoundaryConditions(toa_shortwave_down = S₀ * μ₀,
                                                     surface_albedo = albedo));

julia> fluxes.longwave_up == longwave_up && fluxes.longwave_down == longwave_down
true

julia> fluxes.shortwave_up ≈ shortwave_up && fluxes.shortwave_down ≈ shortwave_down
true
```

In a kernel the two functors are one `struct` per stream holding the
gas-optics model, the column's device arrays and the column index, the
stencil and source brackets are read from arrays filled by a staging kernel,
and the flux and scratch arguments are views of one row of the host's
`(ncolumns, nlayers + 1)` and `(ncolumns, nlayers)` matrices. Nothing in the
loop above allocates, so that kernel is the loop above with the host's arrays
in place of `column`.
