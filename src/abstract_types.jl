"""
    AbstractRadiationScheme

Root type for column radiation schemes defined by `NumericalRadiation`.
"""
abstract type AbstractRadiationScheme end

"""
    AbstractLongwaveScheme <: AbstractRadiationScheme

A column longwave radiative transfer scheme. Concrete subtypes implement
[`solve_longwave!`](@ref).
"""
abstract type AbstractLongwaveScheme <: AbstractRadiationScheme end

"""
    AbstractShortwaveScheme <: AbstractRadiationScheme

A column shortwave radiative transfer scheme. Concrete subtypes implement
[`solve_shortwave!`](@ref).
"""
abstract type AbstractShortwaveScheme <: AbstractRadiationScheme end

"""
    AbstractShortwaveTransmissivity <: AbstractRadiationScheme

A layer-transmissivity model used by shortwave radiative-transfer solvers.
"""
abstract type AbstractShortwaveTransmissivity <: AbstractRadiationScheme end

"""
    AbstractShortwaveClouds <: AbstractRadiationScheme

A diagnostic cloud model for the shortwave.
"""
abstract type AbstractShortwaveClouds <: AbstractRadiationScheme end

"""
    AbstractAtmosphericState

Root type for atmospheric states accepted by the staged radiation interface.
Host models may provide their own state/view types when they implement the
required component methods.
"""
abstract type AbstractAtmosphericState end

"""
    AbstractGasOpticsModel

Root type for gas-optics models that can materialize optical properties or
source terms independently of a radiative-transfer solver.
"""
abstract type AbstractGasOpticsModel end

"""
    AbstractCloudOpticsModel

Root type for cloud-optics models that can be evaluated independently of gas
optics and solvers.
"""
abstract type AbstractCloudOpticsModel end

"""
    AbstractAerosolOpticsModel

Root type for aerosol-optics models that can be evaluated independently of gas
optics and solvers.
"""
abstract type AbstractAerosolOpticsModel end

"""
    AbstractRadiativeTransferSolver

Root type for solvers that consume optical properties/source terms and produce
fluxes.
"""
abstract type AbstractRadiativeTransferSolver end

"""
    AbstractRadiationBackend

Root type for runtime backends such as CPU, CUDA, or host-model-specific
kernel launch paths.
"""
abstract type AbstractRadiationBackend end
