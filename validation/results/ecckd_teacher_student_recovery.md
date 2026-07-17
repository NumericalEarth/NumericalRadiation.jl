# ecCKD Teacher-Student Recovery

Status: **passed**

| Field | Value |
|---|---:|
| Published reference | `/shared/home/greg/.julia/artifacts/49ce668ce0861f9d5e8299d68af7138485eb5f19/ecrad-131ac980517719b7a859e3ccc117919a1d888a20/data/ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc` |
| Recovered candidate | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_recovered_sw32_candidate.nc` |
| Coefficient arrays | 6 |
| Parameters | 172992 |
| Optimizer | Enzyme reverse-mode gradient descent in log-coefficient space |
| Iterations | 32 |
| Initial loss | 0.0002498636616492827 |
| Final loss | 1.568419624147537e-10 |
| Loss reduction factor | 1.5930919111337177e6 |
| Enzyme used for training | true |
| Reactant compile check | passed |
| Recovery metrics status | passed |
| Worst log-coefficient RMSE | 1.2571419279602349e-5 |
| Worst p99 relative coefficient error | 2.3427731855160456e-5 |
| G-point weight max abs error | 0.0 |
| Band weight max abs error | 0.0 |

This is a teacher-student recovery gate against a published ecCKD NetCDF
definition. It keeps topology, coefficient shapes, and the coefficient
target fixed, then varies only the Julia optimizer stack.
