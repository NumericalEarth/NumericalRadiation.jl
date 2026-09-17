# Column Schemes

## Umbrella Column Wrapper

```@docs
RadiativeTransferColumn
reset!
radiative_heating!
radiation_workspace
```

## Column Inputs

```@docs
AtmosphereProfile
ColumnGrid
SurfaceState
PhysicalConstants
ThermodynamicConstants
default_earth_constants
LongwaveDiagnostics
ShortwaveDiagnostics
```

## Longwave

```@docs
AbstractLongwaveScheme
AnalyticBandLongwave
solve_longwave!
planck_wavenumber
water_vapor_line_absorption_reference
water_vapor_continuum_absorption_reference
carbon_dioxide_absorption_reference
NumericalRadiation.williams_optical_depth_increment
```

## Shortwave

```@docs
AbstractShortwaveScheme
NumericalRadiation.TransparentShortwave
NumericalRadiation.OneBandShortwave
NumericalRadiation.OneBandGreyShortwave
OneBandShortwaveRadiativeTransfer
NumericalRadiation.AbstractShortwaveTransmissivity
ConstantShortwaveTransmissivity
BackgroundShortwaveTransmissivity
NumericalRadiation.compute_transmissivity!
NumericalRadiation.AbstractShortwaveClouds
NoClouds
DiagnosticClouds
solve_shortwave!
```

## Solar Geometry and Thermodynamics

```@docs
solar_declination
equation_of_time
cosine_solar_zenith
NumericalRadiation.fractional_year_angle
NumericalRadiation.saturation_humidity
```
