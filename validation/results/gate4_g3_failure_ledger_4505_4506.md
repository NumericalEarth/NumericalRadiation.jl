# Gate-4 G3 failure ledger: attempts 4505 (LW) / 4506 (SW)

Status: **g3_attempts_4505_4506_failed_semantic_diagnosed**

read-only evidence ledger; writes nothing except its own JSON/MD results.

| Gate | Result |
|---|---|
| evidence_childlog_lw | passed |
| evidence_childlog_sw | passed |
| evidence_commit_ancestry | passed |
| evidence_joblog_lw | passed |
| evidence_joblog_sw | passed |
| evidence_receipt_lw | passed |
| evidence_receipt_sw | passed |
| evidence_runroot_preserved_lw | passed |
| evidence_runroot_preserved_sw | passed |
| evidence_script_blob_pin_lw | passed |
| evidence_script_blob_pin_sw | passed |
| fixtures | passed |

Mechanism: SIGFPE in ATLAS at the FIRST LAPACK call (inv(background), ckd_model.cpp:681) under unconditional FP traps; child status flattened to rc 1 by the upstream tee/PIPESTATUS pipeline. The H5open shim worked; inputs/staging were not at fault.

Remedy decision (executor amendment, separate commit): exact-version Netlib preload-only, BLAS:LAPACK:H5-shim order, no LD_LIBRARY_PATH; plus raw child rc/signal surfacing.

Forensics: both RUNROOTs preserved; four custody files digest-bound (Agent 42 capture-suffix protocol); canonical finals absent at authoring.
