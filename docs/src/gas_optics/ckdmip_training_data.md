# CKDMIP Training Data

The published ecCKD generation workflow depends on CKDMIP data in two very
different size classes:

- small source and model-definition assets, which this package can resolve
  automatically through `Artifacts.toml`;
- the full CKDMIP line-by-line spectral absorption database, which is too large
  for ordinary package instantiation or CI.

The small assets are artifact-backed:

- `ecrad_data`: official ecRad data files, including published ecCKD
  CKD-definition NetCDF files and reduced CKDMIP evaluation files;
- `ecckd_source`: official ecCKD v1.2 source, including `optimize_lut`,
  Adept-based cost functions, and the shell scripts that encode the published
  training workflow.

The full line-by-line database must be provided separately. The official CKDMIP
page lists the public data endpoint:

```text
https://aux.ecmwf.int/ecpds/home/ckdmip/
ftp://ckdmip:<non-empty-password>@aux.ecmwf.int
```

The ecCKD source expects a local CKDMIP tree with subdirectories like:

```text
$RH_CKDMIP_DATA_PATH/
  mmm/
    conc/
    lw_spectra/
    sw_spectra/
    sw_spectra_extras/
  idealized/
    conc/
    lw_spectra/
    sw_spectra/
  evaluation1/
    conc/
    lw_spectra/
    sw_spectra/
    lw_fluxes/
    sw_fluxes/
  evaluation2/
    conc/
    lw_spectra/
    sw_spectra/
    lw_fluxes/
    sw_fluxes/
```

Set `RH_CKDMIP_DATA_PATH` to the root of that mounted or downloaded tree before
running exact ecCKD objective-reconstruction experiments. The `5gas-*` and
`rel-*` flux files are not public CKDMIP archive inputs; they must be generated
locally from the spectra before the exact original ecCKD objective can be
reconstructed.

The download planner, tree preflight, and objective-reconstruction check
scripts — the validation platform, its gates, and its evidence — live on the
`validation-platform` branch.

Do not add the full CKDMIP line-by-line database to the default package
artifacts. It is large enough that downloads should be explicit, resumable, and
owned by the user or by a dedicated data-preparation job.
