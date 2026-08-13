# Gate-4 G2d flux completion ledger

Status: **g2d_flux_completed_verified**

read-only evidence ledger; writes nothing except its own JSON/MD results.

| Gate | Result |
|---|---|
| evidence_checkpoint_json_pin | passed |
| evidence_checkpoint_source_pin | passed |
| evidence_commit_ancestry | passed |
| evidence_flux_outputs_and_installs | passed |
| evidence_rayleigh_finals | passed |
| evidence_receipt_cross_check | passed |
| evidence_residue | passed |
| evidence_sbatch_pin | passed |
| evidence_terminal_log | passed |
| evidence_terminal_monitor_output | passed |
| evidence_termination_receipt | passed |
| fixtures | passed |
| validator_extracted_from_pinned_sbatch | passed |

Attempt: job 4503 (COMPLETED 0:0, 02:12:42 of 08:00:00), dual receipt + log digest-bound; see JSON.

Outputs: LW 451045 B x 2 copies; SW 1817493 B x 3 copies; rayleigh 5 finals (~4.2 GiB); every copy full-schema validated.

Receipt pin note: the termination-record file was first captured 2026-08-13T14:57:48 (full receipt sha 59d79073..., disclosed) and overwritten at 14:59:22 by session 40's re-capture of the same completed job (7328195a..., bound as evidence A; the re-capture lacks the DerivedExitCode line). Per the monitor's receipt ruling the ORIGINAL 14:57:48 watcher output is preserved at /shared/home/greg/data/ckdmip-logs/g4-g2d-4503-terminal-monitor-output.txt (stored read-only at preservation; content digest-bound to aaeed4d4... by this ledger) and bound as evidence B for the terminal-capture timestamp, DerivedExitCode, and the done/hash tail; common fields are cross-checked exactly. The two FULL receipts are NOT claimed byte- or field-identical.
