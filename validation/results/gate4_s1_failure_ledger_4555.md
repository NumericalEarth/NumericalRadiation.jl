# Gate-4 S1 failure ledger: job 4555

Status: **s1_4555_failure_recorded**

ARGUMENT-POSITION link defect in the fresh (9a2a6908) configure's Adept >= 2.1 test: the m4 macro embeds its own -ladept AHEAD of conftest.cpp, so left-to-right linker scanning drops the library before the object that needs adept::compiler_version() (out-of-line, [abi:cxx11]) -> undefined reference -> 'Unable to find Adept library version >= 2.1'. Paths were present (-L + rpath in the failing command); no runtime environment involved.

generated configure vintage differs despite identical current m4 source: the extant built tree's configure (9ed1baac) checks Adept >= 1.1 while m4/adept.m4 is byte-identical (79d60785) between that tree and the artifact; the extant generated configure is stale generated state, so config.status --config (user options only) was insufficient build-equivalence evidence.

Corrected recipe: `./configure --with-adept=/shared/home/greg/local/adept-2-install --with-netcdf=/shared/home/greg/local/ckdmip-stack 'LDFLAGS=-L/shared/home/greg/local/adept-2-install/lib -Wl,-rpath,/shared/home/greg/local/adept-2-install/lib' 'LIBS=-ladept'` (preflight design evidence; ephemeral diagnostics NOT content-pinned; attempt-2 fail-closed configure/config.status is the execution proof)

| Gate | Result |
|---|---|
| evidence_configure_vintage_evidence | passed |
| evidence_dual_receipts | passed |
| evidence_failed_config_log | passed |
| evidence_job_log | passed |
| fixtures | passed |
