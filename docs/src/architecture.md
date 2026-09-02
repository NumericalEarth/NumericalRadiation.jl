# Architecture

The package exposes the existing analytic-band column solvers through three
levels of API.

## High-level column update

[`radiative_heating!`](@ref) runs the reusable [`RadiativeTransferColumn`](@ref)
workspace by calling longwave and shortwave component solvers. This is the
convenience path for examples and single-column workflows.

## Component access

Host models can call [`solve_longwave!`](@ref), [`solve_shortwave!`](@ref), and
[`heating_rates!`](@ref) independently. This keeps solver, flux, and tendency
ownership explicit for models that need their own vertical integrals or
tendency insertion.

The staged interface also defines [`optical_properties!`](@ref),
[`cloud_optical_properties!`](@ref), [`aerosol_optical_properties!`](@ref), and
[`radiative_fluxes!`](@ref) for gas-optics and solver implementations. The
ecCKD tabulated models ([`EcCKDTabulatedGasOpticsModel`](@ref)) fill
[`LongwaveOpticalProperties`](@ref) and [`ShortwaveOpticalProperties`](@ref),
and the staged solvers cover clear-sky ([`CloudlessLongwave`](@ref),
[`CloudlessShortwave`](@ref)) and cloud-overlap
([`CloudOverlapLongwave`](@ref), [`CloudOverlapShortwave`](@ref)) transport,
all writing caller-owned [`RadiativeFluxes`](@ref).

[`heating_rates!`](@ref) can convert [`RadiativeFluxes`](@ref) into layer
heating rates for a [`ColumnAtmosphere`](@ref) using explicit `gravity` and
`heat_capacity` keywords. The convention is top-down pressure interfaces,
net-downward flux, and positive heating for atmospheric warming.

## Workspace access

[`radiation_workspace`](@ref) returns reusable storage for repeated runtime
calls. For the current analytic-band path, [`RadiativeTransferColumn`](@ref) is
already the workspace: it owns the temperature-tendency vector, shortwave
transmissivity scratch, and diagnostics.

Host integrations — such as the SpeedyWeather and RRTMGP package extensions —
should prefer caller-owned arrays, views, or explicit workspaces over
per-call temporary arrays.
