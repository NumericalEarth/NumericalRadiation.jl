# ecRad All-Sky Cloud-Effect Diagnostics

This diagnostic compares cloud radiative effects, defined as total-sky net flux minus clear-sky net flux, between ecRad references and `radiative_heating_*` candidate variables.

## all_sky_tropical_column

Status: **missing_cloud_effect_variable**

Path: `validation/reference/ecrad/all_sky_tropical_column.nc`

Missing variables: `radiative_heating_lw_up`, `radiative_heating_lw_down`, `radiative_heating_sw_up`, `radiative_heating_sw_down`, `radiative_heating_heating_rate`, `radiative_heating_lw_up_clear`, `radiative_heating_lw_down_clear`, `radiative_heating_sw_up_clear`, `radiative_heating_sw_down_clear`, `radiative_heating_heating_rate_clear`

## ecckd_all_sky_tropical_column

Status: **diagnosed**

Path: `validation/reference/ecrad/ecckd_all_sky_tropical_column.nc`

### Boundary Cloud Effect Error

| Boundary | Component | RMSE | Max abs | Mean bias | Mean abs | Units |
|---|---|---:|---:|---:|---:|---|
| toa | lw | 0.0433570381216 | 0.11927976108 | 0.0268216077742 | 0.0268216077742 | W m^-2 |
| toa | sw | 0.00411567929948 | 0.00852997698519 | 0.00283105997055 | 0.00283106148167 | W m^-2 |
| toa | total | 0.0459546717149 | 0.121816644466 | 0.0296526677448 | 0.0296526677448 | W m^-2 |
| surface | lw | 0.260672050223 | 0.738309685835 | 0.156024909177 | 0.156024909177 | W m^-2 |
| surface | sw | 0.00317238615501 | 0.00624643420099 | 0.00223758239034 | 0.00223825172982 | W m^-2 |
| surface | total | 0.262591402408 | 0.740687884605 | 0.158262491567 | 0.158262491567 | W m^-2 |

### Profile Cloud Effect Error

| Component | RMSE | Max abs | Mean bias | Mean abs | Units |
|---|---:|---:|---:|---:|---|
| lw | 0.0961445798646 | 0.738309685835 | 0.0450488267791 | 0.0450493536772 | W m^-2 |
| sw | 0.00376641287336 | 0.00875834214264 | 0.00260725284623 | 0.00261232819767 | W m^-2 |
| total | 0.0978679724978 | 0.740687884605 | 0.0476560796254 | 0.0476569665395 | W m^-2 |
| heating_rate | 0.00771176158864 | 0.112223865022 | -0.00104610655569 | 0.00243130570023 | K day^-1 |
