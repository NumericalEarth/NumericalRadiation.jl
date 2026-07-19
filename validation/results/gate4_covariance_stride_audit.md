# Gate-4 covariance-stride audit

Status: **covariance_stride_audit_passed**

index/stride audit only; no floor, objective-value, or recovery claim.

| Gate | Result |
|---|---|
| prior_per_g_independent | passed |
| recovery_vector_mapping | passed |
| stride_2d_permutation_conjugate | passed |
| stride_3d_permutation_conjugate | passed |
| support_arrays_not_prior_regularized | passed |

Key finding: upstream per-g prior order is p-fastest (alpha = it*np+ip; 3-D adds ic*nt*np), the local flatten is t-fastest, and the two are PROVEN permutation-conjugate with equal quadratic forms; the whole-file recovery-vector order (g fastest) is a distinct, separately proven mapping. The g-point sits outside the covariance (per-g prior independence verified by gradient).

Provenance: branch `glw/gate4-recovery`, generated_from_head `fee860f` (pre-own-commit).
