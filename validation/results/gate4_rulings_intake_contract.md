# Gate-4 rulings intake contract

Status: **rulings_intake_awaiting_assignments**

derivative fail-closed rulings intake; no election, no inferred authority, no default decision; the 8 UNASSIGNED rows refuse assignment until a source-proven authority updates the register; unenumerated option sets refuse resolution; the canonical status reflects the latest successfully emitted run (atomic same-directory temp + rename -- a failed write can never truncate or silently preserve a stale-ready artifact as this run's output) and prior decisions survive only as historical non-authorizing evidence.

| Gate | Verdict |
|---|---|
| assignment_state | passed |
| fixtures | passed |
| register_verified_and_sources_fresh | passed |

## Rulings (9 rows, always all 9)

- **R-G2-D1** [OPEN] authority: UNASSIGNED
  - options: {"mode": "unenumerated_refuses_resolution", "note": "no pinned source machine-enumerates exact option IDs; resolution refused until one does"}
- **R-G2-D2** [OPEN] authority: UNASSIGNED
  - options: {"mode": "unenumerated_refuses_resolution", "note": "no pinned source machine-enumerates exact option IDs; resolution refused until one does"}
- **R-G2-D3** [OPEN] authority: UNASSIGNED
  - options: {"mode": "machine_enumerated", "option_ids": ["variant_eps_clamping", "variant_pair_selection"]}
- **R-G2-D4** [OPEN] authority: UNASSIGNED
  - options: {"mode": "unenumerated_refuses_resolution", "note": "no pinned source machine-enumerates exact option IDs; resolution refused until one does"}
- **R-T45-AX1** [OPEN] authority: UNASSIGNED
  - options: {"mode": "unenumerated_refuses_resolution", "note": "no pinned source machine-enumerates exact option IDs; resolution refused until one does"}
- **R-T45-AX2** [OPEN] authority: UNASSIGNED
  - options: {"mode": "unenumerated_refuses_resolution", "note": "no pinned source machine-enumerates exact option IDs; resolution refused until one does"}
  - derived equivalence (not an election): the conjunction (d_toa <= m && d_surface <= m) is mathematically equivalent to max(d_toa, d_surface) <= m when the same margin and the same signed/absolute transform apply; both source-described reporting forms are preserved and marked verdict-equivalent -- they cannot change pass/fail absent a different threshold/transform
- **R-T45-AX3** [OPEN] authority: UNASSIGNED
  - options: {"mode": "unenumerated_refuses_resolution", "note": "no pinned source machine-enumerates exact option IDs; resolution refused until one does"}
- **R-T45-AX4** [OPEN] authority: UNASSIGNED
  - options: {"mode": "unenumerated_refuses_resolution", "note": "no pinned source machine-enumerates exact option IDs; resolution refused until one does"}
- **R-QUOTA-PATH-AD** [OPEN] authority: Greg -- explicitly assigned by the runbook: 'No `rm`, no quo...
  - options: {"mode": "machine_enumerated", "option_ids": ["path_a", "path_d_exact_byte_scope"]}

## Domain readiness

- `g2_binding_runner`: {"missing": ["R-G2-D1", "R-G2-D2", "R-G2-D3", "R-G2-D4"], "ready": false, "requires": ["R-G2-D1", "R-G2-D2", "R-G2-D3", "R-G2-D4"]}
- `quota_path`: {"missing": ["R-QUOTA-PATH-AD"], "non_authorizing_note": "recording a ruling does NOT itself authorize any action: this intake grants no authority for additional deletion, quota change, or job submission; execution requires separate independently verified authorization under the applicable runbook/checkpoint protocol", "requires": ["R-QUOTA-PATH-AD"], "state": "awaiting_ruling"}
- `t45_evaluator`: {"missing": ["R-T45-AX1", "R-T45-AX2", "R-T45-AX3", "R-T45-AX4"], "ready": false, "requires": ["R-T45-AX1", "R-T45-AX2", "R-T45-AX3", "R-T45-AX4"]}

## Assignment source

- path: `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/gate4_rulings_assignment.json` (authored out of band; never written by any unit)
- present: false

## Expected assignment schema

```json
{"authored_at_utc": "<ISO-8601>", "authored_by": "<nonempty; authorship is out of band>", "note": "<optional>", "register_pin": {"case": "gate4_pending_rulings_register", "sha256": "<sha256 of the live register artifact>", "status": "pending_rulings_register_recorded"}, "rulings": [{"decided_at_utc": "<fully anchored ISO-8601>", "decided_by": "<authority; quota requires exactly Greg>", "decision": "<verbatim machine-enumerated option id>", "evidence": {"kind": "<source kind, e.g. conversation_record/file>", "locator": "<independently reviewable locator/record>", "quote": "<exact verbatim quote>", "sha256": "<optional 64-hex digest of the evidence source>"}, "notes": "<optional>", "ruling_id": "<ALL 9 register IDs, each exactly once>", "state": "<OPEN | RESOLVED -- explicit; OPEN rows carry ONLY ruling_id+state; RESOLVED rows require every field below>"}], "schema": "gate4_rulings_assignment_v1"}
```

Provenance: branch `glw/gate4-recovery`, generated_from_head `9216204` (pre-own-commit).
