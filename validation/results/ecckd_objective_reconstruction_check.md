# ecCKD Objective Reconstruction Check

Status: **blocked_missing_original_training_assets**

ecRad source root: `/shared/home/greg/.julia/artifacts/49ce668ce0861f9d5e8299d68af7138485eb5f19/ecrad-131ac980517719b7a859e3ccc117919a1d888a20`

ecCKD source root: `/shared/home/greg/.julia/artifacts/7b210aef53e908cfe3c709945f0763c37ca82aaa/ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd`

Current supported recovery: Teacher-student coefficient recovery against published ecCKD CKD-definition files using Reactant compilation checks and Enzyme gradients.

## Checks

| Asset | Present | Role | Evidence count |
|---|---:|---|---:|
| published ecCKD CKD-definition files | true | Published model targets for schema validation, teacher-student recovery, and coefficient comparisons. | 6 |
| CKDMIP evaluation profiles and reference fluxes | true | Evaluation data for radiation-model comparison after a model has been generated. | 3 |
| ecRad CKDMIP evaluation scripts | true | Reference examples for evaluating CKD files in ecRad. | 4 |
| ecRad runtime ecCKD source | true | Runtime implementation needed to understand how published CKD-definition files are consumed. | 3 |
| original LBL training database | false | Upstream CKDMIP spectra, concentrations, and public flux inputs required before derived ecCKD training fluxes can be generated. | 0 |
| derived ecCKD training flux products | false | Derived 5-gas and relative-humidity perturbation flux products consumed by the published ecCKD optimizer scripts. | 18 |
| official ecCKD generator and optimizer source | true | Required to keep all non-optimizer choices identical while swapping in the Reactant/Enzyme optimizer. | 4 |
| official ecCKD objective weights and training scripts | true | Required to define the exact gases, profiles, spectral weights, loss terms, and stopping criteria used by the published models. | 5 |

## Blockers

- No complete CKDMIP line-by-line training tree was found; set RH_CKDMIP_DATA_PATH to a mounted/downloaded CKDMIP data root and run ckdmip_training_data_preflight.

## Next Required Inputs

- Set RH_CKDMIP_DATA_PATH to a complete CKDMIP tree with public upstream spectra, concentration, and flux inputs.
- Generate the derived ecCKD 5gas/rel training flux products locally from the upstream spectra if they are not already present.
- Encode the original profile set, spectral weights, gases, loss terms, and stopping criteria before varying optimizer settings.
