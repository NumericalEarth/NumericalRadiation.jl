# Gate-4 G2c fetch completion ledger

Status: **g2c_fetch_completed_verified** -- terminal log 4500 + stable disk 70/70 exact + h5-open all + no .part in either band dir

read-only evidence ledger; nothing submitted, fetched, or modified by this unit outside its own results artifacts.

| Gate | Result |
|---|---|
| attempt_registry_integrity | passed |
| fixtures | passed |
| latest_registered_attempt_evidenced | passed |
| log_scan_readable | passed |
| manifest_integrity | passed |
| no_unregistered_newer_attempt | passed |
| reviewed_sbatch_sha_pinned | passed |
| scheduler_probe_ok | passed |
| terminal_log_digest_bound | passed |
| termination_receipt_bound | passed |

Attempts (job id: log state):
- 4440 [UNREGISTERED legacy]: semantic_failure (FINALIZED lines: 0; provenance only)
- 4500 [registered]: terminal_complete (FINALIZED lines: 40; provenance only)

Queue probe: ok=true, active=0, unregistered_active=false

Termination receipt: readable=true, JobState=COMPLETED, bound=true, sha256=759f56047841fb53d08b11b0cffcc5707357e6351c8e205d31d720f464dfcbd6

Disk: 70/70 exact-size finals; 0 .part (both band dirs enumerated); stable=true; h5-opened every final: true

Continuity policy: TIMEOUT-only resumption of the SAME reviewed sbatch is covered by the recorded durable G2c authorization; requires state g2c_fetch_ledger_resumable_timeout (stable clean-part disk), live quota guard pass, scheduler probe OK with no duplicate, unchanged reviewed sbatch sha, and a registry row appended for the new job ID at resubmission. Semantic failures are NEVER auto-resubmitted.
